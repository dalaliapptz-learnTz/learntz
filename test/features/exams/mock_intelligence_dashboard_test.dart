import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';
import 'package:learntz/features/exams/exam_providers.dart';
import 'package:learntz/features/exams/screens/mock_intelligence_dashboard_screen.dart';

void main() {
  group('Sub-Stage 5 Models Unit Tests', () {
    test('MockLeaderboardEntry and MockIntelligenceLeaderboard parse correctly', () {
      final json = {
        'rank': 1,
        'comparison_id': 'comp-101',
        'mock_paper_id': 'mock-201',
        'mock_title': 'Dar es Salaam Regional Mock 2024 - Basic Mathematics',
        'tier': 'regional',
        'region': 'Dar es Salaam Region',
        'region_id': 'dar-es-salaam',
        'district_id': null,
        'location_subtitle': 'Dar es Salaam Region',
        'real_paper_title': 'NECTA CSEE Basic Mathematics 2024',
        'year': 2024,
        'topic_overlap_ratio': 0.88,
        'difficulty_alignment_score': 0.95,
        'predictive_validity_index': 0.908,
      };

      final entry = MockLeaderboardEntry.fromJson(json);
      expect(entry.rank, 1);
      expect(entry.comparisonId, 'comp-101');
      expect(entry.mockPaperId, 'mock-201');
      expect(entry.mockTitle, contains('Dar es Salaam Regional Mock'));
      expect(entry.tier, 'regional');
      expect(entry.locationSubtitle, 'Dar es Salaam Region');
      expect(entry.realPaperTitle, contains('NECTA CSEE'));
      expect(entry.year, 2024);
      expect(entry.topicOverlapRatio, 0.88);
      expect(entry.difficultyAlignmentScore, 0.95);
      expect(entry.predictiveValidityIndex, 0.908);

      final board = MockIntelligenceLeaderboard.fromJson({
        'country_code': 'TZ',
        'year': 2024,
        'rankings': [json],
      });
      expect(board.countryCode, 'TZ');
      expect(board.year, 2024);
      expect(board.rankings.length, 1);
      expect(board.rankings.first.rank, 1);
    });

    test('TopicFrequencyItem and HistoricalTopicFrequencyData parse correctly', () {
      final json = {
        'topic_id': 'top-501',
        'topic_title': 'Coordinate Geometry & Straight Lines',
        'subject_id': 'subj-501',
        'recurrence_rate': 'High Recurrence',
        'question_count': 14,
        'total_marks': 48.0,
      };

      final item = TopicFrequencyItem.fromJson(json);
      expect(item.topicId, 'top-501');
      expect(item.topicTitle, 'Coordinate Geometry & Straight Lines');
      expect(item.recurrenceRate, 'High Recurrence');
      expect(item.questionCount, 14);
      expect(item.totalMarks, 48.0);

      final data = HistoricalTopicFrequencyData.fromJson({
        'country_code': 'TZ',
        'topic_frequency': [json],
      });
      expect(data.countryCode, 'TZ');
      expect(data.topicFrequency.length, 1);
      expect(data.topicFrequency.first.questionCount, 14);
    });
  });

  group('MockIntelligenceDashboardScreen Widget Tests', () {
    final sampleLeaderboard = MockIntelligenceLeaderboard(
      countryCode: 'TZ',
      year: 2024,
      rankings: const [
        MockLeaderboardEntry(
          rank: 1,
          comparisonId: 'comp-1',
          mockPaperId: 'mock-1',
          mockTitle: 'Dar es Salaam Regional Mock 2024 - Basic Mathematics',
          tier: 'regional',
          region: 'Dar es Salaam Region',
          district: null,
          realPaperTitle: 'NECTA CSEE Basic Mathematics 2024',
          year: 2024,
          topicOverlapRatio: 0.88,
          difficultyAlignmentScore: 0.95,
          predictiveValidityIndex: 0.91,
        ),
        MockLeaderboardEntry(
          rank: 2,
          comparisonId: 'comp-2',
          mockPaperId: 'mock-2',
          mockTitle: 'Arusha Inter-District Mock 2024 - Basic Mathematics',
          tier: 'district',
          region: 'Arusha Region',
          district: 'Arusha City District',
          realPaperTitle: 'NECTA CSEE Basic Mathematics 2024',
          year: 2024,
          topicOverlapRatio: 0.80,
          difficultyAlignmentScore: 0.85,
          predictiveValidityIndex: 0.82,
        ),
      ],
    );

    final sampleTopicFrequency = HistoricalTopicFrequencyData(
      countryCode: 'TZ',
      topicFrequency: const [
        TopicFrequencyItem(
          topicId: 'top-1',
          topicTitle: 'Algebraic Expressions & Factorization',
          subjectId: 'subj-1',
          recurrenceRate: 'High Recurrence',
          questionCount: 18,
          totalMarks: 64.0,
        ),
        TopicFrequencyItem(
          topicId: 'top-2',
          topicTitle: 'Probability & Statistics',
          subjectId: 'subj-1',
          recurrenceRate: 'Regular Recurrence',
          questionCount: 9,
          totalMarks: 32.0,
        ),
      ],
    );

    testWidgets('renders header, methodology, leaderboard, and topic frequencies',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockIntelligenceLeaderboardProvider((
              countryCode: 'TZ',
              year: 2024,
            )).overrideWith((ref) async => sampleLeaderboard),
            mockIntelligenceLeaderboardProvider((
              countryCode: 'TZ',
              year: null,
            )).overrideWith((ref) async => sampleLeaderboard),
            historicalTopicFrequencyProvider((
              subjectId: null,
              countryCode: 'TZ',
            )).overrideWith((ref) async => sampleTopicFrequency),
          ],
          child: const MaterialApp(
            home: MockIntelligenceDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('Mock-to-Real Examination Intelligence'), findsOneWidget);
      expect(
        find.textContaining('Empirical calibration measuring how closely regional & district mocks'),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Exam Centre'), findsOneWidget);
      expect(find.text('Question Bank'), findsOneWidget);

      // Methodology card
      expect(find.text('Predictive Validity Calibration Engine'), findsOneWidget);
      expect(
        find.textContaining('Jaccard topic set overlap with the real national examination (60% weight)'),
        findsOneWidget,
      );

      // Filter chips
      expect(find.text('All Years'), findsOneWidget);
      expect(find.text('2024 (Calibrated)'), findsOneWidget);

      // Section 1: Leaderboard
      expect(
        find.text('Regional & District Mock Predictive Leaderboard'),
        findsOneWidget,
      );
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(
        find.text('Dar es Salaam Regional Mock 2024 - Basic Mathematics'),
        findsOneWidget,
      );
      expect(
        find.text('Arusha Inter-District Mock 2024 - Basic Mathematics'),
        findsOneWidget,
      );
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('VALIDITY'), findsNWidgets(2));

      // Section 2: Historical Topic Frequency
      expect(
        find.text('Historical Recurring Topic Frequency & Weighting'),
        findsOneWidget,
      );
      expect(
        find.text('Algebraic Expressions & Factorization'),
        findsOneWidget,
      );
      expect(find.text('18 Questions in Bank'), findsOneWidget);
      expect(find.text('64 Total Marks'), findsOneWidget);
      expect(find.text('High Recurrence'), findsOneWidget);

      expect(find.text('Probability & Statistics'), findsOneWidget);
      expect(find.text('9 Questions in Bank'), findsOneWidget);
      expect(find.text('32 Total Marks'), findsOneWidget);
      expect(find.text('Regular Recurrence'), findsOneWidget);

      // Filter chip interaction
      await tester.tap(find.text('All Years'));
      await tester.pumpAndSettle();

      // Still renders after switching year filter chip
      expect(find.text('Mock-to-Real Examination Intelligence'), findsOneWidget);
    });
  });
}
