import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'date_utils.dart';
import '../models/contribution_data.dart';

class GitHubAPI {
  final String token;

  GitHubAPI({required this.token});

  /// Builds GraphQL query for CURRENT MONTH ONLY (optimized)
  String _buildQuery(String username) {
    // ✅ FIXED: Only fetch current month (was fetching full year)
    final from = AppDateUtils.getStartOfMonth().toUtc().toIso8601String();
    final to = AppDateUtils.getEndOfMonth().toUtc().toIso8601String();

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

  /// Fetches GitHub contribution data with proper error handling and retry logic
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
          'GitHubAPI: Fetching contributions for $username (attempt $attempts)',
        );

        final response = await http
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
              onTimeout: () => throw TimeoutException(
                'GitHub API request timed out after ${AppConstants.apiTimeout.inSeconds}s',
              ),
            );

        // Handle HTTP status codes
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Check for GraphQL errors
          if (data['errors'] != null && data['errors'].isNotEmpty) {
            final errorMsg =
                data['errors'][0]['message'] ?? 'Unknown GraphQL error';
            throw GitHubAPIException('GraphQL Error: $errorMsg');
          }

          // Check if user exists
          if (data['data'] == null || data['data']['user'] == null) {
            throw GitHubAPIException('User not found: $username');
          }

          debugPrint('GitHubAPI: Successfully fetched data');
          return _parseResponse(data, username);
        } else if (response.statusCode == 401) {
          // Token invalid - don't retry
          throw GitHubAPIException(
            'Invalid GitHub token. Please check your credentials.',
          );
        } else if (response.statusCode == 403) {
          // Rate limit or token permissions - check headers
          final remaining = response.headers['x-ratelimit-remaining'];
          if (remaining == '0') {
            final resetTime = response.headers['x-ratelimit-reset'];
            throw GitHubAPIException(
              'GitHub API rate limit exceeded. Resets at: $resetTime',
            );
          } else {
            throw GitHubAPIException(
              'GitHub API access forbidden. Check token permissions (needs read:user scope).',
            );
          }
        } else if (response.statusCode >= 500) {
          // Server error - retry makes sense
          lastException = GitHubAPIException(
            'GitHub server error (${response.statusCode}). Retrying...',
          );
          debugPrint('GitHubAPI: Server error, will retry');

          if (attempts <= retryCount) {
            await Future.delayed(
              Duration(seconds: 2 * attempts),
            ); // Exponential backoff
            continue;
          }
        } else {
          throw GitHubAPIException(
            'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on SocketException catch (e) {
        // Network error - retry makes sense
        lastException = GitHubAPIException('Network error: ${e.message}');
        debugPrint('GitHubAPI: Network error, will retry');

        if (attempts <= retryCount) {
          await Future.delayed(Duration(seconds: 2 * attempts));
          continue;
        }
      } on TimeoutException catch (e) {
        // Timeout - retry makes sense
        lastException = GitHubAPIException('Request timeout: ${e.message}');
        debugPrint('GitHubAPI: Timeout, will retry');

        if (attempts <= retryCount) {
          await Future.delayed(Duration(seconds: 2 * attempts));
          continue;
        }
      } on GitHubAPIException {
        // Don't retry API-specific errors (invalid token, user not found)
        rethrow;
      } catch (e) {
        // Unexpected error
        throw GitHubAPIException('Unexpected error: ${e.toString()}');
      }
    }

    // All retries exhausted
    throw lastException ??
        GitHubAPIException('Failed after $retryCount retries');
  }

  /// Parses GitHub API response into structured data
  CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    try {
      final calendar =
          json['data']['user']['contributionsCollection']['contributionCalendar'];
      final weeksJson = calendar['weeks'] as List;

      // Flatten all days from all weeks and filter to current month/year
      final allDays = <ContributionDay>[];
      final now = DateTime.now();
      for (var week in weeksJson) {
        final daysJson = week['contributionDays'] as List;
        for (var day in daysJson) {
          final date = DateTime.parse(day['date']);
          // ✅ FIX: Only include days that belong to the current month and year
          if (date.month == now.month && date.year == now.year) {
            allDays.add(
              ContributionDay(
                date: date,
                contributionCount: day['contributionCount'] as int,
                contributionLevel: day['contributionLevel'] as String?,
              ),
            );
          }
        }
      }

      // ✅ No filtering needed - we only requested current month
      final currentMonthDays = allDays;

      // Calculate statistics
      final stats = _calculateStats(currentMonthDays);

      // Build daily contributions map
      final dailyContributions = <int, int>{};
      for (var day in currentMonthDays) {
        dailyContributions[day.date.day] = day.contributionCount;
      }

      debugPrint(
        'GitHubAPI: Parsed ${currentMonthDays.length} days, ${stats['totalContributions']} total contributions',
      );

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
    } catch (e) {
      throw GitHubAPIException(
        'Failed to parse GitHub response: ${e.toString()}',
      );
    }
  }

  /// ✅ FIXED: Improved streak calculation logic
  Map<String, int> _calculateStats(List<ContributionDay> days) {
    int totalContributions = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;
    int tempStreak = 0;
    int streakAtLastContribution = 0;

    // Sort days by date
    final sortedDays = List<ContributionDay>.from(days);
    sortedDays.sort((a, b) => a.date.compareTo(b.date));

    final today = DateTime.now();
    DateTime? lastContributionDate;

    for (var day in sortedDays) {
      totalContributions += day.contributionCount;

      // Track today's commits
      if (day.isToday()) {
        todayCommits = day.contributionCount;
      }

      // Streak calculation
      if (day.contributionCount > 0) {
        tempStreak++;
        lastContributionDate = day.date;
        streakAtLastContribution = tempStreak;

        // Update longest streak
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // ✅ FIXED: Current streak logic
    // Streak is active if:
    // 1. Last contribution was today, OR
    // 2. Last contribution was yesterday (today might not be over yet)
    if (lastContributionDate != null) {
      final daysSinceLastContribution = AppDateUtils.daysBetween(
        lastContributionDate,
        today,
      );

      if (daysSinceLastContribution <= 1) {
        // Streak is still active (contributed today or yesterday)
        currentStreak = streakAtLastContribution;
      } else {
        // Streak is broken (more than 1 day since last contribution)
        currentStreak = 0;
      }
    }

    return {
      'totalContributions': totalContributions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayCommits': todayCommits,
    };
  }
}

/// Custom exception for GitHub API errors
class GitHubAPIException implements Exception {
  final String message;
  GitHubAPIException(this.message);

  @override
  String toString() => 'GitHubAPIException: $message';
}
