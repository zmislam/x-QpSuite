import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/comment_model.dart';
import '../models/post_assets.dart';
import '../models/post_model.dart';
import '../models/post_utils.dart';
import '../providers/post_provider.dart';

// ─── Sort mode enum ──────────────────────────────────

enum CommentSortMode { mostRelevant, newest, allComments }

String _sortLabel(CommentSortMode m) {
  switch (m) {
    case CommentSortMode.mostRelevant:
      return 'Most Relevant';
    case CommentSortMode.newest:
      return 'Newest';
    case CommentSortMode.allComments:
      return 'All Comments';
  }
}

// ─── Sort helper ─────────────────────────────────────

int _engagementScore(CommentModel c) {
  return (c.comment_reactions?.length ?? 0) * 2 + (c.replies?.length ?? 0);
}

List<CommentModel> _sortComments(List<CommentModel> list, CommentSortMode mode) {
  final sorted = List<CommentModel>.from(list);
  switch (mode) {
    case CommentSortMode.newest:
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      break;
    case CommentSortMode.mostRelevant:
      sorted.sort((a, b) {
        final s = _engagementScore(b).compareTo(_engagementScore(a));
        if (s != 0) return s;
        final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      break;
    case CommentSortMode.allComments:
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return da.compareTo(db);
      });
      break;
  }
  return sorted;
}

// ═════════════════════════════════════════════════════
// COMMENT MODAL — shows as DraggableScrollableSheet
// ═════════════════════════════════════════════════════

/// Opens the comment modal bottom sheet.
void showCommentModal(
  BuildContext context, {
  required PostModel post,
  required int postIndex,
  required String currentUserId,
  String? currentUserProfilePic,
}) {
  // Fetch comments when opening
  final postProvider = context.read<PostProvider>();
  if (post.id != null) {
    postProvider.fetchComments(post.id!);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: postProvider,
      child: _CommentModalContent(
        post: post,
        postIndex: postIndex,
        currentUserId: currentUserId,
        currentUserProfilePic: currentUserProfilePic,
      ),
    ),
  );
}

class _CommentModalContent extends StatefulWidget {
  final PostModel post;
  final int postIndex;
  final String currentUserId;
  final String? currentUserProfilePic;

  const _CommentModalContent({
    required this.post,
    required this.postIndex,
    required this.currentUserId,
    this.currentUserProfilePic,
  });

  @override
  State<_CommentModalContent> createState() => _CommentModalContentState();
}

