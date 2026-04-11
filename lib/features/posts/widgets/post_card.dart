import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../content/widgets/media_viewer_modal.dart';
import '../models/media_model.dart';
import '../models/post_assets.dart';
import '../models/post_model.dart';
import '../models/post_utils.dart';
import 'reaction_button.dart';

/// Full-featured PostCard ported from QPF.
/// Displays: page header, description body, media, reaction footer.
class PostCard extends StatelessWidget {
  final PostModel model;
  final int index;
  final String currentUserId;
  final Function(String reaction) onSelectReaction;
  final VoidCallback onPressedComment;
  final VoidCallback onPressedShare;
  final VoidCallback onTapViewReactions;

  const PostCard({
    super.key,
    required this.model,
    required this.index,
    required this.currentUserId,
    required this.onSelectReaction,
    required this.onPressedComment,
    required this.onPressedShare,
    required this.onTapViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    if (model.user_id == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───
            _PostHeader(model: model),

            // ─── Body ───
            _PostBody(model: model),

            // ─── Footer ───
            _PostFooter(
              model: model,
              currentUserId: currentUserId,
              onSelectReaction: onSelectReaction,
              onPressedComment: onPressedComment,
              onPressedShare: onPressedShare,
              onTapViewReactions: onTapViewReactions,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Post Header (Page Post) ──
// ─────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  final PostModel model;
  const _PostHeader({required this.model});

  @override
  Widget build(BuildContext context) {
    final isPagePost = (model.page_id.pageName?.isNotEmpty ?? false);

    final String name;
    final String? profilePic;

    if (isPagePost) {
      name = model.page_id.pageName ?? 'Page';
      profilePic = model.page_id.profilePic;
    } else {
      name = model.user_id?.fullName ?? 'User';
      profilePic = model.user_id?.profile_pic;
    }

    final avatarUrl = profilePic != null && profilePic.isNotEmpty
        ? (isPagePost
            ? ApiConstants.pageProfileUrl(profilePic)
            : ApiConstants.userProfileUrl(profilePic))
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            onBackgroundImageError:
                avatarUrl.isNotEmpty ? (_, __) {} : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 10),

          // Name + time + privacy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      formatPostTime(model.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('·',
                        style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(
                      _privacyIcon(model.post_privacy),
                      size: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black54),
            onPressed: () => _showPostMenu(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _privacyIcon(String? privacy) {
    switch (privacy) {
      case 'friends':
        return Icons.people_outline;
      case 'only_me':
        return Icons.lock_outline;
      default:
        return Icons.public;
    }
  }

  void _showPostMenu(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.bookmark_border_outlined),
              title: const Text('Save Post'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('Copy link'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide Post'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Post Body (Description + Media) ──
// ─────────────────────────────────────────────────────

class _PostBody extends StatefulWidget {
  final PostModel model;
  const _PostBody({required this.model});

  @override
  State<_PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<_PostBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.model.description ?? '';
    final hasMedia =
        widget.model.media != null && widget.model.media!.isNotEmpty;
    final hasBgColor = widget.model.post_background_color != null &&
        widget.model.post_background_color!.isNotEmpty &&
        !hasMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Description ──
        if (description.isNotEmpty) ...[
          if (hasBgColor) ...[
            _buildBgDescription(description),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: _buildDescriptionText(description),
            ),
          ],
        ],

        // ── Media ──
        if (hasMedia) _buildMedia(),
      ],
    );
  }

  Widget _buildBgDescription(String description) {
    Color bgColor;
    try {
      final colorStr = widget.model.post_background_color!.replaceAll('#', '');
      bgColor = Color(int.parse('FF$colorStr', radix: 16));
    } catch (_) {
      bgColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(minHeight: 200),
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescriptionText(String description) {
    const int maxLength = 200;
    final bool needsExpand = description.length > maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _expanded || !needsExpand
              ? description
              : '${description.substring(0, maxLength)}...',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        if (needsExpand)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'See less' : 'See more',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Returns the best image URL for displaying a media item.
  /// For videos, uses the video thumbnail; for images, uses the media file.
  String _mediaDisplayUrl(MediaModel m) {
    if (m.isVideo && m.videoThumbnail != null && m.videoThumbnail!.isNotEmpty) {
      return ApiConstants.videoThumbnailUrl(m.videoThumbnail);
    }
    return ApiConstants.postMediaUrl(m.media);
  }

  /// Converts MediaModel list to ViewableMedia list for the modal viewer.
  List<ViewableMedia> _toViewableMedia() {
    return widget.model.media!
        .map((m) => ViewableMedia(
              url: m.media ?? '',
              type: m.isVideo ? 'video' : 'image',
              thumbnailUrl: m.videoThumbnail,
            ))
        .toList();
  }

  void _openMediaViewer(BuildContext context, int index) {
    MediaViewerModal.show(
      context,
      mediaList: _toViewableMedia(),
      initialIndex: index,
    );
  }

  Widget _buildMedia() {
    final mediaList = widget.model.media!;
    final count = mediaList.length;

    if (count == 1) {
      final url = _mediaDisplayUrl(mediaList[0]);
      return GestureDetector(
        onTap: () => _openMediaViewer(context, 0),
        child: _mediaImage(url, isVideo: mediaList[0].isVideo),
      );
    }

    // Multi-media grid
    if (count == 2) {
      return Row(
        children: [
          Expanded(
              child: GestureDetector(
                  onTap: () => _openMediaViewer(context, 0),
                  child: _mediaImage(
                      _mediaDisplayUrl(mediaList[0]),
                      height: 250,
                      isVideo: mediaList[0].isVideo))),
          const SizedBox(width: 2),
          Expanded(
              child: GestureDetector(
                  onTap: () => _openMediaViewer(context, 1),
                  child: _mediaImage(
                      _mediaDisplayUrl(mediaList[1]),
                      height: 250,
                      isVideo: mediaList[1].isVideo))),
        ],
      );
    }

    // 3+ images: first image full width, rest in a row
    return Column(
      children: [
        GestureDetector(
          onTap: () => _openMediaViewer(context, 0),
          child: _mediaImage(_mediaDisplayUrl(mediaList[0]),
              isVideo: mediaList[0].isVideo),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            for (int i = 1; i < (count > 4 ? 4 : count); i++) ...[
              if (i > 1) const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openMediaViewer(context, i),
                  child: Stack(
                    children: [
                      _mediaImage(
                          _mediaDisplayUrl(mediaList[i]),
                          height: 150,
                          isVideo: mediaList[i].isVideo),
                      if (i == 3 && count > 4)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            alignment: Alignment.center,
                            child: Text(
                              '+${count - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _mediaImage(String url, {double? height, bool isVideo = false}) {
    if (url.isEmpty) {
      return Container(
        height: height ?? 280,
        color: AppColors.surfaceLight,
        child:
            const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
      );
    }

    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: height ?? 280,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: height ?? 280,
            color: AppColors.surfaceLight,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            height: height ?? 280,
            color: AppColors.surfaceLight,
            child:
                const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
          ),
        ),
        // Video play icon overlay
        if (isVideo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// ── Post Footer (Reactions, Comments, Share) ──
// ─────────────────────────────────────────────────────

class _PostFooter extends StatelessWidget {
  final PostModel model;
  final String currentUserId;
  final Function(String reaction) onSelectReaction;
  final VoidCallback onPressedComment;
  final VoidCallback onPressedShare;
  final VoidCallback onTapViewReactions;

  const _PostFooter({
    required this.model,
    required this.currentUserId,
    required this.onSelectReaction,
    required this.onPressedComment,
    required this.onPressedShare,
    required this.onTapViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final int reactionCount = model.reactionCount ?? 0;
    final int commentCount = model.totalComments ?? 0;
    final int shareCount = model.postShareCount ?? 0;

    // Get the user's selected reaction
    final userReactionType = getUserReactionType(model, currentUserId);
    Reaction? selectedReaction;
    if (userReactionType != null) {
      try {
        selectedReaction = kDefaultReactions.firstWhere(
          (r) => r.key == userReactionType,
        );
      } catch (_) {
        selectedReaction = kDefaultReactions.first;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Counts row (above divider) ───
        if (reactionCount > 0 || commentCount > 0 || shareCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              children: [
                if (reactionCount > 0) ...[
                  GestureDetector(
                    onTap: onTapViewReactions,
                    child: Row(
                      children: [
                        _buildReactionIcons(),
                        const SizedBox(width: 4),
                        Text(
                          formatCount(reactionCount),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (commentCount > 0)
                  GestureDetector(
                    onTap: onPressedComment,
                    child: Text(
                      '$commentCount comment${commentCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                if (shareCount > 0) ...[
                  if (commentCount > 0) const SizedBox(width: 12),
                  Text(
                    '$shareCount share${shareCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

        const Divider(height: 1, indent: 14, endIndent: 14),

        // ─── Action buttons row ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              // ─── Reaction Button ───
              Expanded(
                child: Center(
                  child: ReactionButton(
                    value: selectedReaction,
                    onChanged: (reaction) {
                      HapticFeedback.lightImpact();
                      if (reaction != null) {
                        onSelectReaction(reaction.key);
                      } else {
                        // Toggle off — send "like" to toggle
                        onSelectReaction(userReactionType ?? 'like');
                      }
                    },
                    isShowLabel: true,
                  ),
                ),
              ),

              // ─── Comment Button ───
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onPressedComment();
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: AppColors.textSecondaryLight),
                  label: const Text(
                    'Comment',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // ─── Share Button ───
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onPressedShare();
                  },
                  icon: Icon(Icons.reply_rounded,
                      size: 20,
                      color: AppColors.textSecondaryLight,
                      textDirection: TextDirection.rtl),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build stacked reaction icons (like Facebook's overlapping circles)
  Widget _buildReactionIcons() {
    final reactionAssetPaths = getReactionAssets(model, maxCount: 3);

    if (reactionAssetPaths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.thumb_up, size: 10, color: Colors.white),
      );
    }

    return SizedBox(
      width: reactionAssetPaths.length * 14.0 + 6,
      height: 22,
      child: Stack(
        children: [
          for (int i = 0; i < reactionAssetPaths.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    reactionAssetPaths[i],
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
