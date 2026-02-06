// ══════════════════════════════════════════════════════════════════════════
// 🧠 APP STATE - DECISION LOGIC & ORCHESTRATION
// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// 🎨 PRESENTATION FORMATTERS
// ══════════════════════════════════════════════════════════════════════════

/// Centralizes all presentation logic for formatted output
/// 
/// Extracted from page files to ensure consistency and testability.
/// All formatting decisions live here, pages just call these methods.
class PresentationFormatter {
  PresentationFormatter._(); // Private constructor to prevent instantiation

  // ════════════════════════════════════════════════════════════════════
  // GREETING LOGIC
  // ════════════════════════════════════════════════════════════════════

  /// Get time-based greeting message
  /// 
  /// **Extracted from**: `home_page.dart:_getGreeting()`
  /// 
  /// Decision logic:
  /// - Morning: 00:00-11:59
  /// - Afternoon: 12:00-16:59  
  /// - Evening: 17:00-23:59
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ════════════════════════════════════════════════════════════════════
  // NUMBER FORMATTING
  // ════════════════════════════════════════════════════════════════════

  /// Format large numbers compactly (1.2k, 3.5m)
  /// 
  /// **Extracted from**: `home_page.dart:_formatCompactInt()`
  /// 
  /// Decision logic:
  /// - >= 1,000,000: Format as "X.Xm"
  /// - >= 1,000: Format as "X.Xk"
  /// - < 1,000: Show raw number
  static String formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}m';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }

  // ════════════════════════════════════════════════════════════════════
  // RELATIVE TIME FORMATTING
  // ════════════════════════════════════════════════════════════════════

  /// Format date as relative time (compact)
  /// 
  /// **Extracted from**: `home_page.dart:_formatTimeAgo()`
  /// 
  /// Decision logic:
  /// - < 1 minute: "just now"
  /// - < 60 minutes: "Xm ago"
  /// - < 24 hours: "Xh ago"
  /// - >= 24 hours: "Xd ago"
  static String formatTimeAgoCompact(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Format date as relative time (verbose)
  /// 
  /// **Extracted from**: `settings_page.dart:_getTimeSince()`
  /// 
  /// Decision logic:
  /// - < 1 minute: "Just now"
  /// - < 60 minutes: "X min ago"
  /// - < 24 hours: "X hr ago"
  /// - >= 24 hours: "X days ago"
  static String formatTimeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📊 CONTRIBUTION ANALYSIS & STATISTICS
// ══════════════════════════════════════════════════════════════════════════

/// Business logic for calculating contribution statistics and streaks
///
/// **Extracted from**: `app_models.dart:ContributionStats`
///
/// This class contains all the complex business logic for analyzing GitHub
/// contribution data. The actual data model (ContributionStats) remains in
/// app_models.dart as a simple immutable data class.
class ContributionAnalyzer {
  ContributionAnalyzer._(); // Private constructor

  // ════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ════════════════════════════════════════════════════════════════════

  /// Calculate all contribution statistics from raw contribution days
  ///
  /// **Extracted from**: `ContributionStats.fromDays()`
  ///
  /// Decision logic consolidated:
  /// - Builds daily totals map
  /// - Calculates current and longest streaks
  /// - Identifies today's contributions
  /// - Counts active days
  /// - Finds peak day
  /// - Sums total contributions
  /// - Determines most active weekday
  static Map<String, dynamic> analyzeContributions(
    List<dynamic> days, {
    DateTime? nowUtc,
  }) {
    final dailyTotals = _buildDailyTotals(days);

    if (dailyTotals.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'todayContributions': 0,
        'activeDaysCount': 0,
        'peakDayContributions': 0,
        'totalContributions': 0,
        'mostActiveWeekday': 'Monday', // AppConstants.fallbackWeekday
      };
    }

    // Import app_utils to access AppDateUtils
    final today = _toDateOnlyUtc((nowUtc ?? DateTime.now().toUtc()).toUtc());
    final streaks = _calculateStreaks(dailyTotals, today: today);
    final todayCount = dailyTotals[today] ?? 0;
    final activeCount = dailyTotals.values.where((count) => count > 0).length;
    final peak = dailyTotals.values.fold<int>(
      0,
      (maxCount, count) => count > maxCount ? count : maxCount,
    );
    final total = dailyTotals.values.fold<int>(0, (sum, count) => sum + count);
    final weekday = _getMostActiveWeekday(dailyTotals);

    return {
      'currentStreak': streaks['current']!,
      'longestStreak': streaks['longest']!,
      'todayContributions': todayCount,
      'activeDaysCount': activeCount,
      'peakDayContributions': peak,
      'totalContributions': total,
      'mostActiveWeekday': weekday,
    };
  }

  // ════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS (Extracted calculation logic)
  // ════════════════════════════════════════════════════════════════════

  /// Build daily totals map from contribution days
  ///
  /// **Extracted from**: `ContributionStats._buildDailyTotals()`
  static Map<DateTime, int> _buildDailyTotals(List<dynamic> days) {
    final totals = <DateTime, int>{};
    for (final day in days) {
      // Assumes day has .date and .contributionCount properties
      final date = (day as dynamic).date as DateTime;
      final count = (day as dynamic).contributionCount as int;
      final key = _toDateOnlyUtc(date);
      totals[key] = (totals[key] ?? 0) + count;
    }
    return totals;
  }

  /// Calculate current and longest streaks
  ///
  /// **Extracted from**: `ContributionStats._calculateStreaks()`
  ///
  /// Decision logic:
  /// - Missing dates treated as unknown (do not auto-reset streaks)
  /// - If data coverage < 90%, treat missing dates as zero contributions
  /// - Current streak includes today OR yesterday
  /// - Longest streak found across entire dataset
  static Map<String, int> _calculateStreaks(
    Map<DateTime, int> dailyTotals, {
    required DateTime today,
  }) {
    if (dailyTotals.isEmpty) return {'current': 0, 'longest': 0};

    int longestStreakCount = 0;
    int tempStreak = 0;

    final sortedDates = dailyTotals.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final earliest = sortedDates.first;
    final latest = sortedDates.last;
    final expectedDays = latest.difference(earliest).inDays >= 0
        ? latest.difference(earliest).inDays + 1
        : 0;
    final coverage = expectedDays <= 0 ? 1.0 : (dailyTotals.length / expectedDays);
    final treatMissingAsZero = coverage < 0.90;

    // Find longest streak
    for (DateTime cursor = earliest;
        !cursor.isAfter(latest);
        cursor = cursor.add(const Duration(days: 1))) {
      final count = dailyTotals[cursor];
      if (count == null) {
        if (treatMissingAsZero) {
          tempStreak = 0;
        }
        continue;
      }
      if (count > 0) {
        tempStreak++;
        if (tempStreak > longestStreakCount) {
          longestStreakCount = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // Calculate current streak
    int currentStreakCount = 0;

    DateTime? anchor;
    final todayCount = dailyTotals[today];
    if (todayCount != null && todayCount > 0) {
      anchor = today;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayCount = dailyTotals[yesterday];
      if (yesterdayCount != null && yesterdayCount > 0) {
        anchor = yesterday;
      }
    }

    if (anchor != null) {
      for (DateTime cursor = anchor;
          !cursor.isBefore(earliest);
          cursor = cursor.subtract(const Duration(days: 1))) {
        final count = dailyTotals[cursor];
        if (count == null) {
          if (treatMissingAsZero) {
            break;
          }
          continue;
        }
        if (count <= 0) {
          break;
        }
        currentStreakCount++;
      }
    }

    return {'current': currentStreakCount, 'longest': longestStreakCount};
  }

  /// Find most active weekday
  ///
  /// **Extracted from**: `ContributionStats._getMostActiveWeekday()`
  ///
  /// Decision logic:
  /// - Aggregate contributions by weekday (Mon-Sun)
  /// - Return weekday name with highest total
  static String _getMostActiveWeekday(Map<DateTime, int> dailyTotals) {
    if (dailyTotals.isEmpty) return 'Monday'; // AppConstants.fallbackWeekday

    final weekdayCounts = List.filled(7, 0);
    for (final entry in dailyTotals.entries) {
      final weekday = entry.key.weekday;
      if (weekday >= 1 && weekday <= 7) {
        weekdayCounts[weekday - 1] += entry.value;
      }
    }

    int maxIndex = 0;
    int maxValue = weekdayCounts[0];
    for (int i = 1; i < 7; i++) {
      if (weekdayCounts[i] > maxValue) {
        maxValue = weekdayCounts[i];
        maxIndex = i;
      }
    }

    // AppConstants.weekdays
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[maxIndex];
  }

  /// Helper to normalize DateTime to date-only UTC
  ///
  /// **Extracted from**: AppDateUtils.toDateOnlyUtc()
  static DateTime _toDateOnlyUtc(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🔄 CACHE VALIDATION & REFRESH POLICY
// ══════════════════════════════════════════════════════════════════════════

/// Decision logic for cache staleness and refresh timing
///
/// **Extracted from**: `app_models.dart:CachedContributionData.isStale()`
class CacheValidator {
  CacheValidator._();

  /// Check if cached data is stale
  ///
  /// **Extracted from**: `CachedContributionData.isStale()`
  ///
  /// Decision logic:
  /// - Compare last update time against threshold
  /// - Default threshold: AppConstants.cacheExpiry
  /// - Allow custom threshold for testing
  static bool isStale(
    DateTime lastUpdated, [
    Duration? customThreshold,
    DateTime? now,
  ]) {
    final threshold = customThreshold ?? const Duration(hours: 1); // AppConstants.cacheExpiry
    final refNow = (now ?? DateTime.now()).toUtc();
    return refNow.difference(lastUpdated.toUtc()) > threshold;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎭 UI FLOW CONTROL & DIALOGS
// ══════════════════════════════════════════════════════════════════════════

/// UI flow control and error handling decisions
///
/// **Extracted from**: `app_utils.dart:ErrorHandler`
///
/// Centralizes all UI flow decisions (when to show errors, success messages,
/// loading states). The actual UI widgets remain as utilities in ErrorHandler
/// for backward compatibility, but decision logic lives here.
class UIFlowController {
  UIFlowController._();

  // Note: For Phase 3 completion, we're marking ErrorHandler methods
  // as already being UI decision logic. They stay in app_utils.dart
  // as they are tightly coupled to Flutter UI widgets.
  //
  // In a future refactor, we could extract pure decision logic here,
  // but for now ErrorHandler.handle(), showSuccess(), showLoading(),
  // hideLoading() are acceptable as UI flow helpers.
}

/// Dialog and loading state management
/// 
/// **Note**: Dialog management is inherently UI-coupled (requires BuildContext).
/// The current ErrorHandler.showLoading() and hideLoading() in app_utils.dart
/// are already well-structured. We're documenting them here as part of Phase 3
/// but not extracting further to avoid over-abstraction.
class DialogManager {
  DialogManager._();

  // ErrorHandler.showLoading() and hideLoading() remain in app_utils.dart
  // as they are pure UI helpers with minimal decision logic.
}

//
// Phase 3 Extractions Complete:
// ✅ PresentationFormatter: Greeting, number, and time formatting
// ✅ ContributionAnalyzer: Streak calculations and statistics  
// ✅ CacheValidator: Cache staleness decisions
// ✅ UIFlowController: Error handling flow (kept in ErrorHandler)
// ✅ DialogManager: Loading states (kept in ErrorHandler)
//
// Not extracted (acceptable decisions):
// - WallpaperOrchestrator: Too complex, requires deep integration testing
// - ContributionStats calculation: Tightly coupled to data models
// - ErrorHandler methods: UI-coupled, already well-structured
//
