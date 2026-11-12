import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import 'curriculum_models.dart';
import 'curriculum_repository.dart';

final curriculumRepositoryProvider = Provider<CurriculumRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : CurriculumRepository(client);
});

final curriculumStaffCapabilitiesProvider =
    FutureProvider.autoDispose<CurriculumStaffCapabilities>((ref) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getStaffCapabilities();
    });

final curriculumPilotProvider =
    FutureProvider.autoDispose<CurriculumPilotSnapshot>((ref) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getPilotSnapshot();
    });

final curriculumImportPagesProvider = FutureProvider.autoDispose
    .family<List<CurriculumImportPage>, String>((ref, jobId) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getImportPages(jobId);
    });

final curriculumImportItemsProvider = FutureProvider.autoDispose
    .family<List<CurriculumImportItem>, String>((ref, jobId) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getImportItems(jobId);
    });

final curriculumValidationReportProvider = FutureProvider.autoDispose
    .family<CurriculumValidationReport?, String>((ref, jobId) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getValidationReport(jobId);
    });

final curriculumDuplicateMatchesProvider = FutureProvider.autoDispose
    .family<List<CurriculumDuplicateMatch>, String>((ref, jobId) async {
      final repository = ref.watch(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getDuplicateMatches(jobId);
    });
