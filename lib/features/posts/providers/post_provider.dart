import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/comment_model.dart';
import '../models/media_model.dart';
import '../models/post_model.dart';
import '../models/post_utils.dart';

class PostProvider extends ChangeNotifier {
  final ApiService api;

  PostProvider({required this.api});

  // ── State ──
  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentPageId;

  // ── Comment State ──
  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;
  String? _commentPostId;
  bool _isReplying = false;
  String? _replyToCommentId;
  String? _replyToUserName;

  // ── Getters ──
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;
  List<CommentModel> get comments => _comments;
  bool get isLoadingComments => _isLoadingComments;
  String? get commentPostId => _commentPostId;
  bool get isReplying => _isReplying;
  String? get replyToCommentId => _replyToCommentId;
  String? get replyToUserName => _replyToUserName;

  // ═══════════════════════════════════════════════════
  // FETCH PAGE POSTS (using individual posts endpoint)
  // ═══════════════════════════════════════════════════

  Future<void> fetchPagePosts(String pageId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts = [];
    }

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    _currentPageId = pageId;
    notifyListeners();

    try {
      // Use page-specific posts endpoint
      final response = await api.post(
        '${ApiConstants.pagePosts}?pageNo=$_currentPage&pageSize=10',
        data: {
          'page_id': pageId,
          'user_role': 'admin',
        },
      );

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        final rawPosts = data['posts'];
        if (rawPosts is List) {
          final newPosts = rawPosts
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) {
                try {
                  return PostModel.fromMap(e as Map<String, dynamic>);
                } catch (err) {
                  debugPrint('Error parsing post: $err');
                  return null;
                }
              })
              .whereType<PostModel>()
              .toList();

          if (refresh || _currentPage == 1) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _totalPages = data['pageCount'] ?? 1;
          _currentPage++;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching posts: $e');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Fetch posts using individual posts endpoint (page username)
  Future<void> fetchPostsByUsername(String username,
      {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts = [];
    }

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await api.post(
        '${ApiConstants.individualPosts}?pageNo=$_currentPage&pageSize=10',
        data: {'username': username},
      );

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        final rawPosts = data['posts'];
        if (rawPosts is List) {
          final newPosts = rawPosts
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) {
                try {
                  return PostModel.fromMap(e as Map<String, dynamic>);
                } catch (err) {
                  debugPrint('Error parsing post: $err');
                  return null;
                }
              })
              .whereType<PostModel>()
              .toList();

          if (refresh || _currentPage == 1) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _totalPages = data['pageCount'] ?? 1;
          _currentPage++;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching posts: $e');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // DELETE PUBLISHED POST
  // ═══════════════════════════════════════════════════

