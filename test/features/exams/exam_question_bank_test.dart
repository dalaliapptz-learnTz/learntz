import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/exams/exam_models.dart';
import 'package:learntz/features/exams/exam_providers.dart';
import 'package:learntz/features/exams/screens/exam_question_bank_screen.dart';
import 'package:learntz/features/exams/screens/exam_question_review_cockpit_screen.dart';

void main() {
  group('Exam Question Bank Models & Notifier Tests', () {
    test('ExamQuestionOption serializes and deserializes', () {
      final json = {
        'key': 'B',
        'text': 'Refraction of light',
        'is_correct': true,
      };

      final option = ExamQuestionOption.fromJson(json);
      expect(option.key, 'B');
      expect(option.text, 'Refraction of light');
      expect(option.isCorrect, isTrue);

      final out = option.toJson();
      expect(out['key'], 'B');
      expect(out['is_correct'], isTrue);
    });

    test('ExamRubricStep serializes and deserializes', () {
      final json = {
        'step': 1,
        'description': 'Formula state: P = IV',
        'marks_awarded': 1.5,
      };

      final step = ExamRubricStep.fromJson(json);
      expect(step.step, 1);
      expect(step.description, 'Formula state: P = IV');
      expect(step.marksAwarded, 1.5);

      final out = step.toJson();
      expect(out['step'], 1);
      expect(out['marks_awarded'], 1.5);
    });

    test('ExamExtractedQuestion parses and identifies correctly', () {
      final json = {
        'id': '50000000-0000-0000-0000-000000000001',
        'paper_id': '40000000-0000-0000-0000-000000000001',
        'paper_title': 'NECTA CSEE 2024 Physics Paper 1',
        'year': 2024,
        'tier': 'national',
        'authority_id': 'NECTA',
        'subject_name': 'Physics',
        'section_code': 'A',
        'question_number': 1,
        'sub_part': '(a)',
        'question_text': 'State Archimedes principle and give two practical applications.',
        'diagram_url': null,
        'question_type': 'structured',
        'options': [],
        'correct_answer': 'Archimedes principle states that...',
        'rubric_guide': [
          {'step': 1, 'description': 'Definition statement', 'marks_awarded': 2.0},
          {'step': 2, 'description': 'Hydrometer and ships applications', 'marks_awarded': 2.0}
        ],
        'marks': 4.0,
        'topic_id': '20000000-0000-0000-0000-000000000001',
        'topic_title': 'Archimedes Principle & Floatation',
        'bloom_level': 'knowledge',
        'difficulty': 'easy',
        'verification_status': 'approved',
        'created_at': '2026-11-13T10:00:00Z',
      };

      final q = ExamExtractedQuestion.fromJson(json);
      expect(q.id, '50000000-0000-0000-0000-000000000001');
      expect(q.fullIdentifier, 'Sec A Q1 (a)');
      expect(q.isApproved, isTrue);
      expect(q.marks, 4.0);
      expect(q.rubricGuide.length, 2);

      final out = q.toJson();
      expect(out['question_text'], contains('Archimedes'));
      expect((out['rubric_guide'] as List).length, 2);
    });

    test('ExamQuestionReviewResult parses decision and status', () {
      final json = {
        'question_id': '50000000-0000-0000-0000-000000000001',
        'verification_status': 'approved',
        'reviewer_id': '00000000-0000-0000-0000-000000000001',
        'decision': 'approved',
        'reviewed_at': '2026-11-13T12:00:00Z',
      };

      final res = ExamQuestionReviewResult.fromJson(json);
      expect(res.questionId, '50000000-0000-0000-0000-000000000001');
      expect(res.verificationStatus, 'approved');
      expect(res.decision, 'approved');
    });

    test('QuestionBankFilterNotifier updates filter states and resets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(questionBankFilterProvider.notifier);
      expect(container.read(questionBankFilterProvider).bloomLevel, isNull);

      notifier.setBloomLevel('application');
      expect(container.read(questionBankFilterProvider).bloomLevel, 'application');

      notifier.setDifficulty('hard');
      expect(container.read(questionBankFilterProvider).difficulty, 'hard');

      notifier.setSearch('kinetic');
      expect(container.read(questionBankFilterProvider).searchQuery, 'kinetic');

      notifier.reset();
      expect(container.read(questionBankFilterProvider).bloomLevel, isNull);
      expect(container.read(questionBankFilterProvider).difficulty, isNull);
      expect(container.read(questionBankFilterProvider).searchQuery, '');
    });
  });

  group('Exam Question Bank Widgets Tests', () {
    final sampleQuestions = [
      ExamExtractedQuestion(
        id: '50000000-0000-0000-0000-000000000001',
        paperId: '40000000-0000-0000-0000-000000000001',
        paperTitle: 'NECTA CSEE 2024 Physics Paper 1',
        year: 2024,
        tier: 'national',
        authorityId: 'NECTA',
        subjectName: 'Physics',
        sectionCode: 'A',
        questionNumber: 1,
        subPart: '(a)',
        questionText: 'State Archimedes Principle and outline two practical engineering applications.',
        questionType: 'structured',
        options: const [],
        correctAnswer: 'An object immersed in fluid experiences upthrust equal to the weight of fluid displaced.',
        rubricGuide: const [
          ExamRubricStep(step: 1, description: 'Correct wording of principle', marksAwarded: 2.0),
          ExamRubricStep(step: 2, description: 'Application 1: Submarines', marksAwarded: 1.0),
          ExamRubricStep(step: 3, description: 'Application 2: Hydrometers', marksAwarded: 1.0),
        ],
        marks: 4.0,
        topicId: '20000000-0000-0000-0000-000000000001',
        topicTitle: 'Archimedes Principle',
        bloomLevel: 'knowledge',
        difficulty: 'easy',
        verificationStatus: 'approved',
        createdAt: DateTime(2024, 11, 1),
      ),
      ExamExtractedQuestion(
        id: '50000000-0000-0000-0000-000000000002',
        paperId: '40000000-0000-0000-0000-000000000001',
        paperTitle: 'NECTA CSEE 2024 Physics Paper 1',
        year: 2024,
        tier: 'national',
        authorityId: 'NECTA',
        subjectName: 'Physics',
        sectionCode: 'A',
        questionNumber: 2,
        questionText: 'Which electromagnetic wave has the highest frequency?',
        questionType: 'multiple_choice',
        options: const [
          ExamQuestionOption(key: 'A', text: 'Radio waves', isCorrect: false),
          ExamQuestionOption(key: 'B', text: 'Infrared radiation', isCorrect: false),
          ExamQuestionOption(key: 'C', text: 'Gamma rays', isCorrect: true),
          ExamQuestionOption(key: 'D', text: 'Ultraviolet rays', isCorrect: false),
        ],
        correctAnswer: 'C',
        marks: 1.0,
        bloomLevel: 'comprehension',
        difficulty: 'easy',
        verificationStatus: 'approved',
        createdAt: DateTime(2024, 11, 1),
      ),
    ];

    testWidgets('renders ExamQuestionBankScreen with question cards and toggleable solution',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            approvedExamQuestionsProvider.overrideWith(
              (ref) async => sampleQuestions,
            ),
          ],
          child: const MaterialApp(
            home: ExamQuestionBankScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and subtitle
      expect(find.text('National Exam Question Bank'), findsOneWidget);
      expect(find.text('Exam Centre'), findsOneWidget);
      expect(find.text('Review Cockpit'), findsOneWidget);

      // Question 1 text and badges
      expect(find.text('Sec A Q1 (a)'), findsOneWidget);
      expect(find.textContaining('State Archimedes Principle'), findsOneWidget);
      expect(find.text('4 Marks'), findsOneWidget);

      // Question 2 MCQ options
      expect(find.text('Sec A Q2'), findsOneWidget);
      expect(find.textContaining('Which electromagnetic wave'), findsOneWidget);
      expect(find.text('Radio waves'), findsOneWidget);
      expect(find.text('Gamma rays'), findsOneWidget);

      // Tap "Show Solution & Rubric" on Question 1
      final showButtons = find.text('Show Solution & Rubric');
      expect(showButtons, findsNWidgets(2));
      await tester.tap(showButtons.first);
      await tester.pumpAndSettle();

      // Verify rubric breakdown is now visible
      expect(find.text('Marking Scheme & Rubric Guide'), findsOneWidget);
      expect(find.textContaining('Step 1 (2.0m):'), findsOneWidget);
      expect(find.textContaining('Correct wording of principle'), findsOneWidget);
      expect(find.text('Hide Solution'), findsOneWidget);
    });

    testWidgets('renders ExamQuestionReviewCockpitScreen with quality governance and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            approvedExamQuestionsProvider.overrideWith(
              (ref) async => sampleQuestions,
            ),
          ],
          child: const MaterialApp(
            home: ExamQuestionReviewCockpitScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Two-Party Question Review Cockpit'), findsOneWidget);
      expect(find.text('Quality & Pedagogy Standards'), findsOneWidget);
      expect(find.text('1. Verify Question'), findsNWidgets(2));
      expect(find.text('2. Approve & Publish'), findsNWidgets(2));
      expect(find.text('Request Changes'), findsNWidgets(2));
    });
  });
}
