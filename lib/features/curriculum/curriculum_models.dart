class CurriculumSource {
  const CurriculumSource({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.checksum,
    required this.verificationStatus,
    required this.usageRightsStatus,
    required this.documentReference,
    required this.documentFormat,
    required this.usageRightsEvidenceUrl,
    required this.usageRightsNote,
  });

  factory CurriculumSource.fromJson(Map<String, dynamic> json) {
    return CurriculumSource(
      id: json['id'] as String,
      title: json['document_title'] as String,
      sourceUrl: json['source_url'] as String?,
      checksum: json['sha256_checksum'] as String?,
      verificationStatus: json['verification_status'] as String,
      usageRightsStatus: json['usage_rights_status'] as String,
      documentReference: json['document_reference'] as String?,
      documentFormat: json['document_format'] as String?,
      usageRightsEvidenceUrl: json['usage_rights_evidence_url'] as String?,
      usageRightsNote: json['usage_rights_note'] as String?,
    );
  }

  final String id;
  final String title;
  final String? sourceUrl;
  final String? checksum;
  final String verificationStatus;
  final String usageRightsStatus;
  final String? documentReference;
  final String? documentFormat;
  final String? usageRightsEvidenceUrl;
  final String? usageRightsNote;

  bool get canImport =>
      verificationStatus == 'verified' &&
      (usageRightsStatus == 'authorized' ||
          usageRightsStatus == 'public_domain') &&
      checksum != null;
}

class CurriculumVersion {
  const CurriculumVersion({
    required this.id,
    required this.curriculumId,
    required this.versionCode,
    required this.displayName,
    required this.status,
    required this.requiresReviewedImport,
  });

  factory CurriculumVersion.fromJson(Map<String, dynamic> json) {
    return CurriculumVersion(
      id: json['id'] as String,
      curriculumId: json['curriculum_id'] as String,
      versionCode: json['version_code'] as String,
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      requiresReviewedImport: json['requires_reviewed_import'] as bool,
    );
  }

  final String id;
  final String curriculumId;
  final String versionCode;
  final String displayName;
  final String status;
  final bool requiresReviewedImport;
}

class CurriculumImportJob {
  const CurriculumImportJob({
    required this.id,
    required this.sourceId,
    required this.versionId,
    required this.storageBucket,
    required this.storageObjectPath,
    required this.fileSha256,
    required this.documentFormat,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.uploadComplete,
    required this.pageCount,
    required this.extractionEngine,
    required this.status,
    required this.validationErrors,
    required this.attemptCount,
    required this.createdAt,
  });

