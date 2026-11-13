import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/auth_screens.dart';
import 'admin_models.dart';
import 'admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final capabilities = ref.watch(adminCapabilitiesProvider);

    return capabilities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: AuthInlineMessage(message: error.toString(), isError: true),
      ),
      data: (value) => value.canAccessAdmin
          ? _AdminPortalContent(capabilities: value)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                child: Text(
                  l10n.adminAccessDenied,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
    );
  }
}

class _AdminPortalContent extends ConsumerStatefulWidget {
  const _AdminPortalContent({required this.capabilities});

  final AdminCapabilities capabilities;

  @override
  ConsumerState<_AdminPortalContent> createState() =>
      _AdminPortalContentState();
}

class _AdminPortalContentState extends ConsumerState<_AdminPortalContent> {
  final _auditFilterController = TextEditingController();
  String _auditFilter = '';
  String? _statusMessage;
  bool _isError = false;
  bool _isMutating = false;

  @override
  void dispose() {
    _auditFilterController.dispose();
    super.dispose();
  }

  Future<void> _resolveAccountRequest({
    required String userId,
    required String newStatus,
  }) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isMutating = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await repository.resolveAccountRequest(
        userId: userId,
        newStatus: newStatus,
      );
      ref.invalidate(adminAccountRequestsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider(_auditFilter));
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _statusMessage = l10n.adminRequestResolvedMessage;
        _isError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(adminCapabilitiesProvider);
    ref.invalidate(adminDashboardStatsProvider);
    if (widget.capabilities.canManageAccountRequests) {
      ref.invalidate(adminAccountRequestsProvider);
      ref.invalidate(adminAuditLogsProvider(_auditFilter));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = ref.watch(adminDashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminDashboardTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.adminDashboardSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.adminRefreshAction),
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                AuthInlineMessage(
                  message: _statusMessage!,
                  isError: _isError,
                ),
              ],
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminRolesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final assignment in widget.capabilities.roles)
                          AppBadge(
                            label: assignment.countryCode == null
                                ? assignment.role.toUpperCase()
                                : '${assignment.role.toUpperCase()} (${assignment.countryCode})',
                            variant: AppBadgeVariant.primary,
                            size: AppBadgeSize.md,
                          ),
                      ],
                    ),
                    if (widget.capabilities.isCurriculumStaff) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.curriculumAdmin),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l10n.adminOpenCurriculumAction),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              stats.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => AuthInlineMessage(
                  message: error.toString(),
                  isError: true,
                ),
                data: (data) => Wrap(
                  spacing: LearnTzSpacing.md,
                  runSpacing: LearnTzSpacing.md,
                  children: [
                    SizedBox(
                      width: 176,
                      child: AppStatCard(
                        label: l10n.adminMetricCountries,
                        value: data.enabledCountries.toString(),
                        icon: Icons.public,
                        iconColor: LearnTzColors.primary,
                        iconBackgroundColor: LearnTzColors.primary50,
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      child: AppStatCard(
                        label: l10n.adminMetricParents,
                        value: data.parentAccounts.toString(),
                        icon: Icons.people_outline,
                        iconColor: LearnTzColors.secondary,
                        iconBackgroundColor: LearnTzColors.secondary50,
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      child: AppStatCard(
                        label: l10n.adminMetricLearners,
                        value: data.activeLearners.toString(),
                        icon: Icons.school_outlined,
                        iconColor: LearnTzColors.accent,
                        iconBackgroundColor: LearnTzColors.accent50,
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      child: AppStatCard(
                        label: l10n.adminMetricAccountRequests,
                        value: data.pendingAccountRequests.toString(),
                        icon: Icons.pending_actions_outlined,
                        iconColor: LearnTzColors.warning,
                        iconBackgroundColor: LearnTzColors.warningBg,
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      child: AppStatCard(
                        label: l10n.adminMetricCurriculumImports,
                        value: data.pendingCurriculumImports.toString(),
                        icon: Icons.menu_book_outlined,
                        iconColor: LearnTzColors.primary,
                        iconBackgroundColor: LearnTzColors.primary50,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.capabilities.canManageAccountRequests) ...[
                const SizedBox(height: 24),
                _AccountRequestsSection(
                  isMutating: _isMutating,
                  onResolve: _resolveAccountRequest,
                ),
                const SizedBox(height: 24),
                _AuditLogsSection(
                  filterController: _auditFilterController,
                  actionFilter: _auditFilter,
                  onFilterSubmitted: (value) {
                    setState(() {
                      _auditFilter = value.trim();
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRequestsSection extends ConsumerWidget {
  const _AccountRequestsSection({
    required this.isMutating,
    required this.onResolve,
  });

  final bool isMutating;
  final Future<void> Function({
    required String userId,
    required String newStatus,
  })
  onResolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final requests = ref.watch(adminAccountRequestsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminAccountRequestsTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                AuthInlineMessage(message: error.toString(), isError: true),
            data: (items) {
              if (items.isEmpty) {
                return Text(l10n.adminNoAccountRequests);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.fullName.isEmpty ? item.userId : item.fullName,
                      ),
                      subtitle: Text(
                        [
                          item.status,
                          if (item.countryCode != null) item.countryCode!,
                          if (item.requestReason != null &&
                              item.requestReason!.isNotEmpty)
                            item.requestReason!,
                        ].join(' • '),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: isMutating
                                ? null
                                : () => onResolve(
                                    userId: item.userId,
                                    newStatus: 'active',
                                  ),
                            child: Text(l10n.adminApproveReactivateAction),
                          ),
                          if (item.status == 'pending_deactivation')
                            FilledButton.tonal(
                              onPressed: isMutating
                                  ? null
                                  : () => onResolve(
                                      userId: item.userId,
                                      newStatus: 'deactivated',
                                    ),
                              child: Text(l10n.adminConfirmDeactivateAction),
                            ),
                          if (item.status == 'pending_deletion')
                            FilledButton.tonal(
                              onPressed: isMutating
                                  ? null
                                  : () => onResolve(
                                      userId: item.userId,
                                      newStatus: 'deleted',
                                    ),
                              child: Text(l10n.adminConfirmDeleteAction),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AuditLogsSection extends ConsumerWidget {
  const _AuditLogsSection({
    required this.filterController,
    required this.actionFilter,
    required this.onFilterSubmitted,
  });

  final TextEditingController filterController;
  final String actionFilter;
  final ValueChanged<String> onFilterSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final logs = ref.watch(adminAuditLogsProvider(actionFilter));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminAuditLogsTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: filterController,
            decoration: InputDecoration(
              hintText: l10n.adminAuditFilterHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => onFilterSubmitted(filterController.text),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
            onSubmitted: onFilterSubmitted,
          ),
          const SizedBox(height: 12),
          logs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                AuthInlineMessage(message: error.toString(), isError: true),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(l10n.adminNoAuditLogs);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in entries) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${entry.action} (#${entry.id})'),
                      subtitle: Text(
                        '${entry.createdAt.toUtc().toIso8601String()} • '
                        'target=${entry.targetUserId ?? '-'} • '
                        '${entry.metadata}',
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
