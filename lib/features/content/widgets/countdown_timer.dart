import 'dart:async';
import 'package:flutter/material.dart';

/// Live countdown widget that updates every second.
/// Displays "2d 03h 45m 30s" format, transitions to
/// "Publishing soon..." when expired.
class CountdownTimer extends StatefulWidget {
  final DateTime scheduledFor;
  final VoidCallback? onExpired;
  final TextStyle? style;

  const CountdownTimer({
    super.key,
    required this.scheduledFor,
    this.onExpired,
    this.style,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final diff = widget.scheduledFor.difference(DateTime.now());
      if (diff.isNegative && !_expired) {
        _expired = true;
        widget.onExpired?.call();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.scheduledFor.difference(DateTime.now());

    if (diff.isNegative) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.amber[700],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Publishing soon...',
            style: widget.style?.copyWith(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  fontSize: 13,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    parts.add('${hours.toString().padLeft(2, '0')}h');
    parts.add('${minutes.toString().padLeft(2, '0')}m');
    parts.add('${seconds.toString().padLeft(2, '0')}s');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 16, color: Colors.teal[600]),
        const SizedBox(width: 4),
        Text(
          parts.join(' '),
          style: widget.style ??
              TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
