import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';
import 'package:learntz/features/exams/exam_providers.dart';
import 'package:learntz/features/exams/screens/exam_results_analytics_screen.dart';

void main() {
  group('Sub-Stage 4 Models Tests', () {
    test('ExamSectionPerformance and ExamTopicDeficit parse correctly', () {
      final secJson = {
        'section_code': 'A',
        'score': 48.0,
        'possible': 60.0,
        'percentage': 80.0,
      };
      final sec = ExamSectionPerformance.fromJson(secJson);
      expect(sec.sectionCode, 'A');
      expect(sec.score, 48.0);
      expect(sec.percentage, 80.0);

      final topJson = {
        'topic_id': '20000000-0000-0000-0000-000000000001',
        'title': 'Linear Equations & Coordinate Geometry',
        'score': 2.0,
        'possible': 10.0,
        'accuracy_pct': 20.0,
      };
      final deficit = ExamTopicDeficit.fromJson(topJson);
      expect(deficit.title, contains('Linear Equations'));
      expect(deficit.accuracyPct, 20.0);
    });

    test('LearnerExamResultData parses complete graded payload', () {
      final json = {
        'result_id': '90000000-0000-0000-0000-000000000001',
        'attempt_id': '80000000-0000-0000-0000-000000000001',
        'learner_id': '10000000-0000-0000-0000-000000000001',
        'title': 'NECTA CSEE Simulation Mock 2026',
        'total_score': 82.5,
        'total_possible_marks': 100.0,
        'percentage': 82.5,
        'predicted_division_or_grade': 'Division I',
        'grading_system': 'division',
        'section_breakdown': [
          {'section_code': 'A', 'score': 50.0, 'possible': 60.0, 'percentage': 83.3},
          {'section_code': 'B', 'score': 32.5, 'possible': 40.0, 'percentage': 81.3}
        ],
        'topic_deficits': [
          {
            'topic_id': 'top-1',
            'title': 'Probability & Statistics',
            'score': 2.0,
            'possible': 10.0,
            'accuracy_pct': 20.0,
          }
        ],
        'remedial_lessons': [
          {
            'lesson_id': 'les-1',
            'title': 'Mastering Probability Distributions',
            'topic_id': 'top-1',
            'estimated_minutes': 15,
          }
        ],
        'remedial_flashcards': [
          {
            'deck_id': 'deck-1',
            'title': 'Form 4 Math Formula Decks',
            'topic_id': 'top-1',
            'card_count': 24,
          }
        ],
        'created_at': '2026-11-13T12:00:00Z',
        'questions_review': [
          {
            'question_id': 'q1',
            'section_code': 'A',
            'order_index': 1,
            'question_number': 1,
            'sub_part': '(a)',
            'question_text': 'Solve quadratic equation x^2 - 5x + 6 = 0',
            'question_type': 'structured',
            'options': [],
            'correct_answer': 'x = 2 or x = 3',
            'rubric_guide': [
              {'step': 1, 'description': 'Factorization (x - 2)(x - 3) = 0', 'marks_awarded': 2.0},
              {'step': 2, 'description': 'Roots x = 2, 3', 'marks_awarded': 2.0}
            ],
            'marks': 4.0,
            'learner_answer': 'x = 2, x = 3',
            'marks_awarded': 4.0,
            'is_flagged': false,
          }
        ],
      };

      final data = LearnerExamResultData.fromJson(json);
      expect(data.resultId, '90000000-0000-0000-0000-000000000001');
      expect(data.percentage, 82.5);
      expect(data.predictedDivisionOrGrade, 'Division I');
      expect(data.sectionBreakdown.length, 2);
      expect(data.topicDeficits.length, 1);
      expect(data.remedialLessons.length, 1);
      expect(data.remedialFlashcards.length, 1);
      expect(data.questionsReview.length, 1);
      expect(data.questionsReview.first.isFullMarks, isTrue);
    });
  });

  group('ExamResultsAnalyticsScreen Widget Tests', () {
    final sampleResult = LearnerExamResultData(
      resultId: '90000000-0000-0000-0000-000000000001',
      attemptId: '80000000-0000-0000-0000-000000000001',
      learnerId: '10000000-0000-0000-0000-000000000001',
      title: 'NECTA CSEE Simulation Mock 2026',
      totalScore: 78.5,
      totalPossibleMarks: 100.0,
      percentage: 78.5,
      predictedDivisionOrGrade: 'Division I',
      gradingSystem: 'division',
      sectionBreakdown: const [
        ExamSectionPerformance(
          sectionCode: 'A',
          score: 48.5,
          possible: 60.0,
          percentage: 80.8,
        ),
        ExamSectionPerformance(
          sectionCode: 'B',
          score: 30.0,
          possible: 40.0,
          percentage: 75.0,
        ),
      ],
      topicDeficits: const [
        ExamTopicDeficit(
          topicId: 'top-1',
          title: 'Trigonometry & Bearings',
          score: 3.0,
          possible: 10.0,
          accuracyPct: 30.0,
        ),
      ],
      remedialLessons: const [
        RemedialLessonItem(
          lessonId: 'les-101',
          title: 'Sine & Cosine Rules Step-by-Step',
          topicId: 'top-1',
          estimatedMinutes: 12,
        ),
      ],
      remedialFlashcards: const [
        RemedialFlashcardItem(
          deckId: 'deck-101',
          title: 'Trigonometric Identities & Values',
          topicId: 'top-1',
          cardCount: 16,
        ),
      ],
      createdAt: DateTime.now(),
      questionsReview: const [
        ExamQuestionReviewItem(
          questionId: 'q1',
          sectionCode: 'A',
          orderIndex: 1,
          questionNumber: 1,
          questionText: 'Find the hypotenuse of right triangle with sides 6cm and 8cm',
          questionType: 'calculation',
          marks: 4.0,
          learnerAnswer: '10 cm',
          correctAnswer: '10 cm (by Pythagoras theorem)',
          marksAwarded: 4.0,
          isFlagged: false,
        ),
      ],
    );

    testWidgets('renders score, predicted division, section breakdown, remedial plan, and question review',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            examResultsProvider('80000000-0000-0000-0000-000000000001').overrideWith(
              (ref) async => sampleResult,
            ),
          ],
          child: const MaterialApp(
            home: ExamResultsAnalyticsScreen(
              attemptId: '80000000-0000-0000-0000-000000000001',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and subtitle
      expect(find.text('Examination Intelligence & Performance'), findsOneWidget);
      expect(find.text('NECTA CSEE Simulation Mock 2026'), findsOneWidget);

      // Score and Predicted Division
      expect(find.text('78.5%'), findsOneWidget);
      expect(find.text('PREDICTED OUTCOME'), findsOneWidget);
      expect(find.text('Division I'), findsOneWidget);

      // Section breakdown
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);

      // Topic deficits chip
      expect(find.textContaining('Trigonometry & Bearings'), findsOneWidget);

      // Remedial Study Plan links
      expect(find.text('Personalised Remedial Study Plan'), findsOneWidget);
      expect(find.text('Sine & Cosine Rules Step-by-Step'), findsOneWidget);
      expect(find.text('Study Lesson'), findsOneWidget);
      expect(find.text('Trigonometric Identities & Values'), findsOneWidget);
      expect(find.text('Revise Deck'), findsOneWidget);

      // Tap "Show Detailed Review"
      final toggleButton = find.text('Show Detailed Review');
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Detailed question review is now expanded
      expect(find.text('Hide Detailed Review'), findsOneWidget);
      expect(find.textContaining('Find the hypotenuse'), findsOneWidget);
      expect(find.text('Your Answer: 10 cm'), findsOneWidget);
      expect(find.text('Official Solution: 10 cm (by Pythagoras theorem)'), findsOneWidget);
    });
  });
}
