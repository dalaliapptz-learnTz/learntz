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

enum InstitutionalRole {
  institutionalAdmin,
  educationOfficer,
  schoolPrincipal,
  headOfDepartment,
  teacher,
  curriculumAnalyst,
  researcher,
  partnerAuditor;

  String get dbValue => switch (this) {
        InstitutionalRole.institutionalAdmin => 'institutional_admin',
        InstitutionalRole.educationOfficer => 'education_officer',
        InstitutionalRole.schoolPrincipal => 'school_principal',
        InstitutionalRole.headOfDepartment => 'head_of_department',
        InstitutionalRole.teacher => 'teacher',
        InstitutionalRole.curriculumAnalyst => 'curriculum_analyst',
        InstitutionalRole.researcher => 'researcher',
        InstitutionalRole.partnerAuditor => 'partner_auditor',
      };

  String get label => switch (this) {
        InstitutionalRole.institutionalAdmin => 'Institutional Admin',
        InstitutionalRole.educationOfficer => 'Education Officer',
        InstitutionalRole.schoolPrincipal => 'School Principal / Head',
        InstitutionalRole.headOfDepartment => 'Head of Department',
        InstitutionalRole.teacher => 'Teacher / Instructor',
        InstitutionalRole.curriculumAnalyst => 'Curriculum Analyst',
        InstitutionalRole.researcher => 'Education Researcher',
        InstitutionalRole.partnerAuditor => 'Partner Auditor',
      };

  static InstitutionalRole fromString(String val) => switch (val.toLowerCase()) {
        'institutional_admin' => InstitutionalRole.institutionalAdmin,
        'education_officer' => InstitutionalRole.educationOfficer,
        'school_principal' => InstitutionalRole.schoolPrincipal,
        'head_of_department' => InstitutionalRole.headOfDepartment,
        'teacher' => InstitutionalRole.teacher,
        'curriculum_analyst' => InstitutionalRole.curriculumAnalyst,
        'researcher' => InstitutionalRole.researcher,
        'partner_auditor' => InstitutionalRole.partnerAuditor,
        _ => InstitutionalRole.teacher,
      };
}

@immutable
class InstitutionalMember {
  const InstitutionalMember({
    required this.membershipId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.jobTitle,
    this.department,
    this.status = 'active',
    this.createdAt,
  });

  final String membershipId;
  final String userId;
  final String fullName;
  final String email;
  final InstitutionalRole role;
  final String? jobTitle;
  final String? department;
  final String status;
  final DateTime? createdAt;

