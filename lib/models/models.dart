// ══════════════════════════════════════════════════════════════════════════
// 📊 DATA MODELS - GitHub Contribution Data
// ══════════════════════════════════════════════════════════════════════════
// Pure data structures with JSON serialization
// No business logic - only data representation
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════
// CONTRIBUTION DAY - Single day's data
// ══════════════════════════════════════════════════════════════════════════

class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String?
  contributionLevel; // NONE, FIRST_QUARTILE, SECOND_QUARTILE, etc.

  ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  /// Create from JSON
  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    try {
      return ContributionDay(
        date: DateTime.parse(json['date'] as String),
        contributionCount: json['contributionCount'] as int? ?? 0,
        contributionLevel: json['contributionLevel'] as String?,
      );
    } catch (e) {
      debugPrint('ContributionDay.fromJson error: $e');
      return ContributionDay(
        date: DateTime.now(),
        contributionCount: 0,
        contributionLevel: null,
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'contributionCount': contributionCount,
    'contributionLevel': contributionLevel,
  };

  /// Check if this is an active day (has contributions)
  bool get isActive => contributionCount > 0;

  /// Get color intensity level (0-4 for heatmap)
  int get intensityLevel {
    if (contributionCount == 0) return 0;
    if (contributionCount <= 3) return 1;
    if (contributionCount <= 6) return 2;
    if (contributionCount <= 9) return 3;
    return 4;
  }

  @override
  String toString() =>
      'ContributionDay(${date.toString().split(' ')[0]}, $contributionCount commits)';
}

// ══════════════════════════════════════════════════════════════════════════
// CACHED CONTRIBUTION DATA - Complete dataset with stats
// ══════════════════════════════════════════════════════════════════════════

class CachedContributionData {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final int todayCommits;
  final List<ContributionDay> days;
  final Map<int, int> dailyContributions; // day-of-month -> count
  final DateTime lastUpdated;

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayCommits,
    required this.days,
    required this.dailyContributions,
    required this.lastUpdated,
  });

  /// Create from JSON with defensive parsing
  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    try {
      // Parse days list
      final daysList = json['days'] as List<dynamic>? ?? [];
      final parsedDays = daysList
          .map((d) => ContributionDay.fromJson(d as Map<String, dynamic>))
          .toList();

      // Parse daily contributions map
      final dailyMap = <int, int>{};
      final dailyJson = json['dailyContributions'] as Map<String, dynamic>?;
      if (dailyJson != null) {
        dailyJson.forEach((key, value) {
          final day = int.tryParse(key);
          if (day != null && value is int) {
            dailyMap[day] = value;
          }
        });
      }

      // Parse timestamp
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(json['lastUpdated'] as String);
      } catch (e) {
        timestamp = DateTime.now();
        debugPrint('Failed to parse lastUpdated, using now: $e');
      }

      return CachedContributionData(
        username: json['username'] as String? ?? '',
        totalContributions: json['totalContributions'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        todayCommits: json['todayCommits'] as int? ?? 0,
        days: parsedDays,
        dailyContributions: dailyMap,
        lastUpdated: timestamp,
      );
    } catch (e, stack) {
      debugPrint('CachedContributionData.fromJson error: $e\n$stack');
      // Return empty data on catastrophic failure
      return CachedContributionData(
        username: '',
        totalContributions: 0,
        currentStreak: 0,
        longestStreak: 0,
        todayCommits: 0,
        days: [],
        dailyContributions: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'username': username,
    'totalContributions': totalContributions,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'todayCommits': todayCommits,
    'days': days.map((d) => d.toJson()).toList(),
    'dailyContributions': dailyContributions.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Get contribution count for specific day of month (1-31)
  int getContributionsForDay(int dayOfMonth) {
    return dailyContributions[dayOfMonth] ?? 0;
  }

  /// Check if data is stale (older than threshold)
  bool isStale(Duration threshold) {
    return DateTime.now().difference(lastUpdated) > threshold;
  }

  /// Get total days with contributions
  int get activeDaysCount => days.where((d) => d.isActive).length;

  /// Get average contributions per day (for active days only)
  double get averagePerActiveDay {
    if (activeDaysCount == 0) return 0.0;
    return totalContributions / activeDaysCount;
  }

  /// Check if user has contributed today
  bool get hasContributedToday => todayCommits > 0;

  /// Get contribution data for a specific date
  ContributionDay? getDayData(DateTime date) {
    try {
      return days.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'CachedContributionData('
        'user: $username, '
        'total: $totalContributions, '
        'streak: $currentStreak, '
        'today: $todayCommits, '
        'cached: ${lastUpdated.toString().split(' ')[0]}'
        ')';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER CONFIGURATION - User customization settings
// ══════════════════════════════════════════════════════════════════════════

class WallpaperConfig {
  final bool isDarkMode;
  final double verticalPosition; // 0.0 - 1.0
  final double horizontalPosition; // 0.0 - 1.0
  final double scale; // 0.5 - 2.0
  final double opacity; // 0.0 - 1.0
  final String customQuote;
  final double quoteFontSize;
  final double quoteOpacity;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final double cornerRadius;

  WallpaperConfig({
    this.isDarkMode = false,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = 0.7,
    this.opacity = 1.0,
    this.customQuote = '',
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.cornerRadius = 0.0,
  });

  /// Create default configuration
  factory WallpaperConfig.defaults() => WallpaperConfig();

  factory WallpaperConfig.fromJson(Map<String, dynamic> json) {
    return WallpaperConfig(
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        verticalPosition: (json['verticalPosition'] as num?)?.toDouble() ?? 0.5,
        horizontalPosition: (json['horizontalPosition'] as num?)?.toDouble() ?? 0.5,
        scale: (json['scale'] as num?)?.toDouble() ?? 0.7,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        customQuote: json['customQuote'] as String? ?? '',
        quoteFontSize: (json['quoteFontSize'] as num?)?.toDouble() ?? 14.0,
        quoteOpacity: (json['quoteOpacity'] as num?)?.toDouble() ?? 1.0,
        paddingTop: (json['paddingTop'] as num?)?.toDouble() ?? 0.0,
        paddingBottom: (json['paddingBottom'] as num?)?.toDouble() ?? 0.0,
        paddingLeft: (json['paddingLeft'] as num?)?.toDouble() ?? 0.0,
        paddingRight: (json['paddingRight'] as num?)?.toDouble() ?? 0.0,
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'verticalPosition': verticalPosition,
        'horizontalPosition': horizontalPosition,
        'scale': scale,
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

  /// Create copy with modifications
  WallpaperConfig copyWith({
    bool? isDarkMode,
    double? verticalPosition,
    double? horizontalPosition,
    double? scale,
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
  String toString() =>
      'WallpaperConfig(mode: ${isDarkMode ? "dark" : "light"}, scale: $scale)';
}
