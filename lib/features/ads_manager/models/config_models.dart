/// ============================================================
/// Ads Manager V2 — Ads Config Model
/// ============================================================
/// Admin-controlled UI configuration from /campaigns-v2/config.
/// Mirrors the useAdsConfig() hook in qp-web.
/// ============================================================

class AdsManagerConfig {
  // Objectives available for campaign creation
  final List<String> objectives;

  // Ad formats enabled
  final List<String> adFormats;

  // Placements available
  final List<String> placements;

  // CTA options
  final List<CtaOption> ctaOptions;

  // Budget presets (for boost)
  final List<BudgetPreset> boostBudgetPresets;

  // Duration presets (for boost)
  final List<DurationPreset> durationPresets;

  // Targeting defaults
  final TargetingDefaults targetingDefaults;

  // Feature flags
  final FeatureFlags featureFlags;

  // Reach estimate multiplier
  final int reachEstimateMultiplier;

  const AdsManagerConfig({
    this.objectives = const [],
    this.adFormats = const [],
    this.placements = const [],
    this.ctaOptions = const [],
    this.boostBudgetPresets = const [],
    this.durationPresets = const [],
    this.targetingDefaults = const TargetingDefaults(),
    this.featureFlags = const FeatureFlags(),
    this.reachEstimateMultiplier = 120,
  });

  factory AdsManagerConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdsManagerConfig();
    final data = json['data'] ?? json;
    return AdsManagerConfig(
      objectives: List<String>.from(data['objectives'] ?? []),
      adFormats: List<String>.from(data['ad_formats'] ?? []),
      placements: List<String>.from(data['placements'] ?? []),
      ctaOptions: (data['cta_options'] as List?)
              ?.map((e) => CtaOption.fromJson(e))
              .toList() ??
          [],
      boostBudgetPresets: (data['boost_budget_presets'] as List?)
              ?.map((e) => BudgetPreset.fromJson(e))
              .toList() ??
          [],
      durationPresets: (data['duration_presets'] as List?)
              ?.map((e) => DurationPreset.fromJson(e))
              .toList() ??
          [],
      targetingDefaults:
          TargetingDefaults.fromJson(data['targeting_defaults']),
      featureFlags: FeatureFlags.fromJson(data['feature_flags']),
      reachEstimateMultiplier:
          data['reach_estimate_multiplier'] ?? 120,
    );
  }

  /// Static fallback matching constants.js in qp-web
  static const AdsManagerConfig fallback = AdsManagerConfig(
    objectives: [
      'Awareness',
      'Traffic',
      'Engagement',
      'Leads',
      'Sales',
      'Reach',
    ],
    adFormats: [
      'Single_Image',
      'Video',
      'Carousel',
      'Story',
      'Reels',
    ],
    placements: [
      'Feeds',
      'Stories',
      'Reels',
      'Search',
      'VideoFeeds',
    ],
    ctaOptions: [
      CtaOption(value: 'Learn_More', label: 'Learn More'),
      CtaOption(value: 'Shop_Now', label: 'Shop Now'),
      CtaOption(value: 'Sign_Up', label: 'Sign Up'),
      CtaOption(value: 'Contact_Us', label: 'Contact Us'),
      CtaOption(value: 'Book_Now', label: 'Book Now'),
      CtaOption(value: 'Watch_More', label: 'Watch More'),
      CtaOption(value: 'Send_Message', label: 'Send Message'),
      CtaOption(value: 'Get_Quote', label: 'Get Quote'),
    ],
    boostBudgetPresets: [
      BudgetPreset(cents: 200, label: '€2/day'),
      BudgetPreset(cents: 500, label: '€5/day'),
      BudgetPreset(cents: 1000, label: '€10/day'),
      BudgetPreset(cents: 2000, label: '€20/day'),
    ],
    durationPresets: [
      DurationPreset(days: 3, label: '3 days'),
      DurationPreset(days: 7, label: '7 days'),
      DurationPreset(days: 14, label: '14 days'),
      DurationPreset(days: 30, label: '30 days'),
    ],
    targetingDefaults: TargetingDefaults(),
    featureFlags: FeatureFlags(),
    reachEstimateMultiplier: 120,
  );
}

class CtaOption {
  final String value;
  final String label;

  const CtaOption({required this.value, required this.label});

  factory CtaOption.fromJson(Map<String, dynamic> json) {
    return CtaOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class BudgetPreset {
  final int cents;
  final String label;

  const BudgetPreset({required this.cents, required this.label});

  factory BudgetPreset.fromJson(Map<String, dynamic> json) {
    return BudgetPreset(
      cents: json['cents'] ?? 0,
      label: json['label'] ?? '',
    );
  }
}

class DurationPreset {
  final int days;
  final String label;

  const DurationPreset({required this.days, required this.label});

  factory DurationPreset.fromJson(Map<String, dynamic> json) {
    return DurationPreset(
      days: json['days'] ?? 0,
      label: json['label'] ?? '',
    );
  }
}

class TargetingDefaults {
  final int defaultAgeMin;
  final int defaultAgeMax;

  const TargetingDefaults({
    this.defaultAgeMin = 18,
    this.defaultAgeMax = 65,
  });

  factory TargetingDefaults.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TargetingDefaults();
    return TargetingDefaults(
      defaultAgeMin: json['default_age_min'] ?? 18,
      defaultAgeMax: json['default_age_max'] ?? 65,
    );
  }
}

class FeatureFlags {
  final bool boostPostEnabled;
  final bool promotePageEnabled;
  final bool leadFormsEnabled;
  final bool abTestingEnabled;

  const FeatureFlags({
    this.boostPostEnabled = true,
    this.promotePageEnabled = true,
    this.leadFormsEnabled = false,
    this.abTestingEnabled = false,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeatureFlags();
    return FeatureFlags(
      boostPostEnabled: json['boost_post_enabled'] ?? true,
      promotePageEnabled: json['promote_page_enabled'] ?? true,
      leadFormsEnabled: json['lead_forms_enabled'] ?? false,
      abTestingEnabled: json['ab_testing_enabled'] ?? false,
    );
  }
}
