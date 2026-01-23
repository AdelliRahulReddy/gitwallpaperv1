import 'package:flutter/foundation.dart';
import '../core/date_utils.dart';

// ══════════════════════════════════════════════════════════════════════════
// 📦 CONTRIBUTION DATA MODELS - CLEAN & SAFE
// ══════════════════════════════════════════════════════════════════════════
// Models for GitHub contribution data with safe JSON parsing
// ══════════════════════════════════════════════════════════════════════════

/// Single day's contribution data
class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel;

  ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  // ════════════════════════════════════════════════════════════════════════
  // JSON SERIALIZATION
  // ════════════════════════════════════════════════════════════════════════

  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    try {
      final dateStr = json['date'] as String?;
      if (dateStr == null || dateStr.isEmpty) {
        throw const FormatException('Missing date');
      }

      final date = AppDateUtils.parseDate(dateStr);
      if (date == null) {
        throw FormatException('Invalid date: $dateStr');
      }

      final count = _parseCount(json['contributionCount']);

      return ContributionDay(
        date: date,
        contributionCount: count,
        contributionLevel: json['contributionLevel'] as String?,
      );
    } catch (e) {
      debugPrint('ContributionDay: Parse error, using fallback');
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

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static int _parseCount(dynamic value) {
    if (value is int) return value.clamp(0, 10000);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed.clamp(0, 10000);
    }
    throw FormatException('Invalid count: $value');
  }

  bool isToday() => AppDateUtils.isToday(date);

  @override
  String toString() => 'ContributionDay($date: $contributionCount)';
}

// ══════════════════════════════════════════════════════════════════════════
// 💾 CACHED CONTRIBUTION DATA
// ══════════════════════════════════════════════════════════════════════════

class CachedContributionData {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final int todayCommits;
  final List<ContributionDay> days;
  final Map<int, int> dailyContributions;
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

  // ════════════════════════════════════════════════════════════════════════
  // JSON SERIALIZATION
  // ════════════════════════════════════════════════════════════════════════

  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    try {
      final username = json['username'] as String?;
      if (username == null || username.isEmpty) {
        throw const FormatException('Missing username');
      }

      return CachedContributionData(
        username: username,
        totalContributions: _parseIntSafe(json['totalContributions']),
        currentStreak: _parseIntSafe(json['currentStreak']),
        longestStreak: _parseIntSafe(json['longestStreak']),
        todayCommits: _parseIntSafe(json['todayCommits']),
        days: _parseDays(json['days']),
        dailyContributions: _parseDailyMap(json['dailyContributions']),
        lastUpdated: _parseDate(json['lastUpdated']),
      );
    } catch (e) {
      debugPrint('CachedContributionData: Parse error - $e');
      return _createFallback();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
      'days': days.map((day) => day.toJson()).toList(),
      'dailyContributions': dailyContributions.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  // ════════════════════════════════════════════════════════════════════════
  // PARSING HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static int _parseIntSafe(dynamic value, [int fallback = 0]) {
    if (value is int) return value.clamp(0, 1000000);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed.clamp(0, 1000000);
    }
    return fallback;
  }

  static List<ContributionDay> _parseDays(dynamic value) {
    try {
      final list = value as List?;
      if (list == null || list.isEmpty) return [];

      return list
          .map((item) => ContributionDay.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CachedContributionData: Days parse error');
      return [];
    }
  }

  static Map<int, int> _parseDailyMap(dynamic value) {
    final result = <int, int>{};

    try {
      final map = value as Map<String, dynamic>?;
      if (map == null) return result;

      map.forEach((key, val) {
        final dayNum = int.tryParse(key);
        if (dayNum != null && dayNum >= 1 && dayNum <= 31) {
          result[dayNum] = _parseIntSafe(val);
        }
      });
    } catch (e) {
      debugPrint('CachedContributionData: Daily map parse error');
    }

    return result;
  }

  static DateTime? _parseDate(dynamic value) {
    try {
      final str = value as String?;
      if (str == null || str.isEmpty) return null;
      return AppDateUtils.parseDate(str);
    } catch (e) {
      return null;
    }
  }

  static CachedContributionData _createFallback() {
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

  // ════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ════════════════════════════════════════════════════════════════════════

  /// Check if data is stale (default: 24 hours)
  bool isStale({Duration maxAge = const Duration(hours: 24)}) {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > maxAge;
  }

  @override
  String toString() =>
      'CachedContributionData($username: $totalContributions total, $currentStreak streak)';
}
