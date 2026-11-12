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
