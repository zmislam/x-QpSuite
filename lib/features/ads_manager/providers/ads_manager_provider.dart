/// ============================================================
/// Ads Manager V2 — Main Provider
/// ============================================================
/// Port of qp-web's hooks.js (useCampaigns, useAdSets, useAds,
/// usePaymentMethod, useCostBreakdown, useAdsConfig, etc.)
///
/// Manages the global ads manager state with ChangeNotifier.
/// ============================================================

import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/campaign_models.dart';
import '../models/billing_models.dart';
import '../models/analytics_models.dart';
import '../models/config_models.dart';
import '../services/ads_api_service.dart';

class AdsManagerProvider extends ChangeNotifier {
  final AdsApiService _adsApi;

  AdsManagerProvider({required ApiService api})
      : _adsApi = AdsApiService(api: api);

  // ── Campaigns ────────────────────────────────────────────
  List<AdCampaign> _campaigns = [];
  bool _campaignsLoading = false;
  String? _campaignsError;

  List<AdCampaign> get campaigns => _campaigns;
  bool get campaignsLoading => _campaignsLoading;
  String? get campaignsError => _campaignsError;

  int get activeCampaigns =>
      _campaigns.where((c) => c.status == CampaignStatus.active).length;
  int get pausedCampaigns =>
      _campaigns.where((c) => c.status == CampaignStatus.paused).length;
  int get draftCampaigns =>
      _campaigns.where((c) => c.status == CampaignStatus.draft).length;

  Future<void> fetchCampaigns() async {
    _campaignsLoading = true;
    _campaignsError = null;
    notifyListeners();

    try {
      _campaigns = await _adsApi.fetchCampaigns();
    } catch (e) {
      _campaignsError = 'Failed to load campaigns';
      debugPrint('[AdsProvider] fetchCampaigns: $e');
    }

    _campaignsLoading = false;
    notifyListeners();
  }

  Future<AdCampaign?> createCampaign(Map<String, dynamic> body) async {
    try {
      final campaign = await _adsApi.createCampaign(body);
      _campaigns = [campaign, ..._campaigns];
      notifyListeners();
      return campaign;
    } catch (e) {
      debugPrint('[AdsProvider] createCampaign: $e');
      rethrow;
    }
  }

