import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/state/app_providers.dart';
import 'learner_models.dart';
import 'learner_repository.dart';

final learnerRepositoryProvider = Provider<LearnerRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : LearnerRepository(client);
});

final educationCatalogRepositoryProvider =
    Provider<EducationCatalogRepository?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return client == null ? null : EducationCatalogRepository(client);
    });

final parentLearnersProvider = FutureProvider.autoDispose<List<Learner>>((
  ref,
) async {
  final repository = ref.watch(learnerRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.listLearners();
});

final learnerProvider = FutureProvider.autoDispose.family<Learner, String>((
  ref,
  learnerId,
) async {
  final repository = ref.watch(learnerRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getLearner(learnerId);
});

final educationCatalogProvider = FutureProvider.autoDispose<EducationCatalog>((
  ref,
) async {
  final repository = ref.watch(educationCatalogRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getCatalog();
});

final learnerStatusHistoryProvider = FutureProvider.autoDispose
    .family<List<LearnerStatusEvent>, String>((ref, learnerId) async {
      final repository = ref.watch(learnerRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getStatusHistory(learnerId);
    });

final learnerPromotionHistoryProvider = FutureProvider.autoDispose
    .family<List<LearnerPromotion>, String>((ref, learnerId) async {
      final repository = ref.watch(learnerRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getPromotionHistory(learnerId);
    });

final learnerChangeHistoryProvider = FutureProvider.autoDispose
    .family<List<LearnerChangeEvent>, String>((ref, learnerId) async {
      final repository = ref.watch(learnerRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getChangeHistory(learnerId);
    });

final sentGuardianInvitationsProvider = FutureProvider.autoDispose
    .family<List<GuardianInvitation>, String>((ref, learnerId) async {
      final repository = ref.watch(learnerRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listSentGuardianInvitations(learnerId);
    });

final incomingGuardianInvitationsProvider =
    FutureProvider.autoDispose<List<IncomingGuardianInvitation>>((ref) async {
      final repository = ref.watch(learnerRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listIncomingGuardianInvitations();
    });

final activeLearnerProvider = NotifierProvider<ActiveLearnerNotifier, Learner?>(
  ActiveLearnerNotifier.new,
);

class ActiveLearnerNotifier extends Notifier<Learner?> {
  int _selectionVersion = 0;
  String? _selectedByUserId;

  @override
  Learner? build() {
    ref.listen(authStateChangesProvider, (previous, next) {
      final session = next.asData?.value.session;
      if (session == null || session.user.id != _selectedByUserId) clear();
    });
    return null;
  }

  Future<void> select(String learnerId) async {
    final version = ++_selectionVersion;
    final previous = state;
    if (previous != null) _invalidateLearnerState(previous.id);
    state = null;
    final userId = ref.read(supabaseClientProvider)?.auth.currentUser?.id;
    if (userId == null) throw const NotSignedInException();
    final repository = ref.read(learnerRepositoryProvider);
    if (repository == null) throw const AuthNotConfiguredException();
    final learner = await repository.getLearner(learnerId);
    if (version == _selectionVersion &&
        ref.read(supabaseClientProvider)?.auth.currentUser?.id == userId) {
      _selectedByUserId = userId;
      state = learner;
    }
  }

  void clear() {
    _selectionVersion++;
    final previous = state;
    if (previous != null) _invalidateLearnerState(previous.id);
    _selectedByUserId = null;
    state = null;
  }

  void _invalidateLearnerState(String learnerId) {
    ref.invalidate(learnerProvider(learnerId));
    ref.invalidate(learnerStatusHistoryProvider(learnerId));
    ref.invalidate(learnerChangeHistoryProvider(learnerId));
    ref.invalidate(learnerPromotionHistoryProvider(learnerId));
  }
}
