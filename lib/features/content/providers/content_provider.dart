import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/content_models.dart';

enum ContentFilter { all, published, scheduled }
enum ContentTypeFilter { all, post, reel, story }

class ContentProvider extends ChangeNotifier {
  final ApiService _api;

  List<ContentItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  ContentFilter _filter = ContentFilter.all;
  ContentTypeFilter _typeFilter = ContentTypeFilter.all;

  // Per-type content lists
  List<ContentItem> _reelItems = [];
  List<ContentItem> _storyItems = [];
  List<ContentItem> _mentionItems = [];
  List<ContentItem> _photoItems = [];
  bool _isTypeLoading = false;

  // Posts filter state
  String _postsFilter = 'Published'; // Published | Scheduled | Drafts

  // Calendar
  Map<String, CalendarDay> _calendarDays = {};
  String _calendarMonth = '';
  bool _isCalendarLoading = false;

  ContentProvider({required ApiService api}) : _api = api;

  List<ContentItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  ContentFilter get filter => _filter;
  ContentTypeFilter get typeFilter => _typeFilter;
  Map<String, CalendarDay> get calendarDays => _calendarDays;
  bool get isCalendarLoading => _isCalendarLoading;

  // Per-type getters
  List<ContentItem> get reelItems => _reelItems;
  List<ContentItem> get storyItems => _storyItems;
  List<ContentItem> get mentionItems => _mentionItems;
  List<ContentItem> get photoItems => _photoItems;
  bool get isTypeLoading => _isTypeLoading;
  String get postsFilter => _postsFilter;

  void setPostsFilter(String filter) {
    _postsFilter = filter;
    notifyListeners();
  }

  void setFilter(ContentFilter f, String pageId) {
    if (f == _filter) return;
    _filter = f;
    _items = [];
    _page = 1;
    _hasMore = true;
    fetchContent(pageId);
  }

  void setTypeFilter(ContentTypeFilter t, String pageId) {
    if (t == _typeFilter) return;
    _typeFilter = t;
    _items = [];
    _page = 1;
    _hasMore = true;
    fetchContent(pageId);
  }

  Future<void> fetchContent(String pageId, {bool loadMore = false}) async {
    if (_isLoading) return;
    if (loadMore) {
      if (!_hasMore) return;
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
      final params = <String, dynamic>{
        'page': _page,
        'limit': 20,
        'type': _filter.name,
      };
      if (_typeFilter != ContentTypeFilter.all) {
        params['content_type'] =
            _typeFilter.name[0].toUpperCase() + _typeFilter.name.substring(1);
      }

      final res = await _api.get(
        ApiConstants.content(pageId),
        queryParameters: params,
      );

      if (res.data['success'] == true) {
        final list = (res.data['data'] as List?)
                ?.map((e) => ContentItem.fromJson(e))
                .toList() ??
            [];
        if (loadMore) {
          _items.addAll(list);
        } else {
          _items = list;
        }
        _hasMore = list.length >= 20;
      } else {
        _error = res.data['message'] ?? 'Failed to load content';
      }
    } catch (e) {
      _error = 'Could not load content.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCalendar(String pageId, String month) async {
    _isCalendarLoading = true;
    _calendarMonth = month;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.contentCalendar(pageId),
        queryParameters: {'month': month},
      );
      if (res.data['success'] == true) {
        final days = res.data['data']['days'] as Map<String, dynamic>? ?? {};
        _calendarDays = days.map(
          (k, v) => MapEntry(k, CalendarDay.fromJson(k, v)),
        );
      }
    } catch (_) {
      // fail silently for calendar
    }

    _isCalendarLoading = false;
    notifyListeners();
  }

  Future<bool> deleteContent(String pageId, ContentItem item) async {
    try {
      if (item.isPublished) {
        await _api.delete(ApiConstants.publishedPostById(pageId, item.id));
      } else {
        await _api.delete(ApiConstants.scheduledPostById(pageId, item.id));
      }
      _items.removeWhere((i) => i.id == item.id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> publishNow(String pageId, String scheduleId) async {
    try {
      await _api.post(ApiConstants.scheduledPostPublishNow(pageId, scheduleId));
      // Refresh content
      fetchContent(pageId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch content filtered by type: 'Reel', 'Story', 'Mention', 'Photo'
  Future<void> fetchContentByType(String pageId, String type) async {
    _isTypeLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': 1,
        'limit': 50,
        'content_type': type,
      };

      final res = await _api.get(
        ApiConstants.content(pageId),
        queryParameters: params,
      );

      if (res.data['success'] == true) {
        final list = (res.data['data'] as List?)
                ?.map((e) => ContentItem.fromJson(e))
                .toList() ??
            [];
        switch (type) {
          case 'Reel':
            _reelItems = list;
            break;
          case 'Story':
            _storyItems = list;
            break;
          case 'Mention':
            _mentionItems = list;
            break;
          case 'Photo':
            _photoItems = list;
            break;
        }
      }
    } catch (_) {
      // Silently handle — the tab will show empty state
    }

    _isTypeLoading = false;
    notifyListeners();
  }
}
