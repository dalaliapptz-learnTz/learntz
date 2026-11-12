import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learners/learner_providers.dart';
import 'package:learntz/features/learning/learning_models.dart';
import 'package:learntz/features/learning/learning_providers.dart';
import 'package:learntz/features/learning/learning_repository.dart';
import 'package:learntz/features/learning/learning_screens.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

class _TestActiveLearnerNotifier extends ActiveLearnerNotifier {
  _TestActiveLearnerNotifier(this._initial);

  final Learner _initial;

  @override
  Learner? build() => _initial;
}

class _StubLearningRepository implements LearningRepository {
  _StubLearningRepository({
    required this.bundle,
    required this.lesson,
    required this.quiz,
    required this.submissionResult,
  });

  LearningCatalogBundle bundle;
  final LearningLesson lesson;
  final PracticeQuiz quiz;
  final QuizSubmissionResult submissionResult;
  int savedProgressPercent = 0;

  @override
  Future<LearningCatalogBundle> loadCatalogForLearner(Learner learner) async =>
      bundle;

  @override
  Future<LearningLesson> getLesson(String lessonId) async => lesson;

  @override
  Future<PracticeQuiz?> getLessonQuiz({
    required String learnerId,
    required String lessonId,
  }) async =>
      quiz;

  @override
  Future<QuizSubmissionResult> submitQuizAttempt({
    required String learnerId,
    required String quizId,
    required List<int> selectedIndices,
  }) async {
    bundle = LearningCatalogBundle(
      subjects: bundle.subjects,
      topicsBySubject: bundle.topicsBySubject,
      lessonsByTopic: bundle.lessonsByTopic,
      progressByLesson: {
        'lesson-1': const LearnerProgressRecord(
          id: 'prog-1',
          learnerId: 'learner-1',
          lessonId: 'lesson-1',
          status: 'completed',
          readingProgressPercent: 100,
          attemptsCount: 1,
          bestQuizScorePercent: 100,
        ),
      },
      summary: const LearnerLearningSummary(
        learnerId: 'learner-1',
        totalLessons: 1,
        completedLessons: 1,
        inProgressLessons: 0,
        averageQuizScorePercent: 100,
        masteryPercent: 100,
        hasActiveSubscription: true,
      ),
    );
    return submissionResult;
  }

  @override
  Future<LearnerProgressRecord> upsertLessonProgress({
    required String learnerId,
    required String lessonId,
    required int readingProgressPercent,
    bool markCompleted = false,
  }) async {
    savedProgressPercent = markCompleted ? 100 : readingProgressPercent;
    return LearnerProgressRecord(
      id: 'prog-1',
      learnerId: learnerId,
      lessonId: lessonId,
      status: markCompleted ? 'completed' : 'in_progress',
      readingProgressPercent: savedProgressPercent,
      attemptsCount: 1,
      bestQuizScorePercent: 100,
      completedAt: markCompleted ? DateTime.utc(2026, 11, 12) : null,
    );
  }

  @override
  Future<LearnerLearningSummary> getLearningSummary(String learnerId) async =>
      bundle.summary;
}

