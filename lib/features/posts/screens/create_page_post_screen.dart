import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../page_switcher/models/managed_page_model.dart';
import '../providers/post_provider.dart';

/// Create Page Post screen — simple text post creation for a page.
class CreatePagePostScreen extends StatefulWidget {
  final ManagedPageModel page;

  const CreatePagePostScreen({super.key, required this.page});

  @override
  State<CreatePagePostScreen> createState() => _CreatePagePostScreenState();
}

class _CreatePagePostScreenState extends State<CreatePagePostScreen> {
  final TextEditingController _descController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;
  String _privacy = 'public';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canPost => _descController.text.trim().isNotEmpty && !_isPosting;

  Future<void> _createPost() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      final api = context.read<ApiService>();
      final response = await api.post(
        ApiConstants.savePagePost,
        data: {
          'page_id': widget.page.id,
          'description': _descController.text.trim(),
          'post_privacy': _privacy,
          'post_type': 'page_post',
        },
      );

      final data = response.data;
      if (data != null && mounted) {
        // Refresh the posts feed
        context
            .read<PostProvider>()
            .fetchPagePosts(widget.page.id, refresh: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final profilePicUrl = page.profilePic != null
        ? ApiConstants.pageProfileUrl(page.profilePic)
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canPost ? _createPost : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    _canPost ? AppColors.primary : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Page info + privacy ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Page avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profilePicUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.business,
                              size: 24,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.business,
                            size: 24,
                            color: Colors.grey.shade400,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.pageName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Privacy dropdown
                      GestureDetector(
                        onTap: _showPrivacyPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _privacy == 'public'
                                    ? Icons.public
                                    : _privacy == 'friends'
                                        ? Icons.people
                                        : Icons.lock,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _privacy[0].toUpperCase() +
                                    _privacy.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Text input ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _descController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 8),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // ── Bottom toolbar ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? 8
                  : MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.photo_library_outlined,
                  color: Colors.green.shade600,
                  label: 'Photo',
                  onTap: () {
                    // TODO: Image picker
                  },
                ),
                _ToolbarButton(
                  icon: Icons.videocam_outlined,
                  color: Colors.red.shade600,
                  label: 'Video',
                  onTap: () {
                    // TODO: Video picker
                  },
                ),
                _ToolbarButton(
                  icon: Icons.emoji_emotions_outlined,
                  color: Colors.amber.shade700,
                  label: 'Feeling',
                  onTap: () {
                    // TODO: Feeling picker
                  },
                ),
                _ToolbarButton(
                  icon: Icons.location_on_outlined,
                  color: Colors.red,
                  label: 'Location',
                  onTap: () {
                    // TODO: Location picker
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Who can see this post?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _PrivacyOption(
              icon: Icons.public,
              title: 'Public',
              subtitle: 'Anyone can see this post',
              isSelected: _privacy == 'public',
              onTap: () {
                setState(() => _privacy = 'public');
                Navigator.pop(ctx);
              },
            ),
            _PrivacyOption(
              icon: Icons.people,
              title: 'Friends',
              subtitle: 'Only friends can see this post',
              isSelected: _privacy == 'friends',
              onTap: () {
                setState(() => _privacy = 'friends');
                Navigator.pop(ctx);
              },
            ),
            _PrivacyOption(
              icon: Icons.lock,
              title: 'Only me',
              subtitle: 'Only you can see this post',
              isSelected: _privacy == 'only_me',
              onTap: () {
                setState(() => _privacy = 'only_me');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
