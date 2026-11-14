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

  Future<List<ExamExtractedQuestion>> getApprovedQuestions({
    String? paperId,
    String? subjectId,
    String? topicId,
    String? bloomLevel,
    String? difficulty,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'get_approved_exam_questions',
      params: {
        'p_paper_id': paperId,
        'p_subject_id': subjectId,
        'p_topic_id': topicId,
        'p_bloom_level': bloomLevel,
        'p_difficulty': difficulty,
        'p_search': search,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is Map<String, dynamic>) {
      final questionsList = response['questions'] as List<dynamic>? ?? [];
      return questionsList
          .map((q) => ExamExtractedQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> registerQuestion({
    required String paperId,
    required String sectionCode,
    required int questionNumber,
    required String questionText,
    required double marks,
    String? subPart,
    String? diagramUrl,
    String questionType = 'structured',
    List<Map<String, dynamic>> options = const [],
    String? correctAnswer,
    List<Map<String, dynamic>> rubricGuide = const [],
    String? subjectId,
    String? topicId,
    String bloomLevel = 'comprehension',
    String difficulty = 'medium',
  }) async {
    final response = await _client.rpc(
      'register_extracted_exam_question',
      params: {
        'p_paper_id': paperId,
        'p_section_code': sectionCode,
        'p_question_number': questionNumber,
        'p_question_text': questionText,
        'p_marks': marks,
        'p_sub_part': subPart,
        'p_diagram_url': diagramUrl,
        'p_question_type': questionType,
        'p_options': options,
        'p_correct_answer': correctAnswer,
        'p_rubric_guide': rubricGuide,
        'p_subject_id': subjectId,
        'p_topic_id': topicId,
        'p_bloom_level': bloomLevel,
        'p_difficulty': difficulty,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw const FormatException('Invalid response when registering exam question');
  }

  Future<ExamQuestionReviewResult> reviewQuestion({
    required String questionId,
    required String decision,
    String? notes,
  }) async {
    final response = await _client.rpc(
      'review_exam_question',
      params: {
        'p_question_id': questionId,
        'p_decision': decision,
        'p_notes': notes,
      },
    );

    if (response is Map<String, dynamic>) {
      return ExamQuestionReviewResult.fromJson(response);
    }
    throw const FormatException('Invalid response when reviewing question');
  }
}
