import 'package:supabase_flutter/supabase_flutter.dart';

import 'organization_models.dart';

class OrganizationRepository {
  const OrganizationRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Organization>> listOrganizations({
    String? countryCode,
    OrganizationType? type,
    String? search,
    OrganizationStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'list_organizations',
        params: {
          'p_country_code': countryCode,
          'p_type': type?.dbValue,
          'p_search': search != null && search.trim().isNotEmpty
              ? search.trim()
              : null,
          'p_status': status?.dbValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) => Organization.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<OrganizationDetails?> getOrganizationDetails(String orgId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.rpc(
        'get_organization_details',
        params: {'p_org_id': orgId},
      );

      if (response == null) return null;
      return OrganizationDetails.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<SubordinateOrganizationItem>> listSubordinateOrganizations(
    String orgId, {
    OrganizationType? type,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'list_subordinate_organizations',
        params: {
          'p_org_id': orgId,
          'p_type': type?.dbValue,
        },
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              SubordinateOrganizationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> registerEnterpriseOrganization({
    required String countryCode,
    required String name,
    required String slug,
    required OrganizationType type,
    String? registrationNumber,
    String? parentOrganizationId,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
    String brandColor = '#0F4C81',
    Map<String, dynamic> settings = const {},
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client unavailable');
    }

    final response = await client.rpc(
      'register_enterprise_organization',
      params: {
        'p_country_code': countryCode,
        'p_name': name.trim(),
        'p_slug': slug.trim().toLowerCase(),
        'p_type': type.dbValue,
        'p_registration_number': registrationNumber?.trim(),
        'p_parent_organization_id': parentOrganizationId,
        'p_website_url': websiteUrl?.trim(),
        'p_contact_email': contactEmail?.trim(),
        'p_contact_phone': contactPhone?.trim(),
        'p_brand_color': brandColor,
        'p_settings': settings,
      },
    );

    return response as String;
  }

  Future<List<InstitutionalMember>> listOrganizationMembers(String orgId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'list_organization_members',
        params: {'p_org_id': orgId},
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              InstitutionalMember.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserWorkspace>> getUserInstitutionalWorkspaces() async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc('get_user_institutional_workspaces');

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) => UserWorkspace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> inviteOrganizationMember({
    required String orgId,
    required String email,
    required InstitutionalRole role,
    String? jobTitle,
    String? department,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client unavailable');
    }

    final response = await client.rpc(
      'invite_organization_member',
      params: {
        'p_org_id': orgId,
        'p_email': email.trim().toLowerCase(),
        'p_role': role.dbValue,
        'p_job_title': jobTitle?.trim(),
        'p_department': department?.trim(),
      },
    );

    return response as String;
  }

  Future<bool> respondOrganizationInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    final client = _client;
    if (client == null) return false;

    final response = await client.rpc(
      'respond_organization_invitation',
      params: {
        'p_invitation_id': invitationId,
        'p_accept': accept,
      },
    );

    return (response as bool?) ?? false;
  }

  Future<bool> updateOrganizationMemberRole({
    required String membershipId,
    required InstitutionalRole newRole,
    String? jobTitle,
  }) async {
    final client = _client;
    if (client == null) return false;

    final response = await client.rpc(
      'update_organization_member_role',
      params: {
        'p_membership_id': membershipId,
        'p_new_role': newRole.dbValue,
        'p_job_title': jobTitle?.trim(),
      },
    );

    return (response as bool?) ?? false;
  }

  Future<bool> removeOrganizationMember(String membershipId) async {
    final client = _client;
    if (client == null) return false;

    final response = await client.rpc(
      'remove_organization_member',
      params: {'p_membership_id': membershipId},
    );

    return (response as bool?) ?? false;
  }
}
