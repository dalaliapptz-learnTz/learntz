import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';
import 'package:learntz/features/exams/exam_providers.dart';
import 'package:learntz/features/exams/screens/national_examination_centre_screen.dart';

void main() {
  group('NationalExaminationCentreScreen Widget Tests', () {
    final sampleCatalog = ExaminationCentreCatalog(
      authorities: const [
        ExaminationAuthority(
          id: 'NECTA',
          countryCode: 'TZ',
          name: 'National Examinations Council of Tanzania',
          description: '',
        ),
      ],
      examinations: const [
        NationalExamination(
          id: 'TZ-CSEE',
          authorityId: 'NECTA',
          countryCode: 'TZ',
          code: 'CSEE',
          title: 'Certificate of Secondary Education Examination',
          educationLevel: 'O-Level',
        ),
      ],
      recentPapers: [
        ExaminationPaper(
          id: '40000000-0000-0000-0000-000000000001',
          countryCode: 'TZ',
          authorityId: 'NECTA',
          subjectName: 'Basic Mathematics',
          paperTitle: 'NECTA CSEE 2024 Basic Mathematics Paper 1',
          year: 2024,
          paperType: 'official_national',
          tier: 'national',
          durationMinutes: 180,
          totalMarks: 100,
          createdAt: DateTime(2024, 11, 1),
        ),
      ],
      tierCounts: const {
        'national': 4,
        'regional': 2,
        'district': 1,
        'school': 0,
      },
    );

    testWidgets('renders header, stats, and examination paper cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            examinationCentreCatalogProvider('TZ').overrideWith(
              (ref) async => sampleCatalog,
            ),
            filteredExaminationPapersProvider.overrideWith(
              (ref) async => sampleCatalog.recentPapers,
            ),
          ],
          child: const MaterialApp(
            home: NationalExaminationCentreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header assertions
      expect(find.text('National Examination Centre'), findsOneWidget);
      expect(find.text('Upload Mock Exam'), findsOneWidget);

      // Metrics cards
      expect(find.text('Official National'), findsWidgets);
      expect(find.text('Regional Mocks'), findsWidgets);
      expect(find.text('District Mocks'), findsWidgets);

      // Paper card assertions
      expect(find.text('NECTA CSEE 2024 Basic Mathematics Paper 1'), findsOneWidget);
      expect(find.text('Basic Mathematics'), findsOneWidget);
      expect(find.text('180 min'), findsOneWidget);
      expect(find.text('100 Marks'), findsOneWidget);
      expect(find.text('View Exam'), findsOneWidget);
    });

    testWidgets('displays empty state when no papers match filter', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            examinationCentreCatalogProvider('TZ').overrideWith(
              (ref) async => sampleCatalog,
            ),
            filteredExaminationPapersProvider.overrideWith(
              (ref) async => [],
            ),
          ],
          child: const MaterialApp(
            home: NationalExaminationCentreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Examination Papers Found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });
  });
}
