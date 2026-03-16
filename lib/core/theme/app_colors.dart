import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ─────────────────────────────────────────
  static const Color primary = Color(0xFF1B74E4);
  static const Color primaryDark = Color(0xFF2D88FF);
  static const Color secondary = Color(0xFF2BC60C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF5AB9E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Mode ────────────────────────────────────
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF0F2F5);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF050505);
  static const Color textSecondaryLight = Color(0xFF65676B);
  static const Color dividerLight = Color(0xFFCED0D4);
  static const Color hoverLight = Color(0xFFF0F0F0);

  // ── Dark Mode ─────────────────────────────────────
  static const Color backgroundDark = Color(0xFF18191A);
  static const Color surfaceDark = Color(0xFF242526);
  static const Color cardDark = Color(0xFF242526);
  static const Color textPrimaryDark = Color(0xFFE4E6EB);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);
  static const Color dividerDark = Color(0xFF3E4042);
  static const Color hoverDark = Color(0xFF3A3B3C);

  // ── Status ────────────────────────────────────────
  static const Color success = Color(0xFF31A24C);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFF7B928);
  static const Color info = Color(0xFF1B74E4);
  static const Color online = Color(0xFF31A24C);

  // ── Status Badge Colors ───────────────────────────
  static const Color activeBackground = Color(0xFFD1FAE5);
  static const Color activeText = Color(0xFF047857);
  static const Color activeDot = Color(0xFF10B981);

  static const Color pausedBackground = Color(0xFFFEF3C7);
  static const Color pausedText = Color(0xFFB45309);
  static const Color pausedDot = Color(0xFFF59E0B);

  static const Color draftBackground = Color(0xFFF1F5F9);
  static const Color draftText = Color(0xFF475569);
  static const Color draftDot = Color(0xFF94A3B8);

  static const Color completedBackground = Color(0xFFDBEAFE);
  static const Color completedText = Color(0xFF1D4ED8);
  static const Color completedDot = Color(0xFF3B82F6);

  static const Color archivedBackground = Color(0xFFF3F4F6);
  static const Color archivedText = Color(0xFF6B7280);
  static const Color archivedDot = Color(0xFF9CA3AF);

  static const Color rejectedBackground = Color(0xFFFEE2E2);
  static const Color rejectedText = Color(0xFFB91C1C);
  static const Color rejectedDot = Color(0xFFEF4444);

  // ── KPI Trend Colors ──────────────────────────────
  static const Color trendUp = Color(0xFF31A24C);
  static const Color trendDown = Color(0xFFFF3B30);
  static const Color trendNeutral = Color(0xFF65676B);

  // ── Chart Palette ─────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF1B74E4),
    Color(0xFF2BC60C),
    Color(0xFFF7B928),
    Color(0xFFFF3B30),
    Color(0xFF9333EA),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  // Named chart colors for specific use-cases
  static const Color chartBlue = Color(0xFF1B74E4);
  static const Color chartPink = Color(0xFFEC4899);
  static const Color chartGrey = Color(0xFF9CA3AF);
  static const Color chartGreen = Color(0xFF2BC60C);
  static const Color chartOrange = Color(0xFFF97316);
  static const Color chartPurple = Color(0xFF9333EA);
}
