import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/inbox_models.dart';

class InboxProvider extends ChangeNotifier {
  final ApiService _api;

  List<InboxThread> _threads = [];
  bool _isLoading = false;
  String? _error;

  // Thread detail
  List<InboxMessage> _messages = [];
  bool _isMessagesLoading = false;
  bool _hasMoreMessages = true;
  int _messagePage = 1;
  String? _activeThreadId;
  bool _isSending = false;

  InboxProvider({required ApiService api}) : _api = api;

  List<InboxThread> get threads => _threads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<InboxMessage> get messages => _messages;
  bool get isMessagesLoading => _isMessagesLoading;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isSending => _isSending;

  Future<void> fetchThreads(String pageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.inbox(pageId));
      if (res.data['success'] == true) {
        final list = res.data['data']['threads'] as List? ??
            res.data['data'] as List? ??
            [];
        _threads = list.map((e) => InboxThread.fromJson(e)).toList();
      } else {
        _error = res.data['message'] ?? 'Failed to load inbox';
      }
    } catch (e) {
      _error = 'Could not load inbox.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchThreadMessages(String pageId, String threadId,
      {bool loadMore = false}) async {
    if (_isMessagesLoading) return;

    if (loadMore) {
      if (!_hasMoreMessages) return;
      _messagePage++;
    } else {
      _messagePage = 1;
      _messages = [];
      _hasMoreMessages = true;
      _activeThreadId = threadId;
    }

    _isMessagesLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.inboxThread(pageId, threadId),
        queryParameters: {'page': _messagePage, 'limit': 30},
      );
      if (res.data['success'] == true) {
        final list = res.data['data']['messages'] as List? ?? [];
        final msgs =
            list.map((e) => InboxMessage.fromJson(e)).toList();
        if (loadMore) {
          _messages.addAll(msgs);
        } else {
          _messages = msgs;
        }
        _hasMoreMessages = msgs.length >= 30;
      }
    } catch (_) {}

    _isMessagesLoading = false;
    notifyListeners();

    // Mark as read
    if (!loadMore) {
      _markRead(pageId, threadId);
    }
  }

  Future<bool> sendReply(
      String pageId, String threadId, String content) async {
    _isSending = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.inboxThreadReply(pageId, threadId),
        data: {'content': content},
      );
      if (res.data['success'] == true) {
        final msg = InboxMessage.fromJson(
            res.data['data']['message'] ?? res.data['data']);
        _messages.insert(0, msg);
        // Update last message in threads list
        final idx = _threads.indexWhere((t) => t.id == threadId);
        if (idx >= 0) {
          _threads[idx] = InboxThread(
            id: _threads[idx].id,
            contact: _threads[idx].contact,
            lastMessage: msg,
            updatedAt: DateTime.now(),
            isRead: true,
          );
        }
        _isSending = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isSending = false;
    notifyListeners();
    return false;
  }

  Future<void> _markRead(String pageId, String threadId) async {
    try {
      await _api.patch(ApiConstants.inboxThreadRead(pageId, threadId));
    } catch (_) {}
  }
}
