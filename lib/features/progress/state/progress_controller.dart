import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/progress_repository.dart';
import '../models/learning_progress.dart';

class ProgressController extends ChangeNotifier {
  ProgressController(this._repository);

  final ProgressRepository _repository;
  final Map<String, LearningProgress> _progress = {};
  final Set<String> _loadedLearners = {};

  bool isLoaded(String learnerId) => _loadedLearners.contains(learnerId);

  LearningProgress? forLesson(String learnerId, String lessonId) => _progress[_key(learnerId, lessonId)];

  List<LearningProgress> forLearner(String learnerId) =>
      _progress.values.where((item) => item.learnerId == learnerId).toList();

  Future<void> load(String learnerId) async {
    if (isLoaded(learnerId)) return;
    final records = await _repository.getForLearner(learnerId);
    for (final record in records) {
      _progress[_key(record.learnerId, record.lessonId)] = record;
    }
    _loadedLearners.add(learnerId);
    notifyListeners();
  }

  Future<void> updateProgress({
    required String learnerId,
    required String lessonId,
    required int completionPercent,
    required int lastBlockIndex,
  }) async {
    final existing = forLesson(learnerId, lessonId);
    final progress = LearningProgress(
      learnerId: learnerId,
      lessonId: lessonId,
      completionPercent: completionPercent.clamp(0, 100),
      lastBlockIndex: lastBlockIndex,
      updatedAt: DateTime.now(),
      completedAt: completionPercent >= 100 ? DateTime.now() : existing?.completedAt,
    );
    _progress[_key(learnerId, lessonId)] = progress;
    _loadedLearners.add(learnerId);
    notifyListeners();
    await _repository.save(progress);
  }

  Future<void> markCompleted({required String learnerId, required String lessonId, required int blockCount}) {
    return updateProgress(
      learnerId: learnerId,
      lessonId: lessonId,
      completionPercent: 100,
      lastBlockIndex: blockCount,
    );
  }

  static String _key(String learnerId, String lessonId) => '$learnerId::$lessonId';
}

final progressControllerProvider = ChangeNotifierProvider<ProgressController>((ref) {
  return ProgressController(ref.watch(progressRepositoryProvider));
});