  factory InstitutionalMember.fromJson(Map<String, dynamic> json) {
    return InstitutionalMember(
      membershipId: json['membership_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Staff Member',
      email: json['email'] as String? ?? '',
      role: InstitutionalRole.fromString(json['role'] as String? ?? 'teacher'),
      jobTitle: json['job_title'] as String?,
      department: json['department'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

@immutable
class UserWorkspace {
  const UserWorkspace({
    required this.organizationId,
    required this.name,
    required this.slug,
    required this.type,
    required this.countryCode,
    this.brandColor = '#0F4C81',
    this.logoUrl,
    required this.role,
    this.jobTitle,
    this.department,
  });

  final String organizationId;
  final String name;
  final String slug;
  final OrganizationType type;
  final String countryCode;
  final String brandColor;
  final String? logoUrl;
  final InstitutionalRole role;
  final String? jobTitle;
  final String? department;

  factory UserWorkspace.fromJson(Map<String, dynamic> json) {
    return UserWorkspace(
      organizationId: json['organization_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: OrganizationType.fromString(json['type'] as String? ?? 'school'),
      countryCode: json['country_code'] as String? ?? 'TZ',
      brandColor: json['brand_color'] as String? ?? '#0F4C81',
      logoUrl: json['logo_url'] as String?,
      role: InstitutionalRole.fromString(json['role'] as String? ?? 'teacher'),
      jobTitle: json['job_title'] as String?,
      department: json['department'] as String?,
    );
  }
}

@immutable
class MinistryWorkspaceKpis {
  const MinistryWorkspaceKpis({
    required this.ministryOrgId,
    required this.countryCode,
    required this.subordinateSchoolsCount,
    required this.registeredLearnersCount,
    required this.activeSyllabusModulesCount,
    this.recentSchools = const [],
  });

  final String ministryOrgId;
  final String countryCode;
  final int subordinateSchoolsCount;
  final int registeredLearnersCount;
  final int activeSyllabusModulesCount;
  final List<Map<String, dynamic>> recentSchools;

  factory MinistryWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return MinistryWorkspaceKpis(
      ministryOrgId: json['ministry_org_id'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      subordinateSchoolsCount:
          (json['subordinate_schools_count'] as num?)?.toInt() ?? 0,
      registeredLearnersCount:
          (json['registered_learners_count'] as num?)?.toInt() ?? 0,
      activeSyllabusModulesCount:
          (json['active_syllabus_modules_count'] as num?)?.toInt() ?? 0,
      recentSchools: (json['recent_schools'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

@immutable
class ExamAuthorityWorkspaceKpis {
  const ExamAuthorityWorkspaceKpis({
    required this.authorityOrgId,
    required this.authorityCode,
    required this.countryCode,
    required this.archivedPapersCount,
    required this.approvedQuestionsCount,
    required this.activeBlueprintsCount,
    required this.averagePredictiveValidityIndex,
    this.recentPapers = const [],
  });

  final String authorityOrgId;
  final String authorityCode;
  final String countryCode;
  final int archivedPapersCount;
  final int approvedQuestionsCount;
  final int activeBlueprintsCount;
  final double averagePredictiveValidityIndex;
  final List<Map<String, dynamic>> recentPapers;

  factory ExamAuthorityWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return ExamAuthorityWorkspaceKpis(
      authorityOrgId: json['authority_org_id'] as String? ?? '',
      authorityCode: json['authority_code'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      archivedPapersCount:
          (json['archived_papers_count'] as num?)?.toInt() ?? 0,
      approvedQuestionsCount:
          (json['approved_questions_count'] as num?)?.toInt() ?? 0,
      activeBlueprintsCount:
          (json['active_blueprints_count'] as num?)?.toInt() ?? 0,
      averagePredictiveValidityIndex:
          (json['average_predictive_validity_index'] as num?)?.toDouble() ?? 0.0,
      recentPapers: (json['recent_papers'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

@immutable
class GovernanceOfficeWorkspaceKpis {
  const GovernanceOfficeWorkspaceKpis({
    required this.officeOrgId,
    required this.officeName,
    required this.officeType,
    required this.countryCode,
    required this.subordinateSchoolsCount,
    required this.totalLearnersCount,
    required this.averageMockPerformancePct,
    this.schoolsInJurisdiction = const [],
  });

  final String officeOrgId;
  final String officeName;
  final String officeType;
  final String countryCode;
  final int subordinateSchoolsCount;
  final int totalLearnersCount;
  final double averageMockPerformancePct;
  final List<Map<String, dynamic>> schoolsInJurisdiction;

  factory GovernanceOfficeWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return GovernanceOfficeWorkspaceKpis(
      officeOrgId: json['office_org_id'] as String? ?? '',
      officeName: json['office_name'] as String? ?? '',
      officeType: json['office_type'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      subordinateSchoolsCount:
          (json['subordinate_schools_count'] as num?)?.toInt() ?? 0,
      totalLearnersCount:
          (json['total_learners_count'] as num?)?.toInt() ?? 0,
      averageMockPerformancePct:
          (json['average_mock_performance_pct'] as num?)?.toDouble() ?? 0.0,
      schoolsInJurisdiction:
          (json['schools_in_jurisdiction'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [],
    );
  }
}

