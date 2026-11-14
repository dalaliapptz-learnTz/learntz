import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import 'exam_models.dart';
import 'exam_repository.dart';

final examRepositoryProvider = Provider<ExamRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return ExamRepository(client);
});

@immutable
class ExamFilterState {
  const ExamFilterState({
    this.tier,
    this.authorityId,
    this.year,
    this.searchQuery = '',
  });

  final String? tier;
  final String? authorityId;
  final int? year;
  final String searchQuery;

  ExamFilterState copyWith({
    String? Function()? tier,
    String? Function()? authorityId,
    int? Function()? year,
    String? searchQuery,
  }) {
    return ExamFilterState(
      tier: tier != null ? tier() : this.tier,
      authorityId: authorityId != null ? authorityId() : this.authorityId,
      year: year != null ? year() : this.year,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ExamFilterNotifier extends Notifier<ExamFilterState> {
  @override
  ExamFilterState build() => const ExamFilterState();

  void setTier(String? tier) => state = state.copyWith(tier: () => tier);
  void setAuthority(String? authorityId) =>
      state = state.copyWith(authorityId: () => authorityId);
  void setYear(int? year) => state = state.copyWith(year: () => year);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void reset() => state = const ExamFilterState();
}

final examFilterProvider =
    NotifierProvider<ExamFilterNotifier, ExamFilterState>(
  ExamFilterNotifier.new,
);

final examinationCentreCatalogProvider =
    FutureProvider.family<ExaminationCentreCatalog?, String?>(
        (ref, countryCode) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return null;
  return repository.getCatalog(countryCode: countryCode);
});

final filteredExaminationPapersProvider =
    FutureProvider<List<ExaminationPaper>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return [];

  final country = ref.watch(selectedCountryProvider);
  final filter = ref.watch(examFilterProvider);

  return repository.listPapers(
    countryCode: country.countryCode,
    tier: filter.tier,
    authorityId: filter.authorityId,
    year: filter.year,
    search: filter.searchQuery.isEmpty ? null : filter.searchQuery,
  );
});

final examinationPaperDetailsProvider =
    FutureProvider.family<ExaminationPaper?, String>((ref, paperId) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return null;
  return repository.getPaperDetails(paperId);
});

@immutable
class QuestionBankFilterState {
  const QuestionBankFilterState({
    this.paperId,
    this.subjectId,
    this.topicId,
    this.bloomLevel,
    this.difficulty,
    this.searchQuery = '',
  });

  final String? paperId;
  final String? subjectId;
  final String? topicId;
  final String? bloomLevel;
  final String? difficulty;
  final String searchQuery;

  QuestionBankFilterState copyWith({
    String? Function()? paperId,
    String? Function()? subjectId,
    String? Function()? topicId,
    String? Function()? bloomLevel,
    String? Function()? difficulty,
    String? searchQuery,
  }) {
    return QuestionBankFilterState(
      paperId: paperId != null ? paperId() : this.paperId,
      subjectId: subjectId != null ? subjectId() : this.subjectId,
      topicId: topicId != null ? topicId() : this.topicId,
      bloomLevel: bloomLevel != null ? bloomLevel() : this.bloomLevel,
      difficulty: difficulty != null ? difficulty() : this.difficulty,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class QuestionBankFilterNotifier extends Notifier<QuestionBankFilterState> {
  @override
  QuestionBankFilterState build() => const QuestionBankFilterState();

  void setPaperId(String? paperId) =>
      state = state.copyWith(paperId: () => paperId);
  void setSubjectId(String? subjectId) =>
      state = state.copyWith(subjectId: () => subjectId);
  void setTopicId(String? topicId) =>
      state = state.copyWith(topicId: () => topicId);
  void setBloomLevel(String? bloomLevel) =>
      state = state.copyWith(bloomLevel: () => bloomLevel);
  void setDifficulty(String? difficulty) =>
      state = state.copyWith(difficulty: () => difficulty);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void reset() => state = const QuestionBankFilterState();
}

final questionBankFilterProvider =
    NotifierProvider<QuestionBankFilterNotifier, QuestionBankFilterState>(
  QuestionBankFilterNotifier.new,
);

final approvedExamQuestionsProvider =
    FutureProvider<List<ExamExtractedQuestion>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return [];

  final filter = ref.watch(questionBankFilterProvider);

  return repository.getApprovedQuestions(
    paperId: filter.paperId,
    subjectId: filter.subjectId,
    topicId: filter.topicId,
    bloomLevel: filter.bloomLevel,
    difficulty: filter.difficulty,
    search: filter.searchQuery.isEmpty ? null : filter.searchQuery,
  );
});

final learnerExamAttemptProvider =
    FutureProvider.family<LearnerExamAttemptData?, String>((ref, attemptId) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return null;
  return repository.getExamAttempt(attemptId);
});

