class AdminRoleAssignment {
  const AdminRoleAssignment({required this.role, this.countryCode});

  factory AdminRoleAssignment.fromJson(Map<String, dynamic> json) {
    return AdminRoleAssignment(
      role: json['role'] as String,
      countryCode: json['country_code'] as String?,
    );
  }

  final String role;
  final String? countryCode;
}

class AdminCapabilities {
  const AdminCapabilities({
    required this.canAccessAdmin,
    required this.isSuperAdmin,
    required this.isCountryAdmin,
    required this.isSupportAdmin,
    required this.isCurriculumStaff,
    required this.roles,
  });

  const AdminCapabilities.empty()
    : canAccessAdmin = false,
      isSuperAdmin = false,
      isCountryAdmin = false,
      isSupportAdmin = false,
      isCurriculumStaff = false,
      roles = const [];

  factory AdminCapabilities.fromJson(Map<String, dynamic> json) {
    final rawRoles = (json['roles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdminRoleAssignment.fromJson)
        .toList();

    return AdminCapabilities(
      canAccessAdmin: json['can_access_admin'] as bool? ?? false,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      isCountryAdmin: json['is_country_admin'] as bool? ?? false,
      isSupportAdmin: json['is_support_admin'] as bool? ?? false,
      isCurriculumStaff: json['is_curriculum_staff'] as bool? ?? false,
      roles: rawRoles,
    );
  }

  final bool canAccessAdmin;
  final bool isSuperAdmin;
  final bool isCountryAdmin;
  final bool isSupportAdmin;
  final bool isCurriculumStaff;
  final List<AdminRoleAssignment> roles;

  bool get canManageAccountRequests => isSuperAdmin || isSupportAdmin;
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.enabledCountries,
    required this.parentAccounts,
    required this.activeLearners,
    required this.pendingAccountRequests,
    required this.pendingCurriculumImports,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      enabledCountries: (json['enabled_countries'] as num?)?.toInt() ?? 0,
      parentAccounts: (json['parent_accounts'] as num?)?.toInt() ?? 0,
      activeLearners: (json['active_learners'] as num?)?.toInt() ?? 0,
      pendingAccountRequests:
          (json['pending_account_requests'] as num?)?.toInt() ?? 0,
      pendingCurriculumImports:
          (json['pending_curriculum_imports'] as num?)?.toInt() ?? 0,
    );
  }

  final int enabledCountries;
  final int parentAccounts;
  final int activeLearners;
  final int pendingAccountRequests;
  final int pendingCurriculumImports;
}

class AdminAccountRequest {
  const AdminAccountRequest({
    required this.userId,
    required this.fullName,
    required this.status,
    required this.requestedAt,
    this.countryCode,
    this.requestReason,
  });

  factory AdminAccountRequest.fromJson(Map<String, dynamic> json) {
    return AdminAccountRequest(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      countryCode: json['country_code'] as String?,
      status: json['status'] as String,
      requestReason: json['request_reason'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }

  final String userId;
  final String fullName;
  final String? countryCode;
  final String status;
  final String? requestReason;
  final DateTime requestedAt;
}

class AdminAuditLogEntry {
  const AdminAuditLogEntry({
    required this.id,
    required this.action,
    required this.metadata,
    required this.createdAt,
    this.actorUserId,
    this.targetUserId,
  });

  factory AdminAuditLogEntry.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return AdminAuditLogEntry(
      id: (json['id'] as num).toInt(),
      actorUserId: json['actor_user_id'] as String?,
      targetUserId: json['target_user_id'] as String?,
      action: json['action'] as String,
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String? actorUserId;
  final String? targetUserId;
  final String action;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}
