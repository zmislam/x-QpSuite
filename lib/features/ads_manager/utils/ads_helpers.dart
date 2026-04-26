/// ============================================================
/// Ads Manager V2 — Formatting Utilities
/// ============================================================
/// Port of qp-web constants.js helpers:
///   centsToDisplay, shortNumber, formatDateShort, STATUS_COLORS
/// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Convert integer cents to a formatted EUR display string.
/// e.g. 1250 → "€12.50"
String centsToDisplay(int cents) {
  final eur = cents / 100;
  return NumberFormat.currency(
    locale: 'en_IE',
    symbol: '€',
    decimalDigits: 2,
  ).format(eur);
}

/// Compact number display.
/// e.g. 1234 → "1.2K", 1234567 → "1.2M"
String shortNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

/// Format ISO date to short display.
/// e.g. "2026-04-25T..." → "Apr 25"
String formatDateShort(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d').format(date);
}

/// Format ISO date to full display.
/// e.g. "2026-04-25T..." → "Apr 25, 2026"
String formatDateFull(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d, yyyy').format(date);
}

/// Map campaign/ad status to a Color.
/// Matches STATUS_COLORS from qp-web constants.js
Color statusColor(String status) {
  switch (status) {
    case 'Active':
      return const Color(0xFF10B981); // emerald-500
    case 'Paused':
      return const Color(0xFFF59E0B); // amber-500
    case 'Draft':
      return const Color(0xFF94A3B8); // slate-400
    case 'Completed':
      return const Color(0xFF3B82F6); // blue-500
    case 'Archived':
      return const Color(0xFF6B7280); // gray-500
    case 'Rejected':
      return const Color(0xFFEF4444); // red-500
    default:
      return const Color(0xFF94A3B8);
  }
}

/// Status background color (lighter version)
Color statusBgColor(String status) {
  switch (status) {
    case 'Active':
      return const Color(0xFFD1FAE5); // emerald-100
    case 'Paused':
      return const Color(0xFFFEF3C7); // amber-100
    case 'Draft':
      return const Color(0xFFF1F5F9); // slate-100
    case 'Completed':
      return const Color(0xFFDBEAFE); // blue-100
    case 'Archived':
      return const Color(0xFFF3F4F6); // gray-100
    case 'Rejected':
      return const Color(0xFFFEE2E2); // red-100
    default:
      return const Color(0xFFF1F5F9);
  }
}

/// Brand color constant matching qp-web's #307777
const Color kTealBrand = Color(0xFF307777);
const Color kTealDark = Color(0xFF256161);
const Color kTealLight = Color(0xFFE6F2F2);
