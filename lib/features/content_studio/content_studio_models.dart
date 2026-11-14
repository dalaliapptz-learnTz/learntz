import 'package:flutter/foundation.dart';

enum ContentWorkflowStatus {
  draft,
  inReview,
  approved,
  published,
  archived;

  String get dbValue => switch (this) {
        ContentWorkflowStatus.draft => 'draft',
        ContentWorkflowStatus.inReview => 'in_review',
        ContentWorkflowStatus.approved => 'approved',
        ContentWorkflowStatus.published => 'published',
        ContentWorkflowStatus.archived => 'archived',
      };

  String get displayName => switch (this) {
        ContentWorkflowStatus.draft => 'Draft',
        ContentWorkflowStatus.inReview => 'In Review',
        ContentWorkflowStatus.approved => 'Approved',
        ContentWorkflowStatus.published => 'Published',
        ContentWorkflowStatus.archived => 'Archived',
      };

  static ContentWorkflowStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'in_review':
        return ContentWorkflowStatus.inReview;
      case 'approved':
        return ContentWorkflowStatus.approved;
      case 'published':
        return ContentWorkflowStatus.published;
      case 'archived':
        return ContentWorkflowStatus.archived;
      case 'draft':
      default:
        return ContentWorkflowStatus.draft;
    }
  }
}

@immutable
class ContentStudioMetrics {
  const ContentStudioMetrics({
    required this.countryCode,
    required this.totalSubjects,
    required this.totalTopics,
    required this.totalLessons,
    required this.publishedLessons,
    required this.draftLessons,
    required this.inReviewLessons,
    required this.totalMediaAssets,
  });

  final String countryCode;
  final int totalSubjects;
  final int totalTopics;
  final int totalLessons;
  final int publishedLessons;
  final int draftLessons;
  final int inReviewLessons;
  final int totalMediaAssets;

  factory ContentStudioMetrics.fromJson(Map<String, dynamic> json) {
    return ContentStudioMetrics(
      countryCode: json['country_code'] as String? ?? 'ALL',
      totalSubjects: (json['total_subjects'] as num?)?.toInt() ?? 0,
      totalTopics: (json['total_topics'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      publishedLessons: (json['published_lessons'] as num?)?.toInt() ?? 0,
      draftLessons: (json['draft_lessons'] as num?)?.toInt() ?? 0,
      inReviewLessons: (json['in_review_lessons'] as num?)?.toInt() ?? 0,
      totalMediaAssets: (json['total_media_assets'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class StudioLessonItem {
  const StudioLessonItem({
    required this.lessonId,
    required this.lessonTitle,
    this.lessonSummary,
    this.estimatedMinutes = 10,
    this.isFreePreview = false,
    this.lessonOrder = 1,
    this.status = ContentWorkflowStatus.draft,
    this.isPublished = false,
    this.versionNumber = 1,
    this.updatedAt,
  });

  final String lessonId;
  final String lessonTitle;
  final String? lessonSummary;
  final int estimatedMinutes;
  final bool isFreePreview;
  final int lessonOrder;
  final ContentWorkflowStatus status;
  final bool isPublished;
  final int versionNumber;
  final DateTime? updatedAt;

  factory StudioLessonItem.fromJson(Map<String, dynamic> json) {
    return StudioLessonItem(
      lessonId: json['lesson_id'] as String? ?? '',
      lessonTitle: json['lesson_title'] as String? ?? '',
      lessonSummary: json['lesson_summary'] as String?,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      lessonOrder: (json['lesson_order'] as num?)?.toInt() ?? 1,
      status: ContentWorkflowStatus.fromString(json['lesson_status'] as String?),
      isPublished: json['lesson_is_published'] as bool? ?? false,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

@immutable
class StudioTopicItem {
  const StudioTopicItem({
    required this.topicId,
    required this.topicTitle,
    this.topicSummary,
    this.topicOrder = 1,
    this.isPublished = false,
    this.lessons = const [],
  });

  final String topicId;
  final String topicTitle;
  final String? topicSummary;
  final int topicOrder;
  final bool isPublished;
  final List<StudioLessonItem> lessons;

  factory StudioTopicItem.fromJson(Map<String, dynamic> json) {
    return StudioTopicItem(
      topicId: json['topic_id'] as String? ?? '',
      topicTitle: json['topic_title'] as String? ?? '',
      topicSummary: json['topic_summary'] as String?,
      topicOrder: (json['topic_order'] as num?)?.toInt() ?? 1,
      isPublished: json['topic_is_published'] as bool? ?? false,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((item) =>
                  StudioLessonItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StudioSubjectItem {
  const StudioSubjectItem({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.countryCode,
    this.subjectOrder = 1,
    this.topics = const [],
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String countryCode;
  final int subjectOrder;
  final List<StudioTopicItem> topics;

  factory StudioSubjectItem.fromJson(Map<String, dynamic> json) {
    return StudioSubjectItem(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      subjectOrder: (json['subject_order'] as num?)?.toInt() ?? 1,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((item) =>
                  StudioTopicItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}

@immutable
class MediaAssetItem {
  const MediaAssetItem({
    required this.id,
    required this.title,
    required this.countryCode,
    required this.mediaType,
    required this.fileUrl,
    this.fileSizeBytes = 0,
    this.altText,
    this.createdAt,
  });

  final String id;
  final String title;
  final String countryCode;
  final String mediaType;
  final String fileUrl;
  final int fileSizeBytes;
  final String? altText;
  final DateTime? createdAt;

  factory MediaAssetItem.fromJson(Map<String, dynamic> json) {
    return MediaAssetItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      mediaType: json['media_type'] as String? ?? 'image',
      fileUrl: json['file_url'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      altText: json['alt_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
