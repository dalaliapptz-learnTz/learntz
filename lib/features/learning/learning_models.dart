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

class LessonContentBlock {
  const LessonContentBlock({
    required this.type,
    this.body,
    this.style,
    this.title,
    this.content,
    this.term,
    this.pronunciation,
    this.definition,
    this.example,
    this.problem,
    this.steps = const [],
    this.takeaway,
    this.imageUrl,
    this.caption,
    this.altText,
    this.question,
    this.options = const [],
    this.correctIndex,
    this.explanation,
  });

  final String type;
  final String? body;
  final String? style;
  final String? title;
  final String? content;
  final String? term;
  final String? pronunciation;
  final String? definition;
  final String? example;
  final String? problem;
  final List<String> steps;
  final String? takeaway;
  final String? imageUrl;
  final String? caption;
  final String? altText;
  final String? question;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;

  factory LessonContentBlock.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return LessonContentBlock(
      type: json['type'] as String? ?? 'markdown',
      body: json['body'] as String?,
      style: json['style'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      term: json['term'] as String?,
      pronunciation: json['pronunciation'] as String?,
      definition: json['definition'] as String?,
      example: json['example'] as String?,
      problem: json['problem'] as String?,
      steps: rawSteps.map((s) => s.toString()).toList(growable: false),
      takeaway: json['takeaway'] as String?,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      altText: json['alt_text'] as String?,
      question: json['question'] as String?,
      options: rawOptions.map((o) => o.toString()).toList(growable: false),
      correctIndex: (json['correct_index'] as num?)?.toInt(),
      explanation: json['explanation'] as String?,
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
    this.summary,
    this.contentBlocks = const [],
  });

  final String id;
  final String topicId;
  final String title;
  final String bodyMarkdown;
  final int estimatedMinutes;
  final bool isFreePreview;
  final int displayOrder;
  final String? summary;
  final List<LessonContentBlock> contentBlocks;

