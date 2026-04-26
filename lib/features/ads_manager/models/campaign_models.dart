/// ============================================================
/// Ads Manager V2 — Campaign / AdSet / Ad Models
/// ============================================================
/// Mirror of the backend Mongoose schemas in
/// qp-api/models/CampaignV2/
///
/// All monetary values are INTEGER CENTS.
/// ============================================================

// ── Enums ────────────────────────────────────────────────────

enum CampaignObjective {
  awareness,
  traffic,
  engagement,
  leads,
  appPromotion,
  sales,
  reach,
  leadGeneration,
  messages,
  catalogSales,
  storeTraffic;

  String get apiValue {
    switch (this) {
      case CampaignObjective.awareness:
        return 'Awareness';
      case CampaignObjective.traffic:
        return 'Traffic';
      case CampaignObjective.engagement:
        return 'Engagement';
      case CampaignObjective.leads:
        return 'Leads';
      case CampaignObjective.appPromotion:
        return 'App_Promotion';
      case CampaignObjective.sales:
        return 'Sales';
      case CampaignObjective.reach:
        return 'Reach';
      case CampaignObjective.leadGeneration:
        return 'Lead_Generation';
      case CampaignObjective.messages:
        return 'Messages';
      case CampaignObjective.catalogSales:
        return 'Catalog_Sales';
      case CampaignObjective.storeTraffic:
        return 'Store_Traffic';
    }
  }

  String get label {
    switch (this) {
      case CampaignObjective.awareness:
        return 'Awareness';
      case CampaignObjective.traffic:
        return 'Traffic';
      case CampaignObjective.engagement:
        return 'Engagement';
      case CampaignObjective.leads:
        return 'Leads';
      case CampaignObjective.appPromotion:
        return 'App Installs';
      case CampaignObjective.sales:
        return 'Sales';
      case CampaignObjective.reach:
        return 'Reach';
      case CampaignObjective.leadGeneration:
        return 'Lead Generation';
      case CampaignObjective.messages:
        return 'Messages';
      case CampaignObjective.catalogSales:
        return 'Catalog Sales';
      case CampaignObjective.storeTraffic:
        return 'Store Traffic';
    }
  }

  static CampaignObjective fromApi(String? v) {
    for (final o in values) {
      if (o.apiValue == v) return o;
    }
    return CampaignObjective.awareness;
  }
}

enum CampaignStatus {
  draft,
  paused,
  active,
  completed,
  archived,
  rejected;

  String get apiValue => name[0].toUpperCase() + name.substring(1);

  static CampaignStatus fromApi(String? v) {
    for (final s in values) {
      if (s.apiValue == v) return s;
    }
    return CampaignStatus.draft;
  }
}

enum AdminStatus {
  pending,
  active,
  inactive,
  reject;

  static AdminStatus fromApi(String? v) {
    for (final s in values) {
      if (s.name == v) return s;
    }
    return AdminStatus.pending;
  }
}

enum BudgetType {
  daily,
  lifetime;

  String get apiValue => name[0].toUpperCase() + name.substring(1);

  static BudgetType fromApi(String? v) {
    if (v == 'Lifetime') return BudgetType.lifetime;
    return BudgetType.daily;
  }
}

enum PlacementType {
  automatic,
  manual;

  String get apiValue => name[0].toUpperCase() + name.substring(1);

  static PlacementType fromApi(String? v) {
    if (v == 'Manual') return PlacementType.manual;
    return PlacementType.automatic;
  }
}

enum AdFormat {
  singleImage,
  video,
  carousel,
  collection,
  story,
  reels,
  slideshow;

  String get apiValue {
    switch (this) {
      case AdFormat.singleImage:
        return 'Single_Image';
      case AdFormat.video:
        return 'Video';
      case AdFormat.carousel:
        return 'Carousel';
      case AdFormat.collection:
        return 'Collection';
      case AdFormat.story:
        return 'Story';
      case AdFormat.reels:
        return 'Reels';
      case AdFormat.slideshow:
        return 'Slideshow';
    }
  }

  String get label {
    switch (this) {
      case AdFormat.singleImage:
        return 'Single Image';
      case AdFormat.video:
        return 'Video';
      case AdFormat.carousel:
        return 'Carousel';
      case AdFormat.collection:
        return 'Collection';
      case AdFormat.story:
        return 'Story';
      case AdFormat.reels:
        return 'Reels';
      case AdFormat.slideshow:
        return 'Slideshow';
    }
  }

