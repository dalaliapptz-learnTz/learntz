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

@immutable
class SchoolNetworkWorkspaceKpis {
  const SchoolNetworkWorkspaceKpis({
    required this.networkOrgId,
    required this.networkName,
    required this.countryCode,
    this.brandColor = '#059669',
    required this.campusesCount,
    required this.totalEnrolledLearners,
    required this.totalTeachingStaff,
    required this.networkAveragePerformancePct,
    this.campuses = const [],
  });

  final String networkOrgId;
  final String networkName;
  final String countryCode;
  final String brandColor;
  final int campusesCount;
  final int totalEnrolledLearners;
  final int totalTeachingStaff;
  final double networkAveragePerformancePct;
  final List<Map<String, dynamic>> campuses;

  factory SchoolNetworkWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return SchoolNetworkWorkspaceKpis(
      networkOrgId: json['network_org_id'] as String? ?? '',
      networkName: json['network_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      brandColor: json['brand_color'] as String? ?? '#059669',
      campusesCount: (json['campuses_count'] as num?)?.toInt() ?? 0,
      totalEnrolledLearners:
          (json['total_enrolled_learners'] as num?)?.toInt() ?? 0,
      totalTeachingStaff:
          (json['total_teaching_staff'] as num?)?.toInt() ?? 0,
      networkAveragePerformancePct:
          (json['network_average_performance_pct'] as num?)?.toDouble() ?? 0.0,
      campuses: (json['campuses'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

@immutable
class ResearchInstitutionWorkspaceKpis {
  const ResearchInstitutionWorkspaceKpis({
    required this.researchOrgId,
    required this.institutionName,
    required this.countryCode,
    required this.differentialPrivacyStandard,
    required this.anonymizedCohortsCount,
    required this.totalAnonymizedObservations,
    required this.statisticalMasteryIndex,
    this.subjectMasteryDistribution = const [],
    this.availableDatasets = const [],
  });

  final String researchOrgId;
  final String institutionName;
  final String countryCode;
  final String differentialPrivacyStandard;
  final int anonymizedCohortsCount;
  final int totalAnonymizedObservations;
  final double statisticalMasteryIndex;
  final List<Map<String, dynamic>> subjectMasteryDistribution;
  final List<Map<String, dynamic>> availableDatasets;

  factory ResearchInstitutionWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return ResearchInstitutionWorkspaceKpis(
      researchOrgId: json['research_org_id'] as String? ?? '',
      institutionName: json['institution_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      differentialPrivacyStandard:
          json['differential_privacy_standard'] as String? ??
              'k-anonymity (k>=25)',
      anonymizedCohortsCount:
          (json['anonymized_cohorts_count'] as num?)?.toInt() ?? 0,
      totalAnonymizedObservations:
          (json['total_anonymized_observations'] as num?)?.toInt() ?? 0,
      statisticalMasteryIndex:
          (json['statistical_mastery_index'] as num?)?.toDouble() ?? 0.0,
      subjectMasteryDistribution:
          (json['subject_mastery_distribution'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              const [],
      availableDatasets: (json['available_datasets'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

@immutable
class DevelopmentPartnerWorkspaceKpis {
  const DevelopmentPartnerWorkspaceKpis({
    required this.partnerOrgId,
    required this.partnerName,
    required this.countryCode,
    required this.supportedSchoolsCount,
    required this.beneficiaryLearnersCount,
    required this.activeInterventionProgramsCount,
    this.sdg4Benchmarks = const {},
    this.interventions = const [],
  });

  final String partnerOrgId;
  final String partnerName;
  final String countryCode;
  final int supportedSchoolsCount;
  final int beneficiaryLearnersCount;
  final int activeInterventionProgramsCount;
  final Map<String, dynamic> sdg4Benchmarks;
  final List<Map<String, dynamic>> interventions;

  factory DevelopmentPartnerWorkspaceKpis.fromJson(Map<String, dynamic> json) {
    return DevelopmentPartnerWorkspaceKpis(
      partnerOrgId: json['partner_org_id'] as String? ?? '',
      partnerName: json['partner_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'TZ',
      supportedSchoolsCount:
          (json['supported_schools_count'] as num?)?.toInt() ?? 0,
      beneficiaryLearnersCount:
          (json['beneficiary_learners_count'] as num?)?.toInt() ?? 0,
      activeInterventionProgramsCount:
          (json['active_intervention_programs_count'] as num?)?.toInt() ?? 0,
      sdg4Benchmarks: json['sdg4_benchmarks'] != null
          ? Map<String, dynamic>.from(json['sdg4_benchmarks'] as Map)
          : const {},
      interventions: (json['interventions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

@immutable
class ResearchExportResult {
  const ResearchExportResult({
    required this.exportId,
    required this.datasetKey,
    required this.institutionName,
    this.exportedAt,
    required this.privacyStandard,
    required this.recordsCount,
    required this.downloadUrl,
  });

  final String exportId;
  final String datasetKey;
  final String institutionName;
  final DateTime? exportedAt;
  final String privacyStandard;
  final int recordsCount;
  final String downloadUrl;

  factory ResearchExportResult.fromJson(Map<String, dynamic> json) {
    return ResearchExportResult(
      exportId: json['export_id'] as String? ?? '',
      datasetKey: json['dataset_key'] as String? ?? '',
      institutionName: json['institution_name'] as String? ?? '',
      exportedAt: json['exported_at'] != null
          ? DateTime.tryParse(json['exported_at'] as String)
          : null,
      privacyStandard: json['privacy_standard'] as String? ?? '',
      recordsCount: (json['records_count'] as num?)?.toInt() ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }
}

@immutable
class OrganizationSubscriptionStatus {
  const OrganizationSubscriptionStatus({
    required this.hasSubscription,
    this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.tier,
    required this.status,
    this.billingCycle = 'annual',
    this.currency = 'TZS',
    this.currentPrice = 0.0,
    required this.allocatedStudentSeats,
    required this.usedStudentSeats,
    required this.allocatedTeacherSeats,
    required this.usedTeacherSeats,
    required this.allocatedStorageGb,
    required this.usedStorageGb,
    this.periodStart,
    this.periodEnd,
    this.taxId,
    required this.slaResponseHours,
  });

  final bool hasSubscription;
  final String? subscriptionId;
  final String planId;
  final String planName;
  final String tier;
  final String status;
  final String billingCycle;
  final String currency;
  final double currentPrice;
  final int allocatedStudentSeats;
  final int usedStudentSeats;
  final int allocatedTeacherSeats;
  final int usedTeacherSeats;
  final int allocatedStorageGb;
  final int usedStorageGb;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? taxId;
  final int slaResponseHours;

  factory OrganizationSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return OrganizationSubscriptionStatus(
      hasSubscription: json['has_subscription'] as bool? ?? false,
      subscriptionId: json['subscription_id'] as String?,
      planId: json['plan_id'] as String? ?? 'school_pilot',
      planName: json['plan_name'] as String? ?? 'Institutional Pilot',
      tier: json['tier'] as String? ?? 'pilot',
      status: json['status'] as String? ?? 'trialing',
      billingCycle: json['billing_cycle'] as String? ?? 'annual',
      currency: json['currency'] as String? ?? 'TZS',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      allocatedStudentSeats:
          (json['allocated_student_seats'] as num?)?.toInt() ?? 0,
      usedStudentSeats: (json['used_student_seats'] as num?)?.toInt() ?? 0,
      allocatedTeacherSeats:
          (json['allocated_teacher_seats'] as num?)?.toInt() ?? 0,
      usedTeacherSeats: (json['used_teacher_seats'] as num?)?.toInt() ?? 0,
      allocatedStorageGb:
          (json['allocated_storage_gb'] as num?)?.toInt() ?? 50,
      usedStorageGb: (json['used_storage_gb'] as num?)?.toInt() ?? 0,
      periodStart: json['period_start'] != null
          ? DateTime.tryParse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.tryParse(json['period_end'] as String)
          : null,
      taxId: json['tax_id'] as String?,
      slaResponseHours: (json['sla_response_hours'] as num?)?.toInt() ?? 24,
    );
  }
}

@immutable
class OrganizationSupportTicket {
  const OrganizationSupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.slaDueAt,
    this.resolvedAt,
    this.createdAt,
    this.messageCount = 0,
  });

  final String id;
  final String ticketNumber;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime? slaDueAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final int messageCount;

  factory OrganizationSupportTicket.fromJson(Map<String, dynamic> json) {
    return OrganizationSupportTicket(
      id: json['id'] as String? ?? '',
      ticketNumber: json['ticket_number'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'technical_integration',
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'open',
      slaDueAt: json['sla_due_at'] != null
          ? DateTime.tryParse(json['sla_due_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
    );
  }
}