  Future<bool> deletePost(String pageId, String postId) async {
    try {
      await api.delete(ApiConstants.publishedPostById(pageId, postId));
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // EDIT PUBLISHED POST (description)
  // ═══════════════════════════════════════════════════

  Future<bool> editPost(String pageId, String postId, {
    String? description,
    List<String>? addMedia,
    List<String>? removeMediaIds,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (addMedia != null && addMedia.isNotEmpty) data['addMedia'] = addMedia;
      if (removeMediaIds != null && removeMediaIds.isNotEmpty) {
        data['removeMediaIds'] = removeMediaIds;
      }

      final res = await api.patch(
        ApiConstants.publishedPostById(pageId, postId),
        data: data,
      );

      // Update local state from API response
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final resData = res.data['data'];
        if (resData != null && resData is Map<String, dynamic>) {
          if (description != null) {
            _posts[index].description = description;
          }
          // Refresh media list from response
          if (resData['media'] != null) {
            _posts[index].media = List<MediaModel>.from(
              (resData['media'] as List).map((x) => MediaModel.fromMap(x)),
            );
          }
        } else if (description != null) {
          _posts[index].description = description;
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error editing post: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // REACT ON POST (optimistic)
  // ═══════════════════════════════════════════════════

  Future<void> reactOnPost({
    required int postIndex,
    required String reactionType,
    required String userId,
  }) async {
    if (postIndex < 0 || postIndex >= _posts.length) return;

    final post = _posts[postIndex];

    // Optimistic update
    applyOptimisticReaction(
      post: post,
      userId: userId,
      reactionType: reactionType,
    );
    notifyListeners();

    // Fire API call
    try {
      await api.post(
        ApiConstants.reactOnPost,
        data: {
          'reaction_type': reactionType,
          'post_id': post.id,
          'post_single_item_id': null,
          'key': post.key ?? '',
        },
      );
    } catch (e) {
      debugPrint('Error reacting on post: $e');
      // Could revert optimistic update here if needed
    }
  }

  // ═══════════════════════════════════════════════════
  // FETCH COMMENTS
  // ═══════════════════════════════════════════════════

  Future<void> fetchComments(String postId) async {
    _isLoadingComments = true;
    _commentPostId = postId;
    _comments = [];
    notifyListeners();

    try {
      final response = await api.get(ApiConstants.getComments(postId));
      final data = response.data;

      if (data != null && data is Map<String, dynamic>) {
        final rawComments = data['comments'];
        if (rawComments is List) {
          _comments = rawComments
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => CommentModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }

    _isLoadingComments = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // SEND COMMENT
  // ═══════════════════════════════════════════════════

  Future<void> sendComment({
    required String postId,
    required String comment,
    required String postUserId,
    String? key,
  }) async {
    try {
      await api.post(
        ApiConstants.sendComment,
        data: {
          'user_id': postUserId,
          'post_id': postId,
          'comment_name': comment,
          'link': null,
          'link_title': null,
          'link_description': null,
          'link_image': null,
          'image_or_video': null,
          'key': key ?? '',
        },
      );

      // Update comment count on the post
      final postIdx = _posts.indexWhere((p) => p.id == postId);
      if (postIdx != -1) {
        _posts[postIdx].totalComments =
            (_posts[postIdx].totalComments ?? 0) + 1;
      }

      // Refresh comments
      await fetchComments(postId);
    } catch (e) {
      debugPrint('Error sending comment: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // REPLY TO COMMENT
  // ═══════════════════════════════════════════════════

  void setReplyTarget(String commentId, String userName) {
    _isReplying = true;
    _replyToCommentId = commentId;
    _replyToUserName = userName;
    notifyListeners();
  }

  void cancelReply() {
    _isReplying = false;
    _replyToCommentId = null;
    _replyToUserName = null;
    notifyListeners();
  }

  Future<void> replyToComment({
    required String commentId,
    required String replyText,
    required String postId,
    required String replyUserId,
  }) async {
    try {
      await api.post(
        ApiConstants.replyComment,
        data: {
          'comment_id': commentId,
          'replies_user_id': replyUserId,
          'replies_comment_name': replyText,
          'post_id': postId,
          'image_or_video': null,
        },
      );

      cancelReply();
      await fetchComments(postId);
    } catch (e) {
      debugPrint('Error replying to comment: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // REACT ON COMMENT
  // ═══════════════════════════════════════════════════

  Future<void> reactOnComment({
    required String postId,
    required String commentId,
    required String reactionType,
    String? commentRepliesId,
  }) async {
    try {
      final data = <String, dynamic>{
        'reaction_type': reactionType,
        'post_id': postId,
        'comment_id': commentId,
      };
      if (commentRepliesId != null) {
        data['comment_replies_id'] = commentRepliesId;
      }

      await api.post(ApiConstants.reactOnComment, data: data);

      // Refresh comments to show updated reactions
      await fetchComments(postId);
    } catch (e) {
      debugPrint('Error reacting on comment: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════

  void clear() {
    _posts = [];
    _comments = [];
    _isLoading = false;
    _isLoadingMore = false;
    _isLoadingComments = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _currentPageId = null;
    _commentPostId = null;
    _isReplying = false;
    _replyToCommentId = null;
    _replyToUserName = null;
    notifyListeners();
  }
}
