import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../models/learning_progress.dart';

abstract interface class ProgressRepository {
  Future<List<LearningProgress>> getForLearner(String learnerId);

  Future<void> save(LearningProgress progress);
}

class LocalProgressRepository implements ProgressRepository {
  final Map<String, LearningProgress> _items = {};

  @override
  Future<List<LearningProgress>> getForLearner(String learnerId) async =>
      _items.values.where((item) => item.learnerId == learnerId).toList();

  @override
  Future<void> save(LearningProgress progress) async {
    _items[_key(progress.learnerId, progress.lessonId)] = progress;
  }

  static String _key(String learnerId, String lessonId) => '$learnerId::$lessonId';
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<LearningProgress>> getForLearner(String learnerId) async {
    final rows = await client.from('learning_progress').select().eq('learner_id', learnerId);
    return (rows as List<dynamic>).map((row) => _fromRow(row)).toList();
  }

  @override
  Future<void> save(LearningProgress progress) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('learning_progress').upsert({
      'owner_user_id': userId,
      'learner_id': progress.learnerId,
      'lesson_id': progress.lessonId,
      'completion_percent': progress.completionPercent,
      'last_block_index': progress.lastBlockIndex,
      'completed_at': progress.completedAt?.toIso8601String(),
      'updated_at': progress.updatedAt.toIso8601String(),
    });
  }

  LearningProgress _fromRow(Map<String, dynamic> row) => LearningProgress(
        learnerId: row['learner_id'] as String,
        lessonId: row['lesson_id'] as String,
        completionPercent: row['completion_percent'] as int,
        lastBlockIndex: row['last_block_index'] as int,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        completedAt: row['completed_at'] == null ? null : DateTime.parse(row['completed_at'] as String),
      );
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabaseConfiguration) {
    return SupabaseProgressRepository(Supabase.instance.client);
  }
  return LocalProgressRepository();
});
