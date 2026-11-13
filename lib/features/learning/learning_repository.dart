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
    try {
      final result = await _client.rpc(
        'get_lesson_interactive_content',
        params: {'p_lesson_id': lessonId},
      );
      return LearningLesson.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (_) {
      final row = await _client
          .from('lessons')
          .select(
            'id, topic_id, title, body_markdown, estimated_minutes, '
            'is_free_preview, display_order, content_blocks, summary',
          )
          .eq('id', lessonId)
          .single();
      return LearningLesson.fromJson(row);
    }
  }

  Future<LearningLesson> getLessonInteractiveContent(String lessonId) async {
    return getLesson(lessonId);
  }

  Future<List<QuestionBankItem>> getTopicAssessmentQuestions({
    required String topicId,
    int limit = 10,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'get_topic_assessment_questions',
      params: {'p_topic_id': topicId, 'p_limit': limit},
    );
    return (result as List<dynamic>)
        .map(
          (row) => QuestionBankItem.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<AssessmentSubmissionResult> submitAssessmentAttempt({
    required String learnerId,
    required String topicId,
    required List<Map<String, dynamic>> answers,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'submit_assessment_attempt',
      params: {
        'p_learner_id': learnerId,
        'p_topic_id': topicId,
        'p_answers': answers,
      },
    );
    return AssessmentSubmissionResult.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
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

  Future<List<ParentLearnerOverview>> getParentDashboardOverview() async {
    _requireUser();
    final result = await _client.rpc('get_parent_dashboard_overview');
    return (result as List<dynamic>)
        .map(
          (row) =>
              ParentLearnerOverview.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  Future<LearnerDashboardData> getLearnerDashboardData(
    String learnerId,
  ) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learner_dashboard_data',
      params: {'p_learner_id': learnerId},
    );
    return LearnerDashboardData.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<List<CurriculumExplorerSubject>> getCurriculumExplorerTree({
    required String countryCode,
    required String educationSystemId,
    String? educationLevelId,
    String? gradeId,
  }) async {
    final result = await _client.rpc(
      'get_curriculum_explorer_tree',
      params: {
        'p_country_code': countryCode,
        'p_education_system_id': educationSystemId,
        'p_education_level_id': ?educationLevelId,
        'p_grade_id': ?gradeId,
      },
    );
    return (result as List<dynamic>)
        .map(
          (row) => CurriculumExplorerSubject.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<List<LearnerRecommendation>> getLearnerRecommendations(
    String learnerId,
  ) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learner_recommendations',
      params: {'p_learner_id': learnerId},
    );
    return (result as List<dynamic>)
        .map(
          (row) => LearnerRecommendation.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<bool> dismissLearnerRecommendation({
    required String learnerId,
    required String recommendationId,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'dismiss_learner_recommendation',
      params: {
        'p_learner_id': learnerId,
        'p_recommendation_id': recommendationId,
      },
    );
    return result as bool? ?? false;
  }

  Future<LearnerMasteryReport> getLearnerMasteryReport(String learnerId) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learner_mastery_report',
      params: {'p_learner_id': learnerId},
    );
    return LearnerMasteryReport.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<LearnerRevisionOverview> getLearnerRevisionOverview(
    String learnerId,
  ) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learner_revision_overview',
      params: {'p_learner_id': learnerId},
    );
    return LearnerRevisionOverview.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<List<QuestionBankItem>> getWeakTopicDrillQuestions(
    String learnerId, {
    int limit = 10,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'get_weak_topic_drill_questions',
      params: {
        'p_learner_id': learnerId,
        'p_limit': limit,
      },
    );
    return (result as List<dynamic>)
        .map(
          (item) => QuestionBankItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<List<FlashcardDeck>> getFlashcardDecks({
    String? learnerId,
    String? subjectId,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'get_flashcard_decks',
      params: {
        'p_learner_id': ?learnerId,
        'p_subject_id': ?subjectId,
      },
    );
    return (result as List<dynamic>)
        .map(
          (item) => FlashcardDeck.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<List<FlashcardItem>> getDeckFlashcards(String deckId) async {
    _requireUser();
    final result = await _client.rpc(
      'get_deck_flashcards',
      params: {'p_deck_id': deckId},
    );
    return (result as List<dynamic>)
        .map(
          (item) => FlashcardItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<List<LearningResourceItem>> getLearningResources({
    required String countryCode,
    String? curriculumId,
    String? subjectId,
    String? resourceType,
    int limit = 50,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'get_learning_resources',
      params: {
        'p_country_code': countryCode,
        'p_curriculum_id': ?curriculumId,
        'p_subject_id': ?subjectId,
        'p_resource_type': ?resourceType,
        'p_limit': limit,
      },
    );
    return (result as List<dynamic>)
        .map(
          (item) => LearningResourceItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotSignedInException();
    }
    return user;
  }
}
