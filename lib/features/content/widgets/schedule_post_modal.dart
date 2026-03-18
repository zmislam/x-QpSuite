import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'quick_schedule_picker.dart';
import 'story_creator_panel.dart';

/// Full-screen modal bottom sheet for creating Post/Reel/Story
/// with scheduling — mirrors the web SchedulePostModal.
class SchedulePostModal extends StatefulWidget {
  const SchedulePostModal({super.key});

  /// Show the modal as a full-screen bottom sheet.
  /// Returns `true` if content was successfully posted/scheduled.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SchedulePostModal(),
    );
  }

  @override
  State<SchedulePostModal> createState() => _SchedulePostModalState();
}

class _SchedulePostModalState extends State<SchedulePostModal> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  // Core state
  String _contentType = 'Post'; // Post | Reel | Story
  String _postMode = 'schedule'; // schedule | now

  // Schedule picker state
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  // Media
  final List<XFile> _mediaFiles = [];

  // Story-specific state
  StoryMeta? _storyMeta;
  XFile? _storyFile;
  String _storyText = '';

  // Submission
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ─── Content type constraints ───────────────────
  int get _maxFiles {
    if (_contentType == 'Reel') return 1;
    if (_contentType == 'Story') return 1;
    return 10;
  }

  bool get _isReelVideoOnly => _contentType == 'Reel';

  String get _modalTitle {
    switch (_contentType) {
      case 'Reel':
        return 'Create reel';
      case 'Story':
        return 'Create story';
      default:
        return 'Create post';
    }
  }

  String get _submitLabel {
    if (_postMode == 'now') {
      switch (_contentType) {
        case 'Reel':
          return 'Post Reel';
        case 'Story':
          return 'Post Story';
        default:
          return 'Post Now';
      }
    }
    switch (_contentType) {
      case 'Reel':
        return 'Schedule Reel';
      case 'Story':
        return 'Schedule Story';
      default:
        return 'Schedule Post';
    }
  }

  DateTime? get _fullScheduleDate {
    if (_scheduleDate == null || _scheduleTime == null) return null;
    return DateTime(
      _scheduleDate!.year,
      _scheduleDate!.month,
      _scheduleDate!.day,
      _scheduleTime!.hour,
      _scheduleTime!.minute,
    );
  }

  bool get _canSubmit {
    final hasText = _contentType == 'Story'
        ? _storyText.isNotEmpty || _storyFile != null
        : _textController.text.trim().isNotEmpty || _mediaFiles.isNotEmpty;

    if (_postMode == 'now') return hasText && !_isSubmitting;

    // Schedule mode: must also have valid date/time
    final dt = _fullScheduleDate;
    if (dt == null) return false;
    if (dt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      return false;
    }
    return hasText && !_isSubmitting;
  }

  // ─── Helper: detect if XFile is a video ────────
  bool _isVideoFile(XFile file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
  }

  // ─── Media picking ──────────────────────────────
  Future<void> _pickMedia() async {
    if (_isReelVideoOnly) {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _mediaFiles.clear();
          _mediaFiles.add(video);
        });
      }
    } else {
      // pickMultipleMedia selects both images AND videos
      final files = await _picker.pickMultipleMedia(
        limit: _maxFiles - _mediaFiles.length,
      );
      if (files.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(files.take(_maxFiles - _mediaFiles.length));
        });
      }
    }
  }

  // ─── Submit ─────────────────────────────────────
  Future<void> _submit() async {
    if (_isSubmitting || !_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'No active page selected';
      });
      return;
    }

    final contentProvider = context.read<ContentProvider>();

    try {
      // Handle "Post Now" for text stories (instant, no cron)
      if (_postMode == 'now' &&
          _contentType == 'Story' &&
          _storyMeta != null &&
          _storyFile == null) {
        await contentProvider.publishStoryNow(
          pageId,
          text: _storyText,
          storyMeta: _storyMeta!.toMap(),
        );
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story published!'),
              backgroundColor: Color(0xFF307777),
            ),
          );
        }
        return;
      }

      // Upload media files first (if any)
      List<Map<String, String>> mediaList = [];

      // For Story with photo capture
      final filesToUpload = _contentType == 'Story' && _storyFile != null
          ? [_storyFile!]
          : _mediaFiles;

      if (filesToUpload.isNotEmpty) {
        // Try batch upload first
        final formData = FormData();
        for (final file in filesToUpload) {
          final bytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            'media',
            MultipartFile.fromBytes(bytes, filename: file.name),
          ));
        }
        var uploaded = await contentProvider.uploadMedia(pageId, formData);

        // If batch failed and multiple files, fall back to uploading one at a time
        if (uploaded == null && filesToUpload.length > 1) {
          final List<Map<String, String>> individualResults = [];
          bool allSucceeded = true;
          for (final file in filesToUpload) {
            final singleForm = FormData();
            final bytes = await file.readAsBytes();
            singleForm.files.add(MapEntry(
              'media',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ));
            final singleResult = await contentProvider.uploadMedia(pageId, singleForm);
            if (singleResult != null) {
              individualResults.addAll(singleResult);
            } else {
              allSucceeded = false;
              break;
            }
          }
          if (allSucceeded && individualResults.isNotEmpty) {
            uploaded = individualResults;
          }
        }

        if (uploaded == null) {
          setState(() {
            _isSubmitting = false;
            _error = 'Failed to upload media. Please try again.';
          });
          return;
        }
        mediaList = uploaded;
      }

      // Build schedule payload
      final text = _contentType == 'Story'
          ? _storyText
          : _textController.text.trim();

      DateTime scheduledFor;
      if (_postMode == 'now') {
        // Schedule 1 minute ahead for cron to pick up
        scheduledFor = DateTime.now().add(const Duration(minutes: 1));
      } else {
        scheduledFor = _fullScheduleDate!;
      }

      final payload = <String, dynamic>{
        'content_type': _contentType,
        'scheduled_for': scheduledFor.toUtc().toIso8601String(),
        'timezone': DateTime.now().timeZoneName,
        'idempotency_key': const Uuid().v4(),
      };
      if (text.isNotEmpty) payload['text'] = text;
      if (mediaList.isNotEmpty) payload['media'] = mediaList;
      if (_contentType == 'Story' && _storyMeta != null) {
        payload['story_meta'] = _storyMeta!.toMap();
      }

      final result = await contentProvider.scheduleContent(
        pageId,
        data: payload,
        skipRefresh: _postMode == 'now',
      );

      if (result == null && mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Schedule request failed. Please try again.';
        });
        return;
      }

      // For "Post Now": trigger immediate publish instead of waiting for cron
      if (_postMode == 'now' && result != null) {
        final scheduleId = result['_id'] as String?;
        if (scheduleId != null) {
          await contentProvider.publishNow(pageId, scheduleId);
        }
        // Always refresh posts — even if publishNow timed out the backend
        // likely completed; if not, the cron will handle it within 15s
        if (mounted) {
          await context.read<PostProvider>().fetchPagePosts(pageId, refresh: true);
        }
      }

      // Refresh content lists after everything is done
      contentProvider.fetchContent(pageId);
      contentProvider.fetchScheduledPosts(pageId);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _postMode == 'now'
                  ? '${_contentType} published!'
                  : '${_contentType} scheduled!',
            ),
            backgroundColor: const Color(0xFF307777),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to schedule. Please try again.';
        if (e is DioException && e.response?.data is Map) {
          msg = (e.response!.data['error'] ?? e.response!.data['message'] ?? msg).toString();
        }
        setState(() {
          _isSubmitting = false;
          _error = msg;
        });
      }
    }
  }

  // ─── Content type switch handler ────────────────
  void _onContentTypeChanged(String type) {
    setState(() {
      _contentType = type;
      _mediaFiles.clear();
      _storyMeta = null;
      _storyFile = null;
      _storyText = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final page = pagesProvider.activePage;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(),
          // ── Body ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Page info + posting mode toggle
                _buildPageRow(page),
                const SizedBox(height: 12),

                // Content type tabs
                _buildContentTypeTabs(),
                const SizedBox(height: 12),

                // Type-specific hint
                _buildTypeHint(),
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

                // Content area
                if (_contentType == 'Story')
                  StoryCreatorPanel(
                    onStoryMetaChanged: (meta) =>
                        setState(() => _storyMeta = meta),
                    onStoryFileChanged: (file) =>
                        setState(() => _storyFile = file),
                    onTextChanged: (text) =>
                        setState(() => _storyText = text),
                  )
                else ...[
                  // Reel video upload area
                  if (_contentType == 'Reel') ...[
                    _buildReelUpload(),
                    const SizedBox(height: 12),
                  ],

                  // Text input
                  TextField(
                    controller: _textController,
                    maxLines: _mediaFiles.isNotEmpty ? 3 : 6,
                    maxLength: 10000,
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind, ${page?.pageName ?? ''}?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (_) => setState(() {}),
                  ),

                  // Post media grid
                  if (_contentType == 'Post') _buildPostMedia(),
                ],

                const SizedBox(height: 16),

                // Schedule picker (only in schedule mode)
                if (_postMode == 'schedule')
                  QuickSchedulePicker(
                    selectedDate: _scheduleDate,
                    selectedTime: _scheduleTime,
                    onDateChanged: (d) => setState(() => _scheduleDate = d),
                    onTimeChanged: (t) => setState(() => _scheduleTime = t),
                  ),

                const SizedBox(height: 80), // padding for bottom bar
              ],
            ),
          ),

          // ── Bottom bar: Add to post + Submit ──
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            _modalTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE ROW + POST MODE ───────────────────────
  Widget _buildPageRow(dynamic page) {
    return Row(
      children: [
        // Page avatar
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page?.pageName ?? 'Your Page',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        // Post mode toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeChip(
                icon: Icons.schedule,
                label: 'Schedule',
                isSelected: _postMode == 'schedule',
                onTap: () => setState(() => _postMode = 'schedule'),
              ),
              _ModeChip(
                icon: Icons.send,
                label: 'Now',
                isSelected: _postMode == 'now',
                onTap: () => setState(() => _postMode = 'now'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── CONTENT TYPE TABS ──────────────────────────
  Widget _buildContentTypeTabs() {
    return Row(
      children: ['Post', 'Reel', 'Story'].map((type) {
        final isActive = _contentType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _onContentTypeChanged(type),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF307777)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForType(type),
                    size: 16,
                    color: isActive ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Reel':
        return Icons.videocam;
      case 'Story':
        return Icons.auto_stories;
      default:
        return Icons.article;
    }
  }

  // ─── TYPE-SPECIFIC HINT ─────────────────────────
  Widget _buildTypeHint() {
    String? hint;
    Color? color;
    if (_contentType == 'Reel') {
      hint = 'Reels require a single video file.';
      color = Colors.blue;
    } else if (_contentType == 'Story') {
      hint = 'Create a text or photo story. Stories disappear after 24 hours.';
      color = const Color(0xFF307777);
    }
    if (hint == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(hint,
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  // ─── REEL VIDEO UPLOAD ──────────────────────────
  Widget _buildReelUpload() {
    if (_mediaFiles.isNotEmpty) {
      return Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, color: Colors.white54, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _mediaFiles.first.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _mediaFiles.clear()),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Add Video',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text('Upload a video for your reel',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // ─── POST MEDIA GRID ────────────────────────────
  Widget _buildPostMedia() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();

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
          itemCount: _mediaFiles.length,
          itemBuilder: (_, i) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          _mediaFiles[i].path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Image.file(
                          File(_mediaFiles[i].path),
                          fit: BoxFit.cover,
                        ),
                ),
                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _mediaFiles.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
                // Video indicator
                if (_isVideoFile(_mediaFiles[i]))
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, size: 14, color: Colors.white),
                          SizedBox(width: 2),
                          Text('Video', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
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
          // "Add to your post" toolbar (hidden for Story)
          if (_contentType != 'Story')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    icon: Icon(Icons.location_on,
                        color: Colors.red[400], size: 22),
                    onPressed: () {},
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
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF307777),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _submitLabel,
                      style: const TextStyle(
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

/// Small mode toggle chip (Schedule / Now).
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF307777) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
