import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders the first frame of a remote video URL for thumbnail-style previews.
class NetworkVideoPreview extends StatefulWidget {
  final String url;
  final double? height;

  const NetworkVideoPreview({super.key, required this.url, this.height});

  @override
  State<NetworkVideoPreview> createState() => _NetworkVideoPreviewState();
}

class _NetworkVideoPreviewState extends State<NetworkVideoPreview> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant NetworkVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
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
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

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
        height: widget.height,
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
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54),
        ),
      );
    }

    final controller = _controller!;

    // FittedBox provides cover-like crop inside fixed-size media tiles.
    return Container(
      height: widget.height,
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
