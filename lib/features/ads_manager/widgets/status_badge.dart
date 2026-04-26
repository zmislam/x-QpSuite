import 'package:flutter/material.dart';
import '../utils/ads_helpers.dart';

/// Reusable status badge matching qp-web's STATUS_COLORS pattern.
class AdsStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const AdsStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: statusColor(status),
            ),
          ),
        ],
      ),
    );
  }
}