  factory CurriculumImportJob.fromJson(Map<String, dynamic> json) {
    return CurriculumImportJob(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      versionId: json['version_id'] as String,
      storageBucket: json['storage_bucket'] as String,
      storageObjectPath: json['storage_object_path'] as String,
      fileSha256: json['file_sha256'] as String,
      documentFormat: json['document_format'] as String? ?? 'application/pdf',
      originalFilename: json['original_filename'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      uploadComplete: json['upload_complete'] as bool? ?? false,
      pageCount: (json['page_count'] as num?)?.toInt(),
      extractionEngine: json['extraction_engine'] as String?,
      status: json['status'] as String,
      validationErrors: (json['validation_errors'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false),
      attemptCount: (json['attempt_count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String sourceId;
  final String versionId;
  final String storageBucket;
  final String storageObjectPath;
  final String fileSha256;
  final String documentFormat;
  final String? originalFilename;
  final int? fileSizeBytes;
  final bool uploadComplete;
  final int? pageCount;
  final String? extractionEngine;
  final String status;
  final List<String> validationErrors;
  final int attemptCount;
  final DateTime createdAt;
}

class CurriculumImportPage {
  const CurriculumImportPage({
    required this.id,
    required this.pageNumber,
    required this.extractedText,
    required this.extractionMethod,
    required this.ocrConfidence,
    required this.pageMetadata,
    required this.extractionWarnings,
    required this.pageRevision,
    required this.sectionPath,
  });

  factory CurriculumImportPage.fromJson(Map<String, dynamic> json) {
    return CurriculumImportPage(
      id: json['id'] as String,
      pageNumber: (json['page_number'] as num).toInt(),
      extractedText: json['extracted_text'] as String,
      extractionMethod:
          json['extraction_method'] as String? ?? 'selectable_text',
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble(),
      pageMetadata: Map<String, dynamic>.from(
        json['page_metadata'] as Map? ?? const {},
      ),
      extractionWarnings: (json['extraction_warnings'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false),
      pageRevision: (json['page_revision'] as num?)?.toInt() ?? 1,
      sectionPath: (json['section_path'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  final String id;
  final int pageNumber;
  final String extractedText;
  final String extractionMethod;
  final double? ocrConfidence;
  final Map<String, dynamic> pageMetadata;
  final List<String> extractionWarnings;
  final int pageRevision;
  final List<String> sectionPath;
}

class CurriculumImportItem {
  const CurriculumImportItem({
    required this.id,
    required this.jobId,
    required this.importPageId,
    required this.itemType,
    required this.officialTerm,
    required this.sourceText,
    required this.normalizedText,
    required this.reviewStatus,
    required this.createdBy,
    required this.reviewedBy,
    required this.reviewNote,
  });

  factory CurriculumImportItem.fromJson(Map<String, dynamic> json) {
    return CurriculumImportItem(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      importPageId: json['import_page_id'] as String,
      itemType: json['item_type'] as String,
      officialTerm: json['official_term'] as String?,
      sourceText: json['source_text'] as String,
      normalizedText: json['normalized_text'] as String,
      reviewStatus: json['review_status'] as String,
      createdBy: json['created_by'] as String,
      reviewedBy: json['reviewed_by'] as String?,
      reviewNote: json['review_note'] as String?,
    );
  }

  final String id;
  final String jobId;
  final String importPageId;
  final String itemType;
  final String? officialTerm;
  final String sourceText;
  final String normalizedText;
  final String reviewStatus;
  final String createdBy;
  final String? reviewedBy;
  final String? reviewNote;
}

class CurriculumValidationReport {
  const CurriculumValidationReport({
    required this.passed,
    required this.errorCount,
    required this.warningCount,
    required this.status,
    required this.errors,
    required this.warnings,
    required this.createdAt,
  });

  factory CurriculumValidationReport.fromJson(Map<String, dynamic> json) {
    final report = Map<String, dynamic>.from(json['report'] as Map);
    return CurriculumValidationReport(
      passed: json['passed'] as bool,
      errorCount: (json['error_count'] as num).toInt(),
      warningCount: (json['warning_count'] as num).toInt(),
      status: report['status'] as String,
      errors: (report['errors'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      warnings: (report['warnings'] as List<dynamic>? ?? const [])
          .map(
            (value) => CurriculumValidationWarning.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final bool passed;
  final int errorCount;
  final int warningCount;
  final String status;
  final List<String> errors;
  final List<CurriculumValidationWarning> warnings;
  final DateTime createdAt;
}

class CurriculumValidationWarning {
  const CurriculumValidationWarning({required this.message, this.pageNumber});

  factory CurriculumValidationWarning.fromJson(Map<String, dynamic> json) {
    return CurriculumValidationWarning(
      message: json['warning'] as String? ?? json.toString(),
      pageNumber: (json['page_number'] as num?)?.toInt(),
    );
  }

  final String message;
  final int? pageNumber;
}

class CurriculumDuplicateMatch {
  const CurriculumDuplicateMatch({
    required this.id,
    required this.importItemId,
    required this.candidateItemId,
    required this.matchType,
    required this.similarity,
    required this.decision,
    required this.reviewNote,
    required this.candidateLabel,
    required this.candidateText,
  });

  factory CurriculumDuplicateMatch.fromJson(Map<String, dynamic> json) {
    final candidate = Map<String, dynamic>.from(
      json['candidate'] as Map? ?? const {},
    );
    return CurriculumDuplicateMatch(
      id: json['id'] as String,
      importItemId: json['import_item_id'] as String,
      candidateItemId: json['candidate_item_id'] as String,
      matchType: json['match_type'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      decision: json['decision'] as String,
      reviewNote: json['review_note'] as String?,
      candidateLabel:
          candidate['official_term'] as String? ??
          candidate['item_type'] as String? ??
          json['candidate_item_id'] as String,
      candidateText: candidate['normalized_text'] as String? ?? '',
    );
  }

  final String id;
  final String importItemId;
  final String candidateItemId;
  final String matchType;
  final double similarity;
  final String decision;
  final String? reviewNote;
  final String candidateLabel;
  final String candidateText;
}

class CurriculumSourceRightsEvent {
  const CurriculumSourceRightsEvent({
    required this.status,
    required this.note,
    required this.createdAt,
  });

  factory CurriculumSourceRightsEvent.fromJson(Map<String, dynamic> json) {
    return CurriculumSourceRightsEvent(
      status: json['usage_rights_status'] as String,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String status;
  final String note;
  final DateTime createdAt;
}

class CurriculumPilotSnapshot {
  const CurriculumPilotSnapshot({
    required this.source,
    required this.version,
    required this.rightsHistory,
    required this.jobs,
  });

  final CurriculumSource source;
  final CurriculumVersion version;
  final List<CurriculumSourceRightsEvent> rightsHistory;
  final List<CurriculumImportJob> jobs;
}

class CurriculumStaffCapabilities {
  const CurriculumStaffCapabilities({
    required this.canAccess,
    required this.canEdit,
    required this.canReview,
    required this.canApprove,
  });

  final bool canAccess;
  final bool canEdit;
  final bool canReview;
  final bool canApprove;
}
