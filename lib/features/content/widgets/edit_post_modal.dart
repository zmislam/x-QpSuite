import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/models/media_model.dart';
import '../../../features/posts/models/post_model.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../providers/content_provider.dart';

/// Modal for editing a published post — mirrors the web EditPublishedModal
/// with full media CRUD (add/remove), 3-column grid, video support,
/// and "Add to your post" toolbar.
class EditPostModal extends StatefulWidget {
  final PostModel post;

  const EditPostModal({super.key, required this.post});

  static Future<bool?> show(BuildContext context, {required PostModel post}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditPostModal(post: post),
    );
  }

  @override
  State<EditPostModal> createState() => _EditPostModalState();
}

class _EditPostModalState extends State<EditPostModal> {
  late final TextEditingController _textController;
  final _picker = ImagePicker();

  List<MediaModel> _existingMedia = [];
  final List<String> _removedMediaIds = [];
  final List<XFile> _newMediaFiles = [];
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.post.description ?? '');
    _existingMedia = List.from(widget.post.media ?? []);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _totalMedia => _existingMedia.length + _newMediaFiles.length;

  bool get _hasChanges {
    final textChanged =
        _textController.text.trim() != (widget.post.description ?? '').trim();
    return textChanged ||
        _removedMediaIds.isNotEmpty ||
        _newMediaFiles.isNotEmpty;
  }

  bool _isVideoFile(XFile file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
  }

  Future<void> _pickMedia() async {
    final maxNew = 10 - _totalMedia;
    if (maxNew <= 0) return;

    final files = await _picker.pickMultipleMedia(limit: maxNew);
    if (files.isNotEmpty) {
      setState(() {
        _newMediaFiles.addAll(files.take(maxNew));
      });
    }
  }

  void _removeExistingMedia(int index) {
    final m = _existingMedia[index];
    if (m.id != null) {
      _removedMediaIds.add(m.id!);
    }
    setState(() => _existingMedia.removeAt(index));
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null || widget.post.id == null) {
      setState(() {
        _isSaving = false;
        _error = 'Missing page or post ID';
      });
      return;
    }

    try {
      // Upload new media files if any
      List<String>? uploadedFilenames;
      if (_newMediaFiles.isNotEmpty) {
        final cp = context.read<ContentProvider>();
        final formData = FormData();
        for (final file in _newMediaFiles) {
          final bytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            'media',
            MultipartFile.fromBytes(bytes, filename: file.name),
          ));
        }
        var uploaded = await cp.uploadPostMedia(pageId, formData);

        // Fallback: upload one at a time if batch failed
        if (uploaded == null && _newMediaFiles.length > 1) {
          final List<String> individualResults = [];
          bool allOk = true;
          for (final file in _newMediaFiles) {
            final singleForm = FormData();
            final bytes = await file.readAsBytes();
            singleForm.files.add(MapEntry(
              'media',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ));
            final result = await cp.uploadPostMedia(pageId, singleForm);
            if (result != null) {
              individualResults.addAll(result);
            } else {
              allOk = false;
              break;
            }
          }
          if (allOk && individualResults.isNotEmpty) {
            uploaded = individualResults;
          }
        }

        if (uploaded == null) {
          setState(() {
            _isSaving = false;
            _error = 'Failed to upload media';
          });
          return;
        }
        uploadedFilenames = uploaded;
      }

      final postProvider = context.read<PostProvider>();
      final success = await postProvider.editPost(
        pageId,
        widget.post.id!,
        description: _textController.text.trim(),
        addMedia: uploadedFilenames,
        removeMediaIds:
            _removedMediaIds.isNotEmpty ? _removedMediaIds : null,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated'),
            backgroundColor: Color(0xFF307777),
          ),
        );
      } else {
        setState(() {
          _isSaving = false;
          _error = 'Failed to update post. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final page = pagesProvider.activePage;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Page info
                  _buildPageRow(page),
                  const SizedBox(height: 12),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.red[700])),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Text input
                  TextField(
                    controller: _textController,
                    maxLines: _totalMedia > 0 ? 3 : 6,
                    maxLength: 10000,
                    decoration: InputDecoration(
                      hintText:
                          'What\'s on your mind, ${page?.pageName ?? ''}?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (_) => setState(() {}),
                  ),

                  // Media grid (combined existing + new)
                  _buildMediaGrid(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 24),
          ),
          const Expanded(
            child: Text(
              'Edit Post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _save : null,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _hasChanges ? AppColors.primary : Colors.grey[400],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE ROW ───────────────────────────────────
  Widget _buildPageRow(dynamic page) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: page?.profilePic != null
              ? NetworkImage(
                  ApiConstants.pageProfileUrl(page.profilePic))
              : null,
          child: page?.profilePic == null
              ? const Icon(Icons.store, size: 20)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            page?.pageName ?? 'Your Page',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // ─── MEDIA GRID ─────────────────────────────────
  Widget _buildMediaGrid() {
    if (_totalMedia == 0) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _totalMedia,
          itemBuilder: (_, i) {
            if (i < _existingMedia.length) {
              return _buildExistingMediaTile(i);
            }
            return _buildNewMediaTile(i - _existingMedia.length);
          },
        ),
      ],
    );
  }

  Widget _buildExistingMediaTile(int index) {
    final m = _existingMedia[index];
    final isVideo = m.isVideo;
    String url;
    if (isVideo &&
        m.videoThumbnail != null &&
        m.videoThumbnail!.isNotEmpty) {
      url = ApiConstants.videoThumbnailUrl(m.videoThumbnail);
    } else {
      url = ApiConstants.postMediaUrl(m.media);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                            isVideo ? Icons.videocam : Icons.image,
                            color: Colors.grey),
                      ))
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeExistingMedia(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        // Video badge
        if (isVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 14, color: Colors.white),
                  SizedBox(width: 2),
                  Text('Video',
                      style:
                          TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewMediaTile(int index) {
    final file = _newMediaFiles[index];
    final isVideo = _isVideoFile(file);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.videocam,
                        color: Colors.white54, size: 32),
                  ),
                )
              : kIsWeb
                  ? Image.network(file.path, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image,
                                color: Colors.grey),
                          ))
                  : Image.file(File(file.path), fit: BoxFit.cover),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _newMediaFiles.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        // Video badge
        if (isVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 14, color: Colors.white),
                  SizedBox(width: 2),
                  Text('Video',
                      style:
                          TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── BOTTOM BAR ─────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Add to your post" toolbar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text(
                  'Add to your post',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.photo_library,
                      color: Colors.green[600], size: 22),
                  onPressed: _pickMedia,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.emoji_emotions,
                      color: Colors.amber[600], size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _hasChanges && !_isSaving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF307777),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
