import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/content_studio/content_studio_models.dart';
import 'package:learntz/features/content_studio/content_studio_providers.dart';
import 'package:learntz/features/content_studio/screens/content_media_library_screen.dart';
import 'package:learntz/features/content_studio/screens/content_studio_dashboard_screen.dart';
import 'package:learntz/features/content_studio/screens/lesson_editor_studio_screen.dart';

void main() {
  group('Content Studio Models & Enums Tests', () {
    test('ContentWorkflowStatus mappings and fallback', () {
      expect(ContentWorkflowStatus.fromString('draft'), ContentWorkflowStatus.draft);
      expect(ContentWorkflowStatus.fromString('in_review'), ContentWorkflowStatus.inReview);
      expect(ContentWorkflowStatus.fromString('approved'), ContentWorkflowStatus.approved);
      expect(ContentWorkflowStatus.fromString('published'), ContentWorkflowStatus.published);
      expect(ContentWorkflowStatus.fromString('archived'), ContentWorkflowStatus.archived);
      expect(ContentWorkflowStatus.fromString('unknown'), ContentWorkflowStatus.draft);
      expect(ContentWorkflowStatus.fromString(null), ContentWorkflowStatus.draft);

      expect(ContentWorkflowStatus.draft.dbValue, 'draft');
      expect(ContentWorkflowStatus.inReview.dbValue, 'in_review');
      expect(ContentWorkflowStatus.approved.dbValue, 'approved');
      expect(ContentWorkflowStatus.published.dbValue, 'published');
      expect(ContentWorkflowStatus.archived.dbValue, 'archived');

      expect(ContentWorkflowStatus.draft.displayName, 'Draft');
      expect(ContentWorkflowStatus.inReview.displayName, 'In Review');
      expect(ContentWorkflowStatus.approved.displayName, 'Approved');
      expect(ContentWorkflowStatus.published.displayName, 'Published');
      expect(ContentWorkflowStatus.archived.displayName, 'Archived');
    });

    test('ContentStudioMetrics.fromJson parses metrics accurately', () {
      final json = {
        'country_code': 'TZ',
        'total_subjects': 12,
        'total_topics': 48,
        'total_lessons': 120,
        'published_lessons': 85,
        'draft_lessons': 25,
        'in_review_lessons': 10,
        'total_media_assets': 34,
      };

      final metrics = ContentStudioMetrics.fromJson(json);
      expect(metrics.countryCode, 'TZ');
      expect(metrics.totalSubjects, 12);
      expect(metrics.totalTopics, 48);
      expect(metrics.totalLessons, 120);
      expect(metrics.publishedLessons, 85);
      expect(metrics.draftLessons, 25);
      expect(metrics.inReviewLessons, 10);
      expect(metrics.totalMediaAssets, 34);
    });

    test('Studio curriculum tree models parse nested hierarchy', () {
      final json = {
        'subject_id': 's1',
        'subject_name': 'Biology',
        'subject_code': 'BIO-TZ',
        'country_code': 'TZ',
        'subject_order': 1,
        'topics': [
          {
            'topic_id': 't1',
            'topic_title': 'Cell Structure and Organization',
            'topic_summary': 'Introduction to eukaryotic and prokaryotic cells',
            'topic_order': 1,
            'topic_is_published': true,
            'lessons': [
              {
                'lesson_id': 'l1',
                'lesson_title': 'The Plant Cell',
                'lesson_summary': 'Cell wall, chloroplasts, and large vacuole',
                'estimated_minutes': 15,
                'is_free_preview': true,
                'lesson_order': 1,
                'lesson_status': 'published',
                'lesson_is_published': true,
                'version_number': 3,
                'updated_at': '2026-11-14T10:00:00Z',
              }
            ],
          }
        ],
      };

      final subject = StudioSubjectItem.fromJson(json);
      expect(subject.subjectId, 's1');
      expect(subject.subjectName, 'Biology');
      expect(subject.countryCode, 'TZ');
      expect(subject.topics.length, 1);

      final topic = subject.topics.first;
      expect(topic.topicId, 't1');
      expect(topic.topicTitle, 'Cell Structure and Organization');
      expect(topic.isPublished, isTrue);
      expect(topic.lessons.length, 1);

      final lesson = topic.lessons.first;
      expect(lesson.lessonId, 'l1');
      expect(lesson.lessonTitle, 'The Plant Cell');
      expect(lesson.estimatedMinutes, 15);
      expect(lesson.isFreePreview, isTrue);
      expect(lesson.status, ContentWorkflowStatus.published);
      expect(lesson.versionNumber, 3);
      expect(lesson.updatedAt, isNotNull);
    });

    test('MediaAssetItem.fromJson parses media metadata', () {
      final json = {
        'id': 'a1',
        'title': 'Plant Cell Diagram',
        'country_code': 'TZ',
        'media_type': 'diagram',
        'file_url': 'https://assets.learntz.org/diagrams/cell.png',
        'file_size_bytes': 204800,
        'alt_text': 'Detailed diagram of a plant cell',
        'created_at': '2026-11-14T08:00:00Z',
      };

      final asset = MediaAssetItem.fromJson(json);
      expect(asset.id, 'a1');
      expect(asset.title, 'Plant Cell Diagram');
      expect(asset.countryCode, 'TZ');
      expect(asset.mediaType, 'diagram');
      expect(asset.fileSizeBytes, 204800);
      expect(asset.altText, 'Detailed diagram of a plant cell');
      expect(asset.createdAt, isNotNull);
    });
  });

  group('Content Studio Widget Tests', () {
    testWidgets('ContentStudioDashboardScreen renders KPI cards, filters and curriculum tree',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const mockMetrics = ContentStudioMetrics(
        countryCode: 'ALL',
        totalSubjects: 8,
        totalTopics: 24,
        totalLessons: 60,
        publishedLessons: 45,
        draftLessons: 10,
        inReviewLessons: 5,
        totalMediaAssets: 18,
      );

      final mockCatalog = [
        const StudioSubjectItem(
          subjectId: 's1',
          subjectName: 'Tanzania Biology',
          subjectCode: 'TZ-BIO',
          countryCode: 'TZ',
          topics: [
            StudioTopicItem(
              topicId: 't1',
              topicTitle: 'Cell Biology',
              topicOrder: 1,
              isPublished: true,
              lessons: [
                StudioLessonItem(
                  lessonId: 'l1',
                  lessonTitle: 'The Plant Cell',
                  estimatedMinutes: 15,
                  isFreePreview: true,
                  status: ContentWorkflowStatus.published,
                  versionNumber: 2,
                ),
              ],
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentStudioMetricsProvider.overrideWith((ref) async => mockMetrics),
            contentStudioCatalogProvider.overrideWith((ref) async => mockCatalog),
          ],
          child: const MaterialApp(
            home: ContentStudioDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Content Management Studio'), findsOneWidget);
      expect(find.text('Authoring & Editorial Cockpit'), findsOneWidget);
      expect(find.text('New Lesson'), findsOneWidget);
      expect(find.text('Media Library'), findsOneWidget);

      // Filter chips
      expect(find.text('All Markets'), findsOneWidget);
      expect(find.text('TZ'), findsOneWidget);
      expect(find.text('KE'), findsOneWidget);
      expect(find.text('UG'), findsOneWidget);

      // KPI metrics
      expect(find.text('Total Lessons'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('Published Lessons'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);

      // Curriculum Tree
      expect(find.text('Tanzania Biology'), findsOneWidget);
      expect(find.text('Code: TZ-BIO • Country: TZ'), findsOneWidget);
      expect(find.text('Topic 1: Cell Biology'), findsOneWidget);
    });

    testWidgets('LessonEditorStudioScreen renders form, formatting toolbar and preview',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final initialData = {
        'lessonId': 'test-lesson-id-123',
        'topicId': 't1',
        'title': 'Photosynthesis and Energy Transfer',
        'summary': 'Explore the light-dependent and light-independent reactions.',
        'minutes': 20,
        'freePreview': true,
        'status': 'draft',
        'versionNumber': 1,
        'bodyMarkdown': '# Photosynthesis Overview\n\nChlorophyll absorbs sunlight to produce glucose.\n\n> **TIP**: Keep track of the carbon fixation steps.\n',
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studioFlatTopicsProvider.overrideWith(
              (ref) async => [
                const FlatTopicOption(
                  topicId: 't1',
                  topicTitle: 'Cell Biology',
                  subjectName: 'Biology',
                  countryCode: 'TZ',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: LessonEditorStudioScreen(initialData: initialData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and badges
      expect(find.text('Edit Lesson Studio'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);

      // Action buttons
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Submit for Review'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);

      // Metadata inputs
      expect(find.byKey(const Key('lesson-title-field')), findsOneWidget);
      expect(find.text('Photosynthesis and Energy Transfer'), findsWidgets);
      expect(find.byKey(const Key('lesson-markdown-body-field')), findsOneWidget);

      // Toolbar buttons
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('H3'), findsOneWidget);
      expect(find.text('Tip Callout'), findsOneWidget);

      // Live student preview simulation
      expect(find.text('Live Student Reader Preview'), findsOneWidget);
      expect(find.text('Photosynthesis Overview'), findsOneWidget);
      expect(find.text('Chlorophyll absorbs sunlight to produce glucose.'), findsOneWidget);

      // Editorial Governance
      expect(find.text('Editorial Governance & Review Actions'), findsOneWidget);
      expect(find.text('Approve & Publish'), findsOneWidget);
      expect(find.text('Reject to Draft'), findsOneWidget);
      expect(find.text('Archive Lesson'), findsOneWidget);
    });

    testWidgets('ContentMediaLibraryScreen renders assets, search, and upload dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAssets = [
        const MediaAssetItem(
          id: 'a1',
          title: 'Plant Cell Diagram',
          countryCode: 'TZ',
          mediaType: 'diagram',
          fileUrl: 'https://assets.learntz.org/diagrams/plant_cell.png',
          fileSizeBytes: 245760,
          altText: 'Annotated plant cell components',
        ),
        const MediaAssetItem(
          id: 'a2',
          title: 'Human Circulatory System',
          countryCode: 'KE',
          mediaType: 'image',
          fileUrl: 'https://assets.learntz.org/diagrams/circulatory.png',
          fileSizeBytes: 512000,
          altText: 'Heart ventricles and arteries',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentMediaAssetsProvider.overrideWith((ref) async => mockAssets),
          ],
          child: const MaterialApp(
            home: ContentMediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Media & Diagram Asset Library'), findsOneWidget);
      expect(find.byKey(const Key('add-media-asset-btn')), findsOneWidget);

      // Assets rendered
      expect(find.text('Plant Cell Diagram'), findsOneWidget);
      expect(find.text('Human Circulatory System'), findsOneWidget);
      expect(find.text('DIAGRAM'), findsWidgets);
      expect(find.text('IMAGE'), findsWidgets);
      expect(find.text('Markdown Link'), findsNWidgets(2));

      // Open Add Media dialog
      await tester.tap(find.byKey(const Key('add-media-asset-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Add Media / Diagram Asset'), findsOneWidget);
      expect(find.byKey(const Key('media-title-input')), findsOneWidget);
      expect(find.byKey(const Key('media-url-input')), findsOneWidget);
      expect(find.byKey(const Key('media-submit-btn')), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Media / Diagram Asset'), findsNothing);
    });
  });
}
