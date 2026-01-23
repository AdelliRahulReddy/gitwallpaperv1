import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  // ══════════════════════════════════════════════════════════════════════════
  // CURRENT DATE/TIME HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns current month name (e.g., "January", "February")
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
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }

  /// Returns the weekday of the first day of the current month (1 = Mon, 7 = Sun)
  static int getFirstWeekdayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).weekday;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE FORMATTING
  // ══════════════════════════════════════════════════════════════════════════

  /// Formats DateTime to relative time (e.g., "5m ago", "2h ago", "Just now")
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  /// Returns day name (e.g., "Monday", "Tuesday")
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Returns short day name (e.g., "Mon", "Tue")
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Formats date as "2026-01-21"
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats date as "Jan 21, 2026"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE PARSING (with error recovery)
  // ══════════════════════════════════════════════════════════════════════════

  /// ✅ FIXED: Safe date parsing with error handling
  /// Returns null if string is invalid instead of crashing
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) {
      debugPrint('AppDateUtils: Empty date string');
      return null;
    }

    try {
      return DateTime.parse(dateString);
    } on FormatException catch (e) {
      debugPrint('AppDateUtils: Invalid date format "$dateString": $e');
      return null;
    } catch (e) {
      debugPrint(
        'AppDateUtils: Unexpected error parsing date "$dateString": $e',
      );
      return null;
    }
  }

  /// ✅ Safe date parsing with fallback value
  static DateTime parseDateOr(String dateString, DateTime fallback) {
    return parseDate(dateString) ?? fallback;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MONTH/YEAR BOUNDARIES
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns first day of current month (e.g., Jan 1, 2026 00:00:00)
  static DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Returns last day of current month (e.g., Jan 31, 2026 23:59:59)
  static DateTime getEndOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Returns first day of specific month
  static DateTime getStartOfMonthFor(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// Returns last day of specific month
  static DateTime getEndOfMonthFor(int year, int month) {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  /// Returns first day of current year (Jan 1)
  static DateTime getYearStart() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  /// Returns last day of current year (Dec 31)
  static DateTime getYearEnd() {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31, 23, 59, 59);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE COMPARISONS
  // ══════════════════════════════════════════════════════════════════════════

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

  /// Checks if date is in current month
  static bool isInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Checks if date is in current year
  static bool isInCurrentYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Checks if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE CALCULATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns number of days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }

  /// Adds days to a date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtracts days from a date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Returns date with time set to 00:00:00 (start of day)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns date with time set to 23:59:59 (end of day)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
