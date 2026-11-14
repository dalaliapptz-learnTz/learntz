import 'package:supabase_flutter/supabase_flutter.dart';

import 'exam_models.dart';

class ExamRepository {
  const ExamRepository(this._client);

  final SupabaseClient _client;

  Future<ExaminationCentreCatalog> getCatalog({String? countryCode}) async {
    final response = await _client.rpc(
      'get_national_examination_centre_catalog',
      params: {
        if (countryCode != null && countryCode.isNotEmpty)
          'p_country_code': countryCode,
      },
    );

    if (response is Map<String, dynamic>) {
      return ExaminationCentreCatalog.fromJson(response);
    }
    throw const FormatException('Invalid catalog response from Supabase');
  }

  Future<List<ExaminationPaper>> listPapers({
    String? countryCode,
    String? nationalExaminationId,
    String? authorityId,
    String? subjectName,
    String? tier,
    int? year,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'list_examination_papers',
      params: {
        'p_country_code': countryCode,
        'p_national_examination_id': nationalExaminationId,
        'p_authority_id': authorityId,
        'p_subject_name': subjectName,
        'p_tier': tier,
        'p_year': year,
        'p_search': search,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is Map<String, dynamic>) {
      final papersJson = response['papers'] as List<dynamic>? ?? [];
      return papersJson
          .map((p) => ExaminationPaper.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ExaminationPaper?> getPaperDetails(String paperId) async {
    final response = await _client.rpc(
      'get_examination_paper_details',
      params: {'p_paper_id': paperId},
    );

    if (response is Map<String, dynamic>) {
      return ExaminationPaper.fromJson(response);
    }
    return null;
  }

  Future<ExaminationPaperUploadResult> uploadPaper(
    PaperUploadRequest request,
  ) async {
    final response = await _client.rpc(
      'upload_examination_paper',
      params: request.toRpcParams(),
    );

    if (response is Map<String, dynamic>) {
      return ExaminationPaperUploadResult.fromJson(response);
    }
    throw const FormatException('Invalid response when uploading paper');
  }
}