  static AdFormat fromApi(String? v) {
    for (final f in values) {
      if (f.apiValue == v) return f;
    }
    return AdFormat.singleImage;
  }
}

// ── Sub-models ───────────────────────────────────────────────

class AudienceLocation {
  final String type; // Country | Region | City
  final String? key;
  final String? name;
  final bool include;

  const AudienceLocation({
    this.type = 'Country',
    this.key,
    this.name,
    this.include = true,
  });

  factory AudienceLocation.fromJson(Map<String, dynamic> json) {
    return AudienceLocation(
      type: json['type'] ?? 'Country',
      key: json['key'],
      name: json['name'],
      include: json['include'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'key': key,
        'name': name,
        'include': include,
      };
}

class AudienceDemographics {
  final int ageMin;
  final int ageMax;
  final List<String> genders;
  final List<String> languages;

  const AudienceDemographics({
    this.ageMin = 18,
    this.ageMax = 65,
    this.genders = const ['All'],
    this.languages = const [],
  });

  factory AudienceDemographics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AudienceDemographics();
    return AudienceDemographics(
      ageMin: json['age_min'] ?? 18,
      ageMax: json['age_max'] ?? 65,
      genders: List<String>.from(json['genders'] ?? ['All']),
      languages: List<String>.from(json['languages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'age_min': ageMin,
        'age_max': ageMax,
        'genders': genders,
        'languages': languages,
      };
}

class DetailedTargetingItem {
  final String type; // Interest | Behavior | Demographic
  final String? id;
  final String? name;

  const DetailedTargetingItem({
    this.type = 'Interest',
    this.id,
    this.name,
  });

  factory DetailedTargetingItem.fromJson(Map<String, dynamic> json) {
    return DetailedTargetingItem(
      type: json['type'] ?? 'Interest',
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
      };
}

class Audience {
  final List<AudienceLocation> locations;
  final AudienceDemographics demographics;
  final List<DetailedTargetingItem> includeTargeting;
  final List<DetailedTargetingItem> excludeTargeting;

  const Audience({
    this.locations = const [],
    this.demographics = const AudienceDemographics(),
    this.includeTargeting = const [],
    this.excludeTargeting = const [],
  });

  factory Audience.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Audience();
    return Audience(
      locations: (json['locations'] as List?)
              ?.map((e) => AudienceLocation.fromJson(e))
              .toList() ??
          [],
      demographics: AudienceDemographics.fromJson(json['demographics']),
      includeTargeting:
          (json['detailed_targeting']?['include'] as List?)
                  ?.map((e) => DetailedTargetingItem.fromJson(e))
                  .toList() ??
              [],
      excludeTargeting:
          (json['detailed_targeting']?['exclude'] as List?)
                  ?.map((e) => DetailedTargetingItem.fromJson(e))
                  .toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() => {
        'locations': locations.map((l) => l.toJson()).toList(),
        'demographics': demographics.toJson(),
        'detailed_targeting': {
          'include': includeTargeting.map((t) => t.toJson()).toList(),
          'exclude': excludeTargeting.map((t) => t.toJson()).toList(),
        },
      };
}

class AdCreative {
  final String? primaryText;
  final String? headline;
  final String? description;
  final String? mediaUrl;
  final String? mediaType; // image | video
  final String? thumbnailUrl;
  final List<CarouselCard> carouselCards;

  const AdCreative({
    this.primaryText,
    this.headline,
    this.description,
    this.mediaUrl,
    this.mediaType,
    this.thumbnailUrl,
    this.carouselCards = const [],
  });

  factory AdCreative.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdCreative();
    return AdCreative(
      primaryText: json['primary_text'],
      headline: json['headline'],
      description: json['description'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      thumbnailUrl: json['thumbnail_url'],
      carouselCards: (json['carousel_cards'] as List?)
              ?.map((e) => CarouselCard.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (primaryText != null) 'primary_text': primaryText,
        if (headline != null) 'headline': headline,
        if (description != null) 'description': description,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (mediaType != null) 'media_type': mediaType,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (carouselCards.isNotEmpty)
          'carousel_cards': carouselCards.map((c) => c.toJson()).toList(),
      };
}

class CarouselCard {
  final String mediaUrl;
  final String mediaType;
  final String? headline;
  final String? description;
  final String? websiteUrl;

  const CarouselCard({
    required this.mediaUrl,
    this.mediaType = 'image',
    this.headline,
    this.description,
    this.websiteUrl,
  });

  factory CarouselCard.fromJson(Map<String, dynamic> json) {
    return CarouselCard(
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      headline: json['headline'],
      description: json['description'],
      websiteUrl: json['website_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'media_url': mediaUrl,
        'media_type': mediaType,
        if (headline != null) 'headline': headline,
        if (description != null) 'description': description,
        if (websiteUrl != null) 'website_url': websiteUrl,
      };
}

class AdDestination {
  final String type; // Website | App_Store | Phone | None
  final String? websiteUrl;
  final String? appStoreUrl;
  final String? deepLink;
  final String? phoneNumber;

  const AdDestination({
    this.type = 'Website',
    this.websiteUrl,
    this.appStoreUrl,
    this.deepLink,
    this.phoneNumber,
  });

  factory AdDestination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdDestination();
    return AdDestination(
      type: json['type'] ?? 'Website',
      websiteUrl: json['website_url'],
      appStoreUrl: json['app_store_url'],
      deepLink: json['deep_link'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (appStoreUrl != null) 'app_store_url': appStoreUrl,
        if (deepLink != null) 'deep_link': deepLink,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };
}

// ── Main Models ──────────────────────────────────────────────

class AdCampaign {
  final String id;
  final String? userId;
  final String name;
  final CampaignObjective objective;
  final String buyingType;
  final CampaignStatus status;
  final AdminStatus adminStatus;
  final String? rejectNote;
  final int spendingLimit; // cents
  final String? pageId;
  final String? sourcePostId;
  final String? sourceStoryId;
  final String? sourceReelId;
  final String? sourceContentType;
  final bool isBoosted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from /campaigns/:id/full
  final List<AdSet>? adSets;

  const AdCampaign({
    required this.id,
    this.userId,
    required this.name,
    this.objective = CampaignObjective.awareness,
    this.buyingType = 'Auction',
    this.status = CampaignStatus.draft,
    this.adminStatus = AdminStatus.pending,
    this.rejectNote,
    this.spendingLimit = 0,
    this.pageId,
    this.sourcePostId,
    this.sourceStoryId,
    this.sourceReelId,
    this.sourceContentType,
    this.isBoosted = false,
    this.createdAt,
    this.updatedAt,
    this.adSets,
  });

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user_id'],
      name: json['name'] ?? '',
      objective: CampaignObjective.fromApi(json['objective']),
      buyingType: json['buying_type'] ?? 'Auction',
      status: CampaignStatus.fromApi(json['status']),
      adminStatus: AdminStatus.fromApi(json['admin_status']),
      rejectNote: json['reject_note'],
      spendingLimit: json['spending_limit'] ?? 0,
      pageId: json['page_id'],
      sourcePostId: json['source_post_id'],
      sourceStoryId: json['source_story_id'],
      sourceReelId: json['source_reel_id'],
      sourceContentType: json['source_content_type'],
      isBoosted: json['is_boosted'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      adSets: (json['ad_sets'] as List?)
          ?.map((e) => AdSet.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'objective': objective.apiValue,
        'buying_type': buyingType,
        'status': status.apiValue,
        if (spendingLimit > 0) 'spending_limit': spendingLimit,
        if (pageId != null) 'page_id': pageId,
      };
}

class AdSet {
  final String id;
  final String campaignId;
  final String name;
  final CampaignStatus status;
  final BudgetType budgetType;
  final int dailyBudgetCents;
  final int lifetimeBudgetCents;
  final DateTime? startDate;
  final DateTime? endDate;
  final Audience audience;
  final PlacementType placementType;
  final List<String> placements;
  final String optimizationGoal;
  final String bidStrategy;
  final int bidAmountCents;
  final String? billingEvent;
  final int costPerClick;
  final int costPerImpression;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated from full query
  final List<Ad>? ads;

  const AdSet({
    required this.id,
    required this.campaignId,
    required this.name,
    this.status = CampaignStatus.draft,
    this.budgetType = BudgetType.daily,
    this.dailyBudgetCents = 0,
    this.lifetimeBudgetCents = 0,
    this.startDate,
    this.endDate,
    this.audience = const Audience(),
    this.placementType = PlacementType.automatic,
    this.placements = const [],
    this.optimizationGoal = 'Impressions',
    this.bidStrategy = 'Lowest_Cost',
    this.bidAmountCents = 0,
    this.billingEvent,
    this.costPerClick = 0,
    this.costPerImpression = 0,
    this.createdAt,
    this.updatedAt,
    this.ads,
  });

  factory AdSet.fromJson(Map<String, dynamic> json) {
    return AdSet(
      id: json['_id'] ?? json['id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      name: json['name'] ?? '',
      status: CampaignStatus.fromApi(json['status']),
      budgetType: BudgetType.fromApi(json['budget_type']),
      dailyBudgetCents: json['daily_budget_cents'] ?? 0,
      lifetimeBudgetCents: json['lifetime_budget_cents'] ?? 0,
      startDate: DateTime.tryParse(json['start_date'] ?? ''),
      endDate: DateTime.tryParse(json['end_date'] ?? ''),
      audience: Audience.fromJson(json['audience']),
      placementType: PlacementType.fromApi(json['placement_type']),
      placements: List<String>.from(json['placements'] ?? []),
      optimizationGoal: json['optimization_goal'] ?? 'Impressions',
      bidStrategy: json['bid_strategy'] ?? 'Lowest_Cost',
      bidAmountCents: json['bid_amount_cents'] ?? 0,
      billingEvent: json['billing_event'],
      costPerClick: json['cost_per_click'] ?? 0,
      costPerImpression: json['cost_per_impression'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      ads: (json['ads'] as List?)?.map((e) => Ad.fromJson(e)).toList(),
    );
  }

  /// Budget display: returns the active budget in cents
  int get activeBudgetCents =>
      budgetType == BudgetType.lifetime
          ? lifetimeBudgetCents
          : dailyBudgetCents;

  Map<String, dynamic> toCreateJson() => {
        'campaign_id': campaignId,
        'name': name,
        'budget_type': budgetType.apiValue,
        'daily_budget_cents': dailyBudgetCents,
        'lifetime_budget_cents': lifetimeBudgetCents,
        'start_date': (startDate ?? DateTime.now()).toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
        'audience': audience.toJson(),
        'placement_type': placementType.apiValue,
        'placements': placements,
        'optimization_goal': optimizationGoal,
        'bid_strategy': bidStrategy,
        if (bidAmountCents > 0) 'bid_amount_cents': bidAmountCents,
        if (billingEvent != null) 'billing_event': billingEvent,
      };
}

class Ad {
  final String id;
  final String adSetId;
  final String campaignId;
  final String name;
  final String? pageId;
  final String? pageName;
  final String? postId;
  final String? sourcePostId;
  final bool isBoostedPost;
  final AdFormat format;
  final AdCreative creative;
  final String callToAction;
  final AdDestination destination;
  final CampaignStatus status;
  final AdminStatus adminStatus;
  final String? rejectNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ad({
    required this.id,
    required this.adSetId,
    required this.campaignId,
    required this.name,
    this.pageId,
    this.pageName,
    this.postId,
    this.sourcePostId,
    this.isBoostedPost = false,
    this.format = AdFormat.singleImage,
    this.creative = const AdCreative(),
    this.callToAction = 'Learn_More',
    this.destination = const AdDestination(),
    this.status = CampaignStatus.draft,
    this.adminStatus = AdminStatus.pending,
    this.rejectNote,
    this.createdAt,
    this.updatedAt,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['_id'] ?? json['id'] ?? '',
      adSetId: json['ad_set_id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      name: json['name'] ?? '',
      pageId: json['page_id'],
      pageName: json['page_name'],
      postId: json['post_id'],
      sourcePostId: json['source_post_id'],
      isBoostedPost: json['is_boosted_post'] ?? false,
      format: AdFormat.fromApi(json['format']),
      creative: AdCreative.fromJson(json['creative']),
      callToAction: json['call_to_action'] ?? 'Learn_More',
      destination: AdDestination.fromJson(json['destination']),
      status: CampaignStatus.fromApi(json['status']),
      adminStatus: AdminStatus.fromApi(json['admin_status']),
      rejectNote: json['reject_note'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'ad_set_id': adSetId,
        'campaign_id': campaignId,
        'name': name,
        'format': format.apiValue,
        'creative': creative.toJson(),
        'call_to_action': callToAction,
        'destination': destination.toJson(),
        if (pageId != null) 'page_id': pageId,
        if (pageName != null) 'page_name': pageName,
      };
}
