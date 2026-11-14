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
