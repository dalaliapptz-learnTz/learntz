import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class EnterpriseSupportScreen extends ConsumerStatefulWidget {
  const EnterpriseSupportScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  ConsumerState<EnterpriseSupportScreen> createState() =>
      _EnterpriseSupportScreenState();
}

class _EnterpriseSupportScreenState
    extends ConsumerState<EnterpriseSupportScreen> {
  void _openCreateTicketDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedCategory = 'curriculum_import';
    var selectedPriority = 'normal';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Open Enterprise Support Ticket',
            style: LearnTzTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: LearnTzColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject',
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('ticket-subject-field'),
                    controller: subjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Form 4 Physics curriculum sync failure',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: LearnTzTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedCategory,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'curriculum_import',
                                  child: Text('Curriculum Import'),
                                ),
                                DropdownMenuItem(
                                  value: 'technical_integration',
                                  child: Text('Technical Integration'),
                                ),
                                DropdownMenuItem(
                                  value: 'billing',
                                  child: Text('Billing & Invoicing'),
                                ),
                                DropdownMenuItem(
                                  value: 'account_access',
                                  child: Text('Staff Access / SSO'),
                                ),
                                DropdownMenuItem(
                                  value: 'data_export',
                                  child: Text('Data Export & Research'),
                                ),
                                DropdownMenuItem(
                                  value: 'sla_escalation',
                                  child: Text('SLA Escalation'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedCategory = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: LearnTzTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedPriority,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text('Low (48h SLA)'),
                                ),
                                DropdownMenuItem(
                                  value: 'normal',
                                  child: Text('Normal (24h SLA)'),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('High (4h SLA)'),
                                ),
                                DropdownMenuItem(
                                  value: 'urgent',
                                  child: Text('Urgent (1h SLA)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedPriority = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description & Details',
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('ticket-desc-field'),
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Describe the issue, affected users, and steps to reproduce...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              key: const Key('confirm-create-ticket-btn'),
              label: 'Submit Ticket',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.sm,
              onPressed: () async {
                final subject = subjectController.text.trim();
                final desc = descriptionController.text.trim();
                if (subject.isEmpty || desc.isEmpty) return;

                final repo = ref.read(organizationRepositoryProvider);
                try {
                  await repo.createOrganizationSupportTicket(
                    orgId: widget.orgId,
                    subject: subject,
                    description: desc,
                    category: selectedCategory,
                    priority: selectedPriority,
                  );

                  ref.invalidate(
                      organizationSupportTicketsProvider(widget.orgId));
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support ticket created successfully'),
                        backgroundColor: LearnTzColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open ticket: $e'),
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

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(organizationDetailsProvider(widget.orgId));
    final subAsync =
        ref.watch(organizationSubscriptionStatusProvider(widget.orgId));
    final ticketsAsync =
        ref.watch(organizationSupportTicketsProvider(widget.orgId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Breadcrumb
            Row(
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          detailsAsync.maybeWhen(
                            data: (d) => Text(
                              d?.name ?? 'Enterprise Support',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Enterprise SLA Support Desk',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          subAsync.maybeWhen(
                            data: (s) => AppBadge(
                              label: 'SLA: ${s.slaResponseHours}h Guaranteed',
                              variant: s.slaResponseHours <= 4
                                  ? AppBadgeVariant.success
                                  : AppBadgeVariant.primary,
                            ),
                            orElse: () => const AppBadge(
                              label: 'SLA Support',
                              variant: AppBadgeVariant.neutral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct Technical Engineering Support, Data Migration & Enterprise Escalations',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  key: const Key('open-new-ticket-btn'),
                  label: 'Open New Ticket',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.md,
                  icon: Icons.add_circle_outline,
                  onPressed: () => _openCreateTicketDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tickets List Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Institutional Support Tickets',
                        style: LearnTzTypography.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LearnTzColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Tickets',
                        onPressed: () => ref.invalidate(
                            organizationSupportTicketsProvider(widget.orgId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ticketsAsync.when(
                    data: (tickets) {
                      if (tickets.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF15803D),
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active support tickets.',
                                  style: LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your institutional account and integrations are fully operational.',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tickets.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getPriorityColor(ticket.priority)
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                _getCategoryIcon(ticket.category),
                                color: _getPriorityColor(ticket.priority),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  ticket.ticketNumber,
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: LearnTzColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ticket.subject,
                                    style: LearnTzTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Priority: ${ticket.priority.toUpperCase()} • Category: ${ticket.category} • Messages: ${ticket.messageCount}',
                                style: LearnTzTypography.bodySmall.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppBadge(
                                  label: ticket.status.toUpperCase(),
                                  variant: ticket.status == 'resolved'
                                      ? AppBadgeVariant.success
                                      : AppBadgeVariant.warning,
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: LearnTzColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: LearnTzColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load support tickets: $err',
                              style: LearnTzTypography.bodyLarge.copyWith(
                                color: LearnTzColors.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Retry',
                              variant: AppButtonVariant.outlined,
                              size: AppButtonSize.md,
                              onPressed: () => ref.invalidate(
                                  organizationSupportTicketsProvider(
                                      widget.orgId)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return LearnTzColors.error;
      case 'high':
        return const Color(0xFFEA580C);
      case 'normal':
        return LearnTzColors.primary;
      case 'low':
      default:
        return LearnTzColors.neutral500;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'curriculum_import':
        return Icons.auto_stories_outlined;
      case 'billing':
        return Icons.receipt_long_outlined;
      case 'account_access':
        return Icons.lock_open_outlined;
      case 'sla_escalation':
        return Icons.priority_high_outlined;
      case 'data_export':
        return Icons.cloud_download_outlined;
      case 'technical_integration':
      default:
        return Icons.integration_instructions_outlined;
    }
  }
}
