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
}
