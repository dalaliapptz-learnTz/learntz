import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import 'billing_models.dart';

class BillingRepository {
  const BillingRepository(this._client);

  final SupabaseClient _client;

  Future<List<SubscriptionPlan>> listActivePlans({String? countryCode}) async {
    var query = _client
        .from('subscription_plans')
        .select(
          'id, country_code, code, name, price_cents, currency, '
          'billing_interval, features, is_active',
        )
        .eq('is_active', true);

    if (countryCode != null && countryCode.trim().isNotEmpty) {
      query = query.eq('country_code', countryCode.trim().toUpperCase());
    }

    final rows = await query.order('price_cents', ascending: true);
    return (rows as List<dynamic>)
        .map((row) => SubscriptionPlan.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParentSubscription>> listMySubscriptions() async {
    _requireUser();
    final rows = await _client
        .from('parent_subscriptions')
        .select(
          'id, parent_user_id, plan_id, status, current_period_start, '
          'current_period_end, auto_renew',
        )
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((row) => ParentSubscription.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentTransaction>> listMyTransactions() async {
    _requireUser();
    final rows = await _client
        .from('payment_transactions')
        .select(
          'id, subscription_id, provider, reference, amount, currency, '
          'status, msisdn, created_at',
        )
        .order('created_at', ascending: false)
        .limit(25);
    return (rows as List<dynamic>)
        .map((row) => PaymentTransaction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MobileMoneyCheckoutResult> startCheckout({
    required String planId,
    required String provider,
    String? msisdn,
  }) async {
    _requireUser();
    final trimmedPhone = msisdn?.trim();
    final result = await _client.rpc(
      'start_parent_subscription_checkout',
      params: {
        'p_plan_id': planId,
        'p_provider': provider,
        'p_msisdn': (trimmedPhone == null || trimmedPhone.isEmpty)
            ? null
            : trimmedPhone,
      },
    );
    return MobileMoneyCheckoutResult.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<ParentSubscription> cancelSubscription(String subscriptionId) async {
    _requireUser();
    final result = await _client.rpc(
      'cancel_parent_subscription',
      params: {'p_subscription_id': subscriptionId},
    );
    return ParentSubscription.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotSignedInException();
    }
    return user;
  }
}
