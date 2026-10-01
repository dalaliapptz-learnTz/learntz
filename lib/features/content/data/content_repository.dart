import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../models/content_models.dart';

abstract interface class ContentRepository {
  Future<List<LearningResource>> getResources({String? countryCode});

  Future<LearningLesson?> getLesson(String lessonId);
}

class LocalContentRepository implements ContentRepository {
  const LocalContentRepository();

  @override
  Future<List<LearningResource>> getResources({String? countryCode}) async {
    final resources = _resources
        .where((resource) => countryCode == null || resource.countryCode == countryCode)
        .toList();
    return resources;
  }

  @override
  Future<LearningLesson?> getLesson(String lessonId) async {
    for (final resource in _resources) {
      for (final lesson in resource.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }

  static const _resources = <LearningResource>[
    LearningResource(
      id: 'tz-mathematics-fractions',
      countryCode: 'TZ',
      curriculumCode: 'TIE',
      gradeCode: 'STD_5',
      subjectCode: 'MATHEMATICS',
      subjectName: 'Mathematics',
      languageCode: 'en',
      title: 'Fractions',
      description: 'Build a clear understanding of parts, wholes, and equivalent fractions.',
      source: ContentSource.learnOriginal,
      lessons: [
        LearningLesson(
          id: 'tz-fractions-parts-wholes',
          title: 'Parts and wholes',
          summary: 'Recognise a fraction as equal parts of one whole.',
          durationMinutes: 8,
          blocks: [
            LessonBlock(
              type: LessonBlockType.explanation,
              heading: 'A fraction describes a part',
              body: 'When a whole is split into equal parts, a fraction tells us how many of those parts we have. The bottom number tells us the total equal parts, and the top number tells us the parts we are using.',
            ),
            LessonBlock(
              type: LessonBlockType.example,
              heading: 'Example: 3/4',
              body: 'Imagine a chapati divided into four equal pieces. If three pieces are on your plate, you have three-fourths, written as 3/4.',
            ),
            LessonBlock(
              type: LessonBlockType.reflection,
              heading: 'Think about it',
              body: 'What fraction of a group of five equal objects would represent two objects?',
            ),
          ],
        ),
        LearningLesson(
          id: 'tz-fractions-equivalent',
          title: 'Equivalent fractions',
          summary: 'See why different fraction names can describe the same amount.',
          durationMinutes: 10,
          blocks: [
            LessonBlock(
              type: LessonBlockType.explanation,
              heading: 'Same amount, different names',
              body: 'Equivalent fractions have different numbers but represent the same amount. Multiplying or dividing both the numerator and denominator by the same non-zero number keeps the value unchanged.',
            ),
            LessonBlock(
              type: LessonBlockType.example,
              heading: 'Example: 1/2 and 2/4',
              body: 'If one half is split into two equal pieces, the whole is now divided into four parts and two parts are shaded. So 1/2 and 2/4 are equivalent.',
            ),
          ],
        ),
      ],
    ),
    LearningResource(
      id: 'tz-study-skills-reading',
      countryCode: 'TZ',
      curriculumCode: 'TIE',
      gradeCode: 'STD_5',
      subjectCode: 'ENGLISH',
      subjectName: 'English',
      languageCode: 'en',
      title: 'Reading with purpose',
      description: 'Use questions and key words to make sense of a short text.',
      source: ContentSource.supplementary,
      lessons: [
        LearningLesson(
          id: 'tz-reading-key-ideas',
          title: 'Finding key ideas',
          summary: 'Identify the main idea and supporting details in a paragraph.',
          durationMinutes: 7,
          blocks: [
            LessonBlock(
              type: LessonBlockType.explanation,
              heading: 'Read for the main idea',
              body: 'The main idea is what a paragraph is mostly about. Supporting details give examples, reasons, or facts that help explain it.',
            ),
          ],
        ),
      ],
    ),
  ];
}

class SupabaseContentRepository implements ContentRepository {
  SupabaseContentRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<LearningResource>> getResources({String? countryCode}) async {
    final query = client.from('resources').select('''
      id,
      country_code,
      curriculum_code,
      grade_code,
      subject_code,
      subject_name,
      language_code,
      title,
      description,
      source,
        chapters(
          topics(
            lessons(id, title, summary, duration_minutes, lesson_blocks(type, heading, body))
          )
        )
    ''').eq('is_published', true);
    final rows = countryCode == null ? await query : await query.eq('country_code', countryCode);
    return (rows as List<dynamic>).map((row) => _resourceFromRow(row)).toList();
  }

  @override
  Future<LearningLesson?> getLesson(String lessonId) async {
    final rows = await client.from('lessons').select('''
      id,
      title,
      summary,
      duration_minutes,
      lesson_blocks(type, heading, body)
    ''').eq('id', lessonId).eq('is_published', true).limit(1);
    if (rows.isEmpty) return null;
    return _lessonFromRow(rows.first);
  }

  LearningResource _resourceFromRow(Map<String, dynamic> row) => LearningResource(
        id: row['id'] as String,
        countryCode: row['country_code'] as String,
        curriculumCode: row['curriculum_code'] as String,
        gradeCode: row['grade_code'] as String,
        subjectCode: row['subject_code'] as String,
        subjectName: row['subject_name'] as String,
        languageCode: row['language_code'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        source: _sourceFromString(row['source'] as String),
        lessons: _list(row['chapters']).expand((chapter) => 
          _list(chapter['topics']).expand((topic) => 
            _list(topic['lessons']).map(_lessonFromRow)
          )
        ).toList(),
      );

  LearningLesson _lessonFromRow(Map<String, dynamic> row) => LearningLesson(
        id: row['id'] as String,
        title: row['title'] as String,
        summary: row['summary'] as String,
        durationMinutes: row['duration_minutes'] as int,
        blocks: _list(row['lesson_blocks']).map(_blockFromRow).toList(),
      );

  LessonBlock _blockFromRow(Map<String, dynamic> row) => LessonBlock(
        type: _blockTypeFromString(row['type'] as String),
        heading: row['heading'] as String,
        body: row['body'] as String,
      );

  ContentSource _sourceFromString(String value) => ContentSource.values.firstWhere(
        (source) => source.name == value,
        orElse: () => ContentSource.supplementary,
      );

  LessonBlockType _blockTypeFromString(String value) => LessonBlockType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => LessonBlockType.explanation,
      );

  List<Map<String, dynamic>> _list(dynamic value) => (value as List<dynamic>? ?? const [])
      .map((item) => item as Map<String, dynamic>)
      .toList();
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabaseConfiguration) {
    return SupabaseContentRepository(Supabase.instance.client);
  }
  return const LocalContentRepository();
});
