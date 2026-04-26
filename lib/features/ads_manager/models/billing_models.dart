/// ============================================================
/// Ads Manager V2 — Billing & Payment Models
/// ============================================================
/// Mirror of AdAccount + billing endpoint responses.
/// ============================================================

class PaymentMethod {
  final bool hasPaymentMethod;
  final String? paymentType; // "stripe" | "wallet" | null
  final String? brand; // Visa, Mastercard, etc.
  final String? last4;
  final int? expMonth;
  final int? expYear;
  final double? walletBalance; // EUR float — NOT cents

  const PaymentMethod({
    this.hasPaymentMethod = false,
    this.paymentType,
    this.brand,
    this.last4,
    this.expMonth,
    this.expYear,
    this.walletBalance,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PaymentMethod();
    final data = json['data'] ?? json;
    return PaymentMethod(
      hasPaymentMethod: data['has_payment_method'] ?? false,
      paymentType: data['payment_type'],
      brand: data['brand'] ?? data['payment_method_brand'],
      last4: data['last4'] ?? data['payment_method_last4'],
      expMonth: data['exp_month'] ?? data['payment_method_exp_month'],
      expYear: data['exp_year'] ?? data['payment_method_exp_year'],
      walletBalance: (data['wallet_balance'] as num?)?.toDouble(),
    );
  }

  String get displayName {
    if (!hasPaymentMethod) return 'Not set';
    if (paymentType == 'wallet') return 'QP Wallet';
    if (brand != null && last4 != null) return '$brand ••$last4';
    return 'Card';
  }
}

class BillingStatus {
  final String state; // Active | Grace_Period | Disabled | Settled
  final int unbilledSpendCents;
  final int thresholdCents;
  final int lifetimeSpendCents;
  final String currency;
  final bool onboardingCompleted;

  const BillingStatus({
    this.state = 'Active',
    this.unbilledSpendCents = 0,
    this.thresholdCents = 2500,
    this.lifetimeSpendCents = 0,
    this.currency = 'eur',
    this.onboardingCompleted = false,
  });

  factory BillingStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BillingStatus();
    final data = json['data'] ?? json;
    return BillingStatus(
      state: data['state'] ?? 'Active',
      unbilledSpendCents: data['current_unbilled_spend_cents'] ?? 0,
      thresholdCents: data['billing_threshold_cents'] ?? 2500,
      lifetimeSpendCents: data['lifetime_spend_cents'] ?? 0,
      currency: data['currency'] ?? 'eur',
      onboardingCompleted: data['onboarding_completed'] ?? false,
    );
  }
}

class CostOverview {
  final int totalSpentCents;
  final int impressions;
  final int clicks;
  final double ctr;
  final int cpcCents;
  final int cpmCents;

  const CostOverview({
    this.totalSpentCents = 0,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0,
    this.cpcCents = 0,
    this.cpmCents = 0,
  });

  factory CostOverview.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CostOverview();
    return CostOverview(
      totalSpentCents: json['total_spent_cents'] ?? 0,
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0,
      cpcCents: json['cpc_cents'] ?? 0,
      cpmCents: json['cpm_cents'] ?? 0,
    );
  }
}

class DailySpend {
  final String date;
  final int costCents;
  final int impressions;
  final int clicks;

  const DailySpend({
    required this.date,
    this.costCents = 0,
    this.impressions = 0,
    this.clicks = 0,
  });

  factory DailySpend.fromJson(Map<String, dynamic> json) {
    return DailySpend(
      date: json['date'] ?? json['_id'] ?? '',
      costCents: json['cost_cents'] ?? 0,
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
    );
  }
}

class CampaignBreakdown {
  final String id;
  final String name;
  final String? objective;
  final String status;
  final int totalSpentCents;
  final int impressions;
  final int clicks;
  final double budgetUtilizationPct;

  const CampaignBreakdown({
    required this.id,
    required this.name,
    this.objective,
    this.status = 'Draft',
    this.totalSpentCents = 0,
    this.impressions = 0,
    this.clicks = 0,
    this.budgetUtilizationPct = 0,
  });

  factory CampaignBreakdown.fromJson(Map<String, dynamic> json) {
    return CampaignBreakdown(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      objective: json['objective'],
      status: json['status'] ?? 'Draft',
      totalSpentCents: json['total_spent_cents'] ?? 0,
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      budgetUtilizationPct:
          (json['budget_utilization_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CostBreakdownResponse {
  final CostOverview overview;
  final List<DailySpend> dailySpend;
  final List<CampaignBreakdown> campaigns;
  final Map<String, dynamic> accountSummary;

  const CostBreakdownResponse({
    this.overview = const CostOverview(),
    this.dailySpend = const [],
    this.campaigns = const [],
    this.accountSummary = const {},
  });

  factory CostBreakdownResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CostBreakdownResponse();
    final data = json['data'] ?? json;
    return CostBreakdownResponse(
      overview: CostOverview.fromJson(data['overview']),
      dailySpend: (data['daily_spend'] as List?)
              ?.map((e) => DailySpend.fromJson(e))
              .toList() ??
          [],
      campaigns: (data['campaigns'] as List?)
              ?.map((e) => CampaignBreakdown.fromJson(e))
              .toList() ??
          [],
      accountSummary:
          Map<String, dynamic>.from(data['account_summary'] ?? {}),
    );
  }
}

class BillingCycle {
  final String id;
  final String period;
  final int totalChargedCents;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? chargedAt;

  const BillingCycle({
    required this.id,
    this.period = '',
    this.totalChargedCents = 0,
    this.status = 'pending',
    this.startDate,
    this.endDate,
    this.chargedAt,
  });

  factory BillingCycle.fromJson(Map<String, dynamic> json) {
    return BillingCycle(
      id: json['_id'] ?? json['id'] ?? '',
      period: json['period'] ?? '',
      totalChargedCents: json['total_charged_cents'] ?? 0,
      status: json['status'] ?? 'pending',
      startDate: DateTime.tryParse(json['start_date'] ?? ''),
      endDate: DateTime.tryParse(json['end_date'] ?? ''),
      chargedAt: DateTime.tryParse(json['charged_at'] ?? ''),
    );
  }
}
