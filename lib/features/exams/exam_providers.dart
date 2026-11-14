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
