// ══════════════════════════════════════════════════════════════════════════
// 📊 DATA MODELS - Production Ready
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'utils.dart';


// ══════════════════════════════════════════════════════════════════════════
// CONTRIBUTION DAY
// ══════════════════════════════════════════════════════════════════════════

/// Represents a single day of GitHub contributions
@immutable
class ContributionDay {
  /// The date of this contribution day (time component stripped)
  final DateTime date;

  /// Number of contributions made on this day
  final int contributionCount;

  /// GitHub's contribution level string (NONE, FIRST_QUARTILE, etc.)
  final String? contributionLevel;

  const ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  /// Create from GitHub API JSON response
  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final parsedDate = AppDateUtils.parseIsoDate(dateStr);

    if (parsedDate == null) {
      debugPrint('ContributionDay: Invalid date string: $dateStr');
      throw FormatException('Invalid date in ContributionDay JSON: $dateStr');
    }

    final countValue = json['contributionCount'];
    final count = (countValue is num && countValue >= 0) 
        ? countValue.toInt() 
        : 0;

    return ContributionDay(
      date: parsedDate,
      contributionCount: count,
      contributionLevel: json['contributionLevel'] as String?,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.toIsoDateString(date),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel,
      };

  /// Whether this day has any contributions
  bool get isActive => contributionCount > 0;

  /// Get visual intensity level (0-4) for heatmap rendering
  /// Prioritizes GitHub's explicit level, falls back to local thresholds
  int get intensityLevel {
    if (contributionLevel != null) {
      switch (contributionLevel) {
        case 'NONE': return 0;
        case 'FIRST_QUARTILE': return 1;
        case 'SECOND_QUARTILE': return 2;
        case 'THIRD_QUARTILE': return 3;
        case 'FOURTH_QUARTILE': return 4;
      }
    }
    
    // Fallback if level string missing
    return RenderUtils.getContributionLevel(contributionCount);
  }

  /// Get date key for map lookups (YYYY-MM-DD format)
  String get dateKey => AppDateUtils.createDateKey(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionDay &&
          runtimeType == other.runtimeType &&
          AppDateUtils.isSameDay(date, other.date) &&
          contributionCount == other.contributionCount &&
          contributionLevel == other.contributionLevel;

  @override
  int get hashCode =>
      date.year.hashCode ^
      date.month.hashCode ^
      date.day.hashCode ^
      contributionCount.hashCode ^
      contributionLevel.hashCode;

  @override
  String toString() => '$dateKey: $contributionCount contributions';
}

// ══════════════════════════════════════════════════════════════════════════
// CONTRIBUTION STATISTICS
// ══════════════════════════════════════════════════════════════════════════

/// Statistics calculated from contribution data
@immutable
class ContributionStats {
  final int currentStreak;
  final int longestStreak;
  final int todayContributions;
  final int activeDaysCount;
  final int peakDayContributions;
  final int totalContributions;
  final String mostActiveWeekday;

