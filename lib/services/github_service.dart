

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
  // Shared persistent client for connection pooling
  static final http.Client _client = http.Client();

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API - FETCH CONTRIBUTIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Fetches year-to-date contributions with automatic retry
  ///
  /// [token]: GitHub Personal Access Token (passed explicitly to avoid long-term storage)
  /// Returns [CachedContributionData] with contribution stats and calendar data
  /// Throws [GitHubAPIException] on failure after all retries
  static Future<CachedContributionData> fetchContributions({
    required String username,
    required String token,
    int retryCount = 2,
  }) async {
    // 0. Username Validation
    if (!_isValidUsername(username)) {
      throw GitHubAPIException(
        'Invalid username format. GitHub usernames can only contain alphanumeric characters and hyphens.',
        shouldRetry: false,
      );
    }

    // 1. Soft Connectivity Check (DNS lookup)
    // We try to verify connectivity but DO NOT block if it fails,
    // as corporate/VPN networks might block raw DNS lookups.
    try {
      final result = await InternetAddress.lookup('api.github.com')
          .timeout(const Duration(seconds: 3));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ DNS lookup empty (potential offline)');
      }
    } catch (e) {
       // Just log and proceed - allow HTTP client to fail normally if offline
       if (kDebugMode) debugPrint('⚠️ DNS lookup failed (proceeding anyway): $e');
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts <= retryCount) {
      try {
        attempts++;
        if (kDebugMode) {
          debugPrint(
            '🌐 GitHubService: Fetching contributions (Attempt $attempts/${retryCount + 1})',
          );
        }

        final response = await _makeRequest(username, token);
        
        // Handle JSON decoding safely
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
           throw const FormatException('Invalid JSON response');
        }

        _validateResponse(response, data, username);

        if (kDebugMode) debugPrint('✅ GitHubService: Contribution data fetched successfully');
        return _parseResponse(data, username);
      } on GitHubAPIException catch (e) {
        // Don't retry fatal API errors (Auth, Rate Limit, Validation)
        if (!e.shouldRetry) rethrow;
        lastException = e;
      } on SocketException {
        lastException = GitHubAPIException(
          'Connection failed. Please check your internet connection.',
          shouldRetry: true,
        );
      } on TimeoutException {
        lastException = GitHubAPIException(
          'Request timed out. Please try again.',
          shouldRetry: true,
        );
      } on FormatException {
         lastException = GitHubAPIException(
           'Invalid response from GitHub servers.',
           shouldRetry: true,
         );
      } catch (e) {
        // Unknown errors are treated as fatal unless proven otherwise to avoid loops
        lastException = GitHubAPIException('Unexpected error: ${e.toString()}', shouldRetry: false);
        if (kDebugMode) debugPrint('❌ GitHubService: Unexpected error: $e');
      }

      // Exponential backoff retry
      if (attempts <= retryCount) {
        final waitSeconds = 2 * attempts; // 2s, 4s, 6s...
        if (kDebugMode) debugPrint('🔄 GitHubService: Retrying in ${waitSeconds}s...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    throw lastException ?? GitHubAPIException('Failed to connect to GitHub', shouldRetry: true);
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - HTTP REQUEST
  // ════════════════════════════════════════════════════════════════════════

  /// Makes HTTP POST request to GitHub GraphQL API
  static Future<http.Response> _makeRequest(String username, String token) async {
    final now = DateTime.now().toUtc(); // Fix: Force UTC
    
    // Calculate start of current year in UTC
    final from = DateTime.utc(now.year, 1, 1).toIso8601String();
    final to = now.toIso8601String();

    return await _client
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
  static String _buildQuery() {
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
  static void _validateResponse(
    http.Response response,
    Map<String, dynamic> data,
    String username,
  ) {
    // 1. Rate Limit Check (Headers)
    final remaining = response.headers['x-ratelimit-remaining'];
    if (remaining != null && int.tryParse(remaining) == 0) {
       final resetTime = response.headers['x-ratelimit-reset'];
       final resetDate = resetTime != null 
           ? DateTime.fromMillisecondsSinceEpoch(int.parse(resetTime) * 1000).toLocal()
           : null;
       
       throw GitHubAPIException(
         'Rate limit exceeded. Try again ${resetDate != null ? "at ${resetDate.hour}:${resetDate.minute}" : "later"}.',
         shouldRetry: false,
       );
    }

    // 2. HTTP Status Check
    if (response.statusCode != 200) {
      _handleHttpError(response);
    }

    // 3. GraphQL Error Check (Iterate all)
    if (data['errors'] != null) {
      final errors = data['errors'] as List;
      if (errors.isNotEmpty) {
        final messages = errors
            .map((e) => e['message'] as String? ?? 'Unknown error')
            .join(' | ');
            
        if (messages.contains('Could not resolve to a User')) {
           throw GitHubAPIException('User "$username" not found.', shouldRetry: false);
        }
        
        throw GitHubAPIException('GitHub API: $messages', shouldRetry: false);
      }
    }

    // 4. Data Structure Check
    if (data['data'] == null || 
        data['data']['user'] == null || 
        data['data']['user']['contributionsCollection'] == null) {
      throw GitHubAPIException(
        'User "@$username" found but contributions data is missing or private.',
        shouldRetry: false,
      );
    }
  }

  /// Handles HTTP status code errors with user-friendly messages
  static void _handleHttpError(http.Response response) {
    bool shouldRetry = false;
    String message;

    switch (response.statusCode) {
      case 401:
        message = 'Invalid GitHub token. Please update your token in settings.';
        shouldRetry = false;
        break;
      case 403:
        message = 'Access forbidden. Token may lack permissions or be rate-limited.';
        shouldRetry = false;
        break;
      case 404:
        message = 'GitHub endpoint not found.';
        shouldRetry = false;
        break;
      case 422:
        message = 'Validation failed. Check username and parameters.';
        shouldRetry = false;
        break;
      case >= 500:
        message = 'GitHub servers are down (Error ${response.statusCode}).';
        shouldRetry = true; // Retry server errors
        break;
      default:
        message = 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
        shouldRetry = true; // Retry unknown transient errors
    }
    
    throw GitHubAPIException(message, shouldRetry: shouldRetry);
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - DATA PARSING & STATISTICS
  // ════════════════════════════════════════════════════════════════════════

  /// Parses API response and calculates contribution statistics
  static CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    try {
      final collection = json['data']?['user']?['contributionsCollection'];
      if (collection == null) throw const FormatException('Missing collection data');
      
      final calendar = collection['contributionCalendar'] as Map<String, dynamic>?;
      if (calendar == null) throw const FormatException('Missing calendar data');

      final weeksJson = calendar['weeks'] as List?;
      if (weeksJson == null) throw const FormatException('Missing weeks data');

      final apiTotalContributions = calendar['totalContributions'] as int? ?? 0;

      // 1. Flatten all days
      final allDays = _flattenDays(weeksJson);

      // 2. Calculate stats
      final stats = _calculateStats(allDays);

      // 3. Filter for current month
      final now = DateTime.now();
      final currentMonthDays = allDays
          .where((d) => d.date.month == now.month && d.date.year == now.year)
          .toList();

      // 4. Build daily map
      final dailyContributions = <int, int>{};
      for (var day in currentMonthDays) {
        dailyContributions[day.date.day] = day.contributionCount;
      }

      return CachedContributionData(
        username: username,
        totalContributions: apiTotalContributions,
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
        'Failed to process contribution data structure.',
        shouldRetry: false,
      );
    }
  }

  /// Flattens weeks structure into a list of contribution days
  static List<ContributionDay> _flattenDays(List weeksJson) {
    final allDays = <ContributionDay>[];

    for (var week in weeksJson) {
      final daysJson = week['contributionDays'] as List?;
      if (daysJson == null) continue;
      
      for (var day in daysJson) {
        try {
          final dateStr = "${day['date']}T00:00:00Z";
          allDays.add(
            ContributionDay(
              date: DateTime.parse(dateStr),
              contributionCount: day['contributionCount'] as int? ?? 0,
              contributionLevel: day['contributionLevel'] as String?,
            ),
          );
        } catch (_) {}
      }
    }
    return allDays;
  }

  /// Calculates contribution statistics
  static Map<String, int> _calculateStats(List<ContributionDay> days) {
    days.sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int todayCommits = 0;

    int tempStreak = 0;
    DateTime? lastActiveDate;

    // Use UTC for today
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    for (var day in days) {
      if (DateHelper.isSameDay(day.date, today)) {
        todayCommits = day.contributionCount;
      }

      if (day.contributionCount > 0) {
        if (lastActiveDate != null) {
          final daysSince = day.date.difference(lastActiveDate).inDays;

          if (daysSince == 1) {
            tempStreak++;
          } else if (daysSince > 1) {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        } else {
          tempStreak = 1;
        }
        lastActiveDate = day.date;
      }
    }
    
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    if (lastActiveDate != null) {
      final daysSinceLastActive = today.difference(lastActiveDate).inDays;
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

  /// Validates GitHub token format
  static bool isValidTokenFormat(String token) {
    final trimmed = token.trim();
    if (trimmed.startsWith('ghp_')) {
      return RegExp(r'^ghp_[a-zA-Z0-9]{36}$').hasMatch(trimmed);
    } else if (trimmed.startsWith('github_pat_')) {
      return RegExp(r'^github_pat_[a-zA-Z0-9_]{50,}$').hasMatch(trimmed);
    }
    return false;
  }
  
  /// Validates GitHub username format
  static bool _isValidUsername(String username) {
    // GitHub: alphanumeric + hyphen, max 39 chars, no consecutive hyphens, no start/end hyphen
    // Simplified regex:
    final RegExp validUsername = RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
    return validUsername.hasMatch(username);
  }

  /// Gets GitHub API base URL
  static String get apiUrl => AppConfig.githubApiUrl;
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class GitHubAPIException implements Exception {
  final String message;
  final bool shouldRetry;

  GitHubAPIException(this.message, {this.shouldRetry = false});

  @override
  String toString() => message;
}
