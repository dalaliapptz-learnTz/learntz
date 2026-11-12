class EducationCountry {
  const EducationCountry({required this.code, required this.name});

  factory EducationCountry.fromJson(Map<String, dynamic> json) {
    return EducationCountry(
      code: json['country_code'] as String,
      name: json['display_name'] as String,
    );
  }

  final String code;
  final String name;
}

class EducationSystem {
  const EducationSystem({
    required this.id,
    required this.countryCode,
    required this.name,
    this.isEnabled = true,
  });

  factory EducationSystem.fromJson(Map<String, dynamic> json) {
    return EducationSystem(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      name: json['name'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String countryCode;
  final String name;
  final bool isEnabled;
}

class Curriculum {
  const Curriculum({
    required this.id,
    required this.countryCode,
    required this.educationSystemId,
    required this.name,
    required this.code,
    this.isEnabled = true,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    return Curriculum(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      educationSystemId: json['education_system_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String countryCode;
  final String educationSystemId;
  final String name;
  final String code;
  final bool isEnabled;
}

class EducationLevel {
  const EducationLevel({
    required this.id,
    required this.curriculumId,
    required this.name,
    required this.code,
    required this.sequence,
    this.isEnabled = true,
  });

  factory EducationLevel.fromJson(Map<String, dynamic> json) {
    return EducationLevel(
      id: json['id'] as String,
      curriculumId: json['curriculum_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      sequence: (json['sequence'] as num).toInt(),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String curriculumId;
  final String name;
  final String code;
  final int sequence;
  final bool isEnabled;
}

class EducationGrade {
  const EducationGrade({
    required this.id,
    required this.educationLevelId,
    required this.curriculumId,
    required this.name,
    required this.code,
    required this.sequence,
    this.isEnabled = true,
  });

  factory EducationGrade.fromJson(Map<String, dynamic> json) {
    return EducationGrade(
      id: json['id'] as String,
      educationLevelId: json['education_level_id'] as String,
      curriculumId: json['curriculum_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      sequence: (json['sequence'] as num).toInt(),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String educationLevelId;
  final String curriculumId;
  final String name;
  final String code;
  final int sequence;
  final bool isEnabled;
}

class School {
  const School({
    required this.id,
    required this.countryCode,
    required this.educationSystemId,
    required this.name,
    this.isEnabled = true,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      educationSystemId: json['education_system_id'] as String,
      name: json['name'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String countryCode;
  final String educationSystemId;
  final String name;
  final bool isEnabled;
}

class EducationCatalog {
  const EducationCatalog({
    required this.countries,
    required this.systems,
    required this.curricula,
    required this.levels,
    required this.grades,
    required this.schools,
  });

  final List<EducationCountry> countries;
  final List<EducationSystem> systems;
  final List<Curriculum> curricula;
  final List<EducationLevel> levels;
  final List<EducationGrade> grades;
  final List<School> schools;

  EducationCountry? country(String? code) {
    for (final country in countries) {
      if (country.code == code) return country;
    }
    return null;
  }

  EducationSystem? system(String? id) {
    for (final system in systems) {
      if (system.id == id) return system;
    }
    return null;
  }

  Curriculum? curriculum(String? id) {
    for (final curriculum in curricula) {
      if (curriculum.id == id) return curriculum;
    }
    return null;
  }

  EducationLevel? level(String? id) {
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  EducationGrade? grade(String? id) {
    for (final grade in grades) {
      if (grade.id == id) return grade;
    }
    return null;
  }

  School? school(String? id) {
    for (final school in schools) {
      if (school.id == id) return school;
    }
    return null;
  }

  List<EducationSystem> systemsForCountry(String? countryCode) => systems
      .where((system) => system.countryCode == countryCode && system.isEnabled)
      .toList(growable: false);

  List<Curriculum> curriculaForSystem(String? systemId) => curricula
      .where(
        (curriculum) =>
            curriculum.educationSystemId == systemId && curriculum.isEnabled,
      )
      .toList(growable: false);

  List<EducationLevel> levelsForCurriculum(String? curriculumId) => levels
      .where((level) => level.curriculumId == curriculumId && level.isEnabled)
      .toList(growable: false);

  List<EducationGrade> gradesForLevel(String? levelId) => grades
      .where((grade) => grade.educationLevelId == levelId && grade.isEnabled)
      .toList(growable: false);

  List<School> schoolsForSystem(String? countryCode, String? systemId) =>
      schools
          .where(
            (school) =>
                school.countryCode == countryCode &&
                school.educationSystemId == systemId &&
                school.isEnabled,
          )
          .toList(growable: false);
}

class Learner {
  const Learner({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.countryCode,
    required this.educationSystemId,
    required this.curriculumId,
    required this.educationLevelId,
    required this.gradeId,
    required this.schoolId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Learner.fromJson(Map<String, dynamic> json) {
    return Learner(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      countryCode: json['country_code'] as String,
      educationSystemId: json['education_system_id'] as String,
      curriculumId: json['curriculum_id'] as String,
      educationLevelId: json['education_level_id'] as String,
      gradeId: json['grade_id'] as String,
      schoolId: json['school_id'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String countryCode;
  final String educationSystemId;
  final String curriculumId;
  final String educationLevelId;
  final String gradeId;
  final String? schoolId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName =>
      [firstName, middleName, lastName].whereType<String>().join(' ');
}

class LearnerStatusEvent {
  const LearnerStatusEvent({
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory LearnerStatusEvent.fromJson(Map<String, dynamic> json) {
    return LearnerStatusEvent(
      status: json['status'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String status;
  final String? reason;
  final DateTime createdAt;
}

class LearnerChangeEvent {
  const LearnerChangeEvent({
    required this.changedFields,
    required this.createdAt,
  });

  factory LearnerChangeEvent.fromJson(Map<String, dynamic> json) {
    return LearnerChangeEvent(
      changedFields: json['changed_fields'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final Map<String, dynamic> changedFields;
  final DateTime createdAt;
}

class LearnerRelationship {
  const LearnerRelationship({
    required this.id,
    required this.learnerId,
    required this.parentUserId,
    required this.role,
    required this.status,
  });

  factory LearnerRelationship.fromJson(Map<String, dynamic> json) {
    return LearnerRelationship(
      id: json['id'] as String,
      learnerId: json['learner_id'] as String,
      parentUserId: json['parent_user_id'] as String,
      role: json['relationship_role'] as String,
      status: json['relationship_status'] as String,
    );
  }

  final String id;
  final String learnerId;
  final String parentUserId;
  final String role;
  final String status;
}

class LearnerPromotion {
  const LearnerPromotion({
    required this.fromGradeId,
    required this.toGradeId,
    required this.promotionType,
    required this.effectiveOn,
    required this.note,
  });

  factory LearnerPromotion.fromJson(Map<String, dynamic> json) {
    return LearnerPromotion(
      fromGradeId: json['from_grade_id'] as String,
      toGradeId: json['to_grade_id'] as String,
      promotionType: json['promotion_type'] as String,
      effectiveOn: DateTime.parse(json['effective_on'] as String),
      note: json['note'] as String?,
    );
  }

  final String fromGradeId;
  final String toGradeId;
  final String promotionType;
  final DateTime effectiveOn;
  final String? note;
}

class GuardianInvitation {
  const GuardianInvitation({
    required this.id,
    required this.learnerId,
    required this.inviteeEmail,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory GuardianInvitation.fromJson(Map<String, dynamic> json) {
    return GuardianInvitation(
      id: json['id'] as String,
      learnerId: json['learner_id'] as String,
      inviteeEmail: json['invitee_email'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String learnerId;
  final String inviteeEmail;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
}

class IncomingGuardianInvitation {
  const IncomingGuardianInvitation({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    required this.inviterName,
    required this.inviteeEmail,
    required this.expiresAt,
    required this.createdAt,
  });

  factory IncomingGuardianInvitation.fromJson(Map<String, dynamic> json) {
    return IncomingGuardianInvitation(
      id: json['id'] as String,
      learnerId: json['learner_id'] as String,
      learnerName: json['learner_name'] as String,
      inviterName: json['inviter_name'] as String,
      inviteeEmail: json['invitee_email'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String learnerId;
  final String learnerName;
  final String inviterName;
  final String inviteeEmail;
  final DateTime expiresAt;
  final DateTime createdAt;
}
