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

import 'exceptions.dart';
import 'models.dart';
import 'utils.dart';
import 'rendering.dart';

import 'firebase_options.dart';
export 'exceptions.dart'; // Export for backward compatibility if needed

// ══════════════════════════════════════════════════════════════════════════
// 💾 STORAGE SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Service for persistent data storage
class StorageService {
  static SharedPreferences? _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Initialize storage
  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError(
        'StorageService.init() must be called before accessing storage',
      );
    }
    return _prefs!;
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
    await _p.setString(AppConstants.keyUsername, trimmed);
  }

  /// Get GitHub username
  static String? getUsername() {
    return _p.getString(AppConstants.keyUsername);
  }

  // ══════════════════════════════════════════════════════════════════════
  // CACHED DATA
  // ══════════════════════════════════════════════════════════════════════

  /// Save cached contribution data
  static Future<void> setCachedData(CachedContributionData data) async {
    await _p.setString(
      AppConstants.keyCachedData,
      jsonEncode(data.toJson()),
    );
  }

  /// Get cached contribution data
  static CachedContributionData? getCachedData() {
    try {
      final json = _p.getString(AppConstants.keyCachedData);
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
    await _p.remove(AppConstants.keyCachedData);
    await _p.remove(AppConstants.keyLastUpdate);
  }

  // ══════════════════════════════════════════════════════════════════════
  // WALLPAPER CONFIG
  // ══════════════════════════════════════════════════════════════════════

  /// Save wallpaper configuration
  static Future<void> saveWallpaperConfig(WallpaperConfig config) async {
    await _p.setString(
      AppConstants.keyWallpaperConfig,
      jsonEncode(config.toJson()),
    );
  }

  /// Get wallpaper configuration
  static WallpaperConfig getWallpaperConfig() {
    try {
      final json = _p.getString(AppConstants.keyWallpaperConfig);
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
    await _p.setBool(AppConstants.keyAutoUpdate, enabled);
  }

  /// Get auto-update setting
  static bool getAutoUpdate() {
    return _p.getBool(AppConstants.keyAutoUpdate) ?? true;
  }

  // ══════════════════════════════════════════════════════════════════════
  // DIMENSIONS
  // ══════════════════════════════════════════════════════════════════════


  static Future<void> saveDeviceModel(String model) async {
    final normalized = model.trim();
    if (normalized.isEmpty) return;
    await _p.setString(AppConstants.keyDeviceModel, normalized);
  }

  static String? getDeviceModel() {
    final raw = _p.getString(AppConstants.keyDeviceModel);
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static Future<void> saveDeviceMetrics({
    required double width,
    required double height,
    required double pixelRatio,
    required EdgeInsets safeInsets,
  }) async {
    await _p.setDouble(AppConstants.keyDimensionWidth, width);
    await _p.setDouble(AppConstants.keyDimensionHeight, height);
    await _p.setDouble(AppConstants.keyDimensionPixelRatio, pixelRatio);
    await _p.setDouble(AppConstants.keySafeInsetTop, safeInsets.top);
    await _p.setDouble(AppConstants.keySafeInsetBottom, safeInsets.bottom);
    await _p.setDouble(AppConstants.keySafeInsetLeft, safeInsets.left);
    await _p.setDouble(AppConstants.keySafeInsetRight, safeInsets.right);
  }

  static EdgeInsets getSafeInsets() {
    final top = _p.getDouble(AppConstants.keySafeInsetTop) ?? 0.0;
    final bottom = _p.getDouble(AppConstants.keySafeInsetBottom) ?? 0.0;
    final left = _p.getDouble(AppConstants.keySafeInsetLeft) ?? 0.0;
    final right = _p.getDouble(AppConstants.keySafeInsetRight) ?? 0.0;
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  /// Get screen dimensions (stored values are logical pixels from MediaQuery).
  static Map<String, double>? getDimensions() {
    final w = _p.getDouble(AppConstants.keyDimensionWidth);
    final h = _p.getDouble(AppConstants.keyDimensionHeight);
    final pr = _p.getDouble(AppConstants.keyDimensionPixelRatio);

    if (w != null && h != null && pr != null) {
      return {'width': w, 'height': h, 'pixelRatio': pr};
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WALLPAPER OPTIMIZATION
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setLastWallpaperHash(String hash) async {
    await _p.setString(AppConstants.keyWallpaperHash, hash);
  }

  static String? getLastWallpaperHash() {
    return _p.getString(AppConstants.keyWallpaperHash);
  }

  static Future<void> setLastWallpaperPath(String path) async {
    await _p.setString(AppConstants.keyWallpaperPath, path);
  }

  static String? getLastWallpaperPath() {
    return _p.getString(AppConstants.keyWallpaperPath);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METADATA & CLEANUP
  // ══════════════════════════════════════════════════════════════════════════

  /// Save last update timestamp
  static Future<void> setLastUpdate(DateTime dt) async {
    await _p.setString(AppConstants.keyLastUpdate, dt.toIso8601String());
  }

  /// Get last update timestamp
  static DateTime? getLastUpdate() {
    final s = _p.getString(AppConstants.keyLastUpdate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  /// Set onboarding completion status
  static Future<void> setOnboardingComplete(bool v) async {
    await _p.setBool(AppConstants.keyOnboarding, v);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return _p.getBool(AppConstants.keyOnboarding) ?? false;
  }

  /// Logout and clear all data
  static Future<void> logout() async {
    await deleteToken();
    // Audit Fix: Logout Clears Device Metrics (P3) - Fixed
    // Only clear user data, keep device metrics
    await _p.remove(AppConstants.keyUsername);
    await _p.remove(AppConstants.keyCachedData);
    await _p.remove(AppConstants.keyWallpaperConfig);
    // await _p.clear(); // Removed to preserve metrics
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Service for fetching GitHub contribution data
class GitHubService {
  static http.Client _client = http.Client();
  static const String _graphqlEndpoint = AppConstants.apiUrl;

  static void setHttpClient(http.Client client) {
    _client = client;
  }

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
           throw GitHubException.fromResponse(response.statusCode, response.body);
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
           debugPrint('GitHub API 5xx (${response.statusCode}). Retrying in ${delay.inSeconds}s...');
           await Future.delayed(delay);
           continue;
        }

        return response;
      } catch (e) {
        // Retry on Network Errors
        if (attempts < maxAttempts && (e is SocketException || e is TimeoutException)) {
          final delay = Duration(seconds: 1 << attempts); // 2s, 4s, 8s
          debugPrint('GitHub API Network Error ($e). Retrying in ${delay.inSeconds}s...');
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
        }
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
        throw GitHubException('Invalid API response: missing "data" field');
      }
      if (data['data']['user'] == null) {
        throw UserNotFoundException();
      }
      if (data['data']['user']['contributionsCollection'] == null) {
        throw GitHubException('Invalid API response: missing "contributionsCollection"');
      }
    } catch (e) {
      if (e is GitHubException) rethrow;
      throw GitHubException('Schema validation failed: \$e');
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

      return CachedContributionData(
        username: username.trim(),
        totalContributions: computedTotal,
        days: allDays,
        lastUpdated: AppDateUtils.nowUtc,
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
  static Future<bool> validateToken(String username, String token) async {
    if (!isValidTokenFormat(token)) return false;

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: {
          'Authorization': 'Bearer ${token.trim()}',
          'User-Agent': AppStrings.appName,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': 'query { viewer { login } }',
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 && !response.body.contains('"errors"');
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _client.close();
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
    final dynamicClockBuffer = (metrics.height * 0.15).clamp(120.0, 300.0);
    
    final clockAreaBuffer = metrics.safeInsets.top + dynamicClockBuffer;
    final horizontalBuffer = metrics.safeInsets.left + AppConstants.horizontalBuffer;

    return DevicePlacementInsets(
      top: clockAreaBuffer,
      bottom: clockAreaBuffer,
      left: horizontalBuffer,
      right: horizontalBuffer,
    );
  }
}

/// Service for generating and setting wallpapers
class WallpaperService {
  static final _lock = Lock();
  static final _updateLock = Lock();

  /// Generate wallpaper image and set it
  static Future<String> generateAndSetWallpaper({
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
           if (await file.exists()) {
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
                } catch(e) {
                  // Fallback to regenerate if setting fails
                }
             }
             return lastPath;
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
        return filePath;
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
      pixelRatio: 1.0,
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
  static Future<bool> refreshWallpaper({bool isBackground = false}) async {
    return await _updateLock.synchronized(() async {
      try {
        if (isBackground) {
          WidgetsFlutterBinding.ensureInitialized();
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
          await StorageService.init();
        }

        if (!StorageService.getAutoUpdate() && isBackground) return false;

        final lastUpdate = StorageService.getLastUpdate();
        if (lastUpdate != null && isBackground) {
          final diff = DateTime.now().difference(lastUpdate);
          if (diff.inMinutes < AppConstants.refreshCooldownMinutes) return false;
        }

        if (!await _hasConnectivity()) return false;

        final username = StorageService.getUsername();
        final token = await StorageService.getToken();

        if (username == null || token == null) return false;

        CachedContributionData data;
        try {
          data = await GitHubService.fetchContributions(
            username: username,
            token: token,
          );
          await StorageService.setCachedData(data);
          await StorageService.setLastUpdate(AppDateUtils.nowUtc);
        } catch (e) {
          final cached = StorageService.getCachedData();
          if (cached == null) return false;
          data = cached;
        }

        final config = StorageService.getWallpaperConfig();
        await generateAndSetWallpaper(
          data: data,
          config: config,
        );

        return true;
      } catch (e) {
        debugPrint('Wallpaper refresh failed: $e');
        return false;
      }
    });
  }

  /// Check internet connectivity reliably
  static Future<bool> _hasConnectivity() async {
    try {
      final results = await Future.wait(
        AppConstants.connectivityHosts.map(
          (host) => InternetAddress.lookup(host).timeout(const Duration(seconds: 3))
        )
      );
      return results.any((r) => r.isNotEmpty && r[0].rawAddress.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  static String _computeHash(
      CachedContributionData data, WallpaperConfig config, WallpaperTarget target) {
    return '${data.hashCode}_${config.hashCode}_${target.index}';
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
      await WallpaperService.refreshWallpaper(isBackground: true);
    }
  } catch (e, stack) {
    debugPrint('Background handler failed: $e');
    // Audit Fix: Log FCM background errors
    try {
       // Best effort logging - Firebase might not be ready
       if (Firebase.apps.isNotEmpty) {
         await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FCM Background Handler Failed');
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
      await FirebaseMessaging.instance.subscribeToTopic(AppConstants.fcmTopicDailyUpdates);

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
      final mq = MediaQueryData.fromView(view);
      
      await StorageService.saveDeviceMetrics(
        width: mq.size.width,
        height: mq.size.height,
        pixelRatio: mq.devicePixelRatio,
        safeInsets: mq.viewPadding,
      );
    } catch (e) {
      debugPrint('AppConfig init error: $e');
      // Audit Fix: Specific exception for context initialization
      throw ContextInitException('Failed to initialize AppConfig from context: $e');
    }
  }

  /// Dispose all services
  static void dispose() {
    GitHubService.dispose();
    RenderUtils.clearCaches();
  }
}