  List<LessonContentBlock> get effectiveContentBlocks {
    if (contentBlocks.isNotEmpty) return contentBlocks;
    if (bodyMarkdown.trim().isNotEmpty) {
      return [
        LessonContentBlock(
          type: 'markdown',
          body: bodyMarkdown,
        ),
      ];
    }
    return const [];
  }

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['content_blocks'] as List<dynamic>? ?? const [];
    final blocks = rawBlocks
        .map((b) => LessonContentBlock.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList(growable: false);
    return LearningLesson(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      bodyMarkdown: json['body_markdown'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      summary: json['summary'] as String?,
      contentBlocks: blocks,
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

class ParentSubjectOverview {
  const ParentSubjectOverview({
    required this.subjectId,
    required this.subjectName,
    required this.totalLessons,
    required this.completedLessons,
    required this.averageQuizScore,
    required this.status,
  });

  final String subjectId;
  final String subjectName;
  final int totalLessons;
  final int completedLessons;
  final int averageQuizScore;
  final String status; // 'excelling', 'needs_practice', 'on_track'

  factory ParentSubjectOverview.fromJson(Map<String, dynamic> json) {
    return ParentSubjectOverview(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      averageQuizScore: (json['average_quiz_score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'on_track',
    );
  }
}

class LearnerLastAccessedLesson {
  const LearnerLastAccessedLesson({
    required this.lessonId,
    required this.lessonTitle,
    required this.subjectName,
    this.topicTitle,
    required this.readingProgressPercent,
    required this.isCompleted,
    this.lastAccessedAt,
  });

  final String lessonId;
  final String lessonTitle;
  final String subjectName;
  final String? topicTitle;
  final int readingProgressPercent;
  final bool isCompleted;
  final DateTime? lastAccessedAt;

  factory LearnerLastAccessedLesson.fromJson(Map<String, dynamic> json) {
    return LearnerLastAccessedLesson(
      lessonId: json['lesson_id'] as String,
      lessonTitle: json['lesson_title'] as String,
      subjectName: json['subject_name'] as String,
      topicTitle: json['topic_title'] as String?,
      readingProgressPercent:
          (json['reading_progress_percent'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      lastAccessedAt: json['last_accessed_at'] == null
          ? null
          : DateTime.parse(json['last_accessed_at'] as String),
    );
  }
}

class ParentLearnerOverview {
  const ParentLearnerOverview({
    required this.learnerId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.countryCode,
    required this.status,
    required this.gradeName,
    required this.levelName,
    required this.curriculumName,
    required this.systemName,
    required this.schoolName,
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.averageQuizScorePercent,
    required this.masteryPercent,
    required this.streakDays,
    this.lastAccessedAt,
    this.lastLessonAccessed,
    required this.subjectsOverview,
  });

  final String learnerId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String countryCode;
  final String status;
  final String gradeName;
  final String levelName;
  final String curriculumName;
  final String systemName;
  final String schoolName;
  final int totalLessons;
  final int completedLessons;
  final int inProgressLessons;
  final int averageQuizScorePercent;
  final int masteryPercent;
  final int streakDays;
  final DateTime? lastAccessedAt;
  final LearnerLastAccessedLesson? lastLessonAccessed;
  final List<ParentSubjectOverview> subjectsOverview;

  factory ParentLearnerOverview.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects_overview'] as List<dynamic>? ?? const [];
    return ParentLearnerOverview(
      learnerId: json['learner_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      countryCode: json['country_code'] as String,
      status: json['status'] as String,
      gradeName: json['grade_name'] as String? ?? 'N/A',
      levelName: json['level_name'] as String? ?? 'N/A',
      curriculumName: json['curriculum_name'] as String? ?? 'N/A',
      systemName: json['system_name'] as String? ?? 'N/A',
      schoolName: json['school_name'] as String? ?? 'Independent Learner',
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      inProgressLessons: (json['in_progress_lessons'] as num?)?.toInt() ?? 0,
      averageQuizScorePercent:
          (json['average_quiz_score_percent'] as num?)?.toInt() ?? 0,
      masteryPercent: (json['mastery_percent'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 1,
      lastAccessedAt: json['last_accessed_at'] == null
          ? null
          : DateTime.parse(json['last_accessed_at'] as String),
      lastLessonAccessed: json['last_lesson_accessed'] == null
          ? null
          : LearnerLastAccessedLesson.fromJson(
              json['last_lesson_accessed'] as Map<String, dynamic>,
            ),
      subjectsOverview: rawSubjects
          .map((s) => ParentSubjectOverview.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class LearnerDashboardData {
  const LearnerDashboardData({
    required this.learnerId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.countryCode,
    required this.status,
    required this.gradeName,
    required this.systemName,
    required this.curriculumName,
    required this.schoolName,
    required this.summary,
    this.resumeLesson,
    required this.streakDays,
    required this.dailyTargetLessons,
    required this.todayCompletedLessons,
    required this.dailyTargetMinutes,
    this.academicCalendarName,
    this.activeTermName,
  });

  final String learnerId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String countryCode;
  final String status;
  final String gradeName;
  final String systemName;
  final String curriculumName;
  final String schoolName;
  final LearnerLearningSummary summary;
  final LearnerLastAccessedLesson? resumeLesson;
  final int streakDays;
  final int dailyTargetLessons;
  final int todayCompletedLessons;
  final int dailyTargetMinutes;
  final String? academicCalendarName;
  final String? activeTermName;

  factory LearnerDashboardData.fromJson(Map<String, dynamic> json) {
    final rawCal = json['academic_calendar'] as Map<String, dynamic>?;
    String? termName;
    if (rawCal != null) {
      final terms = rawCal['terms'] as List<dynamic>? ?? const [];
      final currentTerm = terms.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['is_current'] == true,
            orElse: () => terms.isNotEmpty ? terms.first as Map<String, dynamic> : null,
          );
      termName = currentTerm?['name'] as String?;
    }

    return LearnerDashboardData(
      learnerId: json['learner_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      countryCode: json['country_code'] as String,
      status: json['status'] as String,
      gradeName: json['grade_name'] as String? ?? 'Grade',
      systemName: json['system_name'] as String? ?? 'National System',
      curriculumName: json['curriculum_name'] as String? ?? 'Curriculum',
      schoolName: json['school_name'] as String? ?? 'Independent Learner',
      summary: LearnerLearningSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      resumeLesson: json['resume_lesson'] == null
          ? null
          : LearnerLastAccessedLesson.fromJson(
              json['resume_lesson'] as Map<String, dynamic>,
            ),
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 1,
      dailyTargetLessons:
          (json['daily_target_lessons'] as num?)?.toInt() ?? 1,
      todayCompletedLessons:
          (json['today_completed_lessons'] as num?)?.toInt() ?? 0,
      dailyTargetMinutes:
          (json['daily_target_minutes'] as num?)?.toInt() ?? 20,
      academicCalendarName: rawCal?['name'] as String?,
      activeTermName: termName,
    );
  }
}

class CurriculumExplorerLesson {
  const CurriculumExplorerLesson({
    required this.lessonId,
    required this.title,
    required this.estimatedMinutes,
    required this.isFreePreview,
    required this.displayOrder,
  });

  final String lessonId;
  final String title;
  final int estimatedMinutes;
  final bool isFreePreview;
  final int displayOrder;

  factory CurriculumExplorerLesson.fromJson(Map<String, dynamic> json) {
    return CurriculumExplorerLesson(
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 15,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class CurriculumExplorerTopic {
  const CurriculumExplorerTopic({
    required this.topicId,
    required this.title,
    required this.summary,
    required this.displayOrder,
    required this.lessons,
  });

  final String topicId;
  final String title;
  final String summary;
  final int displayOrder;
  final List<CurriculumExplorerLesson> lessons;

  factory CurriculumExplorerTopic.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List<dynamic>? ?? const [];
    return CurriculumExplorerTopic(
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      lessons: rawLessons
          .map((l) => CurriculumExplorerLesson.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class CurriculumExplorerSubject {
  const CurriculumExplorerSubject({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.description,
    this.gradeId,
    required this.displayOrder,
    required this.topics,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String description;
  final String? gradeId;
  final int displayOrder;
  final List<CurriculumExplorerTopic> topics;

  int get totalLessons => topics.fold(0, (sum, t) => sum + t.lessons.length);

  factory CurriculumExplorerSubject.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'] as List<dynamic>? ?? const [];
    return CurriculumExplorerSubject(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      description: json['description'] as String? ?? '',
      gradeId: json['grade_id'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      topics: rawTopics
          .map((t) => CurriculumExplorerTopic.fromJson(t as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class MatchingPremiseResponse {
  const MatchingPremiseResponse({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;
}

class QuestionBankItem {
  const QuestionBankItem({
    required this.id,
    required this.topicId,
    this.lessonId,
    required this.questionType,
    required this.difficultyLevel,
    required this.questionText,
    this.options,
    this.matchingPremises = const [],
    this.matchingResponses = const [],
    this.cognitiveTier,
    required this.displayOrder,
  });

  final String id;
  final String topicId;
  final String? lessonId;
  final String questionType;
  final String difficultyLevel;
  final String questionText;
  final List<String>? options;
  final List<MatchingPremiseResponse> matchingPremises;
  final List<MatchingPremiseResponse> matchingResponses;
  final String? cognitiveTier;
  final int displayOrder;

  factory QuestionBankItem.fromJson(Map<String, dynamic> json) {
    List<String>? opts;
    final premises = <MatchingPremiseResponse>[];
    final responses = <MatchingPremiseResponse>[];

    final rawOptions = json['options'];
    if (rawOptions is List) {
      opts = rawOptions.map((e) => e.toString()).toList(growable: false);
    } else if (rawOptions is Map) {
      final rawPremises = rawOptions['premises'] as List<dynamic>? ?? const [];
      final rawResponses = rawOptions['responses'] as List<dynamic>? ?? const [];
      for (final p in rawPremises) {
        if (p is Map) {
          premises.add(
            MatchingPremiseResponse(
              id: p['id'].toString(),
              text: p['text'].toString(),
            ),
          );
        }
      }
      for (final r in rawResponses) {
        if (r is Map) {
          responses.add(
            MatchingPremiseResponse(
              id: r['id'].toString(),
              text: r['text'].toString(),
            ),
          );
        }
      }
    }

    return QuestionBankItem(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      lessonId: json['lesson_id'] as String?,
      questionType: json['question_type'] as String,
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      questionText: json['question_text'] as String,
      options: opts,
      matchingPremises: premises,
      matchingResponses: responses,
      cognitiveTier: json['cognitive_tier'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class AssessmentQuestionGradedResult {
  const AssessmentQuestionGradedResult({
    required this.questionId,
    required this.questionType,
    required this.isCorrect,
    this.userAnswer,
    this.correctAnswer,
    required this.explanation,
  });

  final String questionId;
  final String questionType;
  final bool isCorrect;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final String explanation;

  factory AssessmentQuestionGradedResult.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestionGradedResult(
      questionId: json['question_id'] as String,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      isCorrect: json['is_correct'] as bool? ?? false,
      userAnswer: json['user_answer'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class AssessmentSubmissionResult {
  const AssessmentSubmissionResult({
    required this.scorePercent,
    required this.passed,
    required this.totalQuestions,
    required this.correctCount,
    required this.masteryStatus,
    required this.results,
  });

  final int scorePercent;
  final bool passed;
  final int totalQuestions;
  final int correctCount;
  final String masteryStatus;
  final List<AssessmentQuestionGradedResult> results;

  factory AssessmentSubmissionResult.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return AssessmentSubmissionResult(
      scorePercent: (json['score_percent'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      masteryStatus: json['mastery_status'] as String? ?? 'in_progress',
      results: rawResults
          .map(
            (r) => AssessmentQuestionGradedResult.fromJson(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class LearnerRecommendation {
  const LearnerRecommendation({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    this.topicTitle,
    this.lessonId,
    this.lessonTitle,
    required this.recommendationType,
    required this.title,
    required this.reason,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String? topicTitle;
  final String? lessonId;
  final String? lessonTitle;
  final String recommendationType; // remedial, advanced, spaced_repetition
  final String title;
  final String reason;
  final int priority;
  final DateTime createdAt;

  factory LearnerRecommendation.fromJson(Map<String, dynamic> json) {
    return LearnerRecommendation(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? '',
      topicId: json['topic_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      lessonId: json['lesson_id'] as String?,
      lessonTitle: json['lesson_title'] as String?,
      recommendationType: json['recommendation_type'] as String,
      title: json['title'] as String,
      reason: json['reason'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class LearnerSubjectMasteryBreakdown {
  const LearnerSubjectMasteryBreakdown({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalTopics,
    required this.masteredTopics,
    required this.proficientTopics,
    required this.inProgressTopics,
    required this.notStartedTopics,
    required this.averageAccuracy,
    required this.masteryPercent,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalTopics;
  final int masteredTopics;
  final int proficientTopics;
  final int inProgressTopics;
  final int notStartedTopics;
  final double averageAccuracy;
  final int masteryPercent;

  factory LearnerSubjectMasteryBreakdown.fromJson(Map<String, dynamic> json) {
    return LearnerSubjectMasteryBreakdown(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      totalTopics: (json['total_topics'] as num?)?.toInt() ?? 0,
      masteredTopics: (json['mastered_topics'] as num?)?.toInt() ?? 0,
      proficientTopics: (json['proficient_topics'] as num?)?.toInt() ?? 0,
      inProgressTopics: (json['in_progress_topics'] as num?)?.toInt() ?? 0,
      notStartedTopics: (json['not_started_topics'] as num?)?.toInt() ?? 0,
      averageAccuracy: (json['average_accuracy'] as num?)?.toDouble() ?? 0.0,
      masteryPercent: (json['mastery_percent'] as num?)?.toInt() ?? 0,
    );
  }
}

class LearnerMasteryReport {
  const LearnerMasteryReport({
    required this.learnerId,
    required this.totalTopics,
    required this.masteredTopics,
    required this.proficientTopics,
    required this.inProgressTopics,
    required this.notStartedTopics,
    required this.overallAccuracyRate,
    required this.streakDays,
    required this.readinessIndex,
    required this.subjectsBreakdown,
  });

  final String learnerId;
  final int totalTopics;
  final int masteredTopics;
  final int proficientTopics;
  final int inProgressTopics;
  final int notStartedTopics;
  final double overallAccuracyRate;
  final int streakDays;
  final int readinessIndex; // 0 - 100%
  final List<LearnerSubjectMasteryBreakdown> subjectsBreakdown;

  factory LearnerMasteryReport.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['subjects_breakdown'] as List<dynamic>? ?? const [];
    return LearnerMasteryReport(
      learnerId: json['learner_id'] as String,
      totalTopics: (json['total_topics'] as num?)?.toInt() ?? 0,
      masteredTopics: (json['mastered_topics'] as num?)?.toInt() ?? 0,
      proficientTopics: (json['proficient_topics'] as num?)?.toInt() ?? 0,
      inProgressTopics: (json['in_progress_topics'] as num?)?.toInt() ?? 0,
      notStartedTopics: (json['not_started_topics'] as num?)?.toInt() ?? 0,
      overallAccuracyRate: (json['overall_accuracy_rate'] as num?)?.toDouble() ?? 0.0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      readinessIndex: (json['readiness_index'] as num?)?.toInt() ?? 0,
      subjectsBreakdown: rawBreakdown
          .map(
            (b) => LearnerSubjectMasteryBreakdown.fromJson(
              Map<String, dynamic>.from(b as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class LearnerWeakTopicItem {
  const LearnerWeakTopicItem({
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    required this.subjectName,
    required this.accuracyRate,
    required this.quizzesAttempted,
    required this.masteryStatus,
  });

  final String topicId;
  final String topicTitle;
  final String subjectId;
  final String subjectName;
  final double accuracyRate;
  final int quizzesAttempted;
  final String masteryStatus;

  factory LearnerWeakTopicItem.fromJson(Map<String, dynamic> json) {
    return LearnerWeakTopicItem(
      topicId: json['topic_id'] as String,
      topicTitle: json['topic_title'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      accuracyRate: (json['accuracy_rate'] as num?)?.toDouble() ?? 0.0,
      quizzesAttempted: (json['quizzes_attempted'] as num?)?.toInt() ?? 0,
      masteryStatus: json['mastery_status'] as String? ?? 'not_started',
    );
  }
}

class LearnerRevisionOverview {
  const LearnerRevisionOverview({
    required this.learnerId,
    required this.curriculumId,
    required this.readinessIndex,
    required this.totalCurriculumTopics,
    required this.proficientTopicsCount,
    required this.masteredTopicsCount,
    required this.weakTopics,
    required this.flashcardDecksCount,
    required this.learningResourcesCount,
  });

  final String learnerId;
  final String curriculumId;
  final int readinessIndex;
  final int totalCurriculumTopics;
  final int proficientTopicsCount;
  final int masteredTopicsCount;
  final List<LearnerWeakTopicItem> weakTopics;
  final int flashcardDecksCount;
  final int learningResourcesCount;

  factory LearnerRevisionOverview.fromJson(Map<String, dynamic> json) {
    final rawWeak = json['weak_topics'] as List<dynamic>? ?? const [];
    return LearnerRevisionOverview(
      learnerId: json['learner_id'] as String,
      curriculumId: json['curriculum_id'] as String,
      readinessIndex: (json['readiness_index'] as num?)?.toInt() ?? 0,
      totalCurriculumTopics: (json['total_curriculum_topics'] as num?)?.toInt() ?? 0,
      proficientTopicsCount: (json['proficient_topics_count'] as num?)?.toInt() ?? 0,
      masteredTopicsCount: (json['mastered_topics_count'] as num?)?.toInt() ?? 0,
      weakTopics: rawWeak
          .map((item) => LearnerWeakTopicItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      flashcardDecksCount: (json['flashcard_decks_count'] as num?)?.toInt() ?? 0,
      learningResourcesCount: (json['learning_resources_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.countryCode,
    required this.curriculumId,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    this.topicTitle,
    required this.title,
    required this.description,
    required this.cardCount,
    required this.estimatedMinutes,
    this.createdAt,
  });

  final String id;
  final String countryCode;
  final String curriculumId;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String? topicTitle;
  final String title;
  final String description;
  final int cardCount;
  final int estimatedMinutes;
  final DateTime? createdAt;

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String,
      countryCode: json['country_code'] as String? ?? 'TZ',
      curriculumId: json['curriculum_id'] as String? ?? '',
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? '',
      topicId: json['topic_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}

class FlashcardItem {
  const FlashcardItem({
    required this.id,
    required this.deckId,
    required this.frontPrompt,
    required this.backSolution,
    this.hint,
    this.explanation,
    required this.displayOrder,
  });

  final String id;
  final String deckId;
  final String frontPrompt;
  final String backSolution;
  final String? hint;
  final String? explanation;
  final int displayOrder;

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      frontPrompt: json['front_prompt'] as String,
      backSolution: json['back_solution'] as String,
      hint: json['hint'] as String?,
      explanation: json['explanation'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class LearningResourceItem {
  const LearningResourceItem({
    required this.id,
    required this.countryCode,
    required this.curriculumId,
    this.educationLevelId,
    this.gradeId,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    this.topicTitle,
    required this.title,
    required this.description,
    required this.resourceType,
    required this.fileUrl,
    required this.fileFormat,
    this.fileSizeBytes,
    this.durationSeconds,
    required this.authorOrPublisher,
    required this.isOfficial,
    required this.isDownloadable,
    required this.isPremium,
    this.metadata = const {},
  });

  final String id;
  final String countryCode;
  final String curriculumId;
  final String? educationLevelId;
  final String? gradeId;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String? topicTitle;
  final String title;
  final String description;
  final String resourceType;
  final String fileUrl;
  final String fileFormat;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String authorOrPublisher;
  final bool isOfficial;
  final bool isDownloadable;
  final bool isPremium;
  final Map<String, dynamic> metadata;

  factory LearningResourceItem.fromJson(Map<String, dynamic> json) {
    return LearningResourceItem(
      id: json['id'] as String,
      countryCode: json['country_code'] as String? ?? 'TZ',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String?,
      gradeId: json['grade_id'] as String?,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? '',
      topicId: json['topic_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      resourceType: json['resource_type'] as String,
      fileUrl: json['file_url'] as String,
      fileFormat: json['file_format'] as String? ?? 'pdf',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      authorOrPublisher: json['author_or_publisher'] as String? ?? 'LearnTZ Editorial',
      isOfficial: json['is_official'] as bool? ?? true,
      isDownloadable: json['is_downloadable'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : const {},
    );
  }
}

class OfflineSyncEvent {
  const OfflineSyncEvent({
    required this.clientEventId,
    required this.eventType,
    required this.payload,
    required this.clientRecordedAt,
  });

  final String clientEventId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime clientRecordedAt;

  Map<String, dynamic> toJson() => {
        'client_event_id': clientEventId,
        'event_type': eventType,
        'payload': payload,
        'client_recorded_at': clientRecordedAt.toIso8601String(),
      };

  factory OfflineSyncEvent.fromJson(Map<String, dynamic> json) {
    return OfflineSyncEvent(
      clientEventId: json['client_event_id'] as String,
      eventType: json['event_type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      clientRecordedAt: DateTime.parse(json['client_recorded_at'] as String),
    );
  }
}

class OfflineSyncResult {
  const OfflineSyncResult({
    required this.learnerId,
    required this.eventsReceived,
    required this.eventsProcessed,
    required this.eventsDuplicate,
    required this.syncedAt,
  });

  final String learnerId;
  final int eventsReceived;
  final int eventsProcessed;
  final int eventsDuplicate;
  final DateTime syncedAt;

  factory OfflineSyncResult.fromJson(Map<String, dynamic> json) {
    return OfflineSyncResult(
      learnerId: json['learner_id'] as String,
      eventsReceived: (json['events_received'] as num?)?.toInt() ?? 0,
      eventsProcessed: (json['events_processed'] as num?)?.toInt() ?? 0,
      eventsDuplicate: (json['events_duplicate'] as num?)?.toInt() ?? 0,
      syncedAt: DateTime.tryParse(json['synced_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SubjectOfflinePack {
  const SubjectOfflinePack({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.countryCode,
    required this.curriculumId,
    required this.description,
    required this.topics,
    required this.flashcardDecks,
    required this.packedAt,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String countryCode;
  final String curriculumId;
  final String description;
  final List<dynamic> topics;
  final List<dynamic> flashcardDecks;
  final DateTime packedAt;

  factory SubjectOfflinePack.fromJson(Map<String, dynamic> json) {
    return SubjectOfflinePack(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      countryCode: json['country_code'] as String,
      curriculumId: json['curriculum_id'] as String,
      description: json['description'] as String? ?? '',
      topics: json['topics'] as List<dynamic>? ?? const [],
      flashcardDecks: json['flashcard_decks'] as List<dynamic>? ?? const [],
      packedAt: DateTime.tryParse(json['packed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
