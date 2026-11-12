import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import 'billing_models.dart';
import 'billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : BillingRepository(client);
});

final subscriptionPlansProvider = FutureProvider.autoDispose<List<SubscriptionPlan>>((
  ref,
) async {
  final countryCode = ref.watch(selectedCountryProvider).countryCode;
  final repository = ref.watch(billingRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.listActivePlans(countryCode: countryCode);
});

final parentSubscriptionsProvider =
    FutureProvider.autoDispose<List<ParentSubscription>>((ref) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(billingRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listMySubscriptions();
    });

final parentTransactionsProvider =
    FutureProvider.autoDispose<List<PaymentTransaction>>((ref) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(billingRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listMyTransactions();
    });