class _CommentModalContentState extends State<_CommentModalContent> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  CommentSortMode _sortMode = CommentSortMode.mostRelevant;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(child: _buildCommentList(scrollController)),
              _buildInputArea(context),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final reactionAssets = getReactionAssets(widget.post, maxCount: 3);
    final reactionCount = widget.post.reactionCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Reaction icons + count
              if (reactionAssets.isNotEmpty) ...[
                Row(
                  children: [
                    for (final asset in reactionAssets)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Image.asset(asset, width: 20, height: 20),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Text(
                  '$reactionCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.thumb_up,
                      size: 12, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text('$reactionCount',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],

              const Spacer(),

              // Comment count
              Text(
                '${widget.post.totalComments ?? 0} comment${(widget.post.totalComments ?? 0) == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sort trigger
          Row(
            children: [
              GestureDetector(
                onTap: _showSortPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sortLabel(_sortMode),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        size: 20, color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[350],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sort comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            for (final mode in CommentSortMode.values)
              ListTile(
                title: Text(_sortLabel(mode)),
                trailing: _sortMode == mode
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _sortMode = mode);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Comment List ─────────────────────────────────

  Widget _buildCommentList(ScrollController scrollController) {
    return Consumer<PostProvider>(
      builder: (_, provider, __) {
        if (provider.isLoadingComments) {
          return const Center(child: CircularProgressIndicator());
        }

        final sorted = _sortComments(provider.comments, _sortMode);

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text(
                  'No comments yet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Be the first to comment.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            return _CommentTile(
              comment: sorted[index],
              currentUserId: widget.currentUserId,
              postId: widget.post.id ?? '',
              onReply: (commentId, userName) {
                provider.setReplyTarget(commentId, userName);
                _focusNode.requestFocus();
              },
              onReactOnComment: (commentId, reaction) {
                provider.reactOnComment(
                  postId: widget.post.id ?? '',
                  commentId: commentId,
                  reactionType: reaction,
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Input Area ───────────────────────────────────

  Widget _buildInputArea(BuildContext context) {
    final avatarUrl = widget.currentUserProfilePic != null &&
            widget.currentUserProfilePic!.isNotEmpty
        ? ApiConstants.userProfileUrl(widget.currentUserProfilePic!)
        : '';

    return Consumer<PostProvider>(
      builder: (_, provider, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply banner
              if (provider.isReplying)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Replying to ${provider.replyToUserName ?? "User"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: provider.cancelReply,
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),

              // Input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // User avatar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 16, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                hintText: provider.isReplying
                                    ? 'Reply to ${provider.replyToUserName}...'
                                    : 'Write a comment...',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryLight,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, right: 4),
                            child: InkWell(
                              onTap: () {
                                // TODO: pick media for comment
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt_outlined,
                                    size: 20,
                                    color: AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => _sendComment(provider),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendComment(PostProvider provider) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (provider.isReplying && provider.replyToCommentId != null) {
      provider.replyToComment(
        commentId: provider.replyToCommentId!,
        replyText: text,
        postId: widget.post.id ?? '',
        replyUserId: widget.currentUserId,
      );
    } else {
      provider.sendComment(
        postId: widget.post.id ?? '',
        comment: text,
        postUserId: widget.post.user_id?.id ?? '',
        key: widget.post.key,
      );
    }

    _commentController.clear();
    _focusNode.unfocus();
  }
}

// ═════════════════════════════════════════════════════
// COMMENT TILE — single comment with replies
// ═════════════════════════════════════════════════════

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final String postId;
  final Function(String commentId, String userName) onReply;
  final Function(String commentId, String reaction) onReactOnComment;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.postId,
    required this.onReply,
    required this.onReactOnComment,
  });

  @override
  Widget build(BuildContext context) {
    final user = comment.user_id;
    final name = user?.fullName ?? 'User';
    final profilePic = user?.profile_pic;
    final avatarUrl = profilePic != null && profilePic.isNotEmpty
        ? ApiConstants.userProfileUrl(profilePic)
        : '';
    final isVerified = user?.isProfileVerified ?? false;
    final mediaPath = comment.image_or_video ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Comment ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 8),

              // Comment bubble + actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: AppColors.primary, size: 14),
                              ],
                            ],
                          ),
                          if (comment.comment_name != null &&
                              comment.comment_name!.isNotEmpty &&
                              comment.comment_name != 'null') ...[
                            const SizedBox(height: 4),
                            Text(
                              comment.comment_name!,
                              style: const TextStyle(fontSize: 14, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Comment media
                    if (mediaPath.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: ApiConstants.postMediaUrl(mediaPath),
                          height: 200,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    // Actions row: time, Like, Reply, reaction icons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            formatCommentTime(comment.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Like
                          GestureDetector(
                            onTap: () => onReactOnComment(
                                comment.id ?? '', 'like'),
                            child: Text(
                              _getCommentReactionLabel(comment),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getCommentReactionColor(comment),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Reply
                          GestureDetector(
                            onTap: () => onReply(
                              comment.id ?? '',
                              user?.first_name ?? 'User',
                            ),
                            child: const Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Comment reaction icons
                          _CommentReactionIcons(comment: comment),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // More menu (own comments only)
              if (currentUserId == user?.id)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: Colors.grey, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  offset: const Offset(-50, 0),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (val) {
                    // TODO: handle delete
                  },
                )
              else
                const SizedBox(width: 50),
            ],
          ),

          // ── Replies ──
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 52),
              child: Column(
                children: [
                  for (final reply in comment.replies!)
                    _ReplyTile(
                      reply: reply,
                      currentUserId: currentUserId,
                      comment: comment,
                      onReply: onReply,
                      onReactOnComment: onReactOnComment,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getCommentReactionLabel(CommentModel c) {
    for (final r in c.comment_reactions ?? []) {
      if (r.user_id == currentUserId && r.reaction_type != null) {
        final t = r.reaction_type!;
        return t[0].toUpperCase() + t.substring(1);
      }
    }
    return 'Like';
  }

  Color _getCommentReactionColor(CommentModel c) {
    for (final r in c.comment_reactions ?? []) {
      if (r.user_id == currentUserId) {
        switch (r.reaction_type) {
          case 'like':
            return AppColors.primary;
          case 'love':
            return Colors.red;
          case 'haha':
          case 'wow':
            return Colors.amber.shade700;
          case 'sad':
            return Colors.amber.shade800;
          case 'angry':
            return Colors.orange.shade700;
          default:
            return AppColors.primary;
        }
      }
    }
    return AppColors.textSecondaryLight;
  }
}

// ═════════════════════════════════════════════════════
// REPLY TILE — nested under a comment
// ═════════════════════════════════════════════════════

class _ReplyTile extends StatelessWidget {
  final CommentReply reply;
  final String currentUserId;
  final CommentModel comment;
  final Function(String commentId, String userName) onReply;
  final Function(String commentId, String reaction) onReactOnComment;

  const _ReplyTile({
    required this.reply,
    required this.currentUserId,
    required this.comment,
    required this.onReply,
    required this.onReactOnComment,
  });

  @override
  Widget build(BuildContext context) {
    final user = reply.replies_user_id;
    final name = user?.fullName ?? 'User';
    final profilePic = user?.profile_pic;
    final avatarUrl = profilePic != null && profilePic.isNotEmpty
        ? ApiConstants.userProfileUrl(profilePic)
        : '';
    final isVerified = user?.isProfileVerified ?? false;
    final mediaPath = reply.image_or_video ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 6),

          // Reply bubble + actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: AppColors.primary, size: 14),
                          ],
                        ],
                      ),
                      if (reply.replies_comment_name != null &&
                          reply.replies_comment_name!.isNotEmpty &&
                          reply.replies_comment_name != 'null') ...[
                        const SizedBox(height: 4),
                        Text(
                          reply.replies_comment_name!,
                          style: const TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),

                // Reply media
                if (mediaPath.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.postMediaUrl(mediaPath),
                      height: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                // Actions: time + Like + Reply
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        formatCommentTime(reply.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onReactOnComment(
                          comment.id ?? '',
                          'like',
                        ),
                        child: Text(
                          _getReplyReactionLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getReplyReactionColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onReply(
                          comment.id ?? '',
                          user?.first_name ?? 'User',
                        ),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _ReplyReactionIcons(reply: reply),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // More menu
          if (currentUserId == user?.id)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              offset: const Offset(-50, 0),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (val) {
                // TODO: handle delete
              },
            )
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }

  String _getReplyReactionLabel() {
    for (final r in reply.replies_comment_reactions ?? []) {
      if (r.user_id == currentUserId && r.reaction_type != null) {
        final t = r.reaction_type!;
        return t[0].toUpperCase() + t.substring(1);
      }
    }
    return 'Like';
  }

  Color _getReplyReactionColor() {
    for (final r in reply.replies_comment_reactions ?? []) {
      if (r.user_id == currentUserId) {
        switch (r.reaction_type) {
          case 'like':
            return AppColors.primary;
          case 'love':
            return Colors.red;
          case 'haha':
          case 'wow':
            return Colors.amber.shade700;
          case 'angry':
            return Colors.orange.shade700;
          default:
            return AppColors.primary;
        }
      }
    }
    return AppColors.textSecondaryLight;
  }
}

// ─── Reaction icon helpers ──────────────────────────

class _CommentReactionIcons extends StatelessWidget {
  final CommentModel comment;
  const _CommentReactionIcons({required this.comment});

  @override
  Widget build(BuildContext context) {
    final reactions = comment.comment_reactions ?? [];
    if (reactions.isEmpty) return const SizedBox.shrink();

    final Set<String> types = {};
    for (final r in reactions) {
      if (r.reaction_type != null) types.add(r.reaction_type!);
      if (types.length >= 3) break;
    }

    if (types.isEmpty) return const SizedBox.shrink();

    final icons = <Widget>[];
    for (final type in types) {
      final asset = PostAssets.reactionAsset(type);
      if (asset != null) {
        icons.add(Image.asset(asset, width: 16, height: 16));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...icons,
        if (reactions.length > 1) ...[
          const SizedBox(width: 2),
          Text(
            '${reactions.length}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondaryLight),
          ),
        ],
      ],
    );
  }
}

class _ReplyReactionIcons extends StatelessWidget {
  final CommentReply reply;
  const _ReplyReactionIcons({required this.reply});

  @override
  Widget build(BuildContext context) {
    final reactions = reply.replies_comment_reactions ?? [];
    if (reactions.isEmpty) return const SizedBox.shrink();

    final Set<String> types = {};
    for (final r in reactions) {
      if (r.reaction_type != null) types.add(r.reaction_type!);
      if (types.length >= 3) break;
    }

    if (types.isEmpty) return const SizedBox.shrink();

    final icons = <Widget>[];
    for (final type in types) {
      final asset = PostAssets.reactionAsset(type);
      if (asset != null) {
        icons.add(Image.asset(asset, width: 14, height: 14));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...icons,
        if (reactions.length > 1) ...[
          const SizedBox(width: 2),
          Text(
            '${reactions.length}',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondaryLight),
          ),
        ],
      ],
    );
  }
}
