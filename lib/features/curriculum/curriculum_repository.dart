import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import 'curriculum_models.dart';

class CurriculumRepository {
  const CurriculumRepository(this._client);

  static const tiePrimaryPilotVersionCode = 'tie-primary-pilot-source-review-1';
  static const tiePrimarySourceChecksum =
      '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591';
  static const _sourceColumns =
      'id, document_title, source_url, sha256_checksum, verification_status, '
      'usage_rights_status, document_reference, document_format, usage_rights_evidence_url, '
      'usage_rights_note';
  static const _jobColumns =
      'id, source_id, version_id, storage_bucket, storage_object_path, '
      'file_sha256, document_format, original_filename, file_size_bytes, '
      'upload_complete, page_count, extraction_engine, status, validation_errors, '
      'attempt_count, created_at';
  static const _itemColumns =
      'id, job_id, import_page_id, item_type, official_term, source_text, '
      'normalized_text, review_status, created_by, reviewed_by, review_note';

  final SupabaseClient _client;

  Future<CurriculumStaffCapabilities> getStaffCapabilities() async {
    if (_client.auth.currentUser == null) {
      return const CurriculumStaffCapabilities(
        canAccess: false,
        canEdit: false,
        canReview: false,
        canApprove: false,
      );
    }

    final access = await _hasRole([
      'curriculum_editor',
      'curriculum_reviewer',
      'curriculum_approver',
      'curriculum_admin',
      'country_admin',
    ]);
    final edit = await _hasRole(['curriculum_editor', 'curriculum_admin']);
    final review = await _hasRole(['curriculum_reviewer', 'curriculum_admin']);
    final approve = await _hasRole(['curriculum_approver', 'curriculum_admin']);

    return CurriculumStaffCapabilities(
      canAccess: access,
      canEdit: edit,
      canReview: review,
      canApprove: approve,
    );
  }

  Future<CurriculumPilotSnapshot> getPilotSnapshot() async {
    final sourceJson = await _client
        .from('curriculum_sources')
        .select(_sourceColumns)
        .eq('sha256_checksum', tiePrimarySourceChecksum)
        .single();
    final versionJson = await _client
        .from('curriculum_versions')
        .select(
          'id, curriculum_id, version_code, display_name, status, '
          'requires_reviewed_import',
        )
        .eq('version_code', tiePrimaryPilotVersionCode)
        .single();
    final source = CurriculumSource.fromJson(sourceJson);
    final version = CurriculumVersion.fromJson(versionJson);
    final rightsHistoryJson = await _client
        .from('curriculum_source_rights_history')
        .select('usage_rights_status, note, created_at')
        .eq('source_id', source.id)
        .order('created_at', ascending: false);
    final jobsJson = await _client
        .from('curriculum_import_jobs')
        .select(_jobColumns)
        .eq('version_id', version.id)
        .order('created_at', ascending: false);

    return CurriculumPilotSnapshot(
      source: source,
      version: version,
      rightsHistory: rightsHistoryJson
          .map((row) => CurriculumSourceRightsEvent.fromJson(row))
          .toList(growable: false),
      jobs: jobsJson
          .map((row) => CurriculumImportJob.fromJson(row))
          .toList(growable: false),
    );
  }

  Future<List<CurriculumImportPage>> getImportPages(String jobId) async {
    final rows = await _client
        .from('curriculum_import_pages')
        .select(
          'id, page_number, extracted_text, extraction_method, ocr_confidence, '
          'page_metadata, extraction_warnings, page_revision, section_path',
        )
        .eq('job_id', jobId)
        .order('page_number');
    return rows
        .map((row) => CurriculumImportPage.fromJson(row))
        .toList(growable: false);
  }

  Future<List<CurriculumImportItem>> getImportItems(String jobId) async {
    final rows = await _client
        .from('curriculum_import_items')
        .select(_itemColumns)
        .eq('job_id', jobId)
        .order('created_at');
    return rows
        .map((row) => CurriculumImportItem.fromJson(row))
        .toList(growable: false);
  }

  Future<CurriculumImportJob> registerImport({
    required String versionId,
    required String sourceId,
    required String checksum,
    required String documentFormat,
    required String filename,
    required int fileSizeBytes,
  }) async {
    final row = await _client.rpc(
      'register_curriculum_import_document',
      params: {
        'p_version_id': versionId,
        'p_source_id': sourceId,
        'p_file_sha256': checksum,
        'p_document_format': documentFormat,
        'p_original_filename': filename,
        'p_file_size_bytes': fileSizeBytes,
      },
    );
    return CurriculumImportJob.fromJson(row as Map<String, dynamic>);
  }

