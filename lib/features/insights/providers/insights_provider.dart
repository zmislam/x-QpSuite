import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/insights_models.dart';

enum InsightsPeriod { days7, days14, days30, days90 }

class InsightsProvider extends ChangeNotifier {
  final ApiService _api;

  // Overview
  InsightsData? _overview;
  bool _isOverviewLoading = false;
  String? _overviewError;
  InsightsPeriod _period = InsightsPeriod.days30;
  InsightsMetric _selectedMetric = InsightsMetric.reach;

  // Audience
  AudienceData? _audience;
  bool _isAudienceLoading = false;
  String? _audienceError;

  // Content performance
  List<ContentPerformanceItem> _contentItems = [];
  bool _isContentLoading = false;
  String? _contentError;
  String _contentSort = 'reach';
  int _contentPage = 1;
  bool _hasMoreContent = true;

  // Post-level
  PostInsightsData? _postInsights;
  bool _isPostLoading = false;
  String? _postError;

  InsightsProvider({required ApiService api}) : _api = api;

  // ── Getters ──

  InsightsData? get overview => _overview;
  bool get isOverviewLoading => _isOverviewLoading;
  String? get overviewError => _overviewError;
  InsightsPeriod get period => _period;
  InsightsMetric get selectedMetric => _selectedMetric;

  AudienceData? get audience => _audience;
  bool get isAudienceLoading => _isAudienceLoading;
  String? get audienceError => _audienceError;

  List<ContentPerformanceItem> get contentItems => _contentItems;
  bool get isContentLoading => _isContentLoading;
  String? get contentError => _contentError;
  String get contentSort => _contentSort;
  bool get hasMoreContent => _hasMoreContent;

  PostInsightsData? get postInsights => _postInsights;
  bool get isPostLoading => _isPostLoading;
  String? get postError => _postError;

  // ── Overview ──

  void setPeriod(InsightsPeriod p) {
    _period = p;
    notifyListeners();
  }

  void setSelectedMetric(InsightsMetric m) {
    _selectedMetric = m;
    notifyListeners();
  }

  int get _periodDays {
    switch (_period) {
      case InsightsPeriod.days7:
        return 7;
      case InsightsPeriod.days14:
        return 14;
      case InsightsPeriod.days30:
        return 30;
      case InsightsPeriod.days90:
        return 90;
    }
  }

  Future<void> fetchOverview(String pageId) async {
    _isOverviewLoading = true;
    _overviewError = null;
    notifyListeners();

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final to = DateTime.now();
      final from = to.subtract(Duration(days: _periodDays));
      final res = await _api.get(
        ApiConstants.insights(pageId),
        queryParameters: {'from': fmt.format(from), 'to': fmt.format(to)},
      );
      if (res.data['success'] == true) {
        _overview = InsightsData.fromJson(res.data['data']);
      } else {
        _overviewError = res.data['message'] ?? 'Failed to load insights';
      }
    } catch (e) {
      _overviewError = 'Could not load insights.';
    }

    _isOverviewLoading = false;
    notifyListeners();
  }

  // ── Audience ──

  Future<void> fetchAudience(String pageId) async {
    _isAudienceLoading = true;
    _audienceError = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.insightsAudience(pageId));
      if (res.data['success'] == true) {
        _audience = AudienceData.fromJson(res.data['data']);
      } else {
        _audienceError = res.data['message'] ?? 'Failed to load audience data';
      }
    } catch (e) {
      _audienceError = 'Could not load audience data.';
    }

    _isAudienceLoading = false;
    notifyListeners();
  }

  // ── Content Performance ──

  void setContentSort(String sort) {
    if (_contentSort == sort) return;
    _contentSort = sort;
    _contentItems = [];
    _contentPage = 1;
    _hasMoreContent = true;
    notifyListeners();
  }

  Future<void> fetchContentPerformance(String pageId,
      {bool loadMore = false}) async {
    if (_isContentLoading) return;
    if (loadMore && !_hasMoreContent) return;

    if (loadMore) {
      _contentPage++;
    } else {
      _contentPage = 1;
      _contentItems = [];
      _hasMoreContent = true;
    }

    _isContentLoading = true;
    _contentError = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.insightsContent(pageId),
        queryParameters: {
          'page': _contentPage,
          'limit': 20,
          'sort': _contentSort,
        },
      );
      if (res.data['success'] == true) {
        final list = res.data['data']['posts'] as List? ??
            res.data['data'] as List? ??
            [];
        final items =
            list.map((e) => ContentPerformanceItem.fromJson(e)).toList();
        if (loadMore) {
          _contentItems = [..._contentItems, ...items];
        } else {
          _contentItems = items;
        }
        _hasMoreContent = items.length >= 20;
      } else {
        _contentError = res.data['message'] ?? 'Failed to load content';
      }
    } catch (e) {
      _contentError = 'Could not load content insights.';
    }

    _isContentLoading = false;
    notifyListeners();
  }

  // ── Post-Level ──

  Future<void> fetchPostInsights(String pageId, String postId) async {
    _isPostLoading = true;
    _postError = null;
    _postInsights = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.postInsights(pageId, postId));
      if (res.data['success'] == true) {
        _postInsights = PostInsightsData.fromJson(res.data['data']);
      } else {
        _postError = res.data['message'] ?? 'Failed to load post insights';
      }
    } catch (e) {
      _postError = 'Could not load post insights.';
    }

    _isPostLoading = false;
    notifyListeners();
  }
}
