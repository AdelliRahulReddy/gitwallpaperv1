// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB SERVICE - API Client & Data Processing
// ══════════════════════════════════════════════════════════════════════════
// Handles all GitHub GraphQL API communication with smart retry logic
// Fetches contribution data and calculates statistics
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'utils.dart';

class GitHubService {
  final String token;

  GitHubService({required this.token});

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API - FETCH CONTRIBUTIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Fetches year-to-date contributions with automatic retry
  ///
  /// Returns [CachedContributionData] with contribution stats and calendar data
  /// Throws [GitHubAPIException] on failure after all retries
  Future<CachedContributionData> fetchContributions(
    String username, {
    int retryCount = 2,
  }) async {
    // Check internet connectivity first
    try {
      final hasConnection = await ConnectivityHelper.hasConnection();
      if (!hasConnection) {
        throw GitHubAPIException(
          'No internet connection. Please check your WiFi or mobile data.',
        );
      }
    } catch (e) {
      // Fallback if connectivity check fails, proceed to try request
      if (kDebugMode) debugPrint('⚠️ Connectivity check skipped: $e');
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts <= retryCount) {
      try {
        attempts++;
        if (kDebugMode) {
          debugPrint(
            '🌐 GitHubService: Fetching @$username (Attempt $attempts/${retryCount + 1})',
          );
        }

        final response = await _makeRequest(username);
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        _validateResponse(response, data, username);

        if (kDebugMode) debugPrint('✅ GitHubService: Success');
        return _parseResponse(data, username);
      } on SocketException {
        lastException = GitHubAPIException(
          'Connection failed. Please check your internet connection.',
        );
      } on TimeoutException {
        lastException = GitHubAPIException(
          'Request timed out. Please try again.',
        );
      } on GitHubAPIException {
        rethrow; // Don't retry auth/permission errors
      } on FormatException catch (e) {
        lastException = GitHubAPIException(
          'Invalid response from GitHub. Please try again.',
        );
        if (kDebugMode) debugPrint('⚠️ GitHubService: Parse error: $e');
      } catch (e) {
        lastException = GitHubAPIException('Unexpected error: ${e.toString()}');
        if (kDebugMode) debugPrint('❌ GitHubService: Unexpected error: $e');
      }

      // Exponential backoff retry
      if (attempts <= retryCount) {
        final waitSeconds = 2 * attempts;
        if (kDebugMode) debugPrint('🔄 GitHubService: Retrying in ${waitSeconds}s...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    throw lastException ?? GitHubAPIException('Failed to connect to GitHub');
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - HTTP REQUEST
  // ════════════════════════════════════════════════════════════════════════

  /// Makes HTTP POST request to GitHub GraphQL API
  Future<http.Response> _makeRequest(String username) async {
    final now = DateTime.now();
    // [FIX] Use DateTime.utc for start of year.
    // Using DateTime(year, 1, 1) creates a LOCAL time. When converted .toUtc(),
    // it can shift to the previous year (e.g. UTC+9 00:00 -> UTC 15:00 Prev Day).
    final from = DateTime.utc(now.year, 1, 1).toIso8601String();
    final to = now.toUtc().toIso8601String();

    return await http
        .post(
          Uri.parse(AppConfig.githubApiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'User-Agent': AppConfig.userAgent,
          },
          body: jsonEncode({
            'query': _buildQuery(),
            'variables': {
              'login': username,
              'from': from,
              'to': to,
            },
          }),
        )
        .timeout(
          AppConfig.apiTimeout,
          onTimeout: () => throw TimeoutException('Request timed out'),
        );
  }

  /// Builds GraphQL query for year-to-date contribution data
  /// Uses parameterized variables for security (prevents injection)
  String _buildQuery() {
    return '''
    query(\$login: String!, \$from: DateTime!, \$to: DateTime!) {
      user(login: \$login) {
        contributionsCollection(from: \$from, to: \$to) {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                date
                contributionCount
                contributionLevel
              }
            }
          }
        }
      }
    }
    ''';
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - RESPONSE VALIDATION
  // ════════════════════════════════════════════════════════════════════════

  /// Validates API response and throws appropriate errors
  void _validateResponse(
    http.Response response,
    Map<String, dynamic> data,
    String username,
  ) {
    // HTTP errors
    if (response.statusCode != 200) {
      _handleHttpError(response);
    }

    // GraphQL errors
    if (data['errors'] != null) {
      final errors = data['errors'] as List;
      if (errors.isNotEmpty) {
        final message = errors[0]['message'] as String? ?? 'Unknown error';
        throw GitHubAPIException('GitHub API Error: $message');
      }
    }

    // Empty/invalid data
    if (data['data'] == null || data['data']['user'] == null) {
      throw GitHubAPIException(
        'User "@$username" not found or account is private.',
      );
    }
  }

  /// Handles HTTP status code errors with user-friendly messages
  void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        throw GitHubAPIException(
          'Invalid GitHub token. Please update your token in settings.',
        );
      case 403:
        final reset = response.headers['x-ratelimit-reset'];
        if (reset != null) {
          throw GitHubAPIException(
            'GitHub API rate limit exceeded. Please try again later.',
          );
        } else {
          throw GitHubAPIException(
            'Access forbidden. Check your token permissions.',
          );
        }
      case 404:
        throw GitHubAPIException(
          'GitHub API endpoint not found. Please update the app.',
        );
      case >= 500:
        throw GitHubAPIException(
          'GitHub servers are down (Error ${response.statusCode}). Try again later.',
        );
      default:
        throw GitHubAPIException(
          'HTTP Error ${response.statusCode}: ${response.reasonPhrase ?? "Unknown"}',
        );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - DATA PARSING & STATISTICS
  // ════════════════════════════════════════════════════════════════════════

  /// Parses API response and calculates contribution statistics
  CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    try {
      final collection = json['data']['user']['contributionsCollection'];
      final calendar =
          collection['contributionCalendar'] as Map<String, dynamic>;
      final weeksJson = calendar['weeks'] as List;

      // Get exact total from API (more accurate than manual sum)
      final apiTotalContributions = calendar['totalContributions'] as int? ?? 0;

      // 1. Flatten all days from year-to-date
      final allDays = _flattenDays(weeksJson);

      // 2. Calculate stats from full year
      final stats = _calculateStats(allDays);

      // 3. Filter for current month only (for wallpaper display)
      final now = DateTime.now();
      final currentMonthDays = allDays
          .where((d) => d.date.month == now.month && d.date.year == now.year)
          .toList();

      // 4. Build daily contributions map (day-of-month -> count)
      final dailyContributions = <int, int>{};
      for (var day in currentMonthDays) {
        dailyContributions[day.date.day] = day.contributionCount;
      }

      return CachedContributionData(
        username: username,
        totalContributions: apiTotalContributions, // Use API total
        currentStreak: stats['currentStreak']!,
        longestStreak: stats['longestStreak']!,
        todayCommits: stats['todayCommits']!,
        days: currentMonthDays,
        dailyContributions: dailyContributions,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ GitHubService: Parse error: $e\n$stack');
      throw GitHubAPIException(
        'Failed to process contribution data. Please try again.',
      );
    }
  }

  /// Flattens weeks structure into a list of contribution days
  List<ContributionDay> _flattenDays(List weeksJson) {
    final allDays = <ContributionDay>[];

    for (var week in weeksJson) {
      final daysJson = week['contributionDays'] as List;
      for (var day in daysJson) {
        try {
          // [FIX] Force UTC parsing by appending 'T00:00:00Z'.
          // GitHub returns "YYYY-MM-DD". DateTime.parse() is Local.
          // This causes bugs during DST transitions (e.g. 23 hour days)
          // where .inDays difference returns 0 instead of 1.
          final dateStr = "${day['date']}T00:00:00Z";

          allDays.add(
            ContributionDay(
              date: DateTime.parse(dateStr),
              contributionCount: day['contributionCount'] as int? ?? 0,
              contributionLevel: day['contributionLevel'] as String?,
            ),
          );
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ GitHubService: Skipped invalid day: $e');
          continue; // Skip invalid days
        }
      }
    }

    return allDays;
  }

  /// Calculates contribution statistics (streaks, totals, etc.)
  Map<String, int> _calculateStats(List<ContributionDay> days) {
    // Note: 'days' are already sorted by _flattenDays logic (GitHub returns chronological)
    // but sorting again ensures safety.
    days.sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;

    int tempStreak = 0;
    DateTime? lastActiveDate;

    // Use UTC for today to match the UTC parsing in _flattenDays
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    for (var day in days) {
      // Check if this is today
      if (DateHelper.isSameDay(day.date, today)) {
        todayCommits = day.contributionCount;
      }

      if (day.contributionCount > 0) {
        if (lastActiveDate != null) {
          final daysSince = day.date.difference(lastActiveDate).inDays;

          if (daysSince > 1) {
            // Streak broken
            tempStreak = 1;
          } else if (daysSince == 1) {
            // Streak continues (consecutive day)
            tempStreak++;
          }
          // if daysSince == 0, it's the same day (duplicate entry?), ignore.
        } else {
          // First active day found
          tempStreak = 1;
        }

        lastActiveDate = day.date;

        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      }
    }

    // Validate current streak (must include today or yesterday)
    if (lastActiveDate != null) {
      final daysSinceLastActive = today.difference(lastActiveDate).inDays;
      // If last active was today (0) or yesterday (1), streak is alive.
      currentStreak = daysSinceLastActive <= 1 ? tempStreak : 0;
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
    };
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ════════════════════════════════════════════════════════════════════════

  /// Validates GitHub token format (basic check)
  static bool isValidTokenFormat(String token) {
    final trimmed = token.trim();
    return trimmed.startsWith('ghp_') || trimmed.startsWith('github_pat_');
  }

  /// Gets GitHub API base URL
  static String get apiUrl => AppConfig.githubApiUrl;
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class GitHubAPIException implements Exception {
  final String message;

  GitHubAPIException(this.message);

  @override
  String toString() => message;
}
