enum ContentSource {
  officialLicensed,
  learnOriginal,
  teacherCreated,
  thirdPartyLicensed,
  supplementary,
}

class LearningResource {
  const LearningResource({
    required this.id,
    required this.countryCode,
    required this.curriculumCode,
    required this.gradeCode,
    required this.subjectCode,
    required this.subjectName,
    required this.languageCode,
    required this.title,
    required this.description,
    required this.source,
    required this.lessons,
  });

  final String id;
  final String countryCode;
  final String curriculumCode;
  final String gradeCode;
  final String subjectCode;
  final String subjectName;
  final String languageCode;
  final String title;
  final String description;
  final ContentSource source;
  final List<LearningLesson> lessons;
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.durationMinutes,
    required this.blocks,
  });

  final String id;
  final String title;
  final String summary;
  final int durationMinutes;
  final List<LessonBlock> blocks;
}

class LessonBlock {
  const LessonBlock({
    required this.type,
    required this.heading,
    required this.body,
  });

  final LessonBlockType type;
  final String heading;
  final String body;
}

enum LessonBlockType { explanation, example, reflection }
