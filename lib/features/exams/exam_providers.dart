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
