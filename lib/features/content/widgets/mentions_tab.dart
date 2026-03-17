import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/models/post_model.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../../../features/posts/widgets/post_card.dart';
import '../../../features/posts/widgets/comment_modal.dart';
import '../../../features/posts/widgets/reactions_bottom_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qp_loading.dart';
import '../providers/content_provider.dart';

/// Mentions and tags tab with Facebook/Instagram platform filter.
class MentionsTab extends StatefulWidget {
  const MentionsTab({super.key});

  @override
  State<MentionsTab> createState() => _MentionsTabState();
}

class _MentionsTabState extends State<MentionsTab> {
  String? _lastPageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMentions());
  }

  void _loadMentions() {
    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId != null) {
      _lastPageId = pageId;
      context.read<ContentProvider>().fetchContentByType(pageId, 'Mention');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for page changes
    final currentPageId = context.watch<ManagedPagesProvider>().activePageId;
    if (currentPageId != null && currentPageId != _lastPageId) {
      _lastPageId = currentPageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ContentProvider>().fetchContentByType(currentPageId, 'Mention');
        }
      });
    }

    final content = context.watch<ContentProvider>();
    final mentions = content.mentionItems;

    return Column(
      children: [
        // Content
        Expanded(
          child: content.isTypeLoading && mentions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: QpLoading(itemCount: 3, height: 150),
                )
              : mentions.isEmpty
                  ? const EmptyState(
                      icon: Icons.alternate_email,
                      title: 'No mentions yet',
                      subtitle:
                          'Posts where your page is mentioned or tagged will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadMentions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: mentions.length,
                        itemBuilder: (context, index) {
                          final item = mentions[index];
                          // Convert ContentItem to a basic PostModel for the card
                          final post = _contentToPost(item);
                          return _MentionPostCard(
                            post: post,
                            index: index,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  PostModel _contentToPost(dynamic item) {
    // Build a PostModel from content item data
    return PostModel(
      id: item.id,
      description: item.displayText,
      createdAt: item.createdAt.toIso8601String(),
      reactionCount: item.likeCount,
      totalComments: item.commentCount,
      postShareCount: item.shareCount,
      view_count: item.viewCount,
      user_id: item.authorName != null
          ? null // Will show page info instead
          : null,
    );
  }
}

class _MentionPostCard extends StatelessWidget {
  final PostModel post;
  final int index;
  const _MentionPostCard({
    required this.post,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final authUser = context.read<AuthProvider>().user;
    final currentUserId = authUser?.id ?? '';
    final currentUserProfilePic = authUser?.profilePic;
    final postProvider = context.read<PostProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: PostCard(
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
        onPressedShare: () {},
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
    );
  }
}


