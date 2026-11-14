import 'package:flutter/foundation.dart';

@immutable
class ExaminationAuthority {
  const ExaminationAuthority({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.description,
    this.websiteUrl,
    this.logoUrl,
    this.isAcccredited = true,
  });

  final String id;
  final String countryCode;
  final String name;
  final String description;
  final String? websiteUrl;
  final String? logoUrl;
  final bool isAcccredited;

  factory ExaminationAuthority.fromJson(Map<String, dynamic> json) {
    return ExaminationAuthority(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      websiteUrl: json['website_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      isAcccredited: json['is_accredited'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'country_code': countryCode,
        'name': name,
        'description': description,
        'website_url': websiteUrl,
        'logo_url': logoUrl,
        'is_accredited': isAcccredited,
      };
}

@immutable
class NationalExamination {
  const NationalExamination({
    required this.id,
    required this.authorityId,
    required this.countryCode,
    required this.code,
    required this.title,
    required this.educationLevel,
    this.gradingSystem = 'division',
    this.isActive = true,
  });

  final String id;
  final String authorityId;
  final String countryCode;
  final String code;
  final String title;
  final String educationLevel;
  final String gradingSystem;
  final bool isActive;

  factory NationalExamination.fromJson(Map<String, dynamic> json) {
    return NationalExamination(
      id: json['id'] as String? ?? '',
      authorityId: json['authority_id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      educationLevel: json['education_level'] as String? ?? '',
      gradingSystem: json['grading_system'] as String? ?? 'division',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authority_id': authorityId,
        'country_code': countryCode,
        'code': code,
        'title': title,
        'education_level': educationLevel,
        'grading_system': gradingSystem,
        'is_active': isActive,
      };
}

@immutable
class ExamSectionConfig {
  const ExamSectionConfig({
    required this.code,
    required this.name,
    required this.totalQuestions,
    required this.requiredQuestions,
    required this.marksPerQuestion,
    required this.totalMarks,
  });

  final String code;
  final String name;
  final int totalQuestions;
  final int requiredQuestions;
  final int marksPerQuestion;
  final int totalMarks;

  factory ExamSectionConfig.fromJson(Map<String, dynamic> json) {
    return ExamSectionConfig(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      requiredQuestions: (json['required_questions'] as num?)?.toInt() ?? 0,
      marksPerQuestion: (json['marks_per_question'] as num?)?.toInt() ?? 0,
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'total_questions': totalQuestions,
        'required_questions': requiredQuestions,
        'marks_per_question': marksPerQuestion,
        'total_marks': totalMarks,
      };
}

@immutable
class ExaminationPaper {
  const ExaminationPaper({
    required this.id,
    required this.countryCode,
    required this.authorityId,
    required this.subjectName,
    required this.paperTitle,
    required this.year,
    required this.paperType,
    required this.tier,
    this.nationalExaminationId,
    this.subjectId,
    this.paperNumber = 1,
    this.region,
    this.district,
    this.schoolName,
    this.term,
    this.durationMinutes = 150,
    this.totalMarks = 100.0,
    this.instructions,
    this.sectionsConfig = const [],
    this.pdfStoragePath,
    this.markingSchemeStoragePath,
    required this.createdAt,
  });

  final String id;
  final String countryCode;
  final String? nationalExaminationId;
  final String authorityId;
  final String? subjectId;
  final String subjectName;
  final int paperNumber;
  final String paperTitle;
  final int year;
  final String paperType;
  final String tier;
  final String? region;
  final String? district;
  final String? schoolName;
  final int? term;
  final int durationMinutes;
  final double totalMarks;
  final String? instructions;
  final List<ExamSectionConfig> sectionsConfig;
  final String? pdfStoragePath;
  final String? markingSchemeStoragePath;
  final DateTime createdAt;

  factory ExaminationPaper.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections_config'];
    final sections = <ExamSectionConfig>[];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is Map<String, dynamic>) {
          sections.add(ExamSectionConfig.fromJson(s));
        }
      }
    }

    return ExaminationPaper(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      nationalExaminationId: json['national_examination_id'] as String?,
      authorityId: json['authority_id'] as String? ?? '',
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String? ?? '',
      paperNumber: (json['paper_number'] as num?)?.toInt() ?? 1,
      paperTitle: json['paper_title'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      paperType: json['paper_type'] as String? ?? 'official_national',
      tier: json['tier'] as String? ?? 'national',
      region: json['region'] as String?,
      district: json['district'] as String?,
      schoolName: json['school_name'] as String?,
      term: (json['term'] as num?)?.toInt(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 150,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 100.0,
      instructions: json['instructions'] as String?,
      sectionsConfig: sections,
      pdfStoragePath: json['pdf_storage_path'] as String?,
      markingSchemeStoragePath: json['marking_scheme_storage_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'country_code': countryCode,
        'national_examination_id': nationalExaminationId,
        'authority_id': authorityId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'paper_number': paperNumber,
        'paper_title': paperTitle,
        'year': year,
        'paper_type': paperType,
        'tier': tier,
        'region': region,
        'district': district,
        'school_name': schoolName,
        'term': term,
        'duration_minutes': durationMinutes,
        'total_marks': totalMarks,
        'instructions': instructions,
        'sections_config': sectionsConfig.map((s) => s.toJson()).toList(),
        'pdf_storage_path': pdfStoragePath,
        'marking_scheme_storage_path': markingSchemeStoragePath,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class ExaminationCentreCatalog {
  const ExaminationCentreCatalog({
    required this.authorities,
    required this.examinations,
    required this.recentPapers,
    required this.tierCounts,
  });

  final List<ExaminationAuthority> authorities;
  final List<NationalExamination> examinations;
  final List<ExaminationPaper> recentPapers;
  final Map<String, int> tierCounts;

  factory ExaminationCentreCatalog.fromJson(Map<String, dynamic> json) {
    final authList = (json['authorities'] as List<dynamic>? ?? [])
        .map((a) => ExaminationAuthority.fromJson(a as Map<String, dynamic>))
        .toList();

    final examList = (json['examinations'] as List<dynamic>? ?? [])
        .map((e) => NationalExamination.fromJson(e as Map<String, dynamic>))
        .toList();

    final paperList = (json['recent_papers'] as List<dynamic>? ?? [])
        .map((p) => ExaminationPaper.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawTierCounts = json['tier_counts'] as Map<String, dynamic>? ?? {};
    final counts = rawTierCounts.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));

    return ExaminationCentreCatalog(
      authorities: authList,
      examinations: examList,
      recentPapers: paperList,
      tierCounts: counts,
    );
  }
}

@immutable
class PaperUploadRequest {
  const PaperUploadRequest({
    required this.countryCode,
    required this.authorityId,
    required this.title,
    required this.year,
    required this.tier,
    this.region,
    this.district,
    this.schoolName,
    this.fileUrl = '',
    this.fileSizeBytes,
    this.notes,
  });

  final String countryCode;
  final String authorityId;
  final String title;
  final int year;
  final String tier;
  final String? region;
  final String? district;
  final String? schoolName;
  final String fileUrl;
  final int? fileSizeBytes;
  final String? notes;

  Map<String, dynamic> toRpcParams() => {
        'p_country_code': countryCode,
        'p_authority_id': authorityId,
        'p_title': title,
        'p_year': year,
        'p_tier': tier,
        'p_region': region,
        'p_district': district,
        'p_school_name': schoolName,
        'p_file_url': fileUrl,
        'p_file_size_bytes': fileSizeBytes,
        'p_notes': notes,
      };
}

@immutable
class ExaminationPaperUploadResult {
  const ExaminationPaperUploadResult({
    required this.id,
    required this.countryCode,
    required this.title,
    required this.year,
    required this.tier,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String countryCode;
  final String title;
  final int year;
  final String tier;
  final String status;
  final DateTime createdAt;

  factory ExaminationPaperUploadResult.fromJson(Map<String, dynamic> json) {
    return ExaminationPaperUploadResult(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      tier: json['tier'] as String? ?? 'national',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class ExamQuestionOption {
  const ExamQuestionOption({
    required this.key,
    required this.text,
    this.isCorrect = false,
  });

  final String key;
  final String text;
  final bool isCorrect;

  factory ExamQuestionOption.fromJson(Map<String, dynamic> json) {
    return ExamQuestionOption(
      key: json['key'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'text': text,
        'is_correct': isCorrect,
      };
}

@immutable
class ExamRubricStep {
  const ExamRubricStep({
    required this.step,
    required this.description,
    required this.marksAwarded,
  });

  final int step;
  final String description;
  final double marksAwarded;

  factory ExamRubricStep.fromJson(Map<String, dynamic> json) {
    return ExamRubricStep(
      step: (json['step'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      marksAwarded: (json['marks_awarded'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'description': description,
        'marks_awarded': marksAwarded,
      };
}

@immutable
class ExamExtractedQuestion {
  const ExamExtractedQuestion({
    required this.id,
    required this.paperId,
    this.paperTitle,
    this.year,
    this.tier,
    this.authorityId,
    this.subjectName,
    required this.sectionCode,
    required this.questionNumber,
    this.subPart,
    required this.questionText,
    this.diagramUrl,
    this.questionType = 'structured',
    this.options = const [],
    this.correctAnswer,
    this.rubricGuide = const [],
    required this.marks,
    this.topicId,
    this.topicTitle,
    this.bloomLevel = 'comprehension',
    this.difficulty = 'medium',
    this.verificationStatus = 'draft',
    required this.createdAt,
  });

  final String id;
  final String paperId;
  final String? paperTitle;
  final int? year;
  final String? tier;
  final String? authorityId;
  final String? subjectName;
  final String sectionCode;
  final int questionNumber;
  final String? subPart;
  final String questionText;
  final String? diagramUrl;
  final String questionType;
  final List<ExamQuestionOption> options;
  final String? correctAnswer;
  final List<ExamRubricStep> rubricGuide;
  final double marks;
  final String? topicId;
  final String? topicTitle;
  final String bloomLevel;
  final String difficulty;
  final String verificationStatus;
  final DateTime createdAt;

  String get fullIdentifier {
    final sub = subPart != null && subPart!.isNotEmpty ? ' $subPart' : '';
    return 'Sec $sectionCode Q$questionNumber$sub';
  }

  bool get isApproved => verificationStatus == 'approved';
  bool get isVerified => verificationStatus == 'verified';
  bool get isDraft => verificationStatus == 'draft';

  factory ExamExtractedQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final opts = <ExamQuestionOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          opts.add(ExamQuestionOption.fromJson(o));
        }
      }
    }

    final rawRubric = json['rubric_guide'];
    final rubric = <ExamRubricStep>[];
    if (rawRubric is List) {
      for (final r in rawRubric) {
        if (r is Map<String, dynamic>) {
          rubric.add(ExamRubricStep.fromJson(r));
        }
      }
    }

    return ExamExtractedQuestion(
      id: json['id'] as String? ?? '',
      paperId: json['paper_id'] as String? ?? '',
      paperTitle: json['paper_title'] as String?,
      year: (json['year'] as num?)?.toInt(),
      tier: json['tier'] as String?,
      authorityId: json['authority_id'] as String?,
      subjectName: json['subject_name'] as String?,
      sectionCode: json['section_code'] as String? ?? 'A',
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      subPart: json['sub_part'] as String?,
      questionText: json['question_text'] as String? ?? '',
      diagramUrl: json['diagram_url'] as String?,
      questionType: json['question_type'] as String? ?? 'structured',
      options: opts,
      correctAnswer: json['correct_answer'] as String?,
      rubricGuide: rubric,
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      topicId: json['topic_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      bloomLevel: json['bloom_level'] as String? ?? 'comprehension',
      difficulty: json['difficulty'] as String? ?? 'medium',
      verificationStatus: json['verification_status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'paper_id': paperId,
        'paper_title': paperTitle,
        'year': year,
        'tier': tier,
        'authority_id': authorityId,
        'subject_name': subjectName,
        'section_code': sectionCode,
        'question_number': questionNumber,
        'sub_part': subPart,
        'question_text': questionText,
        'diagram_url': diagramUrl,
        'question_type': questionType,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_answer': correctAnswer,
        'rubric_guide': rubricGuide.map((r) => r.toJson()).toList(),
        'marks': marks,
        'topic_id': topicId,
        'topic_title': topicTitle,
        'bloom_level': bloomLevel,
        'difficulty': difficulty,
        'verification_status': verificationStatus,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class ExamQuestionReviewResult {
  const ExamQuestionReviewResult({
    required this.questionId,
    required this.verificationStatus,
    required this.reviewerId,
    required this.decision,
    required this.reviewedAt,
  });

  final String questionId;
  final String verificationStatus;
  final String reviewerId;
  final String decision;
  final DateTime reviewedAt;

  factory ExamQuestionReviewResult.fromJson(Map<String, dynamic> json) {
    return ExamQuestionReviewResult(
      questionId: json['question_id'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      decision: json['decision'] as String? ?? '',
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class ExaminationBlueprint {
  const ExaminationBlueprint({
    required this.id,
    required this.nationalExaminationId,
    this.subjectId,
    required this.title,
    required this.totalMarks,
    required this.durationMinutes,
    this.structureConfig = const [],
    this.isActive = true,
  });

  final String id;
  final String nationalExaminationId;
  final String? subjectId;
  final String title;
  final double totalMarks;
  final int durationMinutes;
  final List<dynamic> structureConfig;
  final bool isActive;

  factory ExaminationBlueprint.fromJson(Map<String, dynamic> json) {
    return ExaminationBlueprint(
      id: json['id'] as String? ?? '',
      nationalExaminationId: json['national_examination_id'] as String? ?? '',
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String? ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 100.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 180,
      structureConfig: json['structure_config'] as List<dynamic>? ?? const [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'national_examination_id': nationalExaminationId,
        'subject_id': subjectId,
        'title': title,
        'total_marks': totalMarks,
        'duration_minutes': durationMinutes,
        'structure_config': structureConfig,
        'is_active': isActive,
      };
}

@immutable
class GeneratedMockExamination {
  const GeneratedMockExamination({
    required this.id,
    required this.blueprintId,
    required this.title,
    required this.academicYear,
    required this.totalMarks,
    required this.durationMinutes,
    this.curatedBy,
    this.status = 'published',
    required this.createdAt,
  });

  final String id;
  final String blueprintId;
  final String title;
  final int academicYear;
  final double totalMarks;
  final int durationMinutes;
  final String? curatedBy;
  final String status;
  final DateTime createdAt;

  factory GeneratedMockExamination.fromJson(Map<String, dynamic> json) {
    return GeneratedMockExamination(
      id: json['id'] as String? ?? '',
      blueprintId: json['blueprint_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      academicYear: (json['academic_year'] as num?)?.toInt() ?? 2026,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 100.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 180,
      curatedBy: json['curated_by'] as String?,
      status: json['status'] as String? ?? 'published',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class MockRunnerQuestion {
  const MockRunnerQuestion({
    required this.itemId,
    required this.questionId,
    required this.sectionCode,
    required this.orderIndex,
    required this.marks,
    required this.questionNumber,
    this.subPart,
    required this.questionText,
    this.diagramUrl,
    required this.questionType,
    this.options = const [],
    this.topicId,
    this.bloomLevel = 'comprehension',
    this.difficulty = 'medium',
  });

  final String itemId;
  final String questionId;
  final String sectionCode;
  final int orderIndex;
  final double marks;
  final int questionNumber;
  final String? subPart;
  final String questionText;
  final String? diagramUrl;
  final String questionType;
  final List<ExamQuestionOption> options;
  final String? topicId;
  final String bloomLevel;
  final String difficulty;

  String get label => subPart != null && subPart!.isNotEmpty
      ? 'Sec $sectionCode Q$questionNumber $subPart'
      : 'Sec $sectionCode Q$questionNumber';

  factory MockRunnerQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final opts = <ExamQuestionOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          opts.add(ExamQuestionOption.fromJson(o));
        }
      }
    }

    return MockRunnerQuestion(
      itemId: json['item_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      sectionCode: json['section_code'] as String? ?? 'A',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      subPart: json['sub_part'] as String?,
      questionText: json['question_text'] as String? ?? '',
      diagramUrl: json['diagram_url'] as String?,
      questionType: json['question_type'] as String? ?? 'structured',
      options: opts,
      topicId: json['topic_id'] as String?,
      bloomLevel: json['bloom_level'] as String? ?? 'comprehension',
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }
}

@immutable
class LearnerExamResponseState {
  const LearnerExamResponseState({
    required this.questionId,
    this.learnerAnswer,
    this.isFlagged = false,
    this.answeredAt,
  });

  final String questionId;
  final String? learnerAnswer;
  final bool isFlagged;
  final DateTime? answeredAt;

  factory LearnerExamResponseState.fromJson(
    String questionId,
    Map<String, dynamic> json,
  ) {
    return LearnerExamResponseState(
      questionId: questionId,
      learnerAnswer: json['learner_answer'] as String?,
      isFlagged: json['is_flagged'] as bool? ?? false,
      answeredAt: json['answered_at'] != null
          ? DateTime.tryParse(json['answered_at'] as String)
          : null,
    );
  }

  LearnerExamResponseState copyWith({
    String? learnerAnswer,
    bool? isFlagged,
  }) {
    return LearnerExamResponseState(
      questionId: questionId,
      learnerAnswer: learnerAnswer ?? this.learnerAnswer,
      isFlagged: isFlagged ?? this.isFlagged,
      answeredAt: DateTime.now(),
    );
  }
}

@immutable
class LearnerExamAttemptData {
  const LearnerExamAttemptData({
    required this.attemptId,
    required this.mockExamId,
    required this.title,
    required this.status,
    required this.startedAt,
    required this.durationMinutes,
    required this.expiresAt,
    required this.secondsRemaining,
    required this.totalPossibleMarks,
    required this.questions,
    required this.responses,
  });

  final String attemptId;
  final String mockExamId;
  final String title;
  final String status;
  final DateTime startedAt;
  final int durationMinutes;
  final DateTime expiresAt;
  final int secondsRemaining;
  final double totalPossibleMarks;
  final List<MockRunnerQuestion> questions;
  final Map<String, LearnerExamResponseState> responses;

  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired' || secondsRemaining <= 0;

  factory LearnerExamAttemptData.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((q) => MockRunnerQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    final rawResponses = json['responses'] as Map<String, dynamic>? ?? {};
    final responses = <String, LearnerExamResponseState>{};
    rawResponses.forEach((qId, val) {
      if (val is Map<String, dynamic>) {
        responses[qId] = LearnerExamResponseState.fromJson(qId, val);
      }
    });

    return LearnerExamAttemptData(
      attemptId: json['attempt_id'] as String? ?? '',
      mockExamId: json['mock_exam_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'in_progress',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 180,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      secondsRemaining: (json['seconds_remaining'] as num?)?.toInt() ?? 0,
      totalPossibleMarks:
          (json['total_possible_marks'] as num?)?.toDouble() ?? 100.0,
      questions: questions,
      responses: responses,
    );
  }
}

@immutable
class ExamSectionPerformance {
  const ExamSectionPerformance({
    required this.sectionCode,
    required this.score,
    required this.possible,
    required this.percentage,
  });

  final String sectionCode;
  final double score;
  final double possible;
  final double percentage;

  factory ExamSectionPerformance.fromJson(Map<String, dynamic> json) {
    return ExamSectionPerformance(
      sectionCode: json['section_code'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      possible: (json['possible'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class ExamTopicDeficit {
  const ExamTopicDeficit({
    required this.topicId,
    required this.title,
    required this.score,
    required this.possible,
    required this.accuracyPct,
  });

  final String topicId;
  final String title;
  final double score;
  final double possible;
  final double accuracyPct;

  factory ExamTopicDeficit.fromJson(Map<String, dynamic> json) {
    return ExamTopicDeficit(
      topicId: json['topic_id'] as String? ?? '',
      title: json['title'] as String? ?? 'General Topic',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      possible: (json['possible'] as num?)?.toDouble() ?? 0.0,
      accuracyPct: (json['accuracy_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class RemedialLessonItem {
  const RemedialLessonItem({
    required this.lessonId,
    required this.title,
    required this.topicId,
    this.estimatedMinutes = 10,
  });

  final String lessonId;
  final String title;
  final String topicId;
  final int estimatedMinutes;

  factory RemedialLessonItem.fromJson(Map<String, dynamic> json) {
    return RemedialLessonItem(
      lessonId: json['lesson_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
    );
  }
}

@immutable
class RemedialFlashcardItem {
  const RemedialFlashcardItem({
    required this.deckId,
    required this.title,
    required this.topicId,
    this.cardCount = 0,
  });

  final String deckId;
  final String title;
  final String topicId;
  final int cardCount;

  factory RemedialFlashcardItem.fromJson(Map<String, dynamic> json) {
    return RemedialFlashcardItem(
      deckId: json['deck_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? '',
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ExamQuestionReviewItem {
  const ExamQuestionReviewItem({
    required this.questionId,
    required this.sectionCode,
    required this.orderIndex,
    required this.questionNumber,
    this.subPart,
    required this.questionText,
    required this.questionType,
    this.options = const [],
    this.correctAnswer,
    this.rubricGuide = const [],
    required this.marks,
    this.learnerAnswer,
    required this.marksAwarded,
    this.isFlagged = false,
  });

  final String questionId;
  final String sectionCode;
  final int orderIndex;
  final int questionNumber;
  final String? subPart;
  final String questionText;
  final String questionType;
  final List<ExamQuestionOption> options;
  final String? correctAnswer;
  final List<ExamRubricStep> rubricGuide;
  final double marks;
  final String? learnerAnswer;
  final double marksAwarded;
  final bool isFlagged;

  String get label => subPart != null && subPart!.isNotEmpty
      ? 'Sec $sectionCode Q$questionNumber $subPart'
      : 'Sec $sectionCode Q$questionNumber';

  bool get isFullMarks => marksAwarded >= marks && marks > 0;
  bool get isZeroMarks => marksAwarded == 0;

  factory ExamQuestionReviewItem.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'];
    final opts = <ExamQuestionOption>[];
    if (rawOpts is List) {
      for (final o in rawOpts) {
        if (o is Map<String, dynamic>) {
          opts.add(ExamQuestionOption.fromJson(o));
        }
      }
    }

    final rawRub = json['rubric_guide'];
    final rubric = <ExamRubricStep>[];
    if (rawRub is List) {
      for (final r in rawRub) {
        if (r is Map<String, dynamic>) {
          rubric.add(ExamRubricStep.fromJson(r));
        }
      }
    }

    return ExamQuestionReviewItem(
      questionId: json['question_id'] as String? ?? '',
      sectionCode: json['section_code'] as String? ?? 'A',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      questionNumber: (json['question_number'] as num?)?.toInt() ?? 1,
      subPart: json['sub_part'] as String?,
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'structured',
      options: opts,
      correctAnswer: json['correct_answer'] as String?,
      rubricGuide: rubric,
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      learnerAnswer: json['learner_answer'] as String?,
      marksAwarded: (json['marks_awarded'] as num?)?.toDouble() ?? 0.0,
      isFlagged: json['is_flagged'] as bool? ?? false,
    );
  }
}

@immutable
class LearnerExamResultData {
  const LearnerExamResultData({
    required this.resultId,
    required this.attemptId,
    required this.learnerId,
    required this.title,
    required this.totalScore,
    required this.totalPossibleMarks,
    required this.percentage,
    required this.predictedDivisionOrGrade,
    this.gradingSystem = 'division',
    this.sectionBreakdown = const [],
    this.topicDeficits = const [],
    this.remedialLessons = const [],
    this.remedialFlashcards = const [],
    required this.createdAt,
    this.questionsReview = const [],
  });

  final String resultId;
  final String attemptId;
  final String learnerId;
  final String title;
  final double totalScore;
  final double totalPossibleMarks;
  final double percentage;
  final String predictedDivisionOrGrade;
  final String gradingSystem;
  final List<ExamSectionPerformance> sectionBreakdown;
  final List<ExamTopicDeficit> topicDeficits;
  final List<RemedialLessonItem> remedialLessons;
  final List<RemedialFlashcardItem> remedialFlashcards;
  final DateTime createdAt;
  final List<ExamQuestionReviewItem> questionsReview;

  factory LearnerExamResultData.fromJson(Map<String, dynamic> json) {
    final rawSections = json['section_breakdown'] as List<dynamic>? ?? [];
    final sections = rawSections
        .map((s) => ExamSectionPerformance.fromJson(s as Map<String, dynamic>))
        .toList();

    final rawDeficits = json['topic_deficits'] as List<dynamic>? ?? [];
    final deficits = rawDeficits
        .map((d) => ExamTopicDeficit.fromJson(d as Map<String, dynamic>))
        .toList();

    final rawLessons = json['remedial_lessons'] as List<dynamic>? ?? [];
    final lessons = rawLessons
        .map((l) => RemedialLessonItem.fromJson(l as Map<String, dynamic>))
        .toList();

    final rawDecks = json['remedial_flashcards'] as List<dynamic>? ?? [];
    final decks = rawDecks
        .map((d) => RemedialFlashcardItem.fromJson(d as Map<String, dynamic>))
        .toList();

    final rawQuestions = json['questions_review'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((q) => ExamQuestionReviewItem.fromJson(q as Map<String, dynamic>))
        .toList();

    return LearnerExamResultData(
      resultId: json['result_id'] as String? ?? '',
      attemptId: json['attempt_id'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      totalPossibleMarks:
          (json['total_possible_marks'] as num?)?.toDouble() ?? 100.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      predictedDivisionOrGrade:
          json['predicted_division_or_grade'] as String? ?? 'Division 0',
      gradingSystem: json['grading_system'] as String? ?? 'division',
      sectionBreakdown: sections,
      topicDeficits: deficits,
      remedialLessons: lessons,
      remedialFlashcards: decks,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      questionsReview: questions,
    );
  }
}
