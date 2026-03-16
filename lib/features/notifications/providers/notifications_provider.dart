import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_models.dart';

class NotificationsProvider extends ChangeNotifier {
  final ApiService _api;

  List<AppNotification> _items = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  int _page = 1;
  bool _hasMore = true;

  NotificationsProvider({required ApiService api}) : _api = api;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  Future<void> fetchNotifications(String pageId,
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
        ApiConstants.notifications(pageId),
        queryParameters: {'page': _page, 'limit': 20},
      );
      if (res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        final notifications =
            list.map((e) => AppNotification.fromJson(e)).toList();
        if (loadMore) {
          _items = [..._items, ...notifications];
        } else {
          _items = notifications;
        }
        _unreadCount = res.data['unread_count'] ?? 0;
        _hasMore = notifications.length >= 20;
      } else {
        _error = res.data['message'] ?? 'Failed to load notifications';
      }
    } catch (e) {
      _error = 'Could not load notifications.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead(String pageId) async {
    try {
      await _api.patch(ApiConstants.notificationsReadAll(pageId));
      _items = _items.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        link: n.link,
        isRead: true,
        actor: n.actor,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      if (!_items[index].isRead) _unreadCount--;
      _items = List.from(_items)..removeAt(index);
      notifyListeners();
    }
  }
}
