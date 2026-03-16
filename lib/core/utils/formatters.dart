import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Formatters {
  /// Convert cents (integer) to display currency string.
  /// centsToDisplay(1234) → "€12.34"
  static String centsToDisplay(int cents, {String symbol = '€'}) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  /// Format large numbers with K, M, B suffixes.
  /// compactNumber(12500) → "12.5K"
  static String compactNumber(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  /// Format number with commas: 1234567 → "1,234,567"
  static String formatNumber(num value) {
    return NumberFormat('#,##0').format(value);
  }

  /// Format percentage: 12.5 → "+12.5%", -5.3 → "-5.3%"
  static String formatPercent(num value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  /// Format a date: "Mar 13, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format a date/time: "Mar 13, 2026 at 2:30 PM"
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(date);
  }

  /// Format as time ago: "5 minutes ago", "2 hours ago"
  static String formatTimeAgo(DateTime date) {
    return timeago.format(date);
  }

  /// Format short date: "3/13"
  static String formatShortDate(DateTime date) {
    return DateFormat('M/d').format(date);
  }

  /// Format date for chart axis: "Mar 6"
  static String formatChartDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format time: "2:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
