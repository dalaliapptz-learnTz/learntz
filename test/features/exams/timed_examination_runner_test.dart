import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';
import 'package:learntz/features/exams/exam_providers.dart';
import 'package:learntz/features/exams/screens/timed_examination_runner_screen.dart';

void main() {
  group('Sub-Stage 3 Models & Notifier Tests', () {
    test('ExaminationBlueprint parses config correctly', () {
      final json = {
        'id': 'b1000000-0000-0000-0000-000000000001',
        'national_examination_id': 'TZ-CSEE',
        'subject_id': '30000000-0000-0000-0000-000000000102',
        'title': 'NECTA CSEE Basic Mathematics Standard Blueprint',
        'total_marks': 100.0,
        'duration_minutes': 180,
        'structure_config': [
          {'code': 'A', 'question_count': 10, 'total_marks': 60},
          {'code': 'B', 'question_count': 4, 'total_marks': 40}
        ],
        'is_active': true,
      };

      final blueprint = ExaminationBlueprint.fromJson(json);
      expect(blueprint.id, 'b1000000-0000-0000-0000-000000000001');
      expect(blueprint.nationalExaminationId, 'TZ-CSEE');
      expect(blueprint.durationMinutes, 180);
      expect(blueprint.structureConfig.length, 2);

      final out = blueprint.toJson();
      expect(out['national_examination_id'], 'TZ-CSEE');
      expect(out['total_marks'], 100.0);
    });

    test('GeneratedMockExamination parses published mock data', () {
      final json = {
        'id': '60000000-0000-0000-0000-000000000001',
        'blueprint_id': 'b1000000-0000-0000-0000-000000000001',
        'title': 'NECTA CSEE National Simulation Mock 2026',
        'academic_year': 2026,
        'total_marks': 100.0,
        'duration_minutes': 180,
        'curated_by': null,
        'status': 'published',
        'created_at': '2026-11-13T10:00:00Z',
      };

      final mock = GeneratedMockExamination.fromJson(json);
      expect(mock.id, '60000000-0000-0000-0000-000000000001');
      expect(mock.status, 'published');
      expect(mock.academicYear, 2026);
    });

    test('LearnerExamAttemptData parses questions and responses', () {
      final json = {
        'attempt_id': '80000000-0000-0000-0000-000000000001',
        'mock_exam_id': '60000000-0000-0000-0000-000000000001',
        'title': 'NECTA CSEE Mock 2026',
        'status': 'in_progress',
        'started_at': '2026-11-13T10:00:00Z',
        'duration_minutes': 180,
        'expires_at': '2026-11-13T13:00:00Z',
        'seconds_remaining': 10800,
        'total_possible_marks': 100.0,
        'questions': [
          {
            'item_id': '70000000-0000-0000-0000-000000000001',
            'question_id': '50000000-0000-0000-0000-000000000001',
            'section_code': 'A',
            'order_index': 1,
            'marks': 6.0,
            'question_number': 1,
            'question_text': 'Solve for x: 2x + 5 = 15',
            'question_type': 'structured',
            'options': [],
            'topic_id': null,
            'bloom_level': 'application',
            'difficulty': 'easy',
          }
        ],
        'responses': {
          '50000000-0000-0000-0000-000000000001': {
            'learner_answer': 'x = 5',
            'is_flagged': true,
            'answered_at': '2026-11-13T10:05:00Z',
          }
        },
      };

      final attempt = LearnerExamAttemptData.fromJson(json);
      expect(attempt.attemptId, '80000000-0000-0000-0000-000000000001');
      expect(attempt.questions.length, 1);
      expect(attempt.questions.first.label, 'Sec A Q1');
      expect(attempt.responses['50000000-0000-0000-0000-000000000001']?.learnerAnswer, 'x = 5');
      expect(attempt.responses['50000000-0000-0000-0000-000000000001']?.isFlagged, isTrue);
    });

    test('ExamRunnerNotifier controls timer tick, question selection, and answer recording', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final attempt = LearnerExamAttemptData(
        attemptId: '80000000-0000-0000-0000-000000000001',
        mockExamId: '60000000-0000-0000-0000-000000000001',
        title: 'NECTA CSEE Mock',
        status: 'in_progress',
        startedAt: DateTime.now(),
        durationMinutes: 180,
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
        secondsRemaining: 120,
        totalPossibleMarks: 100.0,
        questions: const [
          MockRunnerQuestion(
            itemId: '70000000-0000-0000-0000-000000000001',
            questionId: 'q1',
            sectionCode: 'A',
            orderIndex: 1,
            marks: 6.0,
            questionNumber: 1,
            questionText: 'First question',
            questionType: 'multiple_choice',
            options: [
              ExamQuestionOption(key: 'A', text: 'Opt A'),
              ExamQuestionOption(key: 'B', text: 'Opt B'),
            ],
          ),
          MockRunnerQuestion(
            itemId: '70000000-0000-0000-0000-000000000002',
            questionId: 'q2',
            sectionCode: 'A',
            orderIndex: 2,
            marks: 6.0,
            questionNumber: 2,
            questionText: 'Second question',
            questionType: 'structured',
          ),
        ],
        responses: const {
          'q1': LearnerExamResponseState(
            questionId: 'q1',
            learnerAnswer: 'A',
            isFlagged: false,
          ),
        },
      );

      final notifier = container.read(examRunnerProvider.notifier);
      notifier.initAttempt(attempt);

      var state = container.read(examRunnerProvider);
      expect(state.secondsRemaining, 120);
      expect(state.answers['q1'], 'A');
      expect(state.currentQuestionIndex, 0);

      // Tick timer
      notifier.tick();
      state = container.read(examRunnerProvider);
      expect(state.secondsRemaining, 119);

      // Next question
      notifier.nextQuestion();
      state = container.read(examRunnerProvider);
      expect(state.currentQuestionIndex, 1);
      expect(state.currentQuestion?.questionId, 'q2');

      // Previous question
      notifier.previousQuestion();
      state = container.read(examRunnerProvider);
      expect(state.currentQuestionIndex, 0);

      // Set answer
      notifier.setAnswer('q1', 'B', null);
      state = container.read(examRunnerProvider);
      expect(state.answers['q1'], 'B');

      // Toggle flag
      notifier.toggleFlag('q1', null);
      state = container.read(examRunnerProvider);
      expect(state.flaggedQuestionIds.contains('q1'), isTrue);
    });
  });

  group('TimedExaminationRunnerScreen Widget Tests', () {
    final sampleAttempt = LearnerExamAttemptData(
      attemptId: '80000000-0000-0000-0000-000000000001',
      mockExamId: '60000000-0000-0000-0000-000000000001',
      title: 'NECTA CSEE Simulation 2026',
      status: 'in_progress',
      startedAt: DateTime.now(),
      durationMinutes: 180,
      expiresAt: DateTime.now().add(const Duration(hours: 3)),
      secondsRemaining: 7200,
      totalPossibleMarks: 100.0,
      questions: const [
        MockRunnerQuestion(
          itemId: '70000000-0000-0000-0000-000000000001',
          questionId: 'q1',
          sectionCode: 'A',
          orderIndex: 1,
          marks: 6.0,
          questionNumber: 1,
          questionText: 'What is the SI unit of electric current?',
          questionType: 'multiple_choice',
          options: [
            ExamQuestionOption(key: 'A', text: 'Volt'),
            ExamQuestionOption(key: 'B', text: 'Ampere'),
            ExamQuestionOption(key: 'C', text: 'Ohm'),
            ExamQuestionOption(key: 'D', text: 'Watt'),
          ],
        ),
        MockRunnerQuestion(
          itemId: '70000000-0000-0000-0000-000000000002',
          questionId: 'q2',
          sectionCode: 'A',
          orderIndex: 2,
          marks: 6.0,
          questionNumber: 2,
          questionText: 'Explain the working principle of a transformer.',
          questionType: 'structured',
        ),
      ],
      responses: const {},
    );

    testWidgets('renders countdown timer, question navigator, and navigates questions',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learnerExamAttemptProvider('80000000-0000-0000-0000-000000000001')
                .overrideWith((ref) async => sampleAttempt),
          ],
          child: const MaterialApp(
            home: TimedExaminationRunnerScreen(
              attemptId: '80000000-0000-0000-0000-000000000001',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // App bar title and timer
      expect(find.text('NECTA CSEE Simulation 2026'), findsOneWidget);
      expect(find.textContaining(':'), findsWidgets); // e.g. 02:00:00

      // Question 1 text & options
      expect(find.text('Sec A Q1'), findsOneWidget);
      expect(find.textContaining('What is the SI unit of electric current?'), findsOneWidget);
      expect(find.text('Ampere'), findsOneWidget);
      expect(find.text('Question Navigator'), findsOneWidget);

      // Tap Option B (Ampere)
      await tester.tap(find.text('Ampere'));
      await tester.pumpAndSettle();

      // Tap Next to go to Question 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Question 2 is rendered
      expect(find.text('Sec A Q2'), findsOneWidget);
      expect(find.textContaining('Explain the working principle of a transformer.'), findsOneWidget);
      expect(find.text('Your Working / Response:'), findsOneWidget);

      // Tap Question tile 1 in Question Navigator to jump back
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(find.text('Sec A Q1'), findsOneWidget);
    });
  });
}
