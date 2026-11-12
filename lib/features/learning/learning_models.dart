class LearningSubject {
  const LearningSubject({
    required this.id,
    required this.countryCode,
    required this.curriculumId,
    required this.educationLevelId,
    required this.code,
    required this.name,
    required this.description,
    required this.displayOrder,
    this.gradeId,
  });

  final String id;
  final String countryCode;
  final String curriculumId;
  final String educationLevelId;
  final String? gradeId;
  final String code;
  final String name;
  final String description;
  final int displayOrder;

  factory LearningSubject.fromJson(Map<String, dynamic> json) {
    return LearningSubject(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      curriculumId: json['curriculum_id'] as String,
      educationLevelId: json['education_level_id'] as String,
      gradeId: json['grade_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class LearningTopic {
  const LearningTopic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.summary,
    required this.displayOrder,
  });

  final String id;
  final String subjectId;
  final String title;
  final String summary;
  final int displayOrder;

  factory LearningTopic.fromJson(Map<String, dynamic> json) {
    return LearningTopic(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.bodyMarkdown,
    required this.estimatedMinutes,
    required this.isFreePreview,
    required this.displayOrder,
  });

  final String id;
  final String topicId;
  final String title;
  final String bodyMarkdown;
  final int estimatedMinutes;
  final bool isFreePreview;
  final int displayOrder;

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    return LearningLesson(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      bodyMarkdown: json['body_markdown'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class LearnerProgressRecord {
  const LearnerProgressRecord({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.status,
    required this.readingProgressPercent,
    required this.attemptsCount,
    this.bestQuizScorePercent,
    this.completedAt,
  });

  final String id;
  final String learnerId;
  final String lessonId;
  final String status;
  final int readingProgressPercent;
  final int attemptsCount;
  final int? bestQuizScorePercent;
  final DateTime? completedAt;

  bool get isCompleted => status == 'completed';

  factory LearnerProgressRecord.fromJson(Map<String, dynamic> json) {
    return LearnerProgressRecord(
      id: json['id'] as String,
      learnerId: json['learner_id'] as String,
      lessonId: json['lesson_id'] as String,
      status: json['status'] as String,
      readingProgressPercent:
          (json['reading_progress_percent'] as num?)?.toInt() ?? 0,
      attemptsCount: (json['attempts_count'] as num?)?.toInt() ?? 0,
      bestQuizScorePercent:
          (json['best_quiz_score_percent'] as num?)?.toInt(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );
  }
}

class PracticeQuizQuestion {
  const PracticeQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<String> options;

  factory PracticeQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return PracticeQuizQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      options: rawOptions.map((o) => o.toString()).toList(),
    );
  }
}

class PracticeQuiz {
  const PracticeQuiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.passScorePercent,
    required this.questions,
  });

  final String id;
  final String lessonId;
  final String title;
  final int passScorePercent;
  final List<PracticeQuizQuestion> questions;

  factory PracticeQuiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return PracticeQuiz(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      passScorePercent: (json['pass_score_percent'] as num?)?.toInt() ?? 70,
      questions: rawQuestions
          .map((q) => PracticeQuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestionResult {
  const QuizQuestionResult({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String explanation;

  factory QuizQuestionResult.fromJson(Map<String, dynamic> json) {
    return QuizQuestionResult(
      questionId: json['question_id'] as String,
      selectedIndex: (json['selected_index'] as num).toInt(),
      correctIndex: (json['correct_index'] as num).toInt(),
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class QuizSubmissionResult {
  const QuizSubmissionResult({
    required this.quizId,
    required this.lessonId,
    required this.scorePercent,
    required this.correctCount,
    required this.totalQuestions,
    required this.passed,
    required this.passScorePercent,
    required this.bestQuizScorePercent,
    required this.lessonStatus,
    required this.attemptsCount,
    required this.results,
  });

  final String quizId;
  final String lessonId;
  final int scorePercent;
  final int correctCount;
  final int totalQuestions;
  final bool passed;
  final int passScorePercent;
  final int bestQuizScorePercent;
  final String lessonStatus;
  final int attemptsCount;
  final List<QuizQuestionResult> results;

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return QuizSubmissionResult(
      quizId: json['quiz_id'] as String,
      lessonId: json['lesson_id'] as String,
      scorePercent: (json['score_percent'] as num).toInt(),
      correctCount: (json['correct_count'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      passed: json['passed'] as bool? ?? false,
      passScorePercent: (json['pass_score_percent'] as num).toInt(),
      bestQuizScorePercent: (json['best_quiz_score_percent'] as num).toInt(),
      lessonStatus: json['lesson_status'] as String,
      attemptsCount: (json['attempts_count'] as num).toInt(),
      results: rawResults
          .map((r) => QuizQuestionResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LearnerLearningSummary {
  const LearnerLearningSummary({
    required this.learnerId,
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.averageQuizScorePercent,
    required this.masteryPercent,
    required this.hasActiveSubscription,
  });

  final String learnerId;
  final int totalLessons;
  final int completedLessons;
  final int inProgressLessons;
  final int averageQuizScorePercent;
  final int masteryPercent;
  final bool hasActiveSubscription;

  factory LearnerLearningSummary.fromJson(Map<String, dynamic> json) {
    return LearnerLearningSummary(
      learnerId: json['learner_id'] as String,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      inProgressLessons: (json['in_progress_lessons'] as num?)?.toInt() ?? 0,
      averageQuizScorePercent:
          (json['average_quiz_score_percent'] as num?)?.toInt() ?? 0,
      masteryPercent: (json['mastery_percent'] as num?)?.toInt() ?? 0,
      hasActiveSubscription:
          json['has_active_subscription'] as bool? ?? false,
    );
  }
}

class LearningCatalogBundle {
  const LearningCatalogBundle({
    required this.subjects,
    required this.topicsBySubject,
    required this.lessonsByTopic,
    required this.progressByLesson,
    required this.summary,
  });

  final List<LearningSubject> subjects;
  final Map<String, List<LearningTopic>> topicsBySubject;
  final Map<String, List<LearningLesson>> lessonsByTopic;
  final Map<String, LearnerProgressRecord> progressByLesson;
  final LearnerLearningSummary summary;
}
