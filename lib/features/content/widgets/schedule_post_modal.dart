import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../../../features/posts/providers/post_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'local_video_preview.dart';
import 'quick_schedule_picker.dart';
import 'story_creator_panel.dart';

/// Full-screen modal bottom sheet for creating Post/Reel/Story
/// with scheduling — mirrors the web SchedulePostModal.
class SchedulePostModal extends StatefulWidget {
  /// Default mode: 'schedule' or 'now'
  final String initialPostMode;

  /// Default content type: 'Post' | 'Reel' | 'Story'
  final String initialContentType;

  const SchedulePostModal({
    super.key,
    this.initialPostMode = 'schedule',
    this.initialContentType = 'Post',
  });

  /// Show the modal as a full-screen bottom sheet.
  /// Returns `true` if content was successfully posted/scheduled.
  static Future<bool?> show(
    BuildContext context, {
    String initialPostMode = 'schedule',
    String initialContentType = 'Post',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SchedulePostModal(
        initialPostMode: initialPostMode,
        initialContentType: initialContentType,
      ),
    );
  }

  @override
  State<SchedulePostModal> createState() => _SchedulePostModalState();
}

class _SchedulePostModalState extends State<SchedulePostModal> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  // Core state
  late String _contentType; // Post | Reel | Story
  late String _postMode; // schedule | now

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
  void initState() {
    super.initState();
    _postMode = widget.initialPostMode;
    _contentType = widget.initialContentType;
  }

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
    final name = file.name.toLowerCase();
    final path = file.path.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();

    if (mime.startsWith('video/')) return true;

    const videoExts = ['.mp4', '.mov', '.avi', '.webm', '.mkv', '.m4v'];
    return videoExts.any((ext) => name.endsWith(ext) || path.endsWith(ext));
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
    final postProvider = context.read<PostProvider>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    final text = _contentType == 'Story'
        ? _storyText.trim()
        : _textController.text.trim();
    final filesToUpload = (_contentType == 'Story' && _storyFile != null)
        ? <XFile>[_storyFile!]
        : List<XFile>.from(_mediaFiles);
    final scheduledFor = _postMode == 'now'
        ? DateTime.now().add(const Duration(minutes: 1))
        : _fullScheduleDate!;

    final pendingMedia = filesToUpload
        .map(
          (file) => PendingUploadMedia(file: file, isVideo: _isVideoFile(file)),
        )
        .toList(growable: false);

    final pendingId = contentProvider.addPendingUpload(
      pageId: pageId,
      contentType: _contentType,
      postMode: _postMode,
      text: text,
      media: pendingMedia,
      scheduledFor: _postMode == 'schedule' ? scheduledFor : null,
    );

    // Close instantly and continue upload/schedule in background.
    Navigator.pop(context, true);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          _postMode == 'now'
              ? 'Posting in background...'
              : 'Scheduling in background...',
        ),
        backgroundColor: const Color(0xFF307777),
      ),
    );

    unawaited(
      _runQueuedSubmission(
        contentProvider: contentProvider,
        postProvider: postProvider,
        pageId: pageId,
        pendingId: pendingId,
        contentType: _contentType,
        postMode: _postMode,
        text: text,
        filesToUpload: filesToUpload,
        storyMeta: _storyMeta,
        scheduledFor: scheduledFor,
      ),
    );
  }

  Future<void> _runQueuedSubmission({
    required ContentProvider contentProvider,
    required PostProvider postProvider,
    required String pageId,
    required String pendingId,
    required String contentType,
    required String postMode,
    required String text,
    required List<XFile> filesToUpload,
    required StoryMeta? storyMeta,
    required DateTime scheduledFor,
  }) async {
    try {
      // Keep instant text-story publish path, but run it asynchronously.
      if (postMode == 'now' &&
          contentType == 'Story' &&
          storyMeta != null &&
          filesToUpload.isEmpty) {
        contentProvider.updatePendingUploadStatus(
          pendingId,
          status: 'Publishing',
        );

        final story = await contentProvider.publishStoryNow(
          pageId,
          text: text,
          storyMeta: storyMeta.toMap(),
        );
        if (story == null) {
          throw Exception('Failed to publish story.');
        }

        await Future.wait([
          postProvider.fetchPagePosts(pageId, refresh: true),
          contentProvider.fetchContent(pageId),
        ]);

        contentProvider.markPendingUploadCompleted(
          pendingId,
          status: 'Published',
        );
        return;
      }

      List<Map<String, String>> mediaList = [];
      if (filesToUpload.isNotEmpty) {
        contentProvider.updatePendingUploadStatus(
          pendingId,
          status: 'Uploading',
        );

        final uploaded = await _uploadFilesWithFallback(
          contentProvider,
          pageId,
          filesToUpload,
        );

        if (uploaded == null) {
          throw Exception('Failed to upload media. Please try again.');
        }
        mediaList = uploaded;
      }

      contentProvider.updatePendingUploadStatus(
        pendingId,
        status: postMode == 'now' ? 'Publishing' : 'Scheduling',
      );

      final payload = <String, dynamic>{
        'content_type': contentType,
        'scheduled_for': scheduledFor.toUtc().toIso8601String(),
        'timezone': DateTime.now().timeZoneName,
        'idempotency_key': const Uuid().v4(),
      };
      if (text.isNotEmpty) payload['text'] = text;
      if (mediaList.isNotEmpty) payload['media'] = mediaList;
      if (contentType == 'Story' && storyMeta != null) {
        payload['story_meta'] = storyMeta.toMap();
      }

      final result = await contentProvider.scheduleContent(
        pageId,
        data: payload,
        skipRefresh: true,
      );

      if (result == null) {
        throw Exception('Schedule request failed. Please try again.');
      }

      if (postMode == 'now') {
        final scheduleId = result['_id'] as String?;
        if (scheduleId != null) {
          await contentProvider.publishNow(pageId, scheduleId);
        }

        await Future.wait([
          postProvider.fetchPagePosts(pageId, refresh: true),
          contentProvider.fetchContent(pageId),
          contentProvider.fetchScheduledPosts(pageId),
        ]);

        contentProvider.markPendingUploadCompleted(
          pendingId,
          status: 'Published',
        );
        return;
      }

      await contentProvider.fetchScheduledPosts(pageId);
      contentProvider.markPendingUploadCompleted(
        pendingId,
        status: 'Scheduled',
      );
    } catch (e) {
      contentProvider.markPendingUploadFailed(
        pendingId,
        _errorMessageFromException(e),
      );
    }
  }

  Future<List<Map<String, String>>?> _uploadFilesWithFallback(
    ContentProvider contentProvider,
    String pageId,
    List<XFile> filesToUpload,
  ) async {
    final formData = FormData();
    for (final file in filesToUpload) {
      final bytes = await file.readAsBytes();
      // On web, XFile.name can be '' if name: wasn't passed to constructor
      final fileName = file.name.isNotEmpty
          ? file.name
          : 'upload_${DateTime.now().millisecondsSinceEpoch}.png';
      debugPrint('[Upload] file.name="${file.name}" fileName="$fileName" '
          'file.mimeType="${file.mimeType}" bytes.length=${bytes.length}');
      final mpFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: _inferMediaType(file),
      );
      debugPrint('[Upload] MultipartFile filename="${mpFile.filename}" '
          'contentType=${mpFile.contentType} length=${mpFile.length}');
      formData.files.add(MapEntry('media', mpFile));
    }
    debugPrint('[Upload] FormData files=${formData.files.length} '
        'boundary=${formData.boundary}');

    var uploaded = await contentProvider.uploadMedia(pageId, formData);

    // If batch failed and multiple files, fall back to one-by-one upload.
    if (uploaded == null && filesToUpload.length > 1) {
      final List<Map<String, String>> individualResults = [];
      bool allSucceeded = true;

      for (final file in filesToUpload) {
        final singleForm = FormData();
        final bytes = await file.readAsBytes();
        final fallbackName = file.name.isNotEmpty
            ? file.name
            : 'upload_${DateTime.now().millisecondsSinceEpoch}.png';
        singleForm.files.add(
          MapEntry(
            'media',
            MultipartFile.fromBytes(
              bytes,
              filename: fallbackName,
              contentType: _inferMediaType(file),
            ),
          ),
        );

        final singleResult = await contentProvider.uploadMedia(
          pageId,
          singleForm,
        );
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

    return uploaded;
  }

  String _errorMessageFromException(Object error) {
    if (error is DioException && error.response?.data is Map) {
      final data = error.response!.data as Map;
      final message = (data['error'] ?? data['message'])?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return 'Failed to process content. Please try again.';
  }

  // ─── Infer MIME type from XFile for multipart uploads ──
  MediaType _inferMediaType(XFile file) {
    final name = file.name.toLowerCase();
    // Check explicit mimeType first (set by story capture)
    final mime = file.mimeType ?? '';
    if (mime.isNotEmpty) {
      final parts = mime.split('/');
      if (parts.length == 2) return MediaType(parts[0], parts[1]);
    }
    // Infer from extension
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (name.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (name.endsWith('.webm')) return MediaType('video', 'webm');
    // Default to octet-stream
    return MediaType('application', 'octet-stream');
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
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                            ),
                          ),
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
                    onTextChanged: (text) => setState(() => _storyText = text),
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            _modalTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ? NetworkImage(ApiConstants.pageProfileUrl(page.profilePic))
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF307777) : Colors.grey[100],
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
            child: Text(hint, style: TextStyle(fontSize: 12, color: color)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalVideoPreview(file: _mediaFiles.first),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Text(
                        _mediaFiles.first.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
            Text(
              'Add Video',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload a video for your reel',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
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
            final isVideo = _isVideoFile(_mediaFiles[i]);
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isVideo
                      ? LocalVideoPreview(file: _mediaFiles[i])
                      : kIsWeb
                      ? Image.network(
                          _mediaFiles[i].path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
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
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Video indicator
                if (isVideo)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, size: 14, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Video',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
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
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.photo_library,
                      color: Colors.green[600],
                      size: 22,
                    ),
                    onPressed: _pickMedia,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.location_on,
                      color: Colors.red[400],
                      size: 22,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: Colors.amber[600],
                      size: 22,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
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
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
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
