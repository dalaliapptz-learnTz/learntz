import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_studio_models.dart';

class ContentStudioRepository {
  ContentStudioRepository([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;

  Future<ContentStudioMetrics> getContentStudioMetrics({String? countryCode}) async {
    final client = _client;
    if (client == null) {
      return const ContentStudioMetrics(
        countryCode: 'ALL',
        totalSubjects: 0,
        totalTopics: 0,
        totalLessons: 0,
        publishedLessons: 0,
        draftLessons: 0,
        inReviewLessons: 0,
        totalMediaAssets: 0,
      );
    }

    try {
      final response = await client.rpc(
        'get_content_studio_metrics',
        params: {
          'p_country_code': countryCode == 'ALL' ? null : countryCode,
        },
      );

      return ContentStudioMetrics.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (_) {
      return const ContentStudioMetrics(
        countryCode: 'ALL',
        totalSubjects: 0,
        totalTopics: 0,
        totalLessons: 0,
        publishedLessons: 0,
        draftLessons: 0,
        inReviewLessons: 0,
        totalMediaAssets: 0,
      );
    }
  }

  Future<List<StudioSubjectItem>> getContentStudioCatalog({
    String? countryCode,
    String? search,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'get_content_studio_catalog',
        params: {
          'p_country_code': countryCode == 'ALL' ? null : countryCode,
          'p_search': search?.trim().isEmpty == true ? null : search?.trim(),
        },
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              StudioSubjectItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> upsertStudioLesson({
    required String topicId,
    required String title,
    required String bodyMarkdown,
    String? summary,
    int estimatedMinutes = 10,
    bool isFreePreview = false,
    String status = 'draft',
    List<Map<String, dynamic>>? contentBlocks,
    String? lessonId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client.rpc(
      'upsert_studio_lesson',
      params: {
        'p_topic_id': topicId,
        'p_title': title.trim(),
        'p_body_markdown': bodyMarkdown,
        'p_summary': summary?.trim(),
        'p_estimated_minutes': estimatedMinutes,
        'p_is_free_preview': isFreePreview,
        'p_status': status,
        'p_content_blocks': contentBlocks ?? [],
        'p_lesson_id': lessonId,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> submitLessonReview({
    required String lessonId,
    required String action,
    String? feedback,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client.rpc(
      'submit_lesson_review',
      params: {
        'p_lesson_id': lessonId,
        'p_action': action,
        'p_feedback': feedback?.trim(),
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<MediaAssetItem>> listContentMediaAssets({String? countryCode}) async {
    final client = _client;
    if (client == null) return [];

    try {
      var query = client.from('content_media_assets').select();
      if (countryCode != null && countryCode != 'ALL') {
        query = query.eq('country_code', countryCode);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              MediaAssetItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MediaAssetItem> createMediaAsset({
    required String title,
    required String countryCode,
    required String mediaType,
    required String fileUrl,
    int fileSizeBytes = 0,
    String? altText,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client
        .from('content_media_assets')
        .insert({
          'title': title.trim(),
          'country_code': countryCode,
          'media_type': mediaType,
          'file_url': fileUrl.trim(),
          'file_size_bytes': fileSizeBytes,
          'alt_text': altText?.trim(),
        })
        .select()
        .single();

    return MediaAssetItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>?> getLessonDetail(String lessonId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (_) {
      return null;
    }
  }
}

