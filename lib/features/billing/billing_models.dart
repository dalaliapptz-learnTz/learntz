class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.countryCode,
    required this.code,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.billingInterval,
    required this.features,
    required this.isActive,
  });

  final String id;
  final String countryCode;
  final String code;
  final String name;
  final int priceCents;
  final String currency;
  final String billingInterval;
  final List<String> features;
  final bool isActive;

  String get formattedPrice {
    final major = (priceCents / 100).round();
    return '$currency $major';
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as List<dynamic>? ?? const [];
    return SubscriptionPlan(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String,
      billingInterval: json['billing_interval'] as String,
      features: rawFeatures.map((item) => item.toString()).toList(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ParentSubscription {
  const ParentSubscription({
    required this.id,
    required this.parentUserId,
    required this.planId,
    required this.status,
    required this.autoRenew,
    this.currentPeriodStart,
    this.currentPeriodEnd,
  });

  final String id;
  final String parentUserId;
  final String planId;
  final String status;
  final bool autoRenew;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  bool get isActive => status == 'active';

  factory ParentSubscription.fromJson(Map<String, dynamic> json) {
    return ParentSubscription(
      id: json['id'] as String,
      parentUserId: json['parent_user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String,
      autoRenew: json['auto_renew'] as bool? ?? false,
      currentPeriodStart: json['current_period_start'] == null
          ? null
          : DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
    );
  }
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.subscriptionId,
    required this.provider,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    this.msisdn,
    this.createdAt,
  });

  final String id;
  final String subscriptionId;
  final String provider;
  final String reference;
  final int amount;
  final String currency;
  final String status;
  final String? msisdn;
  final DateTime? createdAt;

  String get formattedAmount => '$currency ${(amount / 100).round()}';

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      provider: json['provider'] as String,
      reference: json['reference'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      msisdn: json['msisdn'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

class MobileMoneyCheckoutResult {
  const MobileMoneyCheckoutResult({
    required this.subscriptionId,
    required this.transactionId,
    required this.reference,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.subscriptionStatus,
    required this.planName,
    required this.billingInterval,
  });

  final String subscriptionId;
  final String transactionId;
  final String reference;
  final String provider;
  final int amount;
  final String currency;
  final String status;
  final String subscriptionStatus;
  final String planName;
  final String billingInterval;

  factory MobileMoneyCheckoutResult.fromJson(Map<String, dynamic> json) {
    return MobileMoneyCheckoutResult(
      subscriptionId: json['subscription_id'] as String,
      transactionId: json['transaction_id'] as String,
      reference: json['reference'] as String,
      provider: json['provider'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      planName: json['plan_name'] as String,
      billingInterval: json['billing_interval'] as String,
    );
  }
}
