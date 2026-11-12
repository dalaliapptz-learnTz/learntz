import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import 'billing_models.dart';
import 'billing_providers.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String _selectedProvider = 'mpesa_tz';
  final _phoneController = TextEditingController();
  MobileMoneyCheckoutResult? _lastCheckout;
  String? _statusMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startCheckout(SubscriptionPlan plan) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      final repo = ref.read(billingRepositoryProvider);
      if (repo == null) return;
      final res = await repo.startCheckout(
        planId: plan.id,
        provider: _selectedProvider,
        msisdn: _phoneController.text,
      );
      ref.invalidate(parentSubscriptionsProvider);
      ref.invalidate(parentTransactionsProvider);
      if (mounted) {
        setState(() => _lastCheckout = res);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _cancelSubscription(String subscriptionId) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      final repo = ref.read(billingRepositoryProvider);
      if (repo == null) return;
      await repo.cancelSubscription(subscriptionId);
      ref.invalidate(parentSubscriptionsProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final subsAsync = ref.watch(parentSubscriptionsProvider);
    final txAsync = ref.watch(parentTransactionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.accountTitle),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subscriptionsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subscriptionsSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                AuthInlineMessage(message: _statusMessage!, isError: true),
              ],
              if (_lastCheckout != null) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.checkoutPendingTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.checkoutPendingDescription(
                          _lastCheckout!.reference,
                          _lastCheckout!.provider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mobileMoneyGatewayLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvider,
                      decoration: InputDecoration(
                        labelText: l10n.mobileMoneyProviderField,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'mpesa_tz',
                          child: Text('M-Pesa (Vodacom Tanzania)'),
                        ),
                        DropdownMenuItem(
                          value: 'mpesa_ke',
                          child: Text('M-Pesa (Safaricom Kenya)'),
                        ),
                        DropdownMenuItem(
                          value: 'airtel_money',
                          child: Text('Airtel Money'),
                        ),
                        DropdownMenuItem(
                          value: 'tigo_pesa',
                          child: Text('Tigo Pesa'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedProvider = val);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.mobilePhoneNumberLabel,
                        hintText: '+255712345678',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.availablePlansTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              plansAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) =>
                    AuthInlineMessage(message: l10n.requestFailed, isError: true),
                data: (plans) => Column(
                  children: [
                    for (final plan in plans) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                Chip(label: Text(plan.formattedPrice)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final feature in plan.features)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $feature'),
                              ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _startCheckout(plan),
                              icon: const Icon(Icons.payments_outlined),
                              label: Text(l10n.subscribeWithMobileMoneyAction),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.currentSubscriptionsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              subsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) =>
                    AuthInlineMessage(message: l10n.requestFailed, isError: true),
                data: (subs) => subs.isEmpty
                    ? AppCard(child: Text(l10n.noSubscriptionsYet))
                    : Column(
                        children: [
                          for (final sub in subs) ...[
                            AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${l10n.curriculumStatusLabel}: ${sub.status}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        if (sub.currentPeriodEnd != null)
                                          Text(
                                            'Ends: ${sub.currentPeriodEnd!.toIso8601String().split('T').first}',
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (sub.status == 'active' ||
                                      sub.status == 'pending_payment')
                                    OutlinedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _cancelSubscription(sub.id),
                                      child: Text(l10n.cancelSubscriptionAction),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.paymentHistoryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              txAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) =>
                    AuthInlineMessage(message: l10n.requestFailed, isError: true),
                data: (txs) => txs.isEmpty
                    ? AppCard(child: Text(l10n.noPaymentTransactions))
                    : Column(
                        children: [
                          for (final tx in txs) ...[
                            AppCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${tx.reference} — ${tx.formattedAmount}',
                                ),
                                subtitle: Text('${tx.provider} • ${tx.status}'),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
