import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import '../learners/learner_models.dart';
import 'learning_models.dart';

class LearningRepository {
  const LearningRepository(this._client);

  final SupabaseClient _client;

  Future<LearningCatalogBundle> loadCatalogForLearner(Learner learner) async {
    _requireUser();
    final subjectsRows = await _client
        .from('subjects')
        .select(
          'id, country_code, curriculum_id, education_level_id, grade_id, '
          'code, name, description, display_order',
        )
        .eq('is_published', true)
        .eq('curriculum_id', learner.curriculumId)
        .eq('education_level_id', learner.educationLevelId)
        .order('display_order', ascending: true);

    final subjects = (subjectsRows as List<dynamic>)
        .map((r) => LearningSubject.fromJson(r as Map<String, dynamic>))
        .where((s) => s.gradeId == null || s.gradeId == learner.gradeId)
        .toList();

    final subjectIds = subjects.map((s) => s.id).toList();
    final topicsBySubject = <String, List<LearningTopic>>{};
    final topicIds = <String>[];

    if (subjectIds.isNotEmpty) {
      final topicsRows = await _client
          .from('topics')
          .select('id, subject_id, title, summary, display_order')
          .inFilter('subject_id', subjectIds)
          .eq('is_published', true)
          .order('display_order', ascending: true);
      for (final row in (topicsRows as List<dynamic>)) {
        final topic = LearningTopic.fromJson(row as Map<String, dynamic>);
        topicsBySubject.putIfAbsent(topic.subjectId, () => []).add(topic);
        topicIds.add(topic.id);
      }
    }

    final lessonsByTopic = <String, List<LearningLesson>>{};
    if (topicIds.isNotEmpty) {
      final lessonsRows = await _client
          .from('lessons')
          .select(
            'id, topic_id, title, body_markdown, estimated_minutes, '
            'is_free_preview, display_order',
          )
          .inFilter('topic_id', topicIds)
          .eq('is_published', true)
          .order('display_order', ascending: true);
      for (final row in (lessonsRows as List<dynamic>)) {
        final lesson = LearningLesson.fromJson(row as Map<String, dynamic>);
        lessonsByTopic.putIfAbsent(lesson.topicId, () => []).add(lesson);
      }
    }

    final progressRows = await _client
        .from('learner_progress')
        .select(
          'id, learner_id, lesson_id, status, reading_progress_percent, '
          'best_quiz_score_percent, attempts_count, completed_at',
        )
        .eq('learner_id', learner.id);
    final progressByLesson = <String, LearnerProgressRecord>{
      for (final row in (progressRows as List<dynamic>))
        (row as Map<String, dynamic>)['lesson_id'] as String:
            LearnerProgressRecord.fromJson(row),
    };

    final summary = await getLearningSummary(learner.id);
    return LearningCatalogBundle(
      subjects: subjects,
      topicsBySubject: topicsBySubject,
      lessonsByTopic: lessonsByTopic,
      progressByLesson: progressByLesson,
      summary: summary,
    );
  }

  Future<LearningLesson> getLesson(String lessonId) async {
    _requireUser();
    final row = await _client
        .from('lessons')
        .select(
          'id, topic_id, title, body_markdown, estimated_minutes, '
          'is_free_preview, display_order',
        )
        .eq('id', lessonId)
        .single();
    return LearningLesson.fromJson(row);
  }

  Future<LearnerLearningSummary> getLearningSummary(String learnerId) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learner_learning_summary',
      params: {'p_learner_id': learnerId},
    );
    return LearnerLearningSummary.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<LearnerProgressRecord> upsertLessonProgress({
    required String learnerId,
    required String lessonId,
    required int readingProgressPercent,
    bool markCompleted = false,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'upsert_learner_lesson_progress',
      params: {
        'p_learner_id': learnerId,
        'p_lesson_id': lessonId,
        'p_reading_progress_percent': readingProgressPercent,
        'p_mark_completed': markCompleted,
      },
    );
    return LearnerProgressRecord.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<PracticeQuiz?> getLessonQuiz({
    required String learnerId,
    required String lessonId,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'get_lesson_practice_quiz',
      params: {'p_learner_id': learnerId, 'p_lesson_id': lessonId},
    );
    if (result == null) return null;
    return PracticeQuiz.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<QuizSubmissionResult> submitQuizAttempt({
    required String learnerId,
    required String quizId,
    required List<int> selectedIndices,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'submit_learner_quiz_attempt',
      params: {
        'p_learner_id': learnerId,
        'p_quiz_id': quizId,
        'p_selected_indices': selectedIndices,
      },
    );
    return QuizSubmissionResult.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotSignedInException();
    }
    return user;
  }
}
