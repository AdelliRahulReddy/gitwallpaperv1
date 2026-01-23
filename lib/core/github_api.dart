import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'date_utils.dart';
import '../models/contribution_data.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB API CLIENT - CLEAN & ROBUST
// ══════════════════════════════════════════════════════════════════════════
// Handles all GitHub GraphQL API communication with smart retry logic
// ══════════════════════════════════════════════════════════════════════════

class GitHubAPI {
  final String token;

  GitHubAPI({required this.token});

  // ════════════════════════════════════════════════════════════════════════
  // 📡 FETCH CONTRIBUTIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Fetches year-to-date contributions with automatic retry
  Future<CachedContributionData> fetchContributions(
    String username, {
    int retryCount = 2,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts <= retryCount) {
      try {
        attempts++;
        debugPrint(
          'GitHubAPI: Fetching $username (Attempt $attempts/${retryCount + 1})',
        );

        final response = await _makeRequest(username);
        final data = jsonDecode(response.body);

        _validateResponse(response, data, username);

        debugPrint('GitHubAPI: Success');
        return _parseResponse(data, username);
      } on SocketException {
        lastException = GitHubAPIException('No internet connection');
      } on TimeoutException {
        lastException = GitHubAPIException('Connection timed out');
      } on GitHubAPIException {
        rethrow; // Don't retry auth/permission errors
      } catch (e) {
        lastException = GitHubAPIException('Unexpected error: $e');
      }

      // Exponential backoff retry
      if (attempts <= retryCount) {
        final wait = Duration(seconds: 2 * attempts);
        debugPrint('GitHubAPI: Retrying in ${wait.inSeconds}s...');
        await Future.delayed(wait);
      }
    }

    throw lastException ?? GitHubAPIException('Failed to connect to GitHub');
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  /// Makes HTTP request to GitHub GraphQL API
  Future<http.Response> _makeRequest(String username) async {
    return await http
        .post(
          Uri.parse(AppConstants.githubApiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'User-Agent': 'GitHubWallpaper/1.0',
          },
          body: jsonEncode({'query': _buildQuery(username)}),
        )
        .timeout(
          AppConstants.apiTimeout,
          onTimeout: () => throw TimeoutException('Request timed out'),
        );
  }

  /// Builds GraphQL query for year-to-date data
  String _buildQuery(String username) {
    final now = DateTime.now();
    final from = DateTime(now.year, 1, 1).toUtc().toIso8601String();
    final to = now.toUtc().toIso8601String();

    return '''
    query {
      user(login: "$username") {
        contributionsCollection(from: "$from", to: "$to") {
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
    if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
      final msg = data['errors'][0]['message'] ?? 'Unknown error';
      throw GitHubAPIException('GitHub Error: $msg');
    }

    // Empty/invalid data
    if (data['data'] == null || data['data']['user'] == null) {
      throw GitHubAPIException('User "$username" not found or private');
    }
  }

  /// Handles HTTP status code errors
  void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        throw GitHubAPIException('Invalid token. Update in settings.');
      case 403:
        final reset = response.headers['x-ratelimit-reset'];
        final msg = reset != null
            ? 'Rate limit exceeded. Try again later.'
            : 'Access forbidden. Check token permissions.';
        throw GitHubAPIException(msg);
      case >= 500:
        throw GitHubAPIException('GitHub is down (${response.statusCode})');
      default:
        throw GitHubAPIException('HTTP Error: ${response.statusCode}');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📊 DATA PARSING
  // ════════════════════════════════════════════════════════════════════════

  /// Parses API response and calculates statistics
  CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    try {
      final calendar =
          json['data']['user']['contributionsCollection']['contributionCalendar'];
      final weeksJson = calendar['weeks'] as List;

      // 1. Flatten all days from year-to-date
      final allDays = _flattenDays(weeksJson);

      // 2. Calculate stats from full year
      final stats = _calculateStats(allDays);

      // 3. Filter for current month only (for wallpaper)
      final now = DateTime.now();
      final currentMonthDays = allDays
          .where((d) => d.date.month == now.month && d.date.year == now.year)
          .toList();

      // 4. Build daily contributions map
      final dailyContributions = <int, int>{};
      for (var day in currentMonthDays) {
        dailyContributions[day.date.day] = day.contributionCount;
      }

      return CachedContributionData(
        username: username,
        totalContributions: stats['totalContributions']!,
        currentStreak: stats['currentStreak']!,
        longestStreak: stats['longestStreak']!,
        todayCommits: stats['todayCommits']!,
        days: currentMonthDays,
        dailyContributions: dailyContributions,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('GitHubAPI: Parse error: $e\n$stack');
      throw GitHubAPIException('Failed to process data');
    }
  }

  /// Flattens weeks into list of days
  List<ContributionDay> _flattenDays(List weeksJson) {
    final allDays = <ContributionDay>[];

    for (var week in weeksJson) {
      final daysJson = week['contributionDays'] as List;
      for (var day in daysJson) {
        allDays.add(
          ContributionDay(
            date: DateTime.parse(day['date']),
            contributionCount: day['contributionCount'] as int,
            contributionLevel: day['contributionLevel'] as String?,
          ),
        );
      }
    }

    return allDays;
  }

  /// Calculates contribution statistics
  Map<String, int> _calculateStats(List<ContributionDay> days) {
    int total = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;

    int tempStreak = 0;
    DateTime? lastActiveDate;
    final today = DateTime.now();

    // Sort chronologically
    days.sort((a, b) => a.date.compareTo(b.date));

    for (var day in days) {
      total += day.contributionCount;

      // Check if today
      if (AppDateUtils.isSameDay(day.date, today)) {
        todayCommits = day.contributionCount;
      }

      // Update streak
      if (day.contributionCount > 0) {
        if (lastActiveDate != null &&
            day.date.difference(lastActiveDate).inDays > 1) {
          tempStreak = 1; // Reset streak
        } else {
          tempStreak++;
        }
        lastActiveDate = day.date;

        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      }
    }

    // Validate current streak (must be today or yesterday)
    if (lastActiveDate != null) {
      final daysSince = AppDateUtils.daysBetween(lastActiveDate, today);
      currentStreak = daysSince <= 1 ? tempStreak : 0;
    }

    return {
      'totalContributions': total,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ⚠️ CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class GitHubAPIException implements Exception {
  final String message;
  GitHubAPIException(this.message);

  @override
  String toString() => message;
}
