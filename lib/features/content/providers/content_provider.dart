import 'dart:async';
import 'package:dio/dio.dart';
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

  // Scheduled posts dedicated state
  List<ContentItem> _scheduledItems = [];
  bool _isScheduledLoading = false;
  bool _scheduledHasMore = true;
  int _scheduledPage = 1;
  String _scheduledStatusFilter = 'all'; // all | Scheduled | Failed | Cancelled
  int _scheduledTotal = 0;
  int _scheduledCount = 0;
  int _failedCount = 0;
  int _cancelledCount = 0;
  Timer? _pollTimer;

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

  // Scheduled posts getters
  List<ContentItem> get scheduledItems => _scheduledItems;
  bool get isScheduledLoading => _isScheduledLoading;
  bool get scheduledHasMore => _scheduledHasMore;
  String get scheduledStatusFilter => _scheduledStatusFilter;
  int get scheduledTotal => _scheduledTotal;
  int get scheduledCount => _scheduledCount;
  int get failedCount => _failedCount;
  int get cancelledCount => _cancelledCount;

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
    // Retry up to 3 times — publish-now can be slow (copies media files)
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await _api.post(
          ApiConstants.scheduledPostPublishNow(pageId, scheduleId),
          data: {},
        );
        if (res.data['success'] == true) {
          return true;
        }
        // If server says "already publishing/published", treat as success
        if (res.statusCode == 404) return true;
        return false;
      } catch (e) {
        final isRetryable = e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.sendTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.connectionError ||
             (e.response?.statusCode != null && e.response!.statusCode! >= 500));
        if (!isRetryable || attempt == maxRetries) {
          debugPrint('[ContentProvider] publishNow failed after $attempt attempts: $e');
          return false;
        }
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
    return false;
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

  // ── Scheduled Posts Management ──────────────────────

  void setScheduledStatusFilter(String filter, String pageId) {
    if (filter == _scheduledStatusFilter) return;
    _scheduledStatusFilter = filter;
    _scheduledItems = [];
    _scheduledPage = 1;
    _scheduledHasMore = true;
    fetchScheduledPosts(pageId);
  }

  Future<void> fetchScheduledPosts(String pageId,
      {bool loadMore = false}) async {
    if (_isScheduledLoading) return;
    if (loadMore) {
      if (!_scheduledHasMore) return;
      _scheduledPage++;
    } else {
      _scheduledPage = 1;
      _scheduledItems = [];
      _scheduledHasMore = true;
    }

    _isScheduledLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': _scheduledPage,
        'limit': 20,
      };
      if (_scheduledStatusFilter != 'all') {
        params['status'] = _scheduledStatusFilter;
      }

      final res = await _api.get(
        ApiConstants.scheduledPosts(pageId),
        queryParameters: params,
      );

      if (res.data['success'] == true) {
        final list = (res.data['data'] as List?)
                ?.map((e) => ContentItem.fromJson({...e, '_source': 'scheduled'}))
                .toList() ??
            [];
        if (loadMore) {
          _scheduledItems.addAll(list);
        } else {
          _scheduledItems = list;
        }
        _scheduledTotal = res.data['total'] ?? list.length;
        _scheduledHasMore = list.length >= 20;

        // Parse status counts if available
        _scheduledCount = res.data['scheduled_count'] ?? 0;
        _failedCount = res.data['failed_count'] ?? 0;
        _cancelledCount = res.data['cancelled_count'] ?? 0;
      }
    } catch (_) {
      // silent
    }

    _isScheduledLoading = false;
    notifyListeners();
  }

  Future<bool> updateScheduledContent(
    String pageId,
    String scheduleId, {
    String? text,
    List<Map<String, String>>? media,
    DateTime? scheduledFor,
    String? contentType,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (text != null) data['text'] = text;
      if (media != null) data['media'] = media;
      if (scheduledFor != null) {
        data['scheduled_for'] = scheduledFor.toUtc().toIso8601String();
      }
      if (contentType != null) data['content_type'] = contentType;

      await _api.patch(
        ApiConstants.scheduledPostById(pageId, scheduleId),
        data: data,
      );
      // Refresh the scheduled list
      fetchScheduledPosts(pageId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> publishStoryNow(
    String pageId, {
    required String text,
    required Map<String, dynamic> storyMeta,
  }) async {
    try {
      final res = await _api.post(
        ApiConstants.publishStoryNow(pageId),
        data: {
          'text': text,
          'story_meta': storyMeta,
        },
      );
      if (res.data['success'] == true) {
        fetchContent(pageId);
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, String>>?> uploadMedia(
    String pageId,
    FormData formData,
  ) async {
    // Retry up to 3 times with exponential backoff
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await _api.uploadFile(
          ApiConstants.contentUploadMedia(pageId),
          formData: formData,
        );
        if (res.data['success'] == true) {
          return (res.data['data'] as List)
              .map((m) => {
                    'url': m['url'] as String,
                    'type': m['type'] as String,
                  })
              .toList();
        }
        return null;
      } catch (e) {
        final isRetryable = e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.sendTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.connectionError ||
             (e.response?.statusCode != null && e.response!.statusCode! >= 500));
        if (!isRetryable || attempt == maxRetries) {
          debugPrint('[ContentProvider] uploadMedia failed after $attempt attempts: $e');
          return null;
        }
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
    return null;
  }

  /// Upload media for an already-published post.
  /// Returns a list of filename strings on success, null on failure.
  Future<List<String>?> uploadPostMedia(
    String pageId,
    FormData formData,
  ) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await _api.uploadFile(
          ApiConstants.publishedPostUploadMedia(pageId),
          formData: formData,
        );
        if (res.data['success'] == true) {
          return (res.data['data'] as List)
              .map((f) => f.toString())
              .toList();
        }
        return null;
      } catch (e) {
        final isRetryable = e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.sendTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.connectionError ||
             (e.response?.statusCode != null && e.response!.statusCode! >= 500));
        if (!isRetryable || attempt == maxRetries) {
          debugPrint('[ContentProvider] uploadPostMedia failed after $attempt attempts: $e');
          return null;
        }
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> scheduleContent(
    String pageId, {
    required Map<String, dynamic> data,
    bool skipRefresh = false,
  }) async {
    try {
      final res = await _api.post(
        ApiConstants.contentSchedule(pageId),
        data: data,
      );
      if (res.data['success'] == true) {
        // Skip background refresh when posting now — publishNow will handle it
        if (!skipRefresh) {
          fetchContent(pageId);
          fetchScheduledPosts(pageId);
        }
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Start auto-polling scheduled posts when items are near-expiry
  void startPolling(String pageId) {
    stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final hasNearExpiry = _scheduledItems.any((item) {
        if (item.status == 'Publishing') return true;
        if (item.scheduledFor == null) return false;
        final diff = item.scheduledFor!.difference(DateTime.now());
        return diff.inMinutes <= 2 && diff.inSeconds > 0;
      });
      if (hasNearExpiry) {
        fetchScheduledPosts(pageId);
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
