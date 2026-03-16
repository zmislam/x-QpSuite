import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/boost_models.dart';

class BoostProvider extends ChangeNotifier {
  final ApiService _api;

  List<BoostedPost> _items = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _isBoosting = false;

  BoostProvider({required ApiService api}) : _api = api;

  List<BoostedPost> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isBoosting => _isBoosting;

  Future<void> fetchBoostedPosts(String pageId,
      {bool loadMore = false}) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    if (loadMore) {
      _page++;
    } else {
      _page = 1;
      _items = [];
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.boostedPosts(pageId),
        queryParameters: {'page': _page, 'limit': 20},
      );
      if (res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        final posts = list.map((e) => BoostedPost.fromJson(e)).toList();
        if (loadMore) {
          _items = [..._items, ...posts];
        } else {
          _items = posts;
        }
        _hasMore = posts.length >= 20;
      } else {
        _error = res.data['message'] ?? 'Failed to load boosted posts';
      }
    } catch (e) {
      _error = 'Could not load boosted posts.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> togglePauseResume(
      String pageId, String campaignId, String action) async {
    try {
      final res = await _api.patch(
        ApiConstants.boostedPostById(pageId, campaignId),
        data: {'action': action},
      );
      if (res.data['success'] == true) {
        final idx = _items.indexWhere((b) => b.id == campaignId);
        if (idx >= 0) {
          // Refresh list to get new status
          await fetchBoostedPosts(pageId);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> canAdvertise() async {
    try {
      final res = await _api.get(ApiConstants.canAdvertise);
      return res.data['data']?['can_advertise'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createBoost({
    required String postId,
    required String pageId,
    required String pageName,
    required int dailyBudgetCents,
    required int durationDays,
    required List<String> locations,
    required int ageMin,
    required int ageMax,
    String callToAction = 'Learn_More',
  }) async {
    _isBoosting = true;
    notifyListeners();

    try {
      final res = await _api.post(ApiConstants.boost, data: {
        'post_id': postId,
        'page_id': pageId,
        'page_name': pageName,
        'audience': {
          'locations': locations,
          'demographics': {'age_min': ageMin, 'age_max': ageMax},
        },
        'daily_budget_cents': dailyBudgetCents,
        'duration_days': durationDays,
        'start_date': DateTime.now().toIso8601String(),
        'call_to_action': callToAction,
      });

      _isBoosting = false;
      notifyListeners();
      return res.data['success'] == true;
    } catch (_) {
      _isBoosting = false;
      notifyListeners();
      return false;
    }
  }
}
