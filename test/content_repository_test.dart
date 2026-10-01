import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/content/data/content_repository.dart';

void main() {
  const repository = LocalContentRepository();

  test('returns only content for the requested country', () async {
    final resources = await repository.getResources(countryCode: 'TZ');

    expect(resources, hasLength(2));
    expect(resources.every((resource) => resource.countryCode == 'TZ'), isTrue);
    expect(resources.first.source.name, 'learnOriginal');
  });

  test('loads a lesson with ordered content blocks', () async {
    final lesson = await repository.getLesson('tz-fractions-parts-wholes');

    expect(lesson, isNotNull);
    expect(lesson!.blocks, hasLength(3));
    expect(lesson.blocks.first.heading, 'A fraction describes a part');
  });
}
