import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/design_system/components/components.dart';

void main() {
  group('LearnTZ Design System 2.0 Educational & Enterprise Components', () {
    testWidgets('AppLessonCard renders lesson metadata and status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLessonCard(
              title: 'Introduction to Integers',
              subject: 'Mathematics',
              durationMinutes: 15,
              orderIndex: 1,
              isCompleted: true,
              isFreePreview: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('• 15m'), findsOneWidget);
      expect(find.text('1. Introduction to Integers'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppConceptBlock renders definition and worked example', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppConceptBlock(
                  type: ConceptBlockType.definition,
                  term: 'Fraction',
                  pronunciation: 'frak-shun',
                  content: 'A numerical quantity that is not a whole number.',
                ),
                AppConceptBlock(
                  type: ConceptBlockType.example,
                  title: 'Addition of Fractions',
                  content: 'Solve 1/2 + 1/4.',
                  steps: ['Find common denominator (4)', 'Add numerators (2+1 = 3)'],
                  takeaway: 'Result is 3/4',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fraction'), findsOneWidget);
      expect(find.text('/frak-shun/'), findsOneWidget);
      expect(find.text('A numerical quantity that is not a whole number.'), findsOneWidget);
      expect(find.text('Addition of Fractions'), findsOneWidget);
      expect(find.text('Find common denominator (4)'), findsOneWidget);
      expect(find.text('Takeaway: Result is 3/4'), findsOneWidget);
    });

    testWidgets('AppDataTable renders rows and empty fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDataTable(
              columns: const [
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Role')),
              ],
              rows: const [
                DataRow(
                  cells: [
                    DataCell(Text('admin@learntz.com')),
                    DataCell(Text('Super Admin')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('admin@learntz.com'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
    });
  });
}
