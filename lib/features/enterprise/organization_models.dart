import 'package:flutter/foundation.dart';

enum OrganizationType {
  ministry,
  examinationAuthority,
  regionalOffice,
  districtOffice,
  schoolNetwork,
  school,
  researchInstitution,
  developmentPartner;

  String get dbValue => switch (this) {
        OrganizationType.ministry => 'ministry',
        OrganizationType.examinationAuthority => 'examination_authority',
        OrganizationType.regionalOffice => 'regional_office',
        OrganizationType.districtOffice => 'district_office',
        OrganizationType.schoolNetwork => 'school_network',
        OrganizationType.school => 'school',
        OrganizationType.researchInstitution => 'research_institution',
        OrganizationType.developmentPartner => 'development_partner',
      };

  String get label => switch (this) {
        OrganizationType.ministry => 'Ministry of Education',
        OrganizationType.examinationAuthority => 'Examination Authority',
        OrganizationType.regionalOffice => 'Regional Office',
        OrganizationType.districtOffice => 'District Office',
        OrganizationType.schoolNetwork => 'School Network / Trust',
        OrganizationType.school => 'Accredited School',
        OrganizationType.researchInstitution => 'Research Institution',
        OrganizationType.developmentPartner => 'Development Partner',
      };

  static OrganizationType fromString(String val) => switch (val.toLowerCase()) {
        'ministry' => OrganizationType.ministry,
        'examination_authority' => OrganizationType.examinationAuthority,
        'regional_office' => OrganizationType.regionalOffice,
        'district_office' => OrganizationType.districtOffice,
        'school_network' => OrganizationType.schoolNetwork,
        'school' => OrganizationType.school,
        'research_institution' => OrganizationType.researchInstitution,
        'development_partner' => OrganizationType.developmentPartner,
        _ => OrganizationType.school,
      };
}

enum OrganizationStatus {
  pendingVerification,
  active,
  suspended,
  archived;

  String get dbValue => switch (this) {
        OrganizationStatus.pendingVerification => 'pending_verification',
        OrganizationStatus.active => 'active',
        OrganizationStatus.suspended => 'suspended',
        OrganizationStatus.archived => 'archived',
      };

  String get label => switch (this) {
        OrganizationStatus.pendingVerification => 'Pending Verification',
        OrganizationStatus.active => 'Active',
        OrganizationStatus.suspended => 'Suspended',
        OrganizationStatus.archived => 'Archived',
      };

  static OrganizationStatus fromString(String val) => switch (val.toLowerCase()) {
        'pending_verification' => OrganizationStatus.pendingVerification,
        'active' => OrganizationStatus.active,
        'suspended' => OrganizationStatus.suspended,
        'archived' => OrganizationStatus.archived,
        _ => OrganizationStatus.pendingVerification,
      };
}

@immutable
class Organization {
  const Organization({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.slug,
    required this.type,
    this.parentName,
    this.status = OrganizationStatus.active,
    this.brandColor = '#0F4C81',
    this.createdAt,
  });

  final String id;
  final String countryCode;
  final String name;
  final String slug;
  final OrganizationType type;
  final String? parentName;
  final OrganizationStatus status;
  final String brandColor;
  final DateTime? createdAt;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: OrganizationType.fromString(json['type'] as String? ?? 'school'),
      parentName: json['parent_name'] as String?,
      status: OrganizationStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      brandColor: json['brand_color'] as String? ?? '#0F4C81',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

@immutable
class OrganizationDetails {
  const OrganizationDetails({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.slug,
    required this.type,
    this.registrationNumber,
    this.parentOrganizationId,
    this.parentName,
    this.parentSlug,
    this.websiteUrl,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.brandColor = '#0F4C81',
    this.status = OrganizationStatus.active,
    this.settings = const {},
    this.directChildrenCount = 0,
    this.totalDescendantsCount = 0,
    this.createdAt,
  });

  final String id;
  final String countryCode;
  final String name;
  final String slug;
  final OrganizationType type;
  final String? registrationNumber;
  final String? parentOrganizationId;
  final String? parentName;
  final String? parentSlug;
  final String? websiteUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final String brandColor;
  final OrganizationStatus status;
  final Map<String, dynamic> settings;
  final int directChildrenCount;
  final int totalDescendantsCount;
  final DateTime? createdAt;

  factory OrganizationDetails.fromJson(Map<String, dynamic> json) {
    return OrganizationDetails(
      id: json['id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: OrganizationType.fromString(json['type'] as String? ?? 'school'),
      registrationNumber: json['registration_number'] as String?,
      parentOrganizationId: json['parent_organization_id'] as String?,
      parentName: json['parent_name'] as String?,
      parentSlug: json['parent_slug'] as String?,
      websiteUrl: json['website_url'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      brandColor: json['brand_color'] as String? ?? '#0F4C81',
      status: OrganizationStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
      directChildrenCount: (json['direct_children_count'] as num?)?.toInt() ?? 0,
      totalDescendantsCount:
          (json['total_descendants_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

@immutable
class SubordinateOrganizationItem {
  const SubordinateOrganizationItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.depth,
    this.parentId,
    this.status = OrganizationStatus.active,
  });

  final String id;
  final String name;
  final String slug;
  final OrganizationType type;
  final int depth;
  final String? parentId;
  final OrganizationStatus status;

  factory SubordinateOrganizationItem.fromJson(Map<String, dynamic> json) {
    return SubordinateOrganizationItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: OrganizationType.fromString(json['type'] as String? ?? 'school'),
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      parentId: json['parent_id'] as String?,
      status: OrganizationStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
    );
  }
}
