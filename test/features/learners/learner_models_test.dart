import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learners/learner_repository.dart';

void main() {
  test('learner model parses profile fields and composes the display name', () {
    final learner = Learner.fromJson({
      'id': 'learner-id',
      'first_name': 'Asha',
      'middle_name': 'Neema',
      'last_name': 'Mushi',
      'date_of_birth': '2015-04-12',
      'gender': null,
      'country_code': 'TZ',
      'education_system_id': 'system-id',
      'curriculum_id': 'curriculum-id',
      'education_level_id': 'level-id',
      'grade_id': 'grade-id',
      'school_id': null,
      'status': 'active',
      'created_at': '2026-11-11T09:00:00Z',
      'updated_at': '2026-11-11T09:00:00Z',
    });

    expect(learner.fullName, 'Asha Neema Mushi');
    expect(learner.dateOfBirth, DateTime(2015, 4, 12));
    expect(learner.schoolId, isNull);
  });

  test('education catalog only returns grades for the selected level', () {
    const catalog = EducationCatalog(
      countries: [EducationCountry(code: 'TZ', name: 'Tanzania')],
      systems: [
        EducationSystem(
          id: 'system-id',
          countryCode: 'TZ',
          name: 'National system',
        ),
      ],
      curricula: [
        Curriculum(
          id: 'curriculum-id',
          countryCode: 'TZ',
          educationSystemId: 'system-id',
          name: 'TIE',
          code: 'TIE',
        ),
      ],
      levels: [
        EducationLevel(
          id: 'primary-id',
          curriculumId: 'curriculum-id',
          name: 'Primary',
          code: 'PRIMARY',
          sequence: 1,
        ),
      ],
      grades: [
        EducationGrade(
          id: 'standard-1',
          educationLevelId: 'primary-id',
          curriculumId: 'curriculum-id',
          name: 'Standard 1',
          code: 'STANDARD_1',
          sequence: 1,
        ),
        EducationGrade(
          id: 'form-1',
          educationLevelId: 'secondary-id',
          curriculumId: 'curriculum-id',
          name: 'Form 1',
          code: 'FORM_1',
          sequence: 1,
        ),
      ],
      schools: [],
    );

    expect(catalog.gradesForLevel('primary-id').map((grade) => grade.name), [
      'Standard 1',
    ]);
    expect(catalog.systemsForCountry('KE'), isEmpty);
    expect(catalog.country('TZ')?.name, 'Tanzania');
  });

  test('registration retry keys are unique UUID v4 values', () {
    final first = LearnerRepository.newRegistrationRequestId();
    final second = LearnerRepository.newRegistrationRequestId();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(uuidV4.hasMatch(first), isTrue);
    expect(uuidV4.hasMatch(second), isTrue);
    expect(first, isNot(second));
  });

  test('guardian invitation models parse email and metadata correctly', () {
    final sent = GuardianInvitation.fromJson({
      'id': 'inv-1',
      'learner_id': 'learner-1',
      'invitee_email': 'guardian@example.test',
      'status': 'pending',
      'expires_at': '2026-11-19T10:00:00Z',
      'created_at': '2026-11-12T10:00:00Z',
    });

    expect(sent.inviteeEmail, 'guardian@example.test');
    expect(sent.status, 'pending');

    final incoming = IncomingGuardianInvitation.fromJson({
      'id': 'inv-2',
      'learner_id': 'learner-1',
      'learner_name': 'Asha Mushi',
      'inviter_name': 'Juma Mushi',
      'invitee_email': 'guardian@example.test',
      'expires_at': '2026-11-19T10:00:00Z',
      'created_at': '2026-11-12T10:00:00Z',
    });

    expect(incoming.learnerName, 'Asha Mushi');
    expect(incoming.inviterName, 'Juma Mushi');
  });
}
