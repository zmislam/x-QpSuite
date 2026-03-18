import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/models/post_model.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../features/posts/widgets/post_card.dart';
import '../../../features/posts/widgets/comment_modal.dart';
import '../../../features/posts/widgets/reactions_bottom_sheet.dart';
import 'edit_post_modal.dart';

/// A PostCard wrapper for Content section that adds an action bar
/// with Insights, Edit, Delete, and Boost buttons below the card,
/// matching the Meta Business Suite web design.
class ContentPostCard extends StatelessWidget {
  final PostModel post;
  final int index;

  const ContentPostCard({
    super.key,
    required this.post,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final authUser = context.read<AuthProvider>().user;
    final currentUserId = authUser?.id ?? '';
    final currentUserProfilePic = authUser?.profilePic;
    final postProvider = context.read<PostProvider>();

    return Column(
      children: [
        // ── The existing PostCard ──
        PostCard(
          model: post,
          index: index,
          currentUserId: currentUserId,
          onSelectReaction: (reaction) {
            postProvider.reactOnPost(
              postIndex: index,
              reactionType: reaction,
              userId: currentUserId,
            );
          },
          onPressedComment: () {
            showCommentModal(
              context,
              post: post,
              postIndex: index,
              currentUserId: currentUserId,
              currentUserProfilePic: currentUserProfilePic,
            );
          },
          onPressedShare: () {
            // TODO: Share sheet
          },
          onTapViewReactions: () {
            if (post.id != null) {
              ReactionsBottomSheet.show(
                context,
                postId: post.id!,
                api: context.read<ApiService>(),
              );
            }
          },
        ),

        // ── Action Bar: Insights · Edit · Delete · Boost ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.dividerLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              // Insights
              _ActionButton(
                icon: Icons.insights_outlined,
                label: 'Insights',
                onTap: () {
                  if (post.id != null) {
                    context.push('/insights/post/${post.id}');
                  }
                },
              ),
              const SizedBox(width: 4),
              // Edit
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _handleEdit(context),
              ),
              const SizedBox(width: 4),
              // Delete
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red[600],
                onTap: () => _handleDelete(context),
              ),
              const Spacer(),
              // Boost Post
              SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to boost creation
                  },
                  icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                  label: const Text('Boost Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  void _handleEdit(BuildContext context) async {
    final edited = await EditPostModal.show(context, post: post);
    if (edited == true) {
      // PostProvider already updated locally in editPost()
      final pageId = context.read<ManagedPagesProvider>().activePageId;
      if (pageId != null) {
        context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
      }
    }
  }

  void _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null || post.id == null) return;

    final success =
        await context.read<PostProvider>().deletePost(pageId, post.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Post deleted' : 'Failed to delete post'),
          backgroundColor: success ? const Color(0xFF307777) : Colors.red,
        ),
      );
    }
  }
}

/// Compact action button used in the Content post action bar.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[700]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
