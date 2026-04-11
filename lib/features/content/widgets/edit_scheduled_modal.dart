import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'local_video_preview.dart';
import 'network_video_preview.dart';
import 'quick_schedule_picker.dart';

/// Modal for editing an existing scheduled post — mirrors the web
/// EditScheduledModal with content type tabs, 3-column media grid,
/// video support, countdown timer, and "Add to your post" toolbar.
class EditScheduledModal extends StatefulWidget {
  final ContentItem item;

  const EditScheduledModal({super.key, required this.item});

  static Future<void> show(BuildContext context, {required ContentItem item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditScheduledModal(item: item),
    );
  }

  @override
  State<EditScheduledModal> createState() => _EditScheduledModalState();
}

class _EditScheduledModalState extends State<EditScheduledModal> {
  late final TextEditingController _textController;
  final _picker = ImagePicker();

  late String _contentType;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;
  final List<XFile> _newMediaFiles = [];
  List<ContentMedia> _existingMedia = [];
  bool _isSaving = false;
  String? _error;

  // Countdown timer
  Timer? _countdownTimer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.displayText);
    _existingMedia = List.from(widget.item.media);
    _contentType = widget.item.contentType;

    if (widget.item.scheduledFor != null) {
      final local = widget.item.scheduledFor!.toLocal();
      _scheduleDate = DateTime(local.year, local.month, local.day);
      _scheduleTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final dt = _fullScheduleDate;
    if (dt == null) {
      if (_countdownText.isNotEmpty) setState(() => _countdownText = '');
      return;
    }
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) {
      setState(() => _countdownText = '');
      return;
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (mins > 0) parts.add('$mins min');
    setState(
      () => _countdownText = parts.isEmpty
          ? 'less than a minute'
          : parts.join(', '),
    );
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

  int get _totalMedia => _existingMedia.length + _newMediaFiles.length;

  int get _maxFiles {
    if (_contentType == 'Reel') return 1;
    if (_contentType == 'Story') return 1;
    return 10;
  }

  bool get _canSave {
    final hasContent =
        _textController.text.trim().isNotEmpty ||
        _existingMedia.isNotEmpty ||
        _newMediaFiles.isNotEmpty;
    final dt = _fullScheduleDate;
    if (dt == null) return false;
    return hasContent && !_isSaving;
  }

  // Helper: detect if XFile is a video
  bool _isVideoFile(XFile file) {
    final name = file.name.toLowerCase();
    final path = file.path.toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();

    if (mime.startsWith('video/')) return true;

    const videoExts = ['.mp4', '.mov', '.avi', '.webm', '.mkv', '.m4v'];
    return videoExts.any((ext) => name.endsWith(ext) || path.endsWith(ext));
  }

  // Helper: detect if ContentMedia is a video
  bool _isVideoMedia(ContentMedia m) {
    return m.type == 'video' ||
        const [
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
        ].any((ext) => m.url.toLowerCase().endsWith('.$ext'));
  }

  Future<void> _pickMedia() async {
    final maxNew = _maxFiles - _existingMedia.length - _newMediaFiles.length;
    if (maxNew <= 0) return;

    if (_contentType == 'Reel') {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _existingMedia.clear();
          _newMediaFiles.clear();
          _newMediaFiles.add(video);
        });
      }
    } else {
      // pickMultipleMedia selects both images AND videos
      final files = await _picker.pickMultipleMedia(limit: maxNew);
      if (files.isNotEmpty) {
        setState(() {
          _newMediaFiles.addAll(files.take(maxNew));
        });
      }
    }
  }

  void _onContentTypeChanged(String type) {
    if (type == _contentType) return;
    setState(() {
      _contentType = type;
      _newMediaFiles.clear();
      _existingMedia.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null) return;

    final cp = context.read<ContentProvider>();

    try {
      // Upload new media if any
      List<Map<String, String>>? mediaList;
      if (_newMediaFiles.isNotEmpty) {
        final formData = FormData();
        for (final file in _newMediaFiles) {
          final bytes = await file.readAsBytes();
          formData.files.add(
            MapEntry(
              'media',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ),
          );
        }
        var uploaded = await cp.uploadMedia(pageId, formData);

        // If batch failed and multiple files, fall back to uploading one at a time
        if (uploaded == null && _newMediaFiles.length > 1) {
          final List<Map<String, String>> individualResults = [];
          bool allSucceeded = true;
          for (final file in _newMediaFiles) {
            final singleForm = FormData();
            final bytes = await file.readAsBytes();
            singleForm.files.add(
              MapEntry(
                'media',
                MultipartFile.fromBytes(bytes, filename: file.name),
              ),
            );
            final singleResult = await cp.uploadMedia(pageId, singleForm);
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
            _isSaving = false;
            _error = 'Failed to upload new media';
          });
          return;
        }
        // Combine existing + new media
        final existingMaps = _existingMedia.map((m) {
          final item = <String, String>{'url': m.url, 'type': m.type};
          if (m.thumbnailUrl != null && m.thumbnailUrl!.isNotEmpty) {
            item['thumbnail_url'] = m.thumbnailUrl!;
          }
          return item;
        }).toList();
        mediaList = [...existingMaps, ...uploaded];
      } else if (_existingMedia.length != widget.item.media.length) {
        // Some existing media was removed
        mediaList = _existingMedia.map((m) {
          final item = <String, String>{'url': m.url, 'type': m.type};
          if (m.thumbnailUrl != null && m.thumbnailUrl!.isNotEmpty) {
            item['thumbnail_url'] = m.thumbnailUrl!;
          }
          return item;
        }).toList();
      }

      final ok = await cp.updateScheduledContent(
        pageId,
        widget.item.id,
        text: _textController.text.trim(),
        media: mediaList,
        scheduledFor: _fullScheduleDate,
        contentType: _contentType != widget.item.contentType
            ? _contentType
            : null,
      );

      if (mounted) {
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled post updated'),
              backgroundColor: Color(0xFF307777),
            ),
          );
        } else {
          setState(() {
            _isSaving = false;
            _error = 'Failed to update. Please try again.';
          });
        }
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Page info
                _buildPageRow(page),
                const SizedBox(height: 12),

                // Content type tabs
                _buildContentTypeTabs(),
                const SizedBox(height: 12),

                // Type-specific hint
                _buildTypeHint(),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
                ],

                // Reel video upload area
                if (_contentType == 'Reel') ...[
                  const SizedBox(height: 12),
                  _buildReelUpload(),
                ],

                // Text input
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: _totalMedia > 0 ? 3 : 6,
                  maxLength: 10000,
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind, ${page?.pageName ?? ''}?',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: (_) => setState(() {}),
                ),

                // Media grid (Post / Story type — combined existing + new)
                if (_contentType != 'Reel') _buildMediaGrid(),

                const SizedBox(height: 16),

                // Schedule picker
                QuickSchedulePicker(
                  selectedDate: _scheduleDate,
                  selectedTime: _scheduleTime,
                  onDateChanged: (d) {
                    setState(() => _scheduleDate = d);
                    _updateCountdown();
                  },
                  onTimeChanged: (t) {
                    setState(() => _scheduleTime = t);
                    _updateCountdown();
                  },
                ),

                // Countdown display
                if (_countdownText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCountdown(),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
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
          const Text(
            'Edit post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // ─── PAGE ROW ───────────────────────────────────
  Widget _buildPageRow(dynamic page) {
    return Row(
      children: [
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
          child: Text(
            page?.pageName ?? 'Your Page',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

  // ─── TYPE HINT ──────────────────────────────────
  Widget _buildTypeHint() {
    String? hint;
    Color? color;
    if (_contentType == 'Reel') {
      hint = 'Reels require a single video file.';
      color = Colors.blue;
    } else if (_contentType == 'Story') {
      hint =
          'Stories allow a single photo or video. Stories disappear after 24 hours.';
      color = const Color(0xFF307777);
    }
    if (hint == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
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
    final hasReel = _newMediaFiles.isNotEmpty || _existingMedia.isNotEmpty;
    if (hasReel) {
      final hasNew = _newMediaFiles.isNotEmpty;
      final name = _newMediaFiles.isNotEmpty
          ? _newMediaFiles.first.name
          : _existingMedia.first.url.split('/').last;

      String existingPreviewUrl = '';
      String existingFullUrl = '';
      bool existingIsVideo = false;
      if (!hasNew && _existingMedia.isNotEmpty) {
        final media = _existingMedia.first;
        existingIsVideo = _isVideoMedia(media);
        existingPreviewUrl = ApiConstants.contentMediaDisplayUrl(
          url: media.url,
          thumbnailUrl: media.thumbnailUrl,
          type: media.type,
          mediaBaseDir: media.mediaBaseDir,
          isScheduled: true,
        );
        existingFullUrl = ApiConstants.contentMediaFullUrl(
          url: media.url,
          mediaBaseDir: media.mediaBaseDir,
          isScheduled: true,
        );
      }

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
                  hasNew
                      ? LocalVideoPreview(file: _newMediaFiles.first)
                      : existingPreviewUrl.isNotEmpty
                      ? Image.network(
                          existingPreviewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) =>
                              existingIsVideo && existingFullUrl.isNotEmpty
                              ? NetworkVideoPreview(url: existingFullUrl)
                              : Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(
                                      Icons.videocam,
                                      color: Colors.white54,
                                      size: 34,
                                    ),
                                  ),
                                ),
                        )
                      : existingIsVideo && existingFullUrl.isNotEmpty
                      ? NetworkVideoPreview(url: existingFullUrl)
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white54,
                              size: 34,
                            ),
                          ),
                        ),
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
                        name,
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
              onTap: () => setState(() {
                _newMediaFiles.clear();
                _existingMedia.clear();
              }),
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

  // ─── MEDIA GRID (combined existing + new) ───────
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
    final isVideo = _isVideoMedia(m);
    final displayUrl = ApiConstants.contentMediaDisplayUrl(
      url: m.url,
      thumbnailUrl: m.thumbnailUrl,
      type: m.type,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: true,
    );
    final fullUrl = ApiConstants.contentMediaFullUrl(
      url: m.url,
      mediaBaseDir: m.mediaBaseDir,
      isScheduled: true,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: displayUrl.isNotEmpty
              ? Image.network(
                  displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) =>
                      isVideo && fullUrl.isNotEmpty
                      ? NetworkVideoPreview(url: fullUrl)
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            isVideo ? Icons.videocam : Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                )
              : isVideo && fullUrl.isNotEmpty
              ? NetworkVideoPreview(url: fullUrl)
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _existingMedia.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (isVideo)
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
              ? LocalVideoPreview(file: file)
              : kIsWeb
              ? Image.network(
                  file.path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : Image.file(File(file.path), fit: BoxFit.cover),
        ),
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
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (isVideo)
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
  }

  // ─── COUNTDOWN DISPLAY ──────────────────────────
  Widget _buildCountdown() {
    final dt = _fullScheduleDate;
    if (dt == null) return const SizedBox.shrink();

    final formatted = DateFormat('EEE, MMM d').format(dt);
    final timeFormatted = DateFormat('h:mm a').format(dt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF307777).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF307777).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF307777).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer, size: 18, color: Color(0xFF307777)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$formatted at $timeFormatted',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_countdownText.isNotEmpty)
                  Text(
                    'Posting in $_countdownText',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF307777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
          // Save button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
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