  Future<AdCampaign?> updateCampaign(
      String id, Map<String, dynamic> body) async {
    try {
      final updated = await _adsApi.updateCampaign(id, body);
      final idx = _campaigns.indexWhere((c) => c.id == id);
      if (idx >= 0) {
        _campaigns[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('[AdsProvider] updateCampaign: $e');
      rethrow;
    }
  }

  Future<void> deleteCampaign(String id) async {
    try {
      await _adsApi.deleteCampaign(id);
      _campaigns.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[AdsProvider] deleteCampaign: $e');
      rethrow;
    }
  }

  // ── Ad Sets ──────────────────────────────────────────────
  List<AdSet> _adSets = [];
  bool _adSetsLoading = false;
  String? _adSetsError;
  String? _selectedCampaignId;

  List<AdSet> get adSets => _adSets;
  bool get adSetsLoading => _adSetsLoading;
  String? get adSetsError => _adSetsError;
  String? get selectedCampaignId => _selectedCampaignId;

  Future<void> fetchAdSets({String? campaignId}) async {
    _selectedCampaignId = campaignId;
    _adSetsLoading = true;
    _adSetsError = null;
    notifyListeners();

    try {
      _adSets = await _adsApi.fetchAdSets(campaignId: campaignId);
    } catch (e) {
      _adSetsError = 'Failed to load ad sets';
      debugPrint('[AdsProvider] fetchAdSets: $e');
    }

    _adSetsLoading = false;
    notifyListeners();
  }

  Future<AdSet?> createAdSet(Map<String, dynamic> body) async {
    try {
      final adSet = await _adsApi.createAdSet(body);
      _adSets = [adSet, ..._adSets];
      notifyListeners();
      return adSet;
    } catch (e) {
      debugPrint('[AdsProvider] createAdSet: $e');
      rethrow;
    }
  }

  Future<AdSet?> updateAdSet(
      String id, Map<String, dynamic> body) async {
    try {
      final updated = await _adsApi.updateAdSet(id, body);
      final idx = _adSets.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        _adSets[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('[AdsProvider] updateAdSet: $e');
      rethrow;
    }
  }

  Future<void> deleteAdSet(String id) async {
    try {
      await _adsApi.deleteAdSet(id);
      _adSets.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[AdsProvider] deleteAdSet: $e');
      rethrow;
    }
  }

  // ── Ads ──────────────────────────────────────────────────
  List<Ad> _ads = [];
  bool _adsLoading = false;
  String? _adsError;
  String? _selectedAdSetId;

  List<Ad> get ads => _ads;
  bool get adsLoading => _adsLoading;
  String? get adsError => _adsError;
  String? get selectedAdSetId => _selectedAdSetId;

  Future<void> fetchAds({String? adSetId}) async {
    _selectedAdSetId = adSetId;
    _adsLoading = true;
    _adsError = null;
    notifyListeners();

    try {
      _ads = await _adsApi.fetchAds(adSetId: adSetId);
    } catch (e) {
      _adsError = 'Failed to load ads';
      debugPrint('[AdsProvider] fetchAds: $e');
    }

    _adsLoading = false;
    notifyListeners();
  }

  Future<Ad?> createAd(Map<String, dynamic> body) async {
    try {
      final ad = await _adsApi.createAd(body);
      _ads = [ad, ..._ads];
      notifyListeners();
      return ad;
    } catch (e) {
      debugPrint('[AdsProvider] createAd: $e');
      rethrow;
    }
  }

  Future<String> uploadAdMedia(
    String filePath, {
    String? filename,
    void Function(int, int)? onProgress,
  }) {
    return _adsApi.uploadAdMedia(filePath,
        filename: filename, onProgress: onProgress);
  }

  Future<Ad?> updateAd(String id, Map<String, dynamic> body) async {
    try {
      final updated = await _adsApi.updateAd(id, body);
      final idx = _ads.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _ads[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('[AdsProvider] updateAd: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _adsApi.deleteAd(id);
      _ads.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[AdsProvider] deleteAd: $e');
      rethrow;
    }
  }

  // ── Billing / Cost Breakdown ─────────────────────────────
  CostBreakdownResponse _costBreakdown = const CostBreakdownResponse();
  bool _costBreakdownLoading = false;
  int _costBreakdownDays = 30;

  CostBreakdownResponse get costBreakdown => _costBreakdown;
  bool get costBreakdownLoading => _costBreakdownLoading;
  int get costBreakdownDays => _costBreakdownDays;

  Future<void> fetchCostBreakdown({int days = 30}) async {
    _costBreakdownDays = days;
    _costBreakdownLoading = true;
    notifyListeners();

    try {
      _costBreakdown = await _adsApi.fetchCostBreakdown(days: days);
    } catch (e) {
      debugPrint('[AdsProvider] fetchCostBreakdown: $e');
    }

    _costBreakdownLoading = false;
    notifyListeners();
  }

  // ── Payment Method ───────────────────────────────────────
  PaymentMethod _paymentMethod = const PaymentMethod();
  bool _paymentLoading = false;

  PaymentMethod get paymentMethod => _paymentMethod;
  bool get paymentLoading => _paymentLoading;

  Future<void> fetchPaymentMethod() async {
    _paymentLoading = true;
    notifyListeners();

    try {
      _paymentMethod = await _adsApi.fetchPaymentMethod();
    } catch (e) {
      debugPrint('[AdsProvider] fetchPaymentMethod: $e');
    }

    _paymentLoading = false;
    notifyListeners();
  }

  Future<bool> canAdvertise() => _adsApi.canAdvertise();

  // ── Config ───────────────────────────────────────────────
  AdsManagerConfig _config = AdsManagerConfig.fallback;
  bool _configLoading = false;

  AdsManagerConfig get config => _config;
  bool get configLoading => _configLoading;

  Future<void> fetchConfig() async {
    _configLoading = true;
    notifyListeners();

    try {
      _config = await _adsApi.fetchConfig();
    } catch (e) {
      debugPrint('[AdsProvider] fetchConfig: $e');
      _config = AdsManagerConfig.fallback;
    }

    _configLoading = false;
    notifyListeners();
  }

  // ── Analytics ────────────────────────────────────────────
  CampaignAnalytics? _selectedCampaignAnalytics;
  bool _analyticsLoading = false;

  CampaignAnalytics? get selectedCampaignAnalytics =>
      _selectedCampaignAnalytics;
  bool get analyticsLoading => _analyticsLoading;

  Future<void> fetchCampaignAnalytics(
    String campaignId, {
    int days = 7,
  }) async {
    _analyticsLoading = true;
    notifyListeners();

    try {
      _selectedCampaignAnalytics =
          await _adsApi.fetchCampaignAnalytics(campaignId, days: days);
    } catch (e) {
      debugPrint('[AdsProvider] fetchCampaignAnalytics: $e');
    }

    _analyticsLoading = false;
    notifyListeners();
  }

  Future<AdAnalyticsResponse?> fetchAdAnalytics(
    String adId, {
    int days = 7,
  }) async {
    try {
      return await _adsApi.fetchAdAnalytics(adId, days: days);
    } catch (e) {
      debugPrint('[AdsProvider] fetchAdAnalytics: $e');
      return null;
    }
  }

  Future<DemographicBreakdown?> fetchAdDemographics(
    String adId, {
    int days = 7,
  }) async {
    try {
      return await _adsApi.fetchAdDemographics(adId, days: days);
    } catch (e) {
      debugPrint('[AdsProvider] fetchAdDemographics: $e');
      return null;
    }
  }

  // ── Boost ────────────────────────────────────────────────
  bool _boostLoading = false;
  bool get boostLoading => _boostLoading;

  Future<Map<String, dynamic>> boostPost(
      Map<String, dynamic> payload) async {
    _boostLoading = true;
    notifyListeners();

    try {
      final result = await _adsApi.boostPost(payload);
      _boostLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _boostLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ── Onboarding ───────────────────────────────────────────
  Map<String, dynamic>? _onboardingProfile;
  bool _onboardingLoading = false;

  Map<String, dynamic>? get onboardingProfile => _onboardingProfile;
  bool get onboardingLoading => _onboardingLoading;
  bool get onboardingCompleted =>
      _onboardingProfile?['onboarding_completed'] == true;

  Future<void> fetchOnboardingProfile() async {
    _onboardingLoading = true;
    notifyListeners();

    try {
      _onboardingProfile = await _adsApi.fetchOnboardingProfile();
    } catch (e) {
      debugPrint('[AdsProvider] fetchOnboardingProfile: $e');
    }

    _onboardingLoading = false;
    notifyListeners();
  }

  // ── Init: load everything needed for the overview ────────
  Future<void> initDashboard() async {
    await Future.wait([
      fetchCampaigns(),
      fetchCostBreakdown(days: _costBreakdownDays),
      fetchPaymentMethod(),
      fetchConfig(),
    ]);
  }

  /// Refresh all currently loaded data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchCampaigns(),
      fetchCostBreakdown(days: _costBreakdownDays),
      fetchPaymentMethod(),
      if (_selectedCampaignId != null)
        fetchAdSets(campaignId: _selectedCampaignId),
      if (_selectedAdSetId != null)
        fetchAds(adSetId: _selectedAdSetId),
    ]);
  }
}
