import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import 'learner_models.dart';

class LearnerRepository {
  const LearnerRepository(this._client);

  static const _learnerColumns =
      'id, first_name, middle_name, last_name, date_of_birth, gender, '
      'country_code, education_system_id, curriculum_id, '
      'education_level_id, grade_id, school_id, status, created_at, updated_at';

  final SupabaseClient _client;

  Future<List<Learner>> listLearners() async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final rows = await _client
        .from('learners')
        .select(_learnerColumns)
        .order('created_at');
    return rows.map((row) => Learner.fromJson(row)).toList(growable: false);
  }

  Future<Learner> getLearner(String learnerId) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client
        .from('learners')
        .select(_learnerColumns)
        .eq('id', learnerId)
        .single();
    return Learner.fromJson(row);
  }

  Future<Learner> createLearner({
    required String registrationRequestId,
    required String firstName,
    required String? middleName,
    required String lastName,
    required DateTime dateOfBirth,
    required String? gender,
    required String countryCode,
    required String educationSystemId,
    required String curriculumId,
    required String educationLevelId,
    required String gradeId,
    required String? schoolId,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'create_learner',
      params: {
        'p_registration_request_id': registrationRequestId,
        'p_first_name': firstName.trim(),
        'p_middle_name': middleName?.trim(),
        'p_last_name': lastName.trim(),
        'p_date_of_birth': _dateOnly(dateOfBirth),
        'p_gender': gender,
        'p_country_code': countryCode,
        'p_education_system_id': educationSystemId,
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
        'p_school_id': schoolId,
      },
    );
    return Learner.fromJson(row as Map<String, dynamic>);
  }

  Future<Learner> updateLearner({
    required String learnerId,
    required String firstName,
    required String? middleName,
    required String lastName,
    required DateTime dateOfBirth,
    required String? gender,
    required String countryCode,
    required String educationSystemId,
    required String curriculumId,
    required String educationLevelId,
    required String gradeId,
    required String? schoolId,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'update_learner',
      params: {
        'p_learner_id': learnerId,
        'p_first_name': firstName.trim(),
        'p_middle_name': middleName?.trim(),
        'p_last_name': lastName.trim(),
        'p_date_of_birth': _dateOnly(dateOfBirth),
        'p_gender': gender,
        'p_country_code': countryCode,
        'p_education_system_id': educationSystemId,
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
        'p_school_id': schoolId,
      },
    );
    return Learner.fromJson(row as Map<String, dynamic>);
  }

  Future<Learner> deactivateLearner(String learnerId) =>
      _learnerStatusAction('deactivate_learner', learnerId);

  Future<Learner> requestDeletion(String learnerId) =>
      _learnerStatusAction('request_learner_deletion', learnerId);

  Future<List<LearnerStatusEvent>> getStatusHistory(String learnerId) async {
    final rows = await _client
        .from('learner_status_history')
        .select('status, reason, created_at')
        .eq('learner_id', learnerId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => LearnerStatusEvent.fromJson(row))
        .toList(growable: false);
  }

  Future<List<LearnerPromotion>> getPromotionHistory(String learnerId) async {
    final rows = await _client
        .from('learner_promotions')
        .select(
          'from_grade_id, to_grade_id, promotion_type, effective_on, note',
        )
        .eq('learner_id', learnerId)
        .order('effective_on', ascending: false);
    return rows
        .map((row) => LearnerPromotion.fromJson(row))
        .toList(growable: false);
  }

  Future<List<LearnerChangeEvent>> getChangeHistory(String learnerId) async {
    final rows = await _client
        .from('learner_change_history')
        .select('changed_fields, created_at')
        .eq('learner_id', learnerId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => LearnerChangeEvent.fromJson(row))
        .toList(growable: false);
  }

  Future<void> recordPromotion({
    required String learnerId,
    required EducationGrade targetGrade,
    required EducationLevel targetLevel,
    required Curriculum targetCurriculum,
    required EducationSystem targetSystem,
    required String? schoolId,
    required String promotionType,
    required DateTime effectiveOn,
    String? note,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    await _client.rpc(
      'record_learner_promotion',
      params: {
        'p_learner_id': learnerId,
        'p_to_country_code': targetSystem.countryCode,
        'p_to_education_system_id': targetSystem.id,
        'p_to_curriculum_id': targetCurriculum.id,
        'p_to_education_level_id': targetLevel.id,
        'p_to_grade_id': targetGrade.id,
        'p_to_school_id': schoolId,
        'p_promotion_type': promotionType,
        'p_effective_on': _dateOnly(effectiveOn),
        'p_note': note?.trim(),
      },
    );
  }

  Future<List<GuardianInvitation>> listSentGuardianInvitations(
    String learnerId,
  ) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final rows = await _client
        .from('guardian_invitations')
        .select('id, learner_id, invitee_email, status, expires_at, created_at')
        .eq('learner_id', learnerId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows
        .map((row) => GuardianInvitation.fromJson(row))
        .toList(growable: false);
  }

  Future<GuardianInvitation> inviteGuardianByEmail({
    required String learnerId,
    required String email,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'invite_learner_guardian_by_email',
      params: {'p_learner_id': learnerId, 'p_invitee_email': email.trim()},
    );
    return GuardianInvitation.fromJson(row as Map<String, dynamic>);
  }

  Future<void> revokeGuardianInvitation(String invitationId) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    await _client.rpc(
      'revoke_guardian_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }

  Future<List<IncomingGuardianInvitation>>
      listIncomingGuardianInvitations() async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final rows = await _client.rpc('list_incoming_guardian_invitations');
    return (rows as List)
        .map(
          (row) =>
              IncomingGuardianInvitation.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<GuardianInvitation> respondGuardianInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'respond_guardian_invitation',
      params: {'p_invitation_id': invitationId, 'p_accept': accept},
    );
    return GuardianInvitation.fromJson(row as Map<String, dynamic>);
  }

  Future<LearnerRelationship> inviteGuardian({
    required String learnerId,
    required String guardianUserId,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'invite_learner_guardian',
      params: {'p_learner_id': learnerId, 'p_guardian_user_id': guardianUserId},
    );
    return LearnerRelationship.fromJson(row as Map<String, dynamic>);
  }

  Future<LearnerRelationship> acceptGuardianInvitation(
    String relationshipId,
  ) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(
      'accept_learner_guardian_invitation',
      params: {'p_relationship_id': relationshipId},
    );
    return LearnerRelationship.fromJson(row as Map<String, dynamic>);
  }

  Future<void> revokeGuardian({
    required String learnerId,
    required String guardianUserId,
  }) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    await _client.rpc(
      'revoke_learner_guardian',
      params: {'p_learner_id': learnerId, 'p_guardian_user_id': guardianUserId},
    );
  }

  Future<Learner> _learnerStatusAction(String action, String learnerId) async {
    if (_client.auth.currentUser == null) throw const NotSignedInException();
    final row = await _client.rpc(action, params: {'p_learner_id': learnerId});
    return Learner.fromJson(row as Map<String, dynamic>);
  }

  static String newRegistrationRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<AcademicCalendar?> getActiveAcademicCalendar({
    required String countryCode,
    required String educationSystemId,
    DateTime? referenceDate,
  }) async {
    final response = await _client.rpc(
      'get_active_academic_calendar',
      params: {
        'p_country_code': countryCode,
        'p_education_system_id': educationSystemId,
        if (referenceDate != null)
          'p_reference_date': referenceDate.toIso8601String().split('T').first,
      },
    );
    if (response == null) return null;
    return AcademicCalendar.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<AcademicTerm>> listAcademicTerms(
    String academicCalendarId,
  ) async {
    final rows = await _client.rpc(
      'list_academic_terms',
      params: {'p_academic_calendar_id': academicCalendarId},
    );
    return (rows as List<dynamic>)
        .map((row) => AcademicTerm.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}

class EducationCatalogRepository {
  const EducationCatalogRepository(this._client);

  final SupabaseClient _client;

  Future<EducationCatalog> getCatalog() async {
    final countries = await _client
        .from('countries')
        .select('country_code, display_name')
        .eq('is_enabled', true)
        .order('display_name');
    final systems = await _client
        .from('education_systems')
        .select('id, country_code, name, is_enabled')
        .order('name');
    final curricula = await _client
        .from('curricula')
        .select('id, country_code, education_system_id, name, code, is_enabled')
        .order('name');
    final levels = await _client
        .from('education_levels')
        .select('id, curriculum_id, name, code, sequence, is_enabled')
        .order('sequence');
    final grades = await _client
        .from('education_grades')
        .select(
          'id, education_level_id, curriculum_id, name, code, sequence, is_enabled',
        )
        .order('sequence');
    final schools = await _client
        .from('schools')
        .select('id, country_code, education_system_id, name, is_enabled')
        .order('name');

    return EducationCatalog(
      countries: countries
          .map((row) => EducationCountry.fromJson(row))
          .toList(growable: false),
      systems: systems
          .map((row) => EducationSystem.fromJson(row))
          .toList(growable: false),
      curricula: curricula
          .map((row) => Curriculum.fromJson(row))
          .toList(growable: false),
      levels: levels
          .map((row) => EducationLevel.fromJson(row))
          .toList(growable: false),
      grades: grades
          .map((row) => EducationGrade.fromJson(row))
          .toList(growable: false),
      schools: schools
          .map((row) => School.fromJson(row))
          .toList(growable: false),
    );
  }
}
