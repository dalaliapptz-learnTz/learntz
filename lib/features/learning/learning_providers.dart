import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import '../learners/learner_providers.dart';
import 'learning_models.dart';
import 'learning_repository.dart';

final learningRepositoryProvider = Provider<LearningRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : LearningRepository(client);
});

final activeLearnerLearningCatalogProvider =
    FutureProvider.autoDispose<LearningCatalogBundle?>((ref) async {
      final learner = ref.watch(activeLearnerProvider);
      if (learner == null) return null;
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.loadCatalogForLearner(learner);
    });

final lessonDetailProvider =
    FutureProvider.autoDispose.family<LearningLesson, String>((
      ref,
      lessonId,
    ) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLesson(lessonId);
    });

final topicAssessmentQuestionsProvider = FutureProvider.autoDispose
    .family<List<QuestionBankItem>, String>((ref, topicId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getTopicAssessmentQuestions(topicId: topicId);
    });

final lessonQuizProvider =
    FutureProvider.autoDispose.family<PracticeQuiz?, String>((
      ref,
      lessonId,
    ) async {
      final learner = ref.watch(activeLearnerProvider);
      if (learner == null) return null;
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLessonQuiz(
        learnerId: learner.id,
        lessonId: lessonId,
      );
    });

final parentDashboardOverviewProvider =
    FutureProvider.autoDispose<List<ParentLearnerOverview>>((ref) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getParentDashboardOverview();
    });

final learnerDashboardDataProvider =
    FutureProvider.autoDispose.family<LearnerDashboardData, String>((
      ref,
      learnerId,
    ) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLearnerDashboardData(learnerId);
    });

final curriculumExplorerTreeProvider = FutureProvider.autoDispose.family<
  List<CurriculumExplorerSubject>,
  ({
    String countryCode,
    String educationSystemId,
    String? educationLevelId,
    String? gradeId,
  })
>((ref, args) async {
  final repository = ref.watch(learningRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getCurriculumExplorerTree(
    countryCode: args.countryCode,
    educationSystemId: args.educationSystemId,
    educationLevelId: args.educationLevelId,
    gradeId: args.gradeId,
  );
});

final learnerRecommendationsProvider = FutureProvider.autoDispose
    .family<List<LearnerRecommendation>, String>((ref, learnerId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLearnerRecommendations(learnerId);
    });

final learnerMasteryReportProvider = FutureProvider.autoDispose
    .family<LearnerMasteryReport, String>((ref, learnerId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLearnerMasteryReport(learnerId);
    });

final learnerRevisionOverviewProvider = FutureProvider.autoDispose
    .family<LearnerRevisionOverview, String>((ref, learnerId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getLearnerRevisionOverview(learnerId);
    });

final weakTopicDrillQuestionsProvider = FutureProvider.autoDispose
    .family<List<QuestionBankItem>, String>((ref, learnerId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getWeakTopicDrillQuestions(learnerId, limit: 10);
    });

final flashcardDecksProvider = FutureProvider.autoDispose.family<
  List<FlashcardDeck>,
  ({String? learnerId, String? subjectId})
>((ref, args) async {
  final repository = ref.watch(learningRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getFlashcardDecks(
    learnerId: args.learnerId,
    subjectId: args.subjectId,
  );
});

final deckFlashcardsProvider = FutureProvider.autoDispose
    .family<List<FlashcardItem>, String>((ref, deckId) async {
      final repository = ref.watch(learningRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.getDeckFlashcards(deckId);
    });

final learningResourcesProvider = FutureProvider.autoDispose.family<
  List<LearningResourceItem>,
  ({
    String countryCode,
    String? curriculumId,
    String? subjectId,
    String? resourceType,
  })
>((ref, args) async {
  final repository = ref.watch(learningRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getLearningResources(
    countryCode: args.countryCode,
    curriculumId: args.curriculumId,
    subjectId: args.subjectId,
    resourceType: args.resourceType,
  );
});

class OfflineSyncState {
  const OfflineSyncState({
    this.pendingEvents = const [],
    this.isSyncing = false,
    this.lastSyncedAt,
    this.lastSyncError,
  });

  final List<OfflineSyncEvent> pendingEvents;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? lastSyncError;

  int get pendingCount => pendingEvents.length;

  OfflineSyncState copyWith({
    List<OfflineSyncEvent>? pendingEvents,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? lastSyncError,
  }) {
    return OfflineSyncState(
      pendingEvents: pendingEvents ?? this.pendingEvents,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncError: lastSyncError,
    );
  }
}

class OfflineSyncNotifier extends Notifier<OfflineSyncState> {
  @override
  OfflineSyncState build() => const OfflineSyncState();

  void queueEvent(OfflineSyncEvent event) {
    state = state.copyWith(
      pendingEvents: [...state.pendingEvents, event],
    );
  }

  Future<OfflineSyncResult?> flushQueue(String learnerId) async {
    final repo = ref.read(learningRepositoryProvider);
    if (repo == null || state.pendingEvents.isEmpty || state.isSyncing) {
      return null;
    }

    state = state.copyWith(isSyncing: true, lastSyncError: null);

    try {
      final eventsToSend = List<OfflineSyncEvent>.from(state.pendingEvents);
      final result = await repo.syncOfflineActivity(
        learnerId: learnerId,
        events: eventsToSend,
      );

      state = state.copyWith(
        pendingEvents: const [],
        isSyncing: false,
        lastSyncedAt: result.syncedAt,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncError: e.toString(),
      );
      return null;
    }
  }
}

final offlineSyncNotifierProvider =
    NotifierProvider<OfflineSyncNotifier, OfflineSyncState>(
  OfflineSyncNotifier.new,
);
