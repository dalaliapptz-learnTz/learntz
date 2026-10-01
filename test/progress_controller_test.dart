import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/progress/data/progress_repository.dart';
import 'package:learntz/features/progress/state/progress_controller.dart';

void main() {
  test('progress is scoped to a learner and can be completed', () async {
    final controller = ProgressController(LocalProgressRepository());

    await controller.updateProgress(
      learnerId: 'amina',
      lessonId: 'lesson-1',
      completionPercent: 50,
      lastBlockIndex: 2,
    );

    expect(controller.forLesson('amina', 'lesson-1')?.completionPercent, 50);
    expect(controller.forLesson('juma', 'lesson-1'), isNull);

    await controller.markCompleted(learnerId: 'amina', lessonId: 'lesson-1', blockCount: 4);

    final progress = controller.forLesson('amina', 'lesson-1');
    expect(progress?.isComplete, isTrue);
    expect(progress?.lastBlockIndex, 4);
  });

  test('local repository reloads saved progress for the same learner', () async {
    final repository = LocalProgressRepository();
    final controller = ProgressController(repository);

    await controller.markCompleted(learnerId: 'neema', lessonId: 'lesson-2', blockCount: 3);
    final reloaded = await repository.getForLearner('neema');

    expect(reloaded, hasLength(1));
    expect(reloaded.single.isComplete, isTrue);
  });
}
