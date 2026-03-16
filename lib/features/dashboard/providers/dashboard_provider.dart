import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  DashboardData? _data;
  bool _isLoading = false;
  String? _error;
  int _period = 7;
  TrendMetric _selectedMetric = TrendMetric.reach;

  DashboardProvider({required ApiService api}) : _api = api;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get period => _period;
  TrendMetric get selectedMetric => _selectedMetric;

  void setSelectedMetric(TrendMetric metric) {
    _selectedMetric = metric;
    notifyListeners();
  }

  Future<void> fetchDashboard(String pageId, {int? periodOverride}) async {
    if (periodOverride != null) _period = periodOverride;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.dashboard(pageId),
        queryParameters: {'period': _period},
      );

      if (res.data['success'] == true) {
        _data = DashboardData.fromJson(res.data['data']);
      } else {
        _error = res.data['message'] ?? 'Failed to load dashboard';
      }
    } catch (e) {
      _error = 'Could not load dashboard. Check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(int days, String pageId) {
    if (days == _period) return;
    _period = days;
    fetchDashboard(pageId);
  }
}
