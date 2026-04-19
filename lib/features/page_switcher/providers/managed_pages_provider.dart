import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/managed_page_model.dart';

class ManagedPagesProvider extends ChangeNotifier {
  final ApiService _api;

  List<ManagedPageModel> _pages = [];
  ManagedPageModel? _activePage;
  bool _isLoading = false;
  bool _isSwitchingPage = false;
  String? _error;

  ManagedPagesProvider({required ApiService api}) : _api = api;

  List<ManagedPageModel> get pages => _pages;
  ManagedPageModel? get activePage => _activePage;
  String? get activePageId => _activePage?.id;
  bool get isLoading => _isLoading;
  bool get isSwitchingPage => _isSwitchingPage;
  String? get error => _error;
  bool get hasPages => _pages.isNotEmpty;

  /// Fetch all pages the user can manage.
  Future<void> fetchPages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.managedPages);
      if (res.data['success'] == true) {
        final list = res.data['data'] as List;
        _pages = list.map((e) => ManagedPageModel.fromJson(e)).toList();

        // Restore last selected page or pick first
        final lastId = StorageService.getString(StorageKeys.lastSelectedPageId);
        if (lastId != null && _pages.any((p) => p.id == lastId)) {
          _activePage = _pages.firstWhere((p) => p.id == lastId);
        } else if (_pages.isNotEmpty) {
          _activePage = _pages.first;
          await StorageService.setString(
              StorageKeys.lastSelectedPageId, _activePage!.id);
        }
      } else {
        _error = res.data['message'] ?? 'Failed to load pages';
      }
    } catch (e) {
      _error = 'Could not load your pages. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Switch to a different page.
  Future<void> setActivePage(ManagedPageModel page) async {
    if (_activePage?.id == page.id) return;

    _isSwitchingPage = true;
    _activePage = page;
    notifyListeners();

    // Persisting the selected page should not block UI updates.
    try {
      await StorageService.setString(StorageKeys.lastSelectedPageId, page.id);
    } catch (_) {
      // Keep the in-memory active page even if persistence fails.
    }
  }

  /// Called by BottomNavShell after all providers have started reloading.
  void clearSwitching() {
    _isSwitchingPage = false;
    notifyListeners();
  }
}
