import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_exceptions.dart';
import 'app_models.dart';
import 'app_utils.dart';
import 'app_state.dart'; // Phase 4: For RefreshPolicy
import 'ui_render.dart';

import 'firebase_options.dart';
export 'app_exceptions.dart'; // Export for backward compatibility if needed

// ══════════════════════════════════════════════════════════════════════════
// 💾 STORAGE SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Service for persistent data storage
class StorageService {
  static SharedPreferences? _prefs;
  static const String _keyPendingWallpaperRefresh = 'pending_wp_refresh';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Initialize storage
  static Future<void> init() async {
    await _ensurePrefs();
  }

  static SharedPreferences? get _pOrNull => _prefs;

  static Future<SharedPreferences> _ensurePrefs() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  // ══════════════════════════════════════════════════════════════════════
  // TOKEN (Secure Storage)
  // ══════════════════════════════════════════════════════════════════════

  /// Save GitHub token securely
  static Future<void> setToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }
    // Audit Fix: Validate token format before storage
    final error = ValidationUtils.validateToken(trimmed);
    if (error != null) {
      throw ArgumentError(error);
    }
    await _secureStorage.write(
      key: AppConstants.keyToken,
      value: trimmed,
    );
  }

  /// Retrieve GitHub token
  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyToken);
    } on PlatformException catch (e) {
      // Only delete if storage is corrupted
      if (e.code == 'CORRUPTED' || e.code == 'FAILED_TO_DECRYPT') {
        await _secureStorage.delete(key: AppConstants.keyToken);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete GitHub token
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.keyToken);
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════════
  // USER DATA
  // ══════════════════════════════════════════════════════════════════════

  /// Save GitHub username
  static Future<void> setUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    // Validate via ValidationUtils to ensure consistency
    final error = ValidationUtils.validateUsername(trimmed);
    if (error != null) {
      throw ArgumentError(error);
    }
    final p = await _ensurePrefs();
    await p.setString(AppConstants.keyUsername, trimmed);
  }

  /// Get GitHub username
  static String? getUsername() {
    return _pOrNull?.getString(AppConstants.keyUsername);
  }

  // ══════════════════════════════════════════════════════════════════════
  // CACHED DATA
  // ══════════════════════════════════════════════════════════════════════

  /// Save cached contribution data
  static Future<void> setCachedData(CachedContributionData data) async {
    final p = await _ensurePrefs();
    await p.setString(
      AppConstants.keyCachedData,
      jsonEncode(data.toJson()),
    );
  }

  /// Get cached contribution data
  static CachedContributionData? getCachedData() {
    try {
      final json = _pOrNull?.getString(AppConstants.keyCachedData);
      if (json == null) return null;
      return CachedContributionData.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear cached data
  static Future<void> clearCache() async {
    final p = await _ensurePrefs();
    await p.remove(AppConstants.keyCachedData);
    await p.remove(AppConstants.keyLastUpdate);
  }

  // ══════════════════════════════════════════════════════════════════════
  // WALLPAPER CONFIG
  // ══════════════════════════════════════════════════════════════════════

  /// Save wallpaper configuration
  static Future<void> saveWallpaperConfig(WallpaperConfig config) async {
    final p = await _ensurePrefs();
    await p.setString(
      AppConstants.keyWallpaperConfig,
      jsonEncode(config.toJson()),
    );
  }

  /// Get wallpaper configuration
  static WallpaperConfig getWallpaperConfig() {
    try {
      final json = _pOrNull?.getString(AppConstants.keyWallpaperConfig);
      if (json == null) return WallpaperConfig.defaults();
      return WallpaperConfig.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      return WallpaperConfig.defaults();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════════════════

  /// Enable/disable auto-update
  static Future<void> setAutoUpdate(bool enabled) async {
    final p = await _ensurePrefs();
    await p.setBool(AppConstants.keyAutoUpdate, enabled);
  }

  /// Get auto-update setting
  static bool getAutoUpdate() {
    return _pOrNull?.getBool(AppConstants.keyAutoUpdate) ?? true;
  }

  // ══════════════════════════════════════════════════════════════════════
  // DIMENSIONS
  // ══════════════════════════════════════════════════════════════════════

  static Future<void> saveDeviceModel(String model) async {
    final normalized = model.trim();
    if (normalized.isEmpty) return;
    final p = await _ensurePrefs();
    await p.setString(AppConstants.keyDeviceModel, normalized);
  }

  static String? getDeviceModel() {
    final raw = _pOrNull?.getString(AppConstants.keyDeviceModel);
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static Future<void> saveDeviceMetrics({
    required double width,
    required double height,
    required double pixelRatio,
    required EdgeInsets safeInsets,
  }) async {
    final p = await _ensurePrefs();
    await p.setDouble(AppConstants.keyDimensionWidth, width);
    await p.setDouble(AppConstants.keyDimensionHeight, height);
    await p.setDouble(AppConstants.keyDimensionPixelRatio, pixelRatio);
    await p.setDouble(AppConstants.keySafeInsetTop, safeInsets.top);
    await p.setDouble(AppConstants.keySafeInsetBottom, safeInsets.bottom);
    await p.setDouble(AppConstants.keySafeInsetLeft, safeInsets.left);
    await p.setDouble(AppConstants.keySafeInsetRight, safeInsets.right);
  }

  static EdgeInsets getSafeInsets() {
    final p = _pOrNull;
    final top = p?.getDouble(AppConstants.keySafeInsetTop) ?? 0.0;
    final bottom = p?.getDouble(AppConstants.keySafeInsetBottom) ?? 0.0;
    final left = p?.getDouble(AppConstants.keySafeInsetLeft) ?? 0.0;
    final right = p?.getDouble(AppConstants.keySafeInsetRight) ?? 0.0;
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  /// Get screen dimensions (stored values are logical pixels from MediaQuery).
  static Map<String, double>? getDimensions() {
    final p = _pOrNull;
    final w = p?.getDouble(AppConstants.keyDimensionWidth);
    final h = p?.getDouble(AppConstants.keyDimensionHeight);
    final pr = p?.getDouble(AppConstants.keyDimensionPixelRatio);

    if (w != null && h != null && pr != null) {
      return {'width': w, 'height': h, 'pixelRatio': pr};
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WALLPAPER OPTIMIZATION
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setLastWallpaperHash(String hash) async {
    final p = await _ensurePrefs();
    await p.setString(AppConstants.keyWallpaperHash, hash);
  }

  static String? getLastWallpaperHash() {
    return _pOrNull?.getString(AppConstants.keyWallpaperHash);
  }

  static Future<void> setLastWallpaperPath(String path) async {
    final p = await _ensurePrefs();
    await p.setString(AppConstants.keyWallpaperPath, path);
  }

  static String? getLastWallpaperPath() {
    return _pOrNull?.getString(AppConstants.keyWallpaperPath);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METADATA & CLEANUP
  // ══════════════════════════════════════════════════════════════════════════

  /// Save last update timestamp
  static Future<void> setLastUpdate(DateTime dt) async {
    final p = await _ensurePrefs();
    await p.setString(AppConstants.keyLastUpdate, dt.toIso8601String());
  }

  /// Get last update timestamp
  static DateTime? getLastUpdate() {
    final s = _pOrNull?.getString(AppConstants.keyLastUpdate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  /// Set onboarding completion status
  static Future<void> setOnboardingComplete(bool v) async {
    final p = await _ensurePrefs();
    await p.setBool(AppConstants.keyOnboarding, v);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return _pOrNull?.getBool(AppConstants.keyOnboarding) ?? false;
  }

  static Future<void> setPendingWallpaperRefresh(bool value) async {
    final p = await _ensurePrefs();
    if (value) {
      await p.setBool(_keyPendingWallpaperRefresh, true);
    } else {
      await p.remove(_keyPendingWallpaperRefresh);
    }
  }

  static bool hasPendingWallpaperRefresh() {
    return _pOrNull?.getBool(_keyPendingWallpaperRefresh) ?? false;
  }

  static Future<bool> consumePendingWallpaperRefresh() async {
    final p = await _ensurePrefs();
    final v = p.getBool(_keyPendingWallpaperRefresh) ?? false;
    if (v) {
      await p.remove(_keyPendingWallpaperRefresh);
    }
    return v;
  }

  /// Logout and clear all data
  static Future<void> logout() async {
    await deleteToken();
    final p = await _ensurePrefs();
    await p.remove(AppConstants.keyUsername);
    await p.remove(AppConstants.keyCachedData);
    await p.remove(AppConstants.keyWallpaperConfig);
    await p.remove(AppConstants.keyLastUpdate);
    await p.remove(AppConstants.keyOnboarding);
    await p.remove(AppConstants.keyWallpaperHash);
    await p.remove(AppConstants.keyWallpaperPath);
    await p.remove(_keyPendingWallpaperRefresh);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Service for fetching GitHub contribution data
class GitHubService {
  static final http.Client _defaultClient = http.Client();
  static http.Client? _overrideClient;
  static const String _graphqlEndpoint = AppConstants.apiUrl;

  static void setHttpClient(http.Client client) {
    // Audit Fix: Dispose previous override if it exists
    if (_overrideClient != null) {
      try {
        _overrideClient!.close();
      } catch (_) {}
    }
    _overrideClient = client;
  }

  static http.Client get _client => _overrideClient ?? _defaultClient;

  static Future<CachedContributionData> fetchContributions({
    required String username,
    required String token,
  }) async {
    try {
      final response = await _makeRequest(username, token);

      late final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // Still check status here because jsonDecode failure might be due to 500 HTML response
        if (response.statusCode != 200) {
          throw GitHubException.fromResponse(
              response.statusCode, response.body);
        }
        throw GitHubException(
          'Invalid API response format',
          statusCode: response.statusCode,
          details: response.body,
        );
      }

      _validateResponse(response, data, username);
      return _parseResponse(data, username);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      rethrow;
    }
  }

  /// Make GraphQL API request with exponential backoff
  static Future<http.Response> _makeRequest(
    String username,
    String token,
  ) async {
    final now = AppDateUtils.nowUtc;
    final to = now.toIso8601String();
    final from = now
        .subtract(Duration(days: AppConstants.githubDataFetchDays))
        .toIso8601String();

    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        final response = await _client
            .post(
              Uri.parse(_graphqlEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'User-Agent': AppStrings.appName,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'query': _contributionQuery,
                'variables': {'login': username.trim(), 'from': from, 'to': to},
              }),
            )
            .timeout(AppConstants.apiTimeout);

        // Retry on Server Errors (5xx)
        if (response.statusCode >= 500 && attempts < maxAttempts) {
          // Audit Fix: Standardize Retry Logic (Exponential Backoff)
          final delay = Duration(seconds: 1 << attempts); // 2s, 4s, 8s
          debugPrint(
              'GitHub API 5xx (${response.statusCode}). Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }

        return response;
      } catch (e) {
        // Retry on Network Errors
        if (attempts < maxAttempts &&
            (e is SocketException || e is TimeoutException)) {
          final delay = Duration(seconds: 1 << attempts); // 2s, 4s, 8s
          debugPrint(
              'GitHub API Network Error ($e). Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  /// GraphQL query for contribution data
  static const String _contributionQuery = '''
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
          commitContributionsByRepository(maxRepositories: 50) {
            repository {
              nameWithOwner
              url
              isPrivate
              primaryLanguage {
                name
                color
              }
              languages(first: 10, orderBy: {field: SIZE, direction: DESC}) {
                edges {
                  size
                  node {
                    name
                    color
                  }
                }
              }
            }
            contributions {
              totalCount
            }
          }
        }
      }
    }
  ''';

  static const String _tokenValidationQuery = r'''
    query {
      viewer {
        login
      }
    }
  ''';

  /// Validate API response
  static void _validateResponse(
    http.Response response,
    Map<String, dynamic> data,
    String username,
  ) {
    if (data['errors'] != null) {
      final errors = data['errors'] as List;
      if (errors.isNotEmpty) {
        final firstMsg = errors.first['message'] ?? 'Unknown GraphQL error';
        throw GitHubException(firstMsg);
      }
    }

    // Audit Fix: API Response Schema Validation (P2)
    try {
      if (data['data'] == null) {
        // If data is missing entirely, it's a protocol error
        throw GitHubException('Invalid API response: missing "data" field');
      }
      
      // Critical Fix: Explicitly handle null user (private/auth required)
      if (data['data']['user'] == null) {
        throw UserNotFoundException();
      }
      
      if (data['data']['user']['contributionsCollection'] == null) {
        throw GitHubException(
            'Invalid API response: missing "contributionsCollection"');
      }
    } catch (e) {
      if (e is GitHubException || e is UserNotFoundException) rethrow;
      throw GitHubException('Schema validation failed: $e');
    }
  }

  /// Parse API response to CachedContributionData
  static CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    try {
      final data = json['data'];
      final user = data['user'];
      final collection = user['contributionsCollection'];
      final calendar =
          collection['contributionCalendar'] as Map<String, dynamic>;
      final apiTotalContributions = calendar['totalContributions'] as int;
      final weeksJson = calendar['weeks'] as List<dynamic>;

      final allDays = <ContributionDay>[];
      for (var week in weeksJson) {
        final daysJson = week['contributionDays'] as List<dynamic>;
        for (var dayJson in daysJson) {
          try {
            allDays.add(
              ContributionDay.fromJson(dayJson as Map<String, dynamic>),
            );
          } catch (e) {
            continue;
          }
        }
      }

      final computedTotal = allDays.fold<int>(
        0,
        (sum, d) => sum + d.contributionCount,
      );

      if (computedTotal != apiTotalContributions) {
        debugPrint(
            '⚠️ Contribution mismatch: API=\$apiTotalContributions, Computed=\$computedTotal');
      }

      final repos = <RepoContribution>[];
      final commitByRepo = collection['commitContributionsByRepository'];
      if (commitByRepo is List) {
        for (final entry in commitByRepo) {
          if (entry is! Map<String, dynamic>) continue;
          final contributions = entry['contributions'] as Map<String, dynamic>?;
          final totalCountRaw = contributions?['totalCount'];
          final commitCount =
              (totalCountRaw is num) ? totalCountRaw.toInt() : 0;
          if (commitCount <= 0) continue;

          final repoJson = entry['repository'] as Map<String, dynamic>?;
          if (repoJson == null) continue;

          final primaryLang =
              repoJson['primaryLanguage'] as Map<String, dynamic>?;
          final langConnection = repoJson['languages'] as Map<String, dynamic>?;
          final edges = langConnection?['edges'] as List<dynamic>? ?? const [];
          final slices = <RepoLanguageSlice>[];
          for (final e in edges) {
            if (e is! Map<String, dynamic>) continue;
            final node = e['node'] as Map<String, dynamic>?;
            if (node == null) continue;
            final sizeRaw = e['size'];
            final size = (sizeRaw is num) ? sizeRaw.toInt() : 0;
            final name = node['name'] as String?;
            if (name == null || name.trim().isEmpty) continue;
            slices.add(
              RepoLanguageSlice(
                name: name,
                color: node['color'] as String?,
                size: size,
              ),
            );
          }

          repos.add(
            RepoContribution(
              nameWithOwner: repoJson['nameWithOwner'] as String? ?? '',
              url: repoJson['url'] as String?,
              isPrivate: repoJson['isPrivate'] as bool? ?? false,
              commitCount: commitCount,
              primaryLanguageName: primaryLang?['name'] as String?,
              primaryLanguageColor: primaryLang?['color'] as String?,
              languages: List.unmodifiable(slices),
            ),
          );
        }
      }

      repos.sort((a, b) => b.commitCount.compareTo(a.commitCount));

      return CachedContributionData(
        username: username.trim(),
        totalContributions: apiTotalContributions,
        days: allDays,
        lastUpdated: AppDateUtils.nowUtc,
        repositories: repos,
      );
    } catch (e) {
      throw GitHubException('Failed to parse API response: $e');
    }
  }

  /// Validate token format using basic sanity checks
  static bool isValidTokenFormat(String token) {
    return ValidationUtils.validateToken(token) == null;
  }

  /// Validate token by first checking format and then making a lightweight API call
  /// Validate token by first checking format and then making a lightweight API call
  static Future<bool> validateToken(String token) async {
    if (!isValidTokenFormat(token)) return false;

    try {
      final response = await _client
          .post(
            Uri.parse(_graphqlEndpoint),
            headers: {
              'Authorization': 'Bearer ${token.trim()}',
              'User-Agent': AppStrings.appName,
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'query': _tokenValidationQuery,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return false;

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return false;
      }

      if (json['errors'] != null) return false;
      if (json['data']?['viewer']?['login'] != null) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    if (_overrideClient != null) return;
    _defaultClient.close();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🖼️ WALLPAPER SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Target screen for wallpaper
enum WallpaperTarget {
  home,
  lock,
  both;

  /// Convert to WallpaperManagerPlus constant
  int toManagerConstant() {
    switch (this) {
      case WallpaperTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case WallpaperTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case WallpaperTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }
}

@immutable
class DeviceMetrics {
  final double width;
  final double height;
  final double pixelRatio;
  final EdgeInsets safeInsets;
  final String? model;

  const DeviceMetrics({
    required this.width,
    required this.height,
    required this.pixelRatio,
    required this.safeInsets,
    required this.model,
  });

  double get aspectRatio => height == 0 ? 0 : height / width;
}

@immutable
class DevicePlacementInsets {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const DevicePlacementInsets({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });
}

class DeviceCompatibilityChecker {
  static DeviceMetrics? metricsFromStorage() {
    final dims = StorageService.getDimensions();
    if (dims == null) return null;
    return DeviceMetrics(
      width: dims['width']!,
      height: dims['height']!,
      pixelRatio: dims['pixelRatio']!,
      safeInsets: StorageService.getSafeInsets(),
      model: StorageService.getDeviceModel(),
    );
  }

  static WallpaperConfig applyPlacement({
    required WallpaperConfig base,
    required WallpaperTarget target,
    DeviceMetrics? metrics,
  }) {
    final m = metrics ?? metricsFromStorage();
    if (m == null) return base;

    final placement = _computePlacementInsets(metrics: m);
    // Audit Fix: Safe Insets Additive Logic (P2)
    // Instead of max(), we add the required placement to the base padding
    final nextPaddingTop = base.paddingTop + placement.top;
    final nextPaddingBottom = base.paddingBottom + placement.bottom;
    final nextPaddingLeft = base.paddingLeft + placement.left;
    final nextPaddingRight = base.paddingRight + placement.right;

    return base.copyWith(
      paddingTop: nextPaddingTop,
      paddingBottom: nextPaddingBottom,
      paddingLeft: nextPaddingLeft,
      paddingRight: nextPaddingRight,
    );
  }

  static DevicePlacementInsets _computePlacementInsets({
    required DeviceMetrics metrics,
  }) {
    // Audit Fix: Proportional Clock Buffer (P2)
    // Use 15% of screen height or at least 120px
    final dynamicClockBuffer =
        (metrics.height * AppConstants.deviceClockBufferHeightFraction).clamp(
      AppConstants.deviceClockBufferMinPx,
      AppConstants.deviceClockBufferMaxPx,
    );

    final clockAreaBuffer = metrics.safeInsets.top + dynamicClockBuffer;
    final horizontalBuffer =
        metrics.safeInsets.left + AppConstants.horizontalBuffer;

    return DevicePlacementInsets(
      top: clockAreaBuffer,
      bottom: clockAreaBuffer,
      left: horizontalBuffer,
      right: horizontalBuffer,
    );
  }
}

/// Result of a wallpaper refresh operation
enum RefreshResult {
  success,
  noChanges,
  networkError,
  authError,
  unknownError,
  throttled;

  bool get isSuccess =>
      this == RefreshResult.success || this == RefreshResult.noChanges;
}

/// Service for generating and setting wallpapers
class WallpaperService {
  static final _lock = Lock();
  static final _updateLock = Lock();

  /// Generate wallpaper image and set it
  /// Returns true if a new wallpaper was generated, false if skipped
  static Future<bool> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.both,
    ValueChanged<double>? onProgress,
  }) async {
    return await _lock.synchronized(() async {
      try {
        onProgress?.call(0.1);

        // Audit Fix: Wallpaper Regeneration Optimization
        final hash = _computeHash(data, config, target);
        final lastHash = StorageService.getLastWallpaperHash();
        final lastPath = StorageService.getLastWallpaperPath();

        if (hash == lastHash && lastPath != null) {
          final file = File(lastPath);
          // Audit Fix: Check file integrity (non-zero size)
          if (await file.exists() && await file.length() > 0) {
            debugPrint('Wallpaper config unchanged. Skipping generation.');
            onProgress?.call(1.0);

            // Still need to set it if it's not currently set (e.g. system reboot)
            if (Platform.isAndroid) {
              // Optimization: In a real app we might check if current wallpaper is same from system
              // For now, we just skip generation but still set it to be safe
              try {
                await WallpaperManagerPlus().setWallpaper(
                  file,
                  target.toManagerConstant(),
                );
              } catch (e) {
                // Fallback to regenerate if setting fails
              }
            }
            return false; // Skipped generation
          }
        }

        // Generate image
        final imageBytes = await _generateWallpaperImage(data, config, target);
        onProgress?.call(0.6);

        // Save to file
        final filePath = await _saveToFile(imageBytes);
        onProgress?.call(0.8);

        // Set as wallpaper on Android
        if (Platform.isAndroid) {
          await WallpaperManagerPlus().setWallpaper(
            File(filePath),
            target.toManagerConstant(),
          );
        }

        await StorageService.setLastWallpaperHash(hash);
        await StorageService.setLastWallpaperPath(filePath);

        onProgress?.call(1.0);
        return true; // New wallpaper generated
      } catch (e) {
        rethrow;
      }
    });
  }

  /// Generate wallpaper image as bytes
  static Future<Uint8List> _generateWallpaperImage(
    CachedContributionData data,
    WallpaperConfig config,
    WallpaperTarget target,
  ) async {
    // Get screen dimensions
    double width = AppConstants.defaultWallpaperWidth;
    double height = AppConstants.defaultWallpaperHeight;
    double pixelRatio = AppConstants.defaultPixelRatio;

    final dims = StorageService.getDimensions();
    if (dims != null) {
      width = dims['width']!;
      height = dims['height']!;
      pixelRatio = dims['pixelRatio']!;
    }

    final physicalWidth = (width * pixelRatio).round();
    final physicalHeight = (height * pixelRatio).round();

    // Create canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, physicalWidth.toDouble(), physicalHeight.toDouble()),
    );
    canvas.scale(pixelRatio, pixelRatio);

    final effectiveConfig = DeviceCompatibilityChecker.applyPlacement(
      base: config,
      target: target,
    );

    MonthHeatmapRenderer.render(
      canvas: canvas,
      size: Size(width, height),
      data: data,
      config: effectiveConfig,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(physicalWidth, physicalHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    // Dispose resources
    image.dispose();
    picture.dispose();

    if (byteData == null) {
      throw Exception('Failed to export image bytes');
    }

    return byteData.buffer.asUint8List();
  }

  /// Save image bytes to temporary file
  static Future<String> _saveToFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();

    // Clean up old wallpaper files
    try {
      final oldFiles = await directory
          .list()
          .where((f) => f.path.contains('github_wallpaper'))
          .toList();
      for (var file in oldFiles) {
        if (file is File) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore individual file deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore directory listing errors
    }

    // Save new file with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/github_wallpaper_$timestamp.png';
    await File(filePath).writeAsBytes(bytes, flush: true);

    return filePath;
  }

  /// Trigger a full refresh of the wallpaper (Fetch -> Render -> Set)
  ///
  /// **Phase 4**: Now delegates ALL decisions to RefreshPolicy in app_state.dart
  static Future<RefreshResult> refreshWallpaper({
    bool isBackground = false,
  }) async {
    return await _updateLock.synchronized(() async {
      try {
        // Initialize if background
        if (isBackground) {
          WidgetsFlutterBinding.ensureInitialized();
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
          await StorageService.init();
        }

        // === DECISION PHASE: Delegate to RefreshPolicy ===
        final decision = RefreshPolicy.shouldRefresh(
          isBackground: isBackground,
          isAndroid: Platform.isAndroid,
          autoUpdateEnabled: StorageService.getAutoUpdate(),
          hasPendingRefresh: StorageService.hasPendingWallpaperRefresh(),
          lastUpdate: StorageService.getLastUpdate(),
          username: StorageService.getUsername(),
          token: await StorageService.getToken(),
          hasConnectivity: await _hasConnectivity(),
        );

        if (!decision.shouldProceed) {
          // Convert string result to enum
          final reason = decision.skipReason as String;
          switch (reason) {
            case 'throttled':
              return RefreshResult.throttled;
            case 'networkError':
              return RefreshResult.networkError;
            case 'authError':
              return RefreshResult.authError;
            default:
              return RefreshResult.noChanges;
          }
        }

        // Consume pending flag if present
        if (StorageService.hasPendingWallpaperRefresh()) {
          await StorageService.consumePendingWallpaperRefresh();
        }

        // === EXECUTION PHASE: Service calls only ===
        final username = StorageService.getUsername()!;
        final token = (await StorageService.getToken())!;

        // 1. Fetch data from GitHub
        CachedContributionData data;
        try {
          data = await GitHubService.fetchContributions(
            username: username,
            token: token,
          );
        } catch (e) {
          debugPrint('Fetch failed: $e');
          return RefreshResult.networkError;
        }

        // 2. Save data to storage
        await StorageService.setCachedData(data);
        await StorageService.setLastUpdate(AppDateUtils.nowUtc);

        // 3. Generate and set wallpaper
        final config = StorageService.getWallpaperConfig();
        final generated = await generateAndSetWallpaper(
          data: data,
          config: config,
        );

        return generated ? RefreshResult.success : RefreshResult.noChanges;
      } catch (e) {
        debugPrint('Wallpaper refresh failed: $e');
        return RefreshResult.unknownError;
      }
    });
  }

  /// Check internet connectivity reliably
  static Future<bool> _hasConnectivity() async {
    // Audit Fix: Generic connectivity check (not just GitHub)
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    for (final host in AppConstants.connectivityHosts) {
      try {
        final request = await client.headUrl(Uri.https(host, ''));
        request.headers.set('User-Agent', AppStrings.appName);
        final response =
            await request.close().timeout(const Duration(seconds: 4));
        if (response.statusCode >= 200 && response.statusCode < 400) {
          // Any response 200-399 means we reached the server and are allowed
          client.close(force: true);
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    client.close(force: true);
    return false;
  }

  static String _computeHash(CachedContributionData data,
      WallpaperConfig config, WallpaperTarget target) {
    // Audit Fix: Optimized Hash Calculation
    // No need to sort if data.days is guaranteed sorted, but we'll do lightweight iteration
    // Use a simpler string format to reduce allocation overhead
    final buffer = StringBuffer();
    // Core data identity
    buffer.write('${data.username}|${data.totalContributions}|');

    // Only hash active days sequence to save length, or just hash all counts efficiently
    // We iterate sequentially; assuming data.days is sorted by date
    // Fix: Ensure sort order for stability
    final sortedDays = List<ContributionDay>.from(data.days)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final d in sortedDays) {
      if (d.contributionCount > 0) {
        buffer.write('${d.dateKey}:${d.contributionCount},');
      }
    }

    // Config identity
    // Hash relevant config fields directly instead of full JSON to improve perf
    buffer.write('|${config.isDarkMode}|${config.scale}|${config.opacity}|${config.customQuote}|');
    buffer.write('${config.verticalPosition}|${config.horizontalPosition}|${config.autoFitWidth}|');
    buffer.write('${config.quoteFontSize}|${config.quoteOpacity}|${config.cornerRadius}|');
    buffer.write('${target.index}');

    return _fnv1a64Hex(utf8.encode(buffer.toString()));
  }

  static String _fnv1a64Hex(List<int> bytes) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    const mask = 0xFFFFFFFFFFFFFFFF;

    for (final b in bytes) {
      hash ^= b;
      hash = (hash * prime) & mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ☁️ FCM SERVICE
// ══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('FCM Background message received: ${message.messageId}');
    final type = message.data['type'] as String?;
    if (type == 'refresh' || type == 'daily_refresh') {
      WidgetsFlutterBinding.ensureInitialized();
      await StorageService.init();

      if (!StorageService.getAutoUpdate()) return;

      // Audit Fix: Deferred Background Refresh
      // Mark as pending just in case immediate execution fails or is killed
      await StorageService.setPendingWallpaperRefresh(true);

      // Attempt immediate refresh (best effort)
      final result = await WallpaperService.refreshWallpaper(isBackground: true);
      
      if (result.isSuccess) {
         // If successful, we can clear the pending flag
         await StorageService.consumePendingWallpaperRefresh();
      }
    }
  } catch (e, stack) {
    debugPrint('Background handler failed: $e');
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance
            .recordError(e, stack, reason: 'FCM Background Handler Failed', fatal: false);
      }
    } catch (_) {}
  }
}

/// Service for Firebase Cloud Messaging
class FcmService {
  /// Initialize FCM
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await FirebaseMessaging.instance
          .subscribeToTopic(AppConstants.fcmTopicDailyUpdates);

      FirebaseMessaging.onMessage.listen((message) async {
        final type = message.data['type'] as String?;
        if ((type == 'refresh' || type == 'daily_refresh') &&
            StorageService.getAutoUpdate()) {
          await WallpaperService.refreshWallpaper();
        }
      });
    }
  }

  /// Unsubscribe from all topics
  static Future<void> unsubscribe() async {
    await FirebaseMessaging.instance
        .unsubscribeFromTopic(AppConstants.fcmTopicDailyUpdates);
  }
}

/// Application configuration helper
class AppConfig {
  /// Initialize app configuration from context
  static Future<void> initializeFromContext(BuildContext context) async {
    try {
      final view = View.of(context);
      await initializeFromView(view);
    } catch (e) {
      debugPrint('AppConfig init error: $e');
      // Audit Fix: Specific exception for context initialization
      throw ContextInitException(
          'Failed to initialize AppConfig from context: $e');
    }
  }

  static Future<void> initializeFromPlatformDispatcher() async {
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;
      await initializeFromView(views.first);
    } catch (e) {
      debugPrint('AppConfig init error: $e');
      throw ContextInitException(
          'Failed to initialize AppConfig from platform dispatcher: $e');
    }
  }

  static Future<void> initializeFromView(ui.FlutterView view) async {
    final mq = MediaQueryData.fromView(view);
    await StorageService.saveDeviceMetrics(
      width: mq.size.width,
      height: mq.size.height,
      pixelRatio: mq.devicePixelRatio,
      safeInsets: mq.viewPadding,
    );
  }

  /// Dispose all services
  static void dispose() {
    GitHubService.dispose();
    RenderUtils.clearCaches();
  }
}
