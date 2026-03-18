import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/page_switcher/providers/managed_pages_provider.dart';
import '../providers/content_provider.dart';

class ScheduleContentScreen extends StatefulWidget {
  const ScheduleContentScreen({super.key});

  @override
  State<ScheduleContentScreen> createState() => _ScheduleContentScreenState();
}

class _ScheduleContentScreenState extends State<ScheduleContentScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  String _contentType = 'Post';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final List<XFile> _mediaFiles = [];
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final files = await _picker.pickMultiImage(limit: 10);
    if (files.isNotEmpty) {
      setState(() {
        _mediaFiles.addAll(files.take(10 - _mediaFiles.length));
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
      _pickTime();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  DateTime? get _fullScheduledDate {
    if (_scheduledDate == null || _scheduledTime == null) return null;
    return DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _mediaFiles.isEmpty) {
      setState(() => _error = 'Add some text or media');
      return;
    }
    if (_fullScheduledDate == null) {
      setState(() => _error = 'Pick a date and time');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final pageId = context.read<ManagedPagesProvider>().activePageId;
    if (pageId == null) return;
    final contentProvider = context.read<ContentProvider>();
    final api = context.read<ApiService>();

    try {
      // Upload media first (with retry via ContentProvider)
      List<Map<String, String>> mediaList = [];
      if (_mediaFiles.isNotEmpty) {
        final formData = FormData();
        for (final file in _mediaFiles) {
          final bytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            'media',
            MultipartFile.fromBytes(bytes, filename: file.name),
          ));
        }
        var uploaded = await contentProvider.uploadMedia(pageId, formData);

        // If batch failed and multiple files, fall back to individual uploads
        if (uploaded == null && _mediaFiles.length > 1) {
          final List<Map<String, String>> individualResults = [];
          bool allSucceeded = true;
          for (final file in _mediaFiles) {
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

        if (uploaded != null) {
          mediaList = uploaded;
        }
      }

      // Schedule
      await api.post(
        ApiConstants.contentSchedule(pageId),
        data: {
          if (text.isNotEmpty) 'text': text,
          if (mediaList.isNotEmpty) 'media': mediaList,
          'content_type': _contentType,
          'scheduled_for': _fullScheduledDate!.toUtc().toIso8601String(),
          'timezone': DateTime.now().timeZoneName,
        },
      );

      if (mounted) {
        context.read<ContentProvider>().fetchContent(pageId);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Failed to schedule. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Content'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Schedule'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 12),
          ],

          // Content type
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Post', label: Text('Post')),
              ButtonSegment(value: 'Reel', label: Text('Reel')),
              ButtonSegment(value: 'Story', label: Text('Story')),
            ],
            selected: {_contentType},
            onSelectionChanged: (s) =>
                setState(() => _contentType = s.first),
          ),
          const SizedBox(height: 16),

          // Text input
          TextField(
            controller: _textController,
            maxLines: 6,
            maxLength: 10000,
            decoration: const InputDecoration(
              hintText: 'Write your post...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Media
          OutlinedButton.icon(
            onPressed: _pickMedia,
            icon: const Icon(Icons.photo_library),
            label: Text('Add Media (${_mediaFiles.length}/10)'),
          ),
          if (_mediaFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _mediaFiles[i].path,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                              )
                            : Image.file(
                                File(_mediaFiles[i].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mediaFiles.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Date / Time
          Text('Schedule Date & Time', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _scheduledDate != null
                        ? DateFormat('MMM d, yyyy').format(_scheduledDate!)
                        : 'Pick Date',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scheduledDate != null ? _pickTime : null,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _scheduledTime != null
                        ? _scheduledTime!.format(context)
                        : 'Pick Time',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
