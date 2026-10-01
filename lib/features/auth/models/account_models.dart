class ParentProfile {
  const ParentProfile({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;
}

class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.countryCode,
    required this.curriculum,
    this.curriculumCode = '',
    this.educationSystem = '',
    this.educationLevel = '',
    this.gradeCode = '',
  });

  final String id;
  final String fullName;
  final String grade;
  final String countryCode;
  final String curriculum;
  final String curriculumCode;
  final String educationSystem;
  final String educationLevel;
  final String gradeCode;
}
