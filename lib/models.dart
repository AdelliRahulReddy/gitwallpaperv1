// ══════════════════════════════════════════════════════════════════════════
// 📊 DATA MODELS - Production Ready
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'utils.dart';

int _toNonNegativeInt(dynamic value, {int fallback = 0}) {
  if (value is! num) return fallback;
  final parsed = value.toInt();
  return parsed >= 0 ? parsed : fallback;
}

String? _normalizeNonEmptyString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _normalizeNameOrFallback(dynamic value, {required String fallback}) {
  return _normalizeNonEmptyString(value) ?? fallback;
}

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

  static const Set<String> _validContributionLevels = {
    'NONE',
    'FIRST_QUARTILE',
    'SECOND_QUARTILE',
    'THIRD_QUARTILE',
    'FOURTH_QUARTILE',
  };

  static const Map<String, int> _contributionLevelRank = {
    'NONE': 0,
    'FIRST_QUARTILE': 1,
    'SECOND_QUARTILE': 2,
    'THIRD_QUARTILE': 3,
    'FOURTH_QUARTILE': 4,
  };

  ContributionDay({
    required DateTime date,
    required int contributionCount,
    String? contributionLevel,
  })  : date = AppDateUtils.toDateOnlyUtc(date),
        contributionCount = contributionCount < 0 ? 0 : contributionCount,
        contributionLevel = contributionCount <= 0
            ? 'NONE'
            : _sanitizeContributionLevel(contributionLevel);

  static String? _sanitizeContributionLevel(String? level) {
    final trimmed = _normalizeNonEmptyString(level);
    if (trimmed == null) return null;
    if (_validContributionLevels.contains(trimmed)) return trimmed;
    debugPrint('ContributionDay: Unknown contribution level "$trimmed"');
    return null;
  }

  static String? strongestLevel(String? first, String? second) {
    final left = _sanitizeContributionLevel(first);
    final right = _sanitizeContributionLevel(second);
    if (left == null) return right;
    if (right == null) return left;
    final leftRank = _contributionLevelRank[left] ?? -1;
    final rightRank = _contributionLevelRank[right] ?? -1;
    return rightRank > leftRank ? right : left;
  }

  /// Create from GitHub API JSON response
  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final parsedDate = AppDateUtils.parseIsoDate(dateStr);

    if (parsedDate == null) {
      debugPrint('ContributionDay: Invalid date string: $dateStr');
      throw FormatException('Invalid date in ContributionDay JSON: $dateStr');
    }

    final countValue = json['contributionCount'];
    final count =
        (countValue is num && countValue >= 0) ? countValue.toInt() : 0;

    return ContributionDay(
      date: parsedDate,
      contributionCount: count,
      contributionLevel: _normalizeNonEmptyString(json['contributionLevel']),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.toIsoDateString(AppDateUtils.toDateOnlyUtc(date)),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel,
      };

  /// Whether this day has any contributions
  bool get isActive => contributionCount > 0;

  int getContributionLevel({Quartiles? quartiles}) {
    return RenderUtils.getContributionLevel(contributionCount,
        quartiles: quartiles);
  }

  /// Get date key for map lookups (YYYY-MM-DD format)
  String get dateKey =>
      AppDateUtils.toIsoDateString(AppDateUtils.toDateOnlyUtc(date));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionDay &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey &&
          contributionCount == other.contributionCount &&
          contributionLevel == other.contributionLevel;

  @override
  int get hashCode =>
      Object.hash(dateKey, contributionCount, contributionLevel);

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
  factory ContributionStats.fromDays(List<ContributionDay> days,
      {DateTime? nowUtc}) {
    final dailyTotals = _buildDailyTotals(days);

    if (dailyTotals.isEmpty) {
      return const ContributionStats(
        currentStreak: 0,
        longestStreak: 0,
        todayContributions: 0,
        activeDaysCount: 0,
        peakDayContributions: 0,
        totalContributions: 0,
        mostActiveWeekday: AppConstants.fallbackWeekday,
      );
    }

    final today =
        AppDateUtils.toDateOnlyUtc((nowUtc ?? AppDateUtils.nowUtc).toUtc());
    final streaks = _calculateStreaks(dailyTotals, today: today);
    final todayCount = dailyTotals[today] ?? 0;
    final activeCount = dailyTotals.values.where((count) => count > 0).length;
    final peak = dailyTotals.values.fold<int>(
      0,
      (maxCount, count) => count > maxCount ? count : maxCount,
    );
    final total = dailyTotals.values.fold<int>(0, (sum, count) => sum + count);
    final weekday = _getMostActiveWeekday(dailyTotals);

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
  /// Missing dates are treated as unknown (do not auto-reset streaks).
  static Map<String, int> _calculateStreaks(Map<DateTime, int> dailyTotals,
      {required DateTime today}) {
    if (dailyTotals.isEmpty) return {'current': 0, 'longest': 0};

    int longestStreakCount = 0;
    int tempStreak = 0;

    final sortedDates = dailyTotals.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final earliest = sortedDates.first;
    final latest = sortedDates.last;
    final expectedDays =
        latest.difference(earliest).inDays >= 0 ? latest.difference(earliest).inDays + 1 : 0;
    final coverage =
        expectedDays <= 0 ? 1.0 : (dailyTotals.length / expectedDays);
    final treatMissingAsZero = coverage < 0.90;

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

  static Map<DateTime, int> _buildDailyTotals(List<ContributionDay> days) {
    final totals = <DateTime, int>{};
    for (final day in days) {
      final key = AppDateUtils.toDateOnlyUtc(day.date);
      totals[key] = (totals[key] ?? 0) + day.contributionCount;
    }
    return totals;
  }

  /// Find most active weekday
  static String _getMostActiveWeekday(Map<DateTime, int> dailyTotals) {
    if (dailyTotals.isEmpty) return AppConstants.fallbackWeekday;

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
// REPOSITORY CONTRIBUTIONS
// ══════════════════════════════════════════════════════════════════════════

@immutable
class RepoLanguageSlice {
  final String name;
  final String? color;
  final int size;

  static const String unknownLanguage = 'Unknown';

  RepoLanguageSlice({
    required String name,
    required this.color,
    required int size,
  })  : name = _normalizeNameOrFallback(name, fallback: unknownLanguage),
        size = size < 0 ? 0 : size;

  factory RepoLanguageSlice.fromJson(Map<String, dynamic> json) {
    return RepoLanguageSlice(
      name: _normalizeNameOrFallback(
        json['name'],
        fallback: unknownLanguage,
      ),
      color: json['color'] as String?,
      size: _toNonNegativeInt(json['size']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'size': size,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoLanguageSlice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => Object.hash(name, color, size);
}

@immutable
class RepoContribution {
  final String nameWithOwner;
  final String? url;
  final bool isPrivate;
  final int commitCount;
  final String? primaryLanguageName;
  final String? primaryLanguageColor;
  final List<RepoLanguageSlice> languages;

  RepoContribution({
    required String nameWithOwner,
    required this.url,
    required this.isPrivate,
    required int commitCount,
    required String? primaryLanguageName,
    required this.primaryLanguageColor,
    required List<RepoLanguageSlice> languages,
  })  : nameWithOwner = _normalizeNameOrFallback(nameWithOwner,
            fallback: 'unknown/unknown'),
        commitCount = commitCount < 0 ? 0 : commitCount,
        primaryLanguageName = _normalizeNonEmptyString(primaryLanguageName),
        languages = List.unmodifiable(languages);

  factory RepoContribution.fromJson(Map<String, dynamic> json) {
    final rawLanguages = (json['languages'] as List<dynamic>? ?? const []);
    final parsedLanguages = <RepoLanguageSlice>[];
    for (final item in rawLanguages) {
      if (item is Map<String, dynamic>) {
        final parsed = RepoLanguageSlice.fromJson(item);
        if (parsed.name.trim().isEmpty) continue;
        parsedLanguages.add(parsed);
      }
    }

    return RepoContribution(
      nameWithOwner: _normalizeNameOrFallback(
        json['nameWithOwner'],
        fallback: 'unknown/unknown',
      ),
      url: json['url'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      commitCount: _toNonNegativeInt(json['commitCount']),
      primaryLanguageName:
          _normalizeNonEmptyString(json['primaryLanguageName']),
      primaryLanguageColor: json['primaryLanguageColor'] as String?,
      languages: List.unmodifiable(parsedLanguages),
    );
  }

  Map<String, dynamic> toJson() => {
        'nameWithOwner': nameWithOwner,
        'url': url,
        'isPrivate': isPrivate,
        'commitCount': commitCount,
        'primaryLanguageName': primaryLanguageName,
        'primaryLanguageColor': primaryLanguageColor,
        'languages': languages.map((l) => l.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoContribution &&
          runtimeType == other.runtimeType &&
          nameWithOwner == other.nameWithOwner &&
          url == other.url &&
          isPrivate == other.isPrivate &&
          commitCount == other.commitCount &&
          primaryLanguageName == other.primaryLanguageName &&
          primaryLanguageColor == other.primaryLanguageColor &&
          listEquals(languages, other.languages);

  @override
  int get hashCode => Object.hash(nameWithOwner, url, isPrivate, commitCount,
      primaryLanguageName, primaryLanguageColor, Object.hashAll(languages));
}

@immutable
class LanguageUsage {
  final String name;
  final String? color;
  final double score;
  final double percent;

  LanguageUsage({
    required String name,
    required this.color,
    required double score,
    required double percent,
  })  : name = _normalizeNameOrFallback(name,
            fallback: RepoLanguageSlice.unknownLanguage),
        score = score < 0 ? 0 : score,
        percent = percent.clamp(0.0, 1.0);

  factory LanguageUsage.fromJson(Map<String, dynamic> json) {
    return LanguageUsage(
      name: _normalizeNameOrFallback(
        json['name'],
        fallback: RepoLanguageSlice.unknownLanguage,
      ),
      color: json['color'] as String?,
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0,
      percent:
          (json['percent'] is num) ? (json['percent'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'score': score,
        'percent': percent,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageUsage &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          color == other.color &&
          score == other.score &&
          percent == other.percent;

  @override
  int get hashCode => Object.hash(name, color, score, percent);
}

// ══════════════════════════════════════════════════════════════════════════
// CACHED CONTRIBUTION DATA
// ══════════════════════════════════════════════════════════════════════════

/// Complete GitHub contribution data with caching metadata
@immutable
class CachedContributionData {
  static const int _maxTopLanguages = 8;

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

  final List<RepoContribution> repositories;
  final List<LanguageUsage> topLanguages;

  /// Pre-computed date lookup map for O(1) access
  final Map<String, ContributionDay> _dateLookupCache;

  final int _equalityDigest;

  CachedContributionData._({
    required this.username,
    required this.totalContributions,
    required this.days,
    required this.lastUpdated,
    required this.stats,
    required this.quartiles,
    required this.repositories,
    required this.topLanguages,
    required Map<String, ContributionDay> dateLookupCache,
  })  : _dateLookupCache = dateLookupCache,
        _equalityDigest = Object.hash(
          username,
          totalContributions,
          lastUpdated,
          quartiles.q1,
          quartiles.q2,
          quartiles.q3,
          Object.hashAll(days),
          Object.hashAll(repositories),
          Object.hashAll(topLanguages),
        );

  factory CachedContributionData({
    required String username,
    required int totalContributions,
    required List<ContributionDay> days,
    required DateTime lastUpdated,
    ContributionStats? stats,
    Quartiles? quartiles,
    List<RepoContribution>? repositories,
    List<LanguageUsage>? topLanguages,
  }) {
    final normalizedDays = _normalizeAndMergeDays(days);
    final dailyTotal = normalizedDays.fold<int>(
      0,
      (sum, day) => sum + day.contributionCount,
    );
    if (totalContributions != dailyTotal) {
      debugPrint(
        'CachedContributionData: total mismatch provided=$totalContributions, computed=$dailyTotal',
      );
    }

    final safeRepositories = List<RepoContribution>.unmodifiable(
      repositories ?? const <RepoContribution>[],
    );
    final safeTopLanguages = List<LanguageUsage>.unmodifiable(
      topLanguages ?? _computeTopLanguages(safeRepositories),
    );
    final lookup = Map<String, ContributionDay>.unmodifiable({
      for (final day in normalizedDays) day.dateKey: day,
    });

    return CachedContributionData._(
      username: username.trim(),
      totalContributions: dailyTotal,
      days: List<ContributionDay>.unmodifiable(normalizedDays),
      lastUpdated: lastUpdated.toUtc(),
      stats: stats ?? ContributionStats.fromDays(normalizedDays),
      quartiles: quartiles ??
          RenderUtils.calculateQuartiles(
            normalizedDays.map((d) => d.contributionCount).toList(),
          ),
      repositories: safeRepositories,
      topLanguages: safeTopLanguages,
      dateLookupCache: lookup,
    );
  }

  static List<LanguageUsage> _computeTopLanguages(
    List<RepoContribution> repositories,
  ) {
    final Map<String, double> totals = {};
    final Map<String, String?> colors = {};

    for (final repo in repositories) {
      if (repo.commitCount <= 0) continue;

      final slices = repo.languages;
      final totalSize = slices.fold<int>(0, (sum, s) => sum + s.size);
      if (totalSize > 0) {
        for (final s in slices) {
          if (s.size <= 0) continue;
          if (s.name == RepoLanguageSlice.unknownLanguage) continue;
          final contribution = repo.commitCount * (s.size / totalSize);
          totals[s.name] = (totals[s.name] ?? 0.0) + contribution;
          colors[s.name] ??= s.color;
        }
        continue;
      }

      final name = repo.primaryLanguageName;
      if (name != null &&
          name.trim().isNotEmpty &&
          name != RepoLanguageSlice.unknownLanguage) {
        totals[name] = (totals[name] ?? 0.0) + repo.commitCount.toDouble();
        colors[name] ??= repo.primaryLanguageColor;
      }
    }

    final totalScore = totals.values.fold<double>(0.0, (a, b) => a + b);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <LanguageUsage>[];
    final maxNamed = entries.length > _maxTopLanguages ? _maxTopLanguages - 1 : _maxTopLanguages;
    var namedScoreTotal = 0.0;
    for (final e in entries.take(maxNamed)) {
      final pct = totalScore <= 0 ? 0.0 : (e.value / totalScore);
      namedScoreTotal += e.value;
      result.add(
        LanguageUsage(
          name: e.key,
          color: colors[e.key],
          score: e.value,
          percent: pct,
        ),
      );
    }
    if (entries.length > _maxTopLanguages && totalScore > 0) {
      final otherScore = (totalScore - namedScoreTotal).clamp(0.0, totalScore);
      if (otherScore > 0) {
        result.add(
          LanguageUsage(
            name: 'Other',
            color: null,
            score: otherScore,
            percent: otherScore / totalScore,
          ),
        );
      }
    }
    return result;
  }

  static List<ContributionDay> _normalizeAndMergeDays(
      List<ContributionDay> raw) {
    final byDate = <String, ContributionDay>{};
    var duplicateDates = 0;

    for (final day in raw) {
      final normalizedDay = ContributionDay(
        date: day.date,
        contributionCount: day.contributionCount,
        contributionLevel: day.contributionLevel,
      );
      final key = normalizedDay.dateKey;
      final existing = byDate[key];

      if (existing == null) {
        byDate[key] = normalizedDay;
        continue;
      }

      duplicateDates++;
      byDate[key] = ContributionDay(
        date: existing.date,
        contributionCount:
            existing.contributionCount + normalizedDay.contributionCount,
        contributionLevel: ContributionDay.strongestLevel(
          existing.contributionLevel,
          normalizedDay.contributionLevel,
        ),
      );
    }

    if (duplicateDates > 0) {
      debugPrint(
        'CachedContributionData: merged $duplicateDates duplicate day entries',
      );
    }

    final normalizedDays = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return normalizedDays;
  }

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
          ? DateTime.parse(lastUpdatedStr).toUtc()
          : AppDateUtils.nowUtc;
    } catch (e) {
      debugPrint(
          'CachedContributionData: Using current time due to parse error: $e');
      timestamp = AppDateUtils.nowUtc;
    }

    final computedTotal =
        parsedDays.fold<int>(0, (sum, d) => sum + d.contributionCount);
    final reportedTotal =
        _toNonNegativeInt(json['totalContributions'], fallback: computedTotal);
    if (reportedTotal != computedTotal) {
      debugPrint(
        'CachedContributionData: JSON total mismatch reported=$reportedTotal, computed=$computedTotal',
      );
    }
    final reposJson = json['repositories'] as List<dynamic>?;
    final parsedRepos = <RepoContribution>[];
    if (reposJson != null) {
      for (final r in reposJson) {
        if (r is Map<String, dynamic>) {
          parsedRepos.add(RepoContribution.fromJson(r));
        }
      }
    }

    final languagesJson = json['topLanguages'] as List<dynamic>?;
    final parsedLanguages = <LanguageUsage>[];
    if (languagesJson != null) {
      for (final l in languagesJson) {
        if (l is Map<String, dynamic>) {
          parsedLanguages.add(LanguageUsage.fromJson(l));
        }
      }
    }

    return CachedContributionData(
      username: (json['username'] as String? ?? '').trim(),
      totalContributions: reportedTotal,
      days: parsedDays,
      lastUpdated: timestamp,
      repositories: parsedRepos,
      topLanguages: parsedLanguages.isEmpty ? null : parsedLanguages,
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
        'repositories': repositories.map((r) => r.toJson()).toList(),
        'topLanguages': topLanguages.map((l) => l.toJson()).toList(),
      };

  /// Get contributions for a specific date (fast lookup)
  int getContributionsForDate(DateTime date) {
    final key = AppDateUtils.toIsoDateString(AppDateUtils.toDateOnlyUtc(date));
    return _dateLookupCache[key]?.contributionCount ?? 0;
  }

  /// Check if cached data is stale
  bool isStale([Duration? customThreshold, DateTime? now]) {
    final threshold = customThreshold ?? AppConstants.cacheExpiry;
    final refNow = (now ?? DateTime.now()).toUtc();
    return refNow.difference(lastUpdated.toUtc()) > threshold;
  }

  /// Convenience getters delegating to stats
  int get currentStreak => stats.currentStreak;
  int get longestStreak => stats.longestStreak;
  int get todayCommits => stats.todayContributions;
  int get activeDaysCount => stats.activeDaysCount;
  int get peakDay => stats.peakDayContributions;
  String get mostActiveWeekday => stats.mostActiveWeekday;
  bool get hasContributedToday => stats.todayContributions > 0;

  int get activeRepositoriesCount =>
      repositories.where((r) => r.commitCount > 0).length;

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
          _equalityDigest == other._equalityDigest &&
          username == other.username &&
          totalContributions == other.totalContributions &&
          lastUpdated == other.lastUpdated &&
          listEquals(days, other.days) &&
          listEquals(repositories, other.repositories) &&
          listEquals(topLanguages, other.topLanguages) &&
          quartiles.q1 == other.quartiles.q1 &&
          quartiles.q2 == other.quartiles.q2 &&
          quartiles.q3 == other.quartiles.q3;

  @override
  int get hashCode => _equalityDigest;

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
    return WallpaperConfig(
      isDarkMode: _parseBool(json['isDarkMode'], false),
      verticalPosition: _parseDouble(json['verticalPosition'], 0.5, 0.0, 1.0),
      horizontalPosition:
          _parseDouble(json['horizontalPosition'], 0.5, 0.0, 1.0),
      scale: _parseDouble(
        json['scale'],
        AppConstants.defaultWallpaperScale,
        0.5,
        8.0,
      ),
      autoFitWidth: _parseBool(json['autoFitWidth'], true),
      opacity: _parseDouble(
        json['opacity'],
        AppConstants.defaultWallpaperOpacity,
        0.0,
        1.0,
      ),
      customQuote: _parseQuote(json['customQuote']),
      quoteFontSize: _parseDouble(json['quoteFontSize'], 14.0, 10.0, 40.0),
      quoteOpacity: _parseDouble(json['quoteOpacity'], 1.0, 0.0, 1.0),
      paddingTop: _parseDouble(json['paddingTop'], 0.0, 0.0, 500.0),
      paddingBottom: _parseDouble(json['paddingBottom'], 0.0, 0.0, 500.0),
      paddingLeft: _parseDouble(json['paddingLeft'], 0.0, 0.0, 500.0),
      paddingRight: _parseDouble(json['paddingRight'], 0.0, 0.0, 500.0),
      cornerRadius: _parseDouble(
        json['cornerRadius'],
        AppConstants.defaultCornerRadius,
        0.0,
        20.0,
      ),
    );
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return defaultValue;
  }

  static String _parseQuote(dynamic value) {
    final trimmed = _normalizeNonEmptyString(value) ?? '';
    if (trimmed.length <= AppConstants.quoteMaxLength) return trimmed;
    return trimmed.substring(0, AppConstants.quoteMaxLength);
  }

  /// Helper to safely parse and clamp double values
  static double _parseDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;
    final parsed = (value is num) ? value.toDouble() : defaultValue;
    if (!parsed.isFinite) return defaultValue;
    return parsed.clamp(min, max).toDouble();
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
      verticalPosition: _parseDouble(
          verticalPosition ?? this.verticalPosition, 0.5, 0.0, 1.0),
      horizontalPosition: _parseDouble(
        horizontalPosition ?? this.horizontalPosition,
        0.5,
        0.0,
        1.0,
      ),
      scale: _parseDouble(
        scale ?? this.scale,
        AppConstants.defaultWallpaperScale,
        0.5,
        8.0,
      ),
      autoFitWidth: autoFitWidth ?? this.autoFitWidth,
      opacity: _parseDouble(
        opacity ?? this.opacity,
        AppConstants.defaultWallpaperOpacity,
        0.0,
        1.0,
      ),
      customQuote: _parseQuote(customQuote ?? this.customQuote),
      quoteFontSize: _parseDouble(
        quoteFontSize ?? this.quoteFontSize,
        14.0,
        10.0,
        40.0,
      ),
      quoteOpacity:
          _parseDouble(quoteOpacity ?? this.quoteOpacity, 1.0, 0.0, 1.0),
      paddingTop: _parseDouble(paddingTop ?? this.paddingTop, 0.0, 0.0, 500.0),
      paddingBottom:
          _parseDouble(paddingBottom ?? this.paddingBottom, 0.0, 0.0, 500.0),
      paddingLeft:
          _parseDouble(paddingLeft ?? this.paddingLeft, 0.0, 0.0, 500.0),
      paddingRight:
          _parseDouble(paddingRight ?? this.paddingRight, 0.0, 0.0, 500.0),
      cornerRadius: _parseDouble(
        cornerRadius ?? this.cornerRadius,
        AppConstants.defaultCornerRadius,
        0.0,
        20.0,
      ),
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