  Future<void> uploadSourceDocument({
    required CurriculumImportJob job,
    required Uint8List bytes,
  }) async {
    await _client.storage
        .from(job.storageBucket)
        .uploadBinary(
          job.storageObjectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: job.documentFormat,
            upsert: true,
          ),
        );
  }

  Future<CurriculumImportJob> markImportUploaded(String jobId) async {
    final row = await _client.rpc(
      'mark_curriculum_import_uploaded',
      params: {'p_job_id': jobId},
    );
    return CurriculumImportJob.fromJson(row as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> validateImport(String jobId) async {
    final result = await _client.rpc(
      'validate_curriculum_import_stage3_3',
      params: {'p_job_id': jobId},
    );
    return result as Map<String, dynamic>;
  }

  Future<CurriculumValidationReport?> getValidationReport(String jobId) async {
    final rows = await _client
        .from('curriculum_validation_results')
        .select('passed, error_count, warning_count, report, created_at')
        .eq('job_id', jobId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return CurriculumValidationReport.fromJson(rows.first);
  }

  Future<List<CurriculumDuplicateMatch>> getDuplicateMatches(
    String jobId,
  ) async {
    final rows = await _client
        .from('curriculum_duplicate_matches')
        .select(
          'id, import_item_id, candidate_item_id, match_type, similarity, '
          'decision, review_note, candidate:curriculum_import_items!curriculum_duplicate_matches_candidate_fk('
          'item_type, official_term, normalized_text)',
        )
        .eq('job_id', jobId)
        .order('created_at');
    return rows
        .map((row) => CurriculumDuplicateMatch.fromJson(row))
        .toList(growable: false);
  }

  Future<void> reviewDuplicateMatch({
    required String matchId,
    required String decision,
    required String? note,
  }) async {
    await _client.rpc(
      'review_curriculum_duplicate_match',
      params: {
        'p_match_id': matchId,
        'p_decision': decision,
        'p_note': note?.trim(),
      },
    );
  }

  Future<void> requestPageReprocess({
    required String jobId,
    required int pageNumber,
  }) async {
    await _client.rpc(
      'request_curriculum_page_reprocess',
      params: {'p_job_id': jobId, 'p_page_number': pageNumber},
    );
  }

  Future<void> addImportItem({
    required String jobId,
    required String versionId,
    required String curriculumId,
    required String pageId,
    required String itemType,
    required String? officialTerm,
    required String sourceText,
    required String normalizedText,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const NotSignedInException();

    await _client.from('curriculum_import_items').insert({
      'job_id': jobId,
      'version_id': versionId,
      'curriculum_id': curriculumId,
      'import_page_id': pageId,
      'item_type': itemType,
      'official_term': officialTerm,
      'source_text': sourceText.trim(),
      'normalized_text': normalizedText.trim(),
      'normalized_fingerprint': List.filled(64, '0').join(),
      'created_by': userId,
    });
  }

  Future<void> verifySource({
    required String sourceId,
    required bool verified,
    required String note,
  }) async {
    await _client.rpc(
      'verify_curriculum_source',
      params: {
        'p_source_id': sourceId,
        'p_verified': verified,
        'p_note': note.trim(),
      },
    );
  }

  Future<void> reviewSourceRights({
    required String sourceId,
    required String status,
    required String note,
    required String? evidenceUrl,
  }) async {
    final trimmedEvidence = evidenceUrl?.trim();
    await _client.rpc(
      'review_curriculum_source_rights',
      params: {
        'p_source_id': sourceId,
        'p_status': status,
        'p_note': note.trim(),
        'p_evidence_url': trimmedEvidence == null || trimmedEvidence.isEmpty
            ? null
            : trimmedEvidence,
      },
    );
  }

  Future<CurriculumImportItem> reviewImportItem({
    required String itemId,
    required String decision,
    required String? note,
  }) async {
    final row = await _client.rpc(
      'review_curriculum_import_item',
      params: {
        'p_item_id': itemId,
        'p_decision': decision,
        'p_note': note?.trim(),
      },
    );
    return CurriculumImportItem.fromJson(row as Map<String, dynamic>);
  }

  Future<void> transitionVersion({
    required String versionId,
    required String targetStatus,
    required String note,
  }) async {
    await _client.rpc(
      'transition_curriculum_version',
      params: {
        'p_version_id': versionId,
        'p_target_status': targetStatus,
        'p_note': note.trim(),
      },
    );
  }

  Future<bool> _hasRole(List<String> roles) async {
    final result = await _client.rpc(
      'has_curriculum_role',
      params: {'p_country_code': 'TZ', 'p_roles': roles},
    );
    return result as bool;
  }
}
