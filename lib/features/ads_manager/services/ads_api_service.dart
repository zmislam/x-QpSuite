/// ============================================================
/// Ads Manager V2 — Centralized API Service
/// ============================================================
/// Port of qp-web/src/components/AdsManager/api.js
/// All ad-related HTTP calls go through this class.
/// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/campaign_models.dart';
import '../models/billing_models.dart';
import '../models/analytics_models.dart';
import '../models/config_models.dart';

class AdsApiService {
  final ApiService _api;

  AdsApiService({required ApiService api}) : _api = api;

  // ════════════════════════════════════════════════════════════
  // CAMPAIGNS
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/campaigns
  Future<List<AdCampaign>> fetchCampaigns() async {
    try {
      final res = await _api.get(ApiConstants.campaigns);
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => AdCampaign.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdsApi] fetchCampaigns error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/campaigns/:id/full
  Future<AdCampaign> fetchCampaignFull(String id) async {
    try {
      final res = await _api.get(ApiConstants.campaignFull(id));
      final data = res.data['data'] ?? res.data;
      return AdCampaign.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] fetchCampaignFull error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/campaigns
  Future<AdCampaign> createCampaign(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConstants.campaigns, data: body);
      final data = res.data['data'] ?? res.data;
      return AdCampaign.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] createCampaign error: $e');
      rethrow;
    }
  }

  /// PATCH /campaigns-v2/campaigns/:id
  Future<AdCampaign> updateCampaign(
      String id, Map<String, dynamic> body) async {
    try {
      final res =
          await _api.patch(ApiConstants.campaignById(id), data: body);
      final data = res.data['data'] ?? res.data;
      return AdCampaign.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] updateCampaign error: $e');
      rethrow;
    }
  }

  /// DELETE /campaigns-v2/campaigns/:id
  Future<void> deleteCampaign(String id) async {
    try {
      await _api.delete(ApiConstants.campaignById(id));
    } catch (e) {
      debugPrint('[AdsApi] deleteCampaign error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // AD SETS
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/ad-sets?campaign_id=...
  Future<List<AdSet>> fetchAdSets({String? campaignId}) async {
    try {
      final params = <String, dynamic>{};
      if (campaignId != null) params['campaign_id'] = campaignId;
      final res =
          await _api.get(ApiConstants.adSets, queryParameters: params);
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => AdSet.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdsApi] fetchAdSets error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/ad-sets
  Future<AdSet> createAdSet(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConstants.adSets, data: body);
      final data = res.data['data'] ?? res.data;
      return AdSet.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] createAdSet error: $e');
      rethrow;
    }
  }

  /// PATCH /campaigns-v2/ad-sets/:id
  Future<AdSet> updateAdSet(
      String id, Map<String, dynamic> body) async {
    try {
      final res =
          await _api.patch(ApiConstants.adSetById(id), data: body);
      final data = res.data['data'] ?? res.data;
      return AdSet.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] updateAdSet error: $e');
      rethrow;
    }
  }

  /// DELETE /campaigns-v2/ad-sets/:id
  Future<void> deleteAdSet(String id) async {
    try {
      await _api.delete(ApiConstants.adSetById(id));
    } catch (e) {
      debugPrint('[AdsApi] deleteAdSet error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ADS
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/ads?ad_set_id=...
  Future<List<Ad>> fetchAds({String? adSetId}) async {
    try {
      final params = <String, dynamic>{};
      if (adSetId != null) params['ad_set_id'] = adSetId;
      final res =
          await _api.get(ApiConstants.ads, queryParameters: params);
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => Ad.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdsApi] fetchAds error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/ads
  Future<Ad> createAd(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConstants.ads, data: body);
      final data = res.data['data'] ?? res.data;
      return Ad.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] createAd error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/ads/upload-media
  Future<String> uploadAdMedia(
    String filePath, {
    String? filename,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          filePath,
          filename: filename,
        ),
      });
      final res = await _api.uploadFile(
        ApiConstants.adsUploadMedia,
        formData: formData,
        onSendProgress: onProgress,
      );
      // Returns the uploaded file URL/path
      return res.data['data']?['url'] ??
          res.data['data']?['media_url'] ??
          res.data['url'] ??
          '';
    } catch (e) {
      debugPrint('[AdsApi] uploadAdMedia error: $e');
      rethrow;
    }
  }

  /// PATCH /campaigns-v2/ads/:id
  Future<Ad> updateAd(String id, Map<String, dynamic> body) async {
    try {
      final res =
          await _api.patch(ApiConstants.adById(id), data: body);
      final data = res.data['data'] ?? res.data;
      return Ad.fromJson(data);
    } catch (e) {
      debugPrint('[AdsApi] updateAd error: $e');
      rethrow;
    }
  }

  /// DELETE /campaigns-v2/ads/:id
  Future<void> deleteAd(String id) async {
    try {
      await _api.delete(ApiConstants.adById(id));
    } catch (e) {
      debugPrint('[AdsApi] deleteAd error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BILLING
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/billing/cost-breakdown?days=N
  Future<CostBreakdownResponse> fetchCostBreakdown({int days = 30}) async {
    try {
      final res = await _api.get(
        ApiConstants.costBreakdown,
        queryParameters: {'days': days},
      );
      return CostBreakdownResponse.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchCostBreakdown error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/billing/payment-method
  Future<PaymentMethod> fetchPaymentMethod() async {
    try {
      final res = await _api.get(ApiConstants.paymentMethod);
      return PaymentMethod.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchPaymentMethod error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/billing/status
  Future<BillingStatus> fetchBillingStatus() async {
    try {
      final res = await _api.get(ApiConstants.billingStatus);
      return BillingStatus.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchBillingStatus error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/billing/can-advertise
  Future<bool> canAdvertise() async {
    try {
      final res = await _api.get(ApiConstants.canAdvertise);
      return res.data['data']?['can_advertise'] == true;
    } catch (e) {
      debugPrint('[AdsApi] canAdvertise error: $e');
      return false;
    }
  }

  /// GET /campaigns-v2/billing/my-cycles
  Future<List<BillingCycle>> fetchBillingCycles() async {
    try {
      final res = await _api.get(ApiConstants.billingCycles);
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => BillingCycle.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[AdsApi] fetchBillingCycles error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/billing/confirm-card
  Future<bool> confirmCard(Map<String, dynamic> body) async {
    try {
      final res =
          await _api.post(ApiConstants.confirmCard, data: body);
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('[AdsApi] confirmCard error: $e');
      rethrow;
    }
  }

  /// DELETE /campaigns-v2/billing/payment-method
  Future<bool> removePaymentMethod() async {
    try {
      final res = await _api.delete(ApiConstants.paymentMethod);
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('[AdsApi] removePaymentMethod error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ANALYTICS
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/analytics/:campaignId
  Future<CampaignAnalytics> fetchCampaignAnalytics(
    String campaignId, {
    int days = 7,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.analytics(campaignId),
        queryParameters: {'days': days},
      );
      return CampaignAnalytics.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchCampaignAnalytics error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/analytics/ad/:adId
  Future<AdAnalyticsResponse> fetchAdAnalytics(
    String adId, {
    int days = 7,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.adAnalytics(adId),
        queryParameters: {'days': days},
      );
      return AdAnalyticsResponse.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchAdAnalytics error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/analytics/:campaignId/demographics
  Future<DemographicBreakdown> fetchDemographics(
      String campaignId) async {
    try {
      final res = await _api.get(
          ApiConstants.campaignDemographics(campaignId));
      return DemographicBreakdown.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchDemographics error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/analytics/ad/:adId/demographics
  Future<DemographicBreakdown> fetchAdDemographics(
    String adId, {
    int days = 7,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.adDemographics(adId),
        queryParameters: {'days': days},
      );
      return DemographicBreakdown.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchAdDemographics error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BOOST & PROMOTE
  // ════════════════════════════════════════════════════════════

  /// POST /campaigns-v2/boost
  Future<Map<String, dynamic>> boostPost(
      Map<String, dynamic> payload) async {
    try {
      final res = await _api.post(ApiConstants.boost, data: payload);
      return Map<String, dynamic>.from(res.data['data'] ?? res.data);
    } catch (e) {
      debugPrint('[AdsApi] boostPost error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/promote-page
  Future<Map<String, dynamic>> promotePage(
      Map<String, dynamic> payload) async {
    try {
      final res =
          await _api.post(ApiConstants.promotePage, data: payload);
      return Map<String, dynamic>.from(res.data['data'] ?? res.data);
    } catch (e) {
      debugPrint('[AdsApi] promotePage error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // CONFIG
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/config (ads manager UI config)
  Future<AdsManagerConfig> fetchConfig() async {
    try {
      // Try fetching; if endpoint doesn't exist yet, use fallback
      final res = await _api.get('/campaigns-v2/config');
      return AdsManagerConfig.fromJson(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchConfig not available, using fallback');
      return AdsManagerConfig.fallback;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ONBOARDING
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/onboarding/profile
  Future<Map<String, dynamic>> fetchOnboardingProfile() async {
    try {
      final res = await _api.get(ApiConstants.onboardingProfile);
      return Map<String, dynamic>.from(
          res.data['data'] ?? res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchOnboardingProfile error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/onboarding/complete
  Future<bool> completeOnboarding(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(
          ApiConstants.onboardingComplete, data: body);
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('[AdsApi] completeOnboarding error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BULK ACTIONS & TABLE DATA
  // ════════════════════════════════════════════════════════════

  /// POST /campaigns-v2/bulk-action
  Future<bool> bulkAction(Map<String, dynamic> body) async {
    try {
      final res =
          await _api.post(ApiConstants.bulkAction, data: body);
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('[AdsApi] bulkAction error: $e');
      rethrow;
    }
  }

  /// GET /campaigns-v2/table-data
  Future<Map<String, dynamic>> fetchTableData({
    String level = 'campaign',
    int page = 1,
    int limit = 50,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final res = await _api.get(
        ApiConstants.tableData,
        queryParameters: {
          'level': level,
          'page': page,
          'limit': limit,
          if (sortBy != null) 'sort_by': sortBy,
          if (sortOrder != null) 'sort_order': sortOrder,
        },
      );
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('[AdsApi] fetchTableData error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // AUDIENCES
  // ════════════════════════════════════════════════════════════

  /// GET /campaigns-v2/audiences/all
  Future<List<Map<String, dynamic>>> fetchAllAudiences() async {
    try {
      final res = await _api.get(ApiConstants.allAudiences);
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[AdsApi] fetchAllAudiences error: $e');
      rethrow;
    }
  }

  /// POST /campaigns-v2/audiences/saved
  Future<Map<String, dynamic>> createSavedAudience(
      Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConstants.savedAudiences, data: body);
      return Map<String, dynamic>.from(res.data['data'] ?? res.data);
    } catch (e) {
      debugPrint('[AdsApi] createSavedAudience error: $e');
      rethrow;
    }
  }
}