  const ContributionStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayContributions,
    required this.activeDaysCount,
    required this.peakDayContributions,
    required this.totalContributions,
    required this.mostActiveWeekday,
  });

  /// Calculate statistics from contribution days
  factory ContributionStats.fromDays(List<ContributionDay> days) {
    if (days.isEmpty) {
      return const ContributionStats(
        currentStreak: 0,
        longestStreak: 0,
        todayContributions: 0,
        activeDaysCount: 0,
        peakDayContributions: 0,
        totalContributions: 0,
        mostActiveWeekday: 'None',
      );
    }

    final streaks = _calculateStreaks(days);
    final todayCount = _getTodayContributions(days);
    final activeCount = days.where((d) => d.isActive).length;
    final peak = days.fold(
        0,
        (max, day) =>
            day.contributionCount > max ? day.contributionCount : max);
    final total = days.fold<int>(0, (sum, d) => sum + d.contributionCount);
    final weekday = _getMostActiveWeekday(days);

    return ContributionStats(
      currentStreak: streaks['current']!,
      longestStreak: streaks['longest']!,
      todayContributions: todayCount,
      activeDaysCount: activeCount,
      peakDayContributions: peak,
      totalContributions: total,
      mostActiveWeekday: weekday,
    );
  }

  /// Calculate current and longest streaks from contribution days
  /// 
  /// Optimized to O(n) in a single pass.
  static Map<String, int> _calculateStreaks(List<ContributionDay> days) {
    if (days.isEmpty) return {'current': 0, 'longest': 0};

    // 5. List Sorting Optimization: Only sort if necessary
    bool isSorted = true;
    for (int i = 0; i < days.length - 1; i++) {
      if (days[i].date.isAfter(days[i + 1].date)) {
        isSorted = false;
        break;
      }
    }

    final sortedDays = isSorted 
        ? days 
        : (List<ContributionDay>.from(days)..sort((a, b) => a.date.compareTo(b.date)));

    int longestStreakCount = 0;
    int tempStreak = 0;

    // Use normalized UTC dates to align with GitHub API (P0 Fix)
    final today = AppDateUtils.toDateOnly(AppDateUtils.nowUtc);
    DateTime? lastDate;

    for (final day in sortedDays) {
      final dayDate = AppDateUtils.toDateOnly(day.date);
      
      if (day.isActive) {
        if (lastDate != null && dayDate.difference(lastDate).inDays == 1) {
          tempStreak++;
        } else {
          // Gap in dates or first active day
          tempStreak = 1;
        }
        
        if (tempStreak > longestStreakCount) {
          longestStreakCount = tempStreak;
        }
        // Fix: Only update lastDate when the day was actually active (P1 Fix)
        // This prevents inactive days from "bridging" or resetting logic incorrectly
        lastDate = dayDate;
      } else {
        tempStreak = 0;
      }
    }

    // Current streak calculation
    int currentStreakCount = 0;
    DateTime? lastActiveDay;
    for (int i = sortedDays.length - 1; i >= 0; i--) {
      if (sortedDays[i].isActive) {
        lastActiveDay = AppDateUtils.toDateOnly(sortedDays[i].date);
        break;
      }
    }

    if (lastActiveDay != null) {
      // Fix: Use normalized dates for strict day difference check
      final diffToToday = today.difference(lastActiveDay).inDays;
      
      // Audit Fix: Strict streak calculation (no grace period)
      // GitHub streaks are strictly based on UTC days.
      if (diffToToday == 0) {
        int streak = 0;
        DateTime expect = lastActiveDay;
        
        for (int i = sortedDays.length - 1; i >= 0; i--) {
          final day = sortedDays[i];
          final dayDate = AppDateUtils.toDateOnly(day.date);
          
          if (dayDate.isAfter(lastActiveDay)) continue;
          
          if (AppDateUtils.isSameDay(dayDate, expect)) {
            if (day.isActive) {
              streak++;
              expect = dayDate.subtract(const Duration(days: 1));
            } else {
              break;
            }
          } else if (dayDate.isBefore(expect)) {
            break; 
          }
        }
        currentStreakCount = streak;
      }
    }

    return {'current': currentStreakCount, 'longest': longestStreakCount};
  }

  /// Get contributions for today (UTC to match GitHub)
  static int _getTodayContributions(List<ContributionDay> days) {
    // Audit Fix: Use UTC to match GitHub contribution data
    final today = AppDateUtils.toDateOnly(AppDateUtils.nowUtc);
    final todayDay = days.firstWhere(
      (d) => AppDateUtils.isSameDay(d.date, today),
      orElse: () => ContributionDay(date: today, contributionCount: 0),
    );
    return todayDay.contributionCount;
  }

  /// Find most active weekday
  static String _getMostActiveWeekday(List<ContributionDay> days) {
    if (days.isEmpty) return AppConstants.fallbackWeekday;

    final weekdayCounts = List.filled(7, 0);
    for (final day in days) {
      final weekday = day.date.weekday;
      if (weekday >= 1 && weekday <= 7) {
        weekdayCounts[weekday - 1] += day.contributionCount;
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

    const weekdays = AppConstants.weekdays;
    return weekdays[maxIndex];
  }

  /// Average contributions per active day
  double get averagePerActiveDay {
    if (activeDaysCount == 0) return 0.0;
    return totalContributions / activeDaysCount;
  }

  @override
  String toString() =>
      'Stats(current: $currentStreak, longest: $longestStreak, today: $todayContributions)';
}

// ══════════════════════════════════════════════════════════════════════════
// CACHED CONTRIBUTION DATA
// ══════════════════════════════════════════════════════════════════════════

/// Complete GitHub contribution data with caching metadata
@immutable
class CachedContributionData {
  /// GitHub username
  final String username;

  /// Total contributions across all days
  final int totalContributions;

  /// List of contribution days
  final List<ContributionDay> days;

  /// When this data was last fetched
  final DateTime lastUpdated;

  /// Calculated statistics (cached)
  final ContributionStats stats;

  /// Dynamic contribution quartiles for heatmap rendering
  final Quartiles quartiles;

  /// Pre-computed date lookup map for O(1) access
  final Map<String, ContributionDay> _dateLookupCache;

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.days,
    required this.lastUpdated,
    ContributionStats? stats,
    Quartiles? quartiles,
  })  : stats = stats ?? ContributionStats.fromDays(days),
        quartiles = quartiles ??
            RenderUtils.calculateQuartiles(
                days.map((d) => d.contributionCount).toList()),
        _dateLookupCache = {for (var day in days) day.dateKey: day};

  /// Create from GitHub API JSON response
  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List<dynamic>? ?? [];
    final parsedDays = <ContributionDay>[];

    // Parse days with error handling
    for (final dayJson in daysList) {
      try {
        if (dayJson is Map<String, dynamic>) {
          parsedDays.add(ContributionDay.fromJson(dayJson));
        }
      } catch (e) {
        debugPrint('CachedContributionData: Skipping invalid day JSON: $e');
        continue;
      }
    }

    DateTime timestamp;
    try {
      final lastUpdatedStr = json['lastUpdated'] as String?;
      timestamp = lastUpdatedStr != null
          ? DateTime.parse(lastUpdatedStr)
          : AppDateUtils.nowUtc;
    } catch (e) {
      debugPrint('CachedContributionData: Using current time due to parse error: $e');
      timestamp = AppDateUtils.nowUtc;
    }

    // Calculate stats from parsed data
    final calculatedStats = ContributionStats.fromDays(parsedDays);

    return CachedContributionData(
      username: json['username'] as String? ?? '',
      totalContributions: json['totalContributions'] as int? ?? 0,
      days: parsedDays,
      lastUpdated: timestamp,
      stats: calculatedStats,
      // quartiles will be auto-calculated by constructor
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'username': username,
        'totalContributions': totalContributions,
        'currentStreak': stats.currentStreak,
        'longestStreak': stats.longestStreak,
        'todayCommits': stats.todayContributions,
        'days': days.map((d) => d.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  /// Get contributions for a specific date (fast lookup)
  int getContributionsForDate(DateTime date) {
    final key = AppDateUtils.createDateKey(date);
    return _dateLookupCache[key]?.contributionCount ?? 0;
  }

  /// Check if cached data is stale
  bool isStale([Duration? customThreshold]) {
    final threshold = customThreshold ?? AppConstants.cacheExpiry;
    return DateTime.now().difference(lastUpdated) > threshold;
  }

  /// Convenience getters delegating to stats
  int get currentStreak => stats.currentStreak;
  int get longestStreak => stats.longestStreak;
  int get todayCommits => stats.todayContributions;
  int get activeDaysCount => stats.activeDaysCount;
  int get peakDay => stats.peakDayContributions;
  String get mostActiveWeekday => stats.mostActiveWeekday;
  bool get hasContributedToday => stats.todayContributions > 0;

  /// Average contributions per active day
  double get averagePerActiveDay {
    if (stats.activeDaysCount == 0) return 0.0;
    return totalContributions / stats.activeDaysCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedContributionData &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          totalContributions == other.totalContributions &&
          lastUpdated == other.lastUpdated &&
          listEquals(days, other.days);

  @override
  int get hashCode =>
      username.hashCode ^
      totalContributions.hashCode ^
      lastUpdated.hashCode ^
      Object.hashAll(days);

  @override
  String toString() =>
      'CachedContributionData(user: $username, total: $totalContributions, days: ${days.length})';
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

/// Configuration for wallpaper generation and rendering
@immutable
class WallpaperConfig {
  /// Dark mode enabled
  final bool isDarkMode;

  /// Vertical position (0.0 = top, 1.0 = bottom)
  final double verticalPosition;

  /// Horizontal position (0.0 = left, 1.0 = right)
  final double horizontalPosition;

  /// Scale factor for heatmap
  final double scale;

  final bool autoFitWidth;

  /// Opacity of heatmap cells (0.0 = transparent, 1.0 = opaque)
  final double opacity;

  /// Custom quote text
  final String customQuote;

  /// Quote font size
  final double quoteFontSize;

  /// Quote opacity
  final double quoteOpacity;

  /// Padding from edges
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  /// Corner radius of heatmap cells
  final double cornerRadius;

  const WallpaperConfig({
    this.isDarkMode = false,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = AppConstants.defaultWallpaperScale,
    this.autoFitWidth = true,
    this.opacity = AppConstants.defaultWallpaperOpacity,
    this.customQuote = '',
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.cornerRadius = AppConstants.defaultCornerRadius,
  });

  /// Create with default values
  factory WallpaperConfig.defaults() => const WallpaperConfig();

  /// Create from JSON storage
  factory WallpaperConfig.fromJson(Map<String, dynamic> json) {
    try {
      return WallpaperConfig(
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        verticalPosition: _parseDouble(json['verticalPosition'], 0.5, 0.0, 1.0),
        horizontalPosition:
            _parseDouble(json['horizontalPosition'], 0.5, 0.0, 1.0),
        scale: _parseDouble(
            json['scale'], AppConstants.defaultWallpaperScale, 0.5, 8.0),
        autoFitWidth: json['autoFitWidth'] as bool? ?? true,
        opacity: _parseDouble(
            json['opacity'], AppConstants.defaultWallpaperOpacity, 0.0, 1.0),
        customQuote: (json['customQuote'] as String? ?? '').trim(),
        quoteFontSize: _parseDouble(json['quoteFontSize'], 14.0, 10.0, 40.0),
        quoteOpacity: _parseDouble(json['quoteOpacity'], 1.0, 0.0, 1.0),
        paddingTop: _parseDouble(json['paddingTop'], 0.0, 0.0, 500.0),
        paddingBottom: _parseDouble(json['paddingBottom'], 0.0, 0.0, 500.0),
        paddingLeft: _parseDouble(json['paddingLeft'], 0.0, 0.0, 500.0),
        paddingRight: _parseDouble(json['paddingRight'], 0.0, 0.0, 500.0),
        cornerRadius: _parseDouble(
            json['cornerRadius'], AppConstants.defaultCornerRadius, 0.0, 20.0),
      );
    } catch (e) {
      debugPrint('WallpaperConfig: Error parsing JSON, using defaults: $e');
      return WallpaperConfig.defaults();
    }
  }

  /// Helper to safely parse and clamp double values
  static double _parseDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;
    final parsed = (value is num) ? value.toDouble() : defaultValue;
    return parsed.clamp(min, max);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'verticalPosition': verticalPosition,
        'horizontalPosition': horizontalPosition,
        'scale': scale,
        'autoFitWidth': autoFitWidth,
        'opacity': opacity,
        'customQuote': customQuote,
        'quoteFontSize': quoteFontSize,
        'quoteOpacity': quoteOpacity,
        'paddingTop': paddingTop,
        'paddingBottom': paddingBottom,
        'paddingLeft': paddingLeft,
        'paddingRight': paddingRight,
        'cornerRadius': cornerRadius,
      };

  /// Create a copy with modified values
  WallpaperConfig copyWith({
    bool? isDarkMode,
    double? verticalPosition,
    double? horizontalPosition,
    double? scale,
    bool? autoFitWidth,
    double? opacity,
    String? customQuote,
    double? quoteFontSize,
    double? quoteOpacity,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    double? cornerRadius,
  }) {
    return WallpaperConfig(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      horizontalPosition: horizontalPosition ?? this.horizontalPosition,
      scale: scale ?? this.scale,
      autoFitWidth: autoFitWidth ?? this.autoFitWidth,
      opacity: opacity ?? this.opacity,
      customQuote: customQuote ?? this.customQuote,
      quoteFontSize: quoteFontSize ?? this.quoteFontSize,
      quoteOpacity: quoteOpacity ?? this.quoteOpacity,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperConfig &&
          runtimeType == other.runtimeType &&
          isDarkMode == other.isDarkMode &&
          verticalPosition == other.verticalPosition &&
          horizontalPosition == other.horizontalPosition &&
          scale == other.scale &&
          autoFitWidth == other.autoFitWidth &&
          opacity == other.opacity &&
          customQuote == other.customQuote &&
          quoteFontSize == other.quoteFontSize &&
          quoteOpacity == other.quoteOpacity &&
          paddingTop == other.paddingTop &&
          paddingBottom == other.paddingBottom &&
          paddingLeft == other.paddingLeft &&
          paddingRight == other.paddingRight &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode =>
      isDarkMode.hashCode ^
      verticalPosition.hashCode ^
      horizontalPosition.hashCode ^
      scale.hashCode ^
      autoFitWidth.hashCode ^
      opacity.hashCode ^
      customQuote.hashCode ^
      quoteFontSize.hashCode ^
      quoteOpacity.hashCode ^
      paddingTop.hashCode ^
      paddingBottom.hashCode ^
      paddingLeft.hashCode ^
      paddingRight.hashCode ^
      cornerRadius.hashCode;

  @override
  String toString() =>
      'WallpaperConfig(dark: $isDarkMode, scale: $scale, opacity: $opacity)';
}

