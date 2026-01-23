import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════
// 📅 DATE UTILITIES - CLEAN & EFFICIENT
// ══════════════════════════════════════════════════════════════════════════
// All date/time operations for GitHub Wallpaper app
// ══════════════════════════════════════════════════════════════════════════

class AppDateUtils {
  // ════════════════════════════════════════════════════════════════════════
  // 📆 CURRENT DATE/TIME
  // ════════════════════════════════════════════════════════════════════════

  /// Returns current date (e.g., "January")
  static String getCurrentMonthName() {
    return DateFormat('MMMM').format(DateTime.now());
  }

  /// Returns current day of month (1-31)
  static int getCurrentDayOfMonth() {
    return DateTime.now().day;
  }

  /// Returns number of days in current month (28-31)
  static int getDaysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Returns weekday of first day of month (1=Mon, 7=Sun)
  static int getFirstWeekdayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).weekday;
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 FORMATTING
  // ════════════════════════════════════════════════════════════════════════

  /// Formats to relative time ("5m ago", "2h ago", "Just now")
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Returns day name ("Monday")
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Returns short day name ("Mon")
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Formats as "2026-01-23"
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats as "Jan 23, 2026"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔄 PARSING
  // ════════════════════════════════════════════════════════════════════════

  /// Parses date string safely (returns null on error)
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('AppDateUtils: Error parsing "$dateString": $e');
      return null;
    }
  }

  /// Parses date with fallback
  static DateTime parseDateOr(String dateString, DateTime fallback) {
    return parseDate(dateString) ?? fallback;
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📍 BOUNDARIES
  // ════════════════════════════════════════════════════════════════════════

  /// Returns first day of current month (Jan 1 00:00:00)
  static DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Returns last day of current month (Jan 31 23:59:59)
  static DateTime getEndOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Returns start of today (00:00:00)
  static DateTime getStartOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// Returns end of today (23:59:59)
  static DateTime getEndOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔍 COMPARISONS
  // ════════════════════════════════════════════════════════════════════════

  /// Checks if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ➕ CALCULATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Returns days between two dates (ignoring time)
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }

  /// Adds days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtracts days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Adds months to date
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  /// Subtracts months from date
  static DateTime subtractMonths(DateTime date, int months) {
    return DateTime(date.year, date.month - months, date.day);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎯 GITHUB-SPECIFIC UTILITIES
  // ════════════════════════════════════════════════════════════════════════

  /// Returns date 365 days ago (for fetching full year of contributions)
  static DateTime getOneYearAgo() {
    return DateTime.now().subtract(const Duration(days: 365));
  }

  /// Returns list of all dates in current month
  static List<DateTime> getDatesInCurrentMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = getDaysInCurrentMonth();

    return List.generate(
      daysInMonth,
      (i) => DateTime(now.year, now.month, i + 1),
    );
  }

  /// Returns week number of year (1-53)
  static int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}
