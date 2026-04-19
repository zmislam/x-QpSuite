import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  static const int _uiAllTime = -1;
  static const int _uiToday = 1;
  static const int _uiYesterday = 2;

  final ApiService _api;

  DashboardData? _data;
  String? _dataPageId;
  bool _isLoading = false;
  String? _error;
  int _period = 30;
  TrendMetric _selectedMetric = TrendMetric.reach;
  int _requestNonce = 0;

  DashboardProvider({required ApiService api}) : _api = api;

  DashboardData? get data => _data;
  String? get dataPageId => _dataPageId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get period => _period;
  TrendMetric get selectedMetric => _selectedMetric;

  /// All available period options matching the web dashboard.
  /// UI values are explicit so "Today" does not collide with API all-time (0).
  static const List<({int value, String label})> periodOptions = [
    (value: _uiToday, label: 'Today'),
    (value: _uiYesterday, label: 'Yesterday'),
    (value: 3, label: '3d'),
    (value: 7, label: '7d'),
    (value: 14, label: '14d'),
    (value: 30, label: '30d'),
    (value: 60, label: '60d'),
    (value: 90, label: '90d'),
    (value: _uiAllTime, label: 'All'),
  ];

  int _normalizeUiPeriod(int value) {
    // Backward compatibility: legacy Today encoding used 0.
    if (value == 0) return _uiToday;
    return value;
  }

  int _toApiPeriod(int uiPeriod) {
    final normalized = _normalizeUiPeriod(uiPeriod);
    return normalized == _uiAllTime ? 0 : normalized;
  }

  void setSelectedMetric(TrendMetric metric) {
    _selectedMetric = metric;
    notifyListeners();
  }

  Future<void> fetchDashboard(String pageId, {int? periodOverride}) async {
    if (periodOverride != null) _period = _normalizeUiPeriod(periodOverride);
    final requestNonce = ++_requestNonce;

    // Prevent stale data from a previously selected page from being rendered
    // while this new page request is in flight.
    if (_dataPageId != null && _dataPageId != pageId) {
      _data = null;
      _dataPageId = null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiPeriod = _toApiPeriod(_period);
      final res = await _api.get(
        ApiConstants.dashboard(pageId),
        queryParameters: {'period': apiPeriod},
      );

      if (requestNonce != _requestNonce) return;

      if (res.data['success'] == true) {
        _data = DashboardData.fromJson(res.data['data']);
        _dataPageId = pageId;
      } else {
        _error = res.data['message'] ?? 'Failed to load dashboard';
      }
    } catch (e) {
      if (requestNonce != _requestNonce) return;

      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final serverMessage = responseData is Map<String, dynamic>
            ? responseData['message']?.toString()
            : null;

        if (statusCode == 401) {
          _error = 'Session expired. Please sign in again.';
        } else if (serverMessage != null && serverMessage.isNotEmpty) {
          _error = serverMessage;
        } else {
          _error = 'Could not load dashboard. Check your connection.';
        }
      } else {
        _error = 'Could not load dashboard. Check your connection.';
      }
    }

    if (requestNonce != _requestNonce) return;

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(int days, String pageId) {
    final normalized = _normalizeUiPeriod(days);
    if (normalized == _period) return;
    _period = normalized;
    fetchDashboard(pageId);
  }
}
