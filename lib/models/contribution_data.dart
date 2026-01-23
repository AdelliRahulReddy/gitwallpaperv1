import 'package:flutter/foundation.dart';
import '../core/date_utils.dart';

/// Represents a single day's contribution data
class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel; // GitHub quartile levels

  ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  /// ✅ FIXED: Safe JSON parsing with error recovery
  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ Safe date parsing
      final dateStr = json['date'] as String?;
      if (dateStr == null || dateStr.isEmpty) {
        throw const FormatException('Missing date field');
      }

      final date = AppDateUtils.parseDate(dateStr);
      if (date == null) {
        throw FormatException('Invalid date format: $dateStr');
      }

      // ✅ Validate contribution count
      final count = json['contributionCount'];
      if (count is! int) {
        throw FormatException(
          'Invalid contributionCount type: ${count.runtimeType}',
        );
      }

      // ✅ Clamp to reasonable range (GitHub max is ~1000 per day)
      final clampedCount = count.clamp(0, 10000);
      if (clampedCount != count) {
        debugPrint(
          'ContributionDay: Clamped count from $count to $clampedCount',
        );
      }

      return ContributionDay(
        date: date,
        contributionCount: clampedCount,
        contributionLevel: json['contributionLevel'] as String?,
      );
    } catch (e) {
      debugPrint('ContributionDay.fromJson error: $e');
      debugPrint('JSON: $json');

      // ✅ Return fallback with today's date and 0 contributions
      return ContributionDay(
        date: DateTime.now(),
        contributionCount: 0,
        contributionLevel: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'contributionCount': contributionCount,
      if (contributionLevel != null) 'contributionLevel': contributionLevel,
    };
  }

  bool isToday() => AppDateUtils.isToday(date);

  @override
  String toString() =>
      'ContributionDay(date: $date, count: $contributionCount)';
}

/// Cached GitHub contribution data with stats
class CachedContributionData {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final int todayCommits;
  final List<ContributionDay> days;
  final Map<int, int> dailyContributions; // day of month -> count
  final DateTime? lastUpdated;

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayCommits,
    required this.days,
    required this.dailyContributions,
    this.lastUpdated,
  });

  /// ✅ FIXED: Safe JSON parsing with comprehensive error recovery
  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ Validate required fields
      final username = json['username'] as String?;
      if (username == null || username.isEmpty) {
        throw const FormatException('Missing username');
      }

      // ✅ Parse stats with validation
      final totalContributions = _parseIntSafe(json['totalContributions'], 0);
      final currentStreak = _parseIntSafe(json['currentStreak'], 0);
      final longestStreak = _parseIntSafe(json['longestStreak'], 0);
      final todayCommits = _parseIntSafe(json['todayCommits'], 0);

      // ✅ Parse days array safely
      List<ContributionDay> daysList;
      try {
        final daysJson = json['days'] as List?;
        if (daysJson == null || daysJson.isEmpty) {
          debugPrint('CachedContributionData: No days data, using empty list');
          daysList = [];
        } else {
          daysList = daysJson
              .map(
                (day) => ContributionDay.fromJson(day as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (e) {
        debugPrint('CachedContributionData: Error parsing days: $e');
        daysList = [];
      }

      // ✅ Parse daily contributions map safely
      final Map<int, int> dailyMap = {};
      try {
        final dailyJson = json['dailyContributions'] as Map<String, dynamic>?;
        if (dailyJson != null) {
          dailyJson.forEach((key, value) {
            try {
              final dayNum = int.parse(key);
              if (dayNum >= 1 && dayNum <= 31) {
                // Valid day of month
                final count = _parseIntSafe(value, 0);
                dailyMap[dayNum] = count;
              }
            } catch (e) {
              debugPrint(
                'CachedContributionData: Skipping invalid daily entry: $key=$value',
              );
            }
          });
        }
      } catch (e) {
        debugPrint(
          'CachedContributionData: Error parsing dailyContributions: $e',
        );
      }

      // ✅ Parse lastUpdated safely
      DateTime? lastUpdated;
      try {
        final lastUpdatedStr = json['lastUpdated'] as String?;
        if (lastUpdatedStr != null && lastUpdatedStr.isNotEmpty) {
          lastUpdated = AppDateUtils.parseDate(lastUpdatedStr);
        }
      } catch (e) {
        debugPrint('CachedContributionData: Error parsing lastUpdated: $e');
      }

      return CachedContributionData(
        username: username,
        totalContributions: totalContributions,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        todayCommits: todayCommits,
        days: daysList,
        dailyContributions: dailyMap,
        lastUpdated: lastUpdated,
      );
    } catch (e, stackTrace) {
      debugPrint('CachedContributionData.fromJson CRITICAL ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON: $json');

      // ✅ Return minimal valid object instead of crashing
      return CachedContributionData(
        username: 'unknown',
        totalContributions: 0,
        currentStreak: 0,
        longestStreak: 0,
        todayCommits: 0,
        days: [],
        dailyContributions: {},
        lastUpdated: null,
      );
    }
  }

  /// ✅ Helper: Safe integer parsing with fallback
  static int _parseIntSafe(dynamic value, int fallback) {
    if (value is int) return value.clamp(0, 1000000);
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed?.clamp(0, 1000000) ?? fallback;
    }
    return fallback;
  }

  Map<String, dynamic> toJson() {
    // Convert int keys to string keys for JSON compatibility
    final dailyContributionsJson = dailyContributions.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return {
      'username': username,
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
      'days': days.map((day) => day.toJson()).toList(),
      'dailyContributions': dailyContributionsJson,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  /// ✅ Helper: Check if data is stale
  bool isStale({Duration maxAge = const Duration(hours: 24)}) {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > maxAge;
  }

  @override
  String toString() =>
      'CachedContributionData(user: $username, total: $totalContributions, streak: $currentStreak)';
}
