import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_models.dart';
import '../organization_providers.dart';

class OrganizationStaffDirectoryScreen extends ConsumerStatefulWidget {
  const OrganizationStaffDirectoryScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  ConsumerState<OrganizationStaffDirectoryScreen> createState() =>
      _OrganizationStaffDirectoryScreenState();
}

class _OrganizationStaffDirectoryScreenState
    extends ConsumerState<OrganizationStaffDirectoryScreen> {
  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(organizationDetailsProvider(widget.orgId));
    final membersAsync = ref.watch(organizationMembersProvider(widget.orgId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/enterprise/directory'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      detailsAsync.maybeWhen(
                        data: (details) => Row(
                          children: [
                            Text(
                              details?.name ?? 'Organization Staff',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (details != null)
                              AppBadge(
                                label: details.type.label,
                                variant: AppBadgeVariant.primary,
                              ),
                          ],
                        ),
                        orElse: () => Text(
                          'Institutional Staff Governance',
                          style: LearnTzTypography.h2.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role-based staff directory, institutional permission management, and secure invitation engine.',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  key: const Key('invite-staff-member-btn'),
                  label: 'Invite Staff',
                  icon: Icons.person_add_alt_1_outlined,
                  size: AppButtonSize.md,
                  onPressed: () => _showInviteStaffDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Summary Metrics
            membersAsync.maybeWhen(
              data: (members) {
                final total = members.length;
                final admins = members
                    .where((m) =>
                        m.role == InstitutionalRole.institutionalAdmin ||
                        m.role == InstitutionalRole.schoolPrincipal)
                    .length;
                final educators = members
                    .where((m) =>
                        m.role == InstitutionalRole.teacher ||
                        m.role == InstitutionalRole.headOfDepartment)
                    .length;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'Total Staff',
                        value: '$total',
                        icon: Icons.group_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'Leadership',
                        value: '$admins',
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'Educators',
                        value: '$educators',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            Text(
              'Active Staff Members',
              style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Members Table / Card List
            membersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load members: $err'),
                  ),
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.group_off_outlined,
                              size: 48,
                              color: LearnTzColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No staff members registered yet.',
                              style: LearnTzTypography.h4,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Invite leadership and educators using the button above.',
                              style: LearnTzTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _buildMemberCard(context, member);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, InstitutionalMember member) {
    final roleBadgeVariant = switch (member.role) {
      InstitutionalRole.institutionalAdmin => AppBadgeVariant.primary,
      InstitutionalRole.schoolPrincipal => AppBadgeVariant.warning,
      InstitutionalRole.headOfDepartment => AppBadgeVariant.neutral,
      InstitutionalRole.teacher => AppBadgeVariant.success,
      _ => AppBadgeVariant.neutral,
    };

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: LearnTzColors.primary.withValues(alpha: 0.1),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: LearnTzColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.fullName,
                      style: LearnTzTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      label: member.role.label,
                      variant: roleBadgeVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (member.jobTitle != null && member.jobTitle!.isNotEmpty)
                      member.jobTitle,
                    if (member.department != null &&
                        member.department!.isNotEmpty)
                      member.department,
                    member.email,
                  ].join(' • '),
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'change_role') {
                _showChangeRoleDialog(context, member);
              } else if (val == 'remove') {
                _confirmRemoveMember(context, member);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_role',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Change Role'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined,
                        size: 18, color: LearnTzColors.error),
                    SizedBox(width: 8),
                    Text('Remove Member',
                        style: TextStyle(color: LearnTzColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInviteStaffDialog(BuildContext context) {
    final emailController = TextEditingController();
    final titleController = TextEditingController();
    final deptController = TextEditingController();
    InstitutionalRole selectedRole = InstitutionalRole.teacher;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Invite Institutional Staff',
            style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  key: const Key('invite-email-field'),
                  label: 'Staff Email Address',
                  hint: 'colleague@institution.ac.tz',
                  controller: emailController,
                ),
                const SizedBox(height: 14),
                Text(
                  'Assigned Institutional Role',
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LearnTzColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<InstitutionalRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: InstitutionalRole.values.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  key: const Key('invite-job-title-field'),
                  label: 'Official Job Title (Optional)',
                  hint: 'e.g. Senior Chemistry Instructor',
                  controller: titleController,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  key: const Key('invite-dept-field'),
                  label: 'Department / Unit (Optional)',
                  hint: 'e.g. Science & STEM Faculty',
                  controller: deptController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              key: const Key('confirm-invite-btn'),
              label: 'Send Invitation',
              size: AppButtonSize.sm,
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final repo = ref.read(organizationRepositoryProvider);
                try {
                  await repo.inviteOrganizationMember(
                    orgId: widget.orgId,
                    email: email,
                    role: selectedRole,
                    jobTitle: titleController.text.trim().isNotEmpty
                        ? titleController.text.trim()
                        : null,
                    department: deptController.text.trim().isNotEmpty
                        ? deptController.text.trim()
                        : null,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation dispatched to $email!'),
                        backgroundColor: LearnTzColors.success,
                      ),
                    );
                    ref.invalidate(organizationMembersProvider(widget.orgId));
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to invite: $err'),
                        backgroundColor: LearnTzColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, InstitutionalMember member) {
    InstitutionalRole newRole = member.role;
    final titleController = TextEditingController(text: member.jobTitle);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Role for ${member.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<InstitutionalRole>(
                initialValue: newRole,
                decoration: const InputDecoration(labelText: 'New Role'),
                items: InstitutionalRole.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => newRole = val);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Updated Job Title',
                controller: titleController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Update Role',
              size: AppButtonSize.sm,
              onPressed: () async {
                final repo = ref.read(organizationRepositoryProvider);
                try {
                  await repo.updateOrganizationMemberRole(
                    membershipId: member.membershipId,
                    newRole: newRole,
                    jobTitle: titleController.text.trim().isNotEmpty
                        ? titleController.text.trim()
                        : null,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ref.invalidate(organizationMembersProvider(widget.orgId));
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $err')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, InstitutionalMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text(
          'Are you sure you want to remove ${member.fullName} from this organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Remove',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () async {
              final repo = ref.read(organizationRepositoryProvider);
              try {
                await repo.removeOrganizationMember(member.membershipId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.invalidate(organizationMembersProvider(widget.orgId));
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $err')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
