import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/posts/models/post_model.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../features/posts/widgets/post_card.dart';
import '../../../features/posts/widgets/comment_modal.dart';
import '../../../features/posts/widgets/reactions_bottom_sheet.dart';

/// A PostCard wrapper for Content section that adds
/// "See Insights" and "Create Ad" action buttons below the card,
/// matching the Meta Business Suite design.
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

        // ── See Insights + Create Ad row ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // See Insights link
              GestureDetector(
                onTap: () {
                  if (post.id != null) {
                    context.push('/insights/post/${post.id}');
                  }
                },
                child: const Text(
                  'See Insights',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Create Ad button
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to ad creation
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Create Ad',
                    style: TextStyle(
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
}