final publishedMocksProvider =
    FutureProvider<List<GeneratedMockExamination>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return [];
  return repository.listPublishedMocks();
});

@immutable
class ExamRunnerState {
  const ExamRunnerState({
    this.attemptData,
    this.currentQuestionIndex = 0,
    this.secondsRemaining = 0,
    this.answers = const {},
    this.flaggedQuestionIds = const {},
    this.isSubmitting = false,
    this.isExpired = false,
  });

  final LearnerExamAttemptData? attemptData;
  final int currentQuestionIndex;
  final int secondsRemaining;
  final Map<String, String> answers;
  final Set<String> flaggedQuestionIds;
  final bool isSubmitting;
  final bool isExpired;

  bool get isCriticalTime => secondsRemaining < 300 && secondsRemaining > 0;
  bool get isUrgentTime => secondsRemaining < 60 && secondsRemaining > 0;

  MockRunnerQuestion? get currentQuestion {
    if (attemptData == null || attemptData!.questions.isEmpty) return null;
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= attemptData!.questions.length) {
      return null;
    }
    return attemptData!.questions[currentQuestionIndex];
  }

  ExamRunnerState copyWith({
    LearnerExamAttemptData? attemptData,
    int? currentQuestionIndex,
    int? secondsRemaining,
    Map<String, String>? answers,
    Set<String>? flaggedQuestionIds,
    bool? isSubmitting,
    bool? isExpired,
  }) {
    return ExamRunnerState(
      attemptData: attemptData ?? this.attemptData,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      answers: answers ?? this.answers,
      flaggedQuestionIds: flaggedQuestionIds ?? this.flaggedQuestionIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class ExamRunnerNotifier extends Notifier<ExamRunnerState> {
  @override
  ExamRunnerState build() => const ExamRunnerState();

  void initAttempt(LearnerExamAttemptData attempt) {
    final existingAnswers = <String, String>{};
    final existingFlags = <String>{};

    for (final entry in attempt.responses.entries) {
      if (entry.value.learnerAnswer != null &&
          entry.value.learnerAnswer!.isNotEmpty) {
        existingAnswers[entry.key] = entry.value.learnerAnswer!;
      }
      if (entry.value.isFlagged) {
        existingFlags.add(entry.key);
      }
    }

    state = ExamRunnerState(
      attemptData: attempt,
      currentQuestionIndex: 0,
      secondsRemaining: attempt.secondsRemaining,
      answers: existingAnswers,
      flaggedQuestionIds: existingFlags,
      isExpired: attempt.isExpired,
    );
  }

  void tick() {
    if (state.secondsRemaining <= 1) {
      state = state.copyWith(
        secondsRemaining: 0,
        isExpired: true,
      );
    } else {
      state = state.copyWith(
        secondsRemaining: state.secondsRemaining - 1,
      );
    }
  }

  void selectQuestion(int index) {
    if (state.attemptData == null) return;
    if (index >= 0 && index < state.attemptData!.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  void nextQuestion() {
    selectQuestion(state.currentQuestionIndex + 1);
  }

  void previousQuestion() {
    selectQuestion(state.currentQuestionIndex - 1);
  }

  Future<void> setAnswer(
    String questionId,
    String answer,
    ExamRepository? repository,
  ) async {
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[questionId] = answer;
    state = state.copyWith(answers: updatedAnswers);

    if (repository != null && state.attemptData != null) {
      final isFlagged = state.flaggedQuestionIds.contains(questionId);
      await repository.recordResponse(
        attemptId: state.attemptData!.attemptId,
        questionId: questionId,
        learnerAnswer: answer,
        isFlagged: isFlagged,
      );
    }
  }

  Future<void> toggleFlag(
    String questionId,
    ExamRepository? repository,
  ) async {
    final updatedFlags = Set<String>.from(state.flaggedQuestionIds);
    final willFlag = !updatedFlags.contains(questionId);
    if (willFlag) {
      updatedFlags.add(questionId);
    } else {
      updatedFlags.remove(questionId);
    }
    state = state.copyWith(flaggedQuestionIds: updatedFlags);

    if (repository != null && state.attemptData != null) {
      final currentAns = state.answers[questionId];
      await repository.recordResponse(
        attemptId: state.attemptData!.attemptId,
        questionId: questionId,
        learnerAnswer: currentAns,
        isFlagged: willFlag,
      );
    }
  }
}

final examRunnerProvider =
    NotifierProvider<ExamRunnerNotifier, ExamRunnerState>(
  ExamRunnerNotifier.new,
);

final examResultsProvider =
    FutureProvider.family<LearnerExamResultData?, String>((ref, attemptId) async {
  final repository = ref.watch(examRepositoryProvider);
  if (repository == null) return null;
  return repository.getExamResults(attemptId);
});
