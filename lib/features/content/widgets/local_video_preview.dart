import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Renders a local picker video file as a visual preview frame.
class LocalVideoPreview extends StatefulWidget {
  final XFile file;

  const LocalVideoPreview({super.key, required this.file});

  @override
  State<LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<LocalVideoPreview> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant LocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _disposeController();
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(widget.file.path))
          : VideoPlayerController.file(File(widget.file.path));

      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      await controller.seekTo(Duration.zero);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _disposeController() async {
    final current = _controller;
    _controller = null;
    await current?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    if (_hasError || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );
    }

    final controller = _controller!;

    // FittedBox ensures a cover-style crop inside fixed-size tiles.
    return Container(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