void main() {
  final activeLearner = Learner(
    id: 'learner-1',
    firstName: 'Amani',
    middleName: null,
    lastName: 'Mushi',
    dateOfBirth: DateTime(2016, 5, 1),
    gender: 'female',
    countryCode: 'TZ',
    educationSystemId: 'sys-1',
    curriculumId: 'curr-1',
    educationLevelId: 'lvl-1',
    gradeId: 'grade-1',
    schoolId: null,
    status: 'active',
    createdAt: DateTime.utc(2026, 11, 12),
    updatedAt: DateTime.utc(2026, 11, 12),
  );

  const subject = LearningSubject(
    id: 'subj-1',
    countryCode: 'TZ',
    curriculumId: 'curr-1',
    educationLevelId: 'lvl-1',
    code: 'tie-kiswahili',
    name: 'Kiswahili',
    description: 'Kusoma na kuandika',
    displayOrder: 1,
  );

  const topic = LearningTopic(
    id: 'topic-1',
    subjectId: 'subj-1',
    title: 'Irabu na Silabi',
    summary: 'Misingi',
    displayOrder: 1,
  );

  const lesson = LearningLesson(
    id: 'lesson-1',
    topicId: 'topic-1',
    title: 'Sauti za Irabu na Silabi Sahili',
    bodyMarkdown: '# Irabu\n\nKatika Kiswahili kuna irabu tano: a, e, i, o, u.',
    estimatedMinutes: 8,
    isFreePreview: true,
    displayOrder: 1,
  );

  const quiz = PracticeQuiz(
    id: 'quiz-1',
    lessonId: 'lesson-1',
    title: 'Jaribio: Irabu za Kiswahili',
    passScorePercent: 70,
    questions: [
      PracticeQuizQuestion(
        id: 'q1',
        prompt: 'Kuna irabu ngapi katika Kiswahili?',
        options: ['Tatu (3)', 'Tano (5)', 'Saba (7)'],
      ),
    ],
  );

  const submissionResult = QuizSubmissionResult(
    quizId: 'quiz-1',
    lessonId: 'lesson-1',
    scorePercent: 100,
    correctCount: 1,
    totalQuestions: 1,
    passed: true,
    passScorePercent: 70,
    bestQuizScorePercent: 100,
    lessonStatus: 'completed',
    attemptsCount: 1,
    results: [
      QuizQuestionResult(
        questionId: 'q1',
        selectedIndex: 1,
        correctIndex: 1,
        isCorrect: true,
        explanation: 'Irabu tano za Kiswahili ni a, e, i, o, u.',
      ),
    ],
  );

  Widget buildTestScope({
    required Widget child,
    required _StubLearningRepository stubRepo,
  }) {
    return ProviderScope(
      overrides: [
        learningRepositoryProvider.overrideWithValue(stubRepo),
        activeLearnerProvider.overrideWith(
          () => _TestActiveLearnerNotifier(activeLearner),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'LearningHubScreen renders active learner, mastery bar at 0%, and published curriculum lessons',
    (tester) async {
      final stubRepo = _StubLearningRepository(
        bundle: LearningCatalogBundle(
          subjects: const [subject],
          topicsBySubject: const {
            'subj-1': [topic],
          },
          lessonsByTopic: const {
            'topic-1': [lesson],
          },
          progressByLesson: const {},
          summary: const LearnerLearningSummary(
            learnerId: 'learner-1',
            totalLessons: 1,
            completedLessons: 0,
            inProgressLessons: 0,
            averageQuizScorePercent: 0,
            masteryPercent: 0,
            hasActiveSubscription: true,
          ),
        ),
        lesson: lesson,
        quiz: quiz,
        submissionResult: submissionResult,
      );

      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        buildTestScope(
          stubRepo: stubRepo,
          child: const LearningHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amani Mushi'), findsOneWidget);
      expect(find.text('Curriculum Mastery Progress'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Kiswahili'), findsOneWidget);
      expect(find.text('Sauti za Irabu na Silabi Sahili'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'LessonReaderScreen renders markdown content, saves reading progress, and completes lesson',
    (tester) async {
      final stubRepo = _StubLearningRepository(
        bundle: LearningCatalogBundle(
          subjects: const [subject],
          topicsBySubject: const {
            'subj-1': [topic],
          },
          lessonsByTopic: const {
            'topic-1': [lesson],
          },
          progressByLesson: const {},
          summary: const LearnerLearningSummary(
            learnerId: 'learner-1',
            totalLessons: 1,
            completedLessons: 0,
            inProgressLessons: 0,
            averageQuizScorePercent: 0,
            masteryPercent: 0,
            hasActiveSubscription: true,
          ),
        ),
        lesson: lesson,
        quiz: quiz,
        submissionResult: submissionResult,
      );

      await tester.pumpWidget(
        buildTestScope(
          stubRepo: stubRepo,
          child: const LessonReaderScreen(lessonId: 'lesson-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sauti za Irabu na Silabi Sahili'), findsOneWidget);
      expect(
        find.text('Katika Kiswahili kuna irabu tano: a, e, i, o, u.'),
        findsOneWidget,
      );
      expect(find.text('Save progress'), findsOneWidget);
      expect(find.text('Mark lesson completed'), findsOneWidget);

      await tester.tap(find.text('Mark lesson completed'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson marked as completed!'), findsOneWidget);
      expect(stubRepo.savedProgressPercent, 100);
    },
  );

  testWidgets(
    'PracticeQuizScreen displays question, radio selection, and submits for instant 100% grading',
    (tester) async {
      final stubRepo = _StubLearningRepository(
        bundle: LearningCatalogBundle(
          subjects: const [subject],
          topicsBySubject: const {
            'subj-1': [topic],
          },
          lessonsByTopic: const {
            'topic-1': [lesson],
          },
          progressByLesson: const {},
          summary: const LearnerLearningSummary(
            learnerId: 'learner-1',
            totalLessons: 1,
            completedLessons: 0,
            inProgressLessons: 0,
            averageQuizScorePercent: 0,
            masteryPercent: 0,
            hasActiveSubscription: true,
          ),
        ),
        lesson: lesson,
        quiz: quiz,
        submissionResult: submissionResult,
      );

      await tester.pumpWidget(
        buildTestScope(
          stubRepo: stubRepo,
          child: const PracticeQuizScreen(lessonId: 'lesson-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1. Kuna irabu ngapi katika Kiswahili?'), findsOneWidget);
      await tester.tap(find.text('Tano (5)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('submit-quiz-button')));
      await tester.pumpAndSettle();

      expect(find.text('Quiz Passed (100%)'), findsOneWidget);
      expect(
        find.text('Score: 1/1 correct • Best recorded score: 100%'),
        findsOneWidget,
      );
      expect(
        find.text('Irabu tano za Kiswahili ni a, e, i, o, u.'),
        findsOneWidget,
      );
    },
  );
}
