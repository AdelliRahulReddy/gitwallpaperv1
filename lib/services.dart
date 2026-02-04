// ══════════════════════════════════════════════════════════════════════════
// 🔧 SERVICES - Production Ready
// ══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:synchronized/synchronized.dart';

import 'models.dart';
import 'app_constants.dart';
import 'graph_layout.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'utils.dart';

import 'exceptions.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Service for fetching GitHub contribution data
class GitHubService {
  static http.Client _client = http.Client();
  static const String _graphqlEndpoint = 'https://api.github.com/graphql';

  static void setHttpClient(http.Client client) {
    _client = client;
  }

  static Future<CachedContributionData> fetchContributions({
    required String username,
    required String token,
  }) async {
    try {
      final response = await _makeRequest(username, token);
      if (response.statusCode != 200) {
        throw GitHubException.fromResponse(response.statusCode, response.body);
      }

      late final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
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

  /// Make GraphQL API request
  static Future<http.Response> _makeRequest(
    String username,
    String token,
  ) async {
    final now = AppDateUtils.nowUtc;
    final to = now.toIso8601String();
    final from = now
        .subtract(Duration(days: AppConstants.githubDataFetchDays))
        .toIso8601String();

    return await _client
        .post(
          Uri.parse(_graphqlEndpoint),
          headers: {
            'Authorization': 'Bearer ${token.trim()}',
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
    // Check HTTP status code with custom exceptions
    if (response.statusCode != 200) {
      throw GitHubException.fromResponse(response.statusCode, response.body);
    }

    // Check for GraphQL errors
    if (data['errors'] != null) {
      final errors = data['errors'] as List;
      final errorMsg = errors.first['message'] ?? 'Unknown GraphQL error';
      throw GitHubException(errorMsg);
    }

    // Validate response structure
    if (data['data'] == null) {
      throw GitHubException('Invalid API response: missing data');
    }

    if (data['data']?['user'] == null) {
      throw UserNotFoundException();
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
      final weeksJson = calendar['weeks'] as List<dynamic>;
      final apiTotalContributions = calendar['totalContributions'] as int;

      // Parse all contribution days
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

      return CachedContributionData(
        username: username.trim(),
        totalContributions: computedTotal == apiTotalContributions
            ? apiTotalContributions
            : computedTotal,
        days: allDays,
        lastUpdated: AppDateUtils.nowUtc,
      );
    } catch (e) {
      throw GitHubException('Failed to parse API response: $e');
    }
  }

  /// Validate token format (basic format check)
  static bool isValidTokenFormat(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return false;

    // Classic personal access token (ghp_)
    if (RegExp(r'^ghp_[a-zA-Z0-9]{36}$').hasMatch(trimmed)) {
      return true;
    }

    // Fine-grained personal access token (github_pat_)
    if (RegExp(r'^github_pat_[a-zA-Z0-9_]{50,}$').hasMatch(trimmed)) {
      return true;
    }

    // OAuth token (40 hex characters)
    if (RegExp(r'^[a-f0-9]{40}$').hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  /// Validate token by making actual API call
  static Future<bool> validateToken(String username, String token) async {
    try {
      await fetchContributions(username: username, token: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
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

    final placement = _computePlacementInsets(target: target, metrics: m);
    final nextPaddingTop =
        base.paddingTop > placement.top ? base.paddingTop : placement.top;
    final nextPaddingBottom = base.paddingBottom > placement.bottom
        ? base.paddingBottom
        : placement.bottom;
    final nextPaddingLeft =
        base.paddingLeft > placement.left ? base.paddingLeft : placement.left;
    final nextPaddingRight = base.paddingRight > placement.right
        ? base.paddingRight
        : placement.right;

    return base.copyWith(
      paddingTop: nextPaddingTop,
      paddingBottom: nextPaddingBottom,
      paddingLeft: nextPaddingLeft,
      paddingRight: nextPaddingRight,
    );
  }

  static DevicePlacementInsets _computePlacementInsets({
    required WallpaperTarget target,
    required DeviceMetrics metrics,
  }) {
    // 100% Unified: Every target (Home, Lock, Both) uses the same balanced placement
    // to ensure 100% consistency across the entire device experience.
    final clockAreaBuffer = metrics.safeInsets.top + 120.0;
    final horizontalBuffer = metrics.safeInsets.left + 32.0;

    return DevicePlacementInsets(
      top: clockAreaBuffer,
      bottom: clockAreaBuffer, // Balanced for perfect vertical centering
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
    
    // 100% Unified: Removed "desiredWallpaperSize" logic.
    // We now force exact screen dimensions for ALL targets (Home, Lock, Both).
    // This prevents the "too big" / "zoomed in" issue on Home screen.

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

    // 100% Unified: Standardize on MonthHeatmapRenderer for all targets
    // as requested by user ("ALL SHOULD SHOULD LOOK SAME LIKE LOCK SCREEN")
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
      final oldFiles = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('github_wallpaper'));
      for (var file in oldFiles) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore individual file deletion errors
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

  /// Perform background wallpaper update
  static Future<bool> performBackgroundUpdate({bool isIsolate = false}) async {
    return await _updateLock.synchronized(() async {
      try {
        if (isIsolate) {
          WidgetsFlutterBinding.ensureInitialized();
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
          await StorageService.init();
        }

        // Respect Auto Update setting (skip if disabled)
        if (!StorageService.getAutoUpdate()) return false;

        final lastUpdate = StorageService.getLastUpdate();
        if (lastUpdate != null) {
          final diff = DateTime.now().difference(lastUpdate);
          if (diff.inMinutes < 15) return false;
        }

        // Check connectivity first
        if (!await _hasConnectivity()) return false;

        // Get credentials
        final username = StorageService.getUsername();
        final token = await StorageService.getToken();

        if (username == null || token == null) {
          return false;
        }

        // Fetch fresh data
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

        // Generate and set wallpaper
        final config = StorageService.getWallpaperConfig();
        await generateAndSetWallpaper(
          data: data,
          config: config,
        );

        return true;
      } catch (e) {
        return false;
      }
    });
  }

  /// Check internet connectivity
  static Future<bool> _hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup('api.github.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

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
    await _secureStorage.write(
      key: AppConstants.keyToken,
      value: trimmed,
    );
  }

  /// Retrieve GitHub token
  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.keyToken);
      return token?.trim();
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
    // Basic validation
    if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$')
        .hasMatch(trimmed)) {
      throw ArgumentError('Invalid GitHub username format');
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

  /// Save screen dimensions
  static Future<void> saveDimensions(
    double width,
    double height,
    double pixelRatio,
  ) async {
    await saveDeviceMetrics(
      width: width,
      height: height,
      pixelRatio: pixelRatio,
      safeInsets: EdgeInsets.zero,
    );
  }

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

  static Future<void> saveDesiredWallpaperSize({
    required double width,
    required double height,
  }) async {
    if (width <= 0 || height <= 0) return;
    await _p.setDouble(AppConstants.keyDesiredWallpaperWidth, width);
    await _p.setDouble(AppConstants.keyDesiredWallpaperHeight, height);
  }

  static Map<String, double>? getDesiredWallpaperSize() {
    final w = _p.getDouble(AppConstants.keyDesiredWallpaperWidth);
    final h = _p.getDouble(AppConstants.keyDesiredWallpaperHeight);
    if (w == null || h == null) return null;
    if (w <= 0 || h <= 0) return null;
    return {'width': w, 'height': h};
  }

  /// Get screen dimensions (stored values are logical pixels from MediaQuery).
  static Map<String, double>? getDimensions() {
    final w = _p.getDouble(AppConstants.keyDimensionWidth);
    final h = _p.getDouble(AppConstants.keyDimensionHeight);
    final pr = _p.getDouble(AppConstants.keyDimensionPixelRatio);

    if (w != null && h != null && pr != null) {
      // saveDeviceMetrics stores MediaQuery size = logical pixels; do not convert again.
      return {'width': w, 'height': h, 'pixelRatio': pr};
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════
  // METADATA
  // ══════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════════════

  /// Logout and clear all data
  static Future<void> logout() async {
    await deleteToken();
    await _p.clear();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎨 HEATMAP RENDERER
// ══════════════════════════════════════════════════════════════════════════

/// Renders GitHub contribution heatmap on canvas
class HeatmapRenderer {
  // Cache for reusable objects (TextPainter removed - created/disposed per use)
  static final Map<String, ui.Radius> _radiusCache = {};

  /// Render heatmap to canvas
  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    double pixelRatio = 1.0,
  }) {
    // Draw background
    final bgPaint = Paint()
      ..color = config.isDarkMode ? AppTheme.githubDarkCard : AppTheme.bgWhite;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final availableWidth =
        size.width - config.paddingLeft - config.paddingRight;
    final availableHeight =
        size.height - config.paddingTop - config.paddingBottom;

    final baseScale = config.autoFitWidth
        ? GraphLayoutCalculator.fitScale(
            availableWidth: availableWidth,
            columns: AppConstants.heatmapWeeks,
            fillFraction: 0.95,
          )
        : config.scale;

    final effectiveScale = baseScale * pixelRatio;
    final boxSize = AppConstants.heatmapBoxSize * effectiveScale;
    final spacing = AppConstants.heatmapBoxSpacing * effectiveScale;
    final cellSize = boxSize + spacing;

    final gridWidth = (AppConstants.heatmapWeeks * cellSize) - spacing;
    final gridHeight = (AppConstants.heatmapDaysPerWeek * cellSize) - spacing;

    // Apply padding and positioning
    final xStart = config.paddingLeft +
        ((availableWidth - gridWidth) * config.horizontalPosition);

    // Calculate date range
    final endToday = AppDateUtils.nowLocal;
    final totalDaysGraph = AppConstants.heatmapTotalDays;
    final startDate = endToday.subtract(Duration(days: totalDaysGraph - 1));

    // Align to start of week (Sunday = 0)
    final daysToSubtract = startDate.weekday % 7;
    final graphStartDate = startDate.subtract(Duration(days: daysToSubtract));

    final headerColor =
        (config.isDarkMode ? AppTheme.bgLight : AppTheme.textPrimary)
            .withValues(alpha: 0.8);
    final headerTextStyle = TextStyle(
      color: headerColor,
      fontSize: 16 * effectiveScale,
      fontWeight: FontWeight.bold,
    );
    final headerText = _headerTextForDate(endToday);
    final headerPainter = TextPainter(
      text: TextSpan(text: headerText, style: headerTextStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: gridWidth);

    final headerGap = (spacing * 3).clamp(spacing, boxSize);

    double quoteHeight = 0.0;
    double quoteGap = 0.0;
    if (config.customQuote.isNotEmpty) {
      final quoteColor = config.isDarkMode
          ? AppTheme.textWhite.withValues(alpha: config.quoteOpacity)
          : AppTheme.textPrimary.withValues(alpha: config.quoteOpacity);
      final quotePainter = TextPainter(
        text: TextSpan(
          text: config.customQuote,
          style: TextStyle(
            color: quoteColor,
            fontSize: config.quoteFontSize * effectiveScale,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
      )..layout(maxWidth: gridWidth);
      quoteHeight = quotePainter.height;
      quotePainter.dispose();
      quoteGap = (spacing * 4).clamp(spacing, boxSize * 1.5);
    }

    final totalBlockHeight =
        headerPainter.height + headerGap + gridHeight + quoteGap + quoteHeight;
    final yStartBlock = config.paddingTop +
        ((availableHeight - totalBlockHeight) * config.verticalPosition);
    final yHeader = yStartBlock;
    final yStart = yHeader + headerPainter.height + headerGap;

    headerPainter.paint(canvas, Offset(xStart, yHeader));
    headerPainter.dispose();

    // Get theme colors
    final heatmapLevels = config.isDarkMode
        ? AppThemeExtension.dark().heatmapLevels
        : AppThemeExtension.light().heatmapLevels;

    // Prepare paints
    final boxPaint = Paint()..style = PaintingStyle.fill;
    final themeExt = config.isDarkMode ? AppThemeExtension.dark() : AppThemeExtension.light();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * effectiveScale
      ..color = themeExt.heatmapTodayHighlight;

    // Get cached radius
    final radiusKey = '${config.cornerRadius}_$effectiveScale';
    final radius = _radiusCache.putIfAbsent(
      radiusKey,
      () => Radius.circular(config.cornerRadius * effectiveScale),
    );

    // Render cells
    final todayDateOnly = AppDateUtils.toDateOnly(endToday);

    for (int col = 0; col < AppConstants.heatmapWeeks; col++) {
      for (int row = 0; row < AppConstants.heatmapDaysPerWeek; row++) {
        final cellIndex = (col * 7) + row;
        final cellDate = graphStartDate.add(Duration(days: cellIndex));

        // Don't draw future dates
        if (cellDate.isAfter(endToday)) continue;

        // Get contribution count and level
        final count = data.getContributionsForDate(cellDate);
        final level = _getLevel(count);

        // Get color with bounds checking
        final cellColor = AppConstants.isValidContributionLevel(level)
            ? heatmapLevels[level]
            : heatmapLevels[0];

        boxPaint.color = cellColor.withValues(alpha: config.opacity);

        // Calculate position
        final x = xStart + (col * cellSize);
        final y = yStart + (row * cellSize);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, boxSize, boxSize),
          radius,
        );

        // Draw cell
        canvas.drawRRect(rect, boxPaint);

        // Highlight today
        final cellDateOnly = AppDateUtils.toDateOnly(cellDate);
        if (AppDateUtils.isSameDay(cellDateOnly, todayDateOnly)) {
          canvas.drawRRect(rect, borderPaint);
        }
      }
    }

    // Draw custom quote if present
    if (config.customQuote.isNotEmpty) {
      _drawQuote(
        canvas,
        config,
        xStart,
        yStart + gridHeight + quoteGap,
        gridWidth,
        effectiveScale,
      );
    }
  }

  static String _headerTextForDate(DateTime date) {
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    final monthName = months[date.month - 1];
    return "$monthName ${date.year}";
  }

  /// Draw custom quote
  static void _drawQuote(
    Canvas canvas,
    WallpaperConfig config,
    double x,
    double y,
    double width,
    double scale,
  ) {
    final color = config.isDarkMode
        ? AppTheme.textWhite.withValues(alpha: config.quoteOpacity)
        : AppTheme.textPrimary.withValues(alpha: config.quoteOpacity);

    final painter = TextPainter(
      text: TextSpan(
        text: config.customQuote,
        style: TextStyle(
          color: color,
          fontSize: config.quoteFontSize * scale,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 3,
    )..layout(maxWidth: width);

    painter.paint(canvas, Offset(x + (width - painter.width) / 2, y));
    painter.dispose(); // ✅ Fixed memory leak
  }

  /// Get contribution level (0-4)
  static int _getLevel(int count) {
    if (count == 0) return 0;
    if (count <= 3) return 1;
    if (count <= 6) return 2;
    if (count <= 9) return 3;
    return 4;
  }

  /// Clear caches (call on app dispose)
  static void clearCaches() {
    _radiusCache.clear();
  }
}

class MonthHeatmapCell {
  final DateTime date;
  final int dayIndex;

  const MonthHeatmapCell({
    required this.date,
    required this.dayIndex,
  });
}

class MonthHeatmapRenderer {
  static final Map<String, ui.Radius> _radiusCache = {};

  static List<MonthHeatmapCell> computeMonthCells({DateTime? referenceDate}) {
    final ref = referenceDate ?? AppDateUtils.nowLocal;
    final days = AppDateUtils.daysInMonth(ref.year, ref.month);
    return List<MonthHeatmapCell>.generate(
      days,
      (i) => MonthHeatmapCell(
          date: DateTime(ref.year, ref.month, i + 1), dayIndex: i),
    );
  }

  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    double pixelRatio = 1.0,
    DateTime? referenceDate,
  }) {
    final bgPaint = Paint()
      ..color = config.isDarkMode ? AppTheme.githubDarkCard : AppTheme.bgWhite;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final DateTime ref = referenceDate ?? AppDateUtils.nowLocal;

    late final List<MonthHeatmapCell> cells;
    try {
      cells = computeMonthCells(referenceDate: ref);
    } catch (e) {
      _drawError(canvas, size, config, pixelRatio);
      return;
    }

    final availableWidth =
        size.width - config.paddingLeft - config.paddingRight;
    final availableHeight =
        size.height - config.paddingTop - config.paddingBottom;

    final baseScale = config.autoFitWidth
        ? GraphLayoutCalculator.fitScale(
            availableWidth: availableWidth,
            columns: AppConstants.monthGridColumns,
            fillFraction: 0.95,
          )
        : config.scale;

    final effectiveScale = baseScale * pixelRatio;
    final boxSize = AppConstants.heatmapBoxSize * effectiveScale;
    final spacing = AppConstants.heatmapBoxSpacing * effectiveScale;
    final cellSize = boxSize + spacing;
    final columns = AppConstants.monthGridColumns;

    // 📅 Calculate Calendar Layout (No Hardcoding)
    final firstOfMonth = DateTime(ref.year, ref.month, 1);
    final weekdayOffset = firstOfMonth.weekday % 7; // 0=Sun, 1=Mon...6=Sat
    final totalCells = cells.length + weekdayOffset;
    final dynamicRows = (totalCells / columns).ceil();

    final gridWidth = (columns * cellSize) - spacing;
    final gridHeight = (dynamicRows * cellSize) - spacing;

    final xStart = config.paddingLeft +
        ((availableWidth - gridWidth) * config.horizontalPosition);

    final headerColor =
        (config.isDarkMode ? AppTheme.bgLight : AppTheme.textPrimary)
            .withValues(alpha: 0.8);
    final headerTextStyle = TextStyle(
      color: headerColor,
      fontSize: 16 * effectiveScale,
      fontWeight: FontWeight.bold,
    );
    final headerText = HeatmapRenderer._headerTextForDate(ref);
    final headerPainter = TextPainter(
      text: TextSpan(text: headerText, style: headerTextStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: gridWidth);

    // 📅 Weekday Labels
    final dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final dayLabelStyle = TextStyle(
      color: headerColor.withValues(alpha: 0.6),
      fontSize: 7 * effectiveScale, // Reduced to ensure 3 letters fit
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2, // Tighter spacing
    );
    
    final dayLabelPainters = dayLabels.map((d) => TextPainter(
      text: TextSpan(text: d, style: dayLabelStyle),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout()).toList(); // Removed maxWidth to allow full 3 letters (centering handles alignment)

    final headerGap = (spacing * 3).clamp(spacing, boxSize);
    final labelsRowHeight = 12 * effectiveScale;
    final labelsGap = spacing * 2;

    double quoteHeight = 0.0;
    double quoteGap = 0.0;
    if (config.customQuote.isNotEmpty) {
      final quoteColor = config.isDarkMode
          ? AppTheme.textWhite.withValues(alpha: config.quoteOpacity)
          : AppTheme.textPrimary.withValues(alpha: config.quoteOpacity);
      final quotePainter = TextPainter(
        text: TextSpan(
          text: config.customQuote,
          style: TextStyle(
            color: quoteColor,
            fontSize: config.quoteFontSize * effectiveScale,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
      )..layout(maxWidth: gridWidth);
      quoteHeight = quotePainter.height;
      quotePainter.dispose();
      quoteGap = (spacing * 4).clamp(spacing, boxSize * 1.5);
    }

    final totalBlockHeight = headerPainter.height +
        headerGap +
        labelsRowHeight +
        labelsGap +
        gridHeight +
        quoteGap +
        quoteHeight;

    final yStartBlock = config.paddingTop +
        ((availableHeight - totalBlockHeight) * config.verticalPosition);
    final yHeader = yStartBlock;
    
    // Paint Header
    headerPainter.paint(canvas, Offset(xStart, yHeader));

    // Paint Weekday Labels
    final yLabels = yHeader + headerPainter.height + headerGap;
    // Safe to dispose headerPainter now that we have read its height
    headerPainter.dispose();

    for (int i = 0; i < dayLabelPainters.length; i++) {
      final p = dayLabelPainters[i];
      final xLabel = xStart + (i * cellSize) + (boxSize - p.width) / 2;
      p.paint(canvas, Offset(xLabel, yLabels));
      p.dispose();
    }

    final yStart = yLabels + labelsRowHeight + labelsGap;

    final heatmapLevels = config.isDarkMode
        ? AppThemeExtension.dark().heatmapLevels
        : AppThemeExtension.light().heatmapLevels;

    final boxPaint = Paint()..style = PaintingStyle.fill;
    final themeExt = config.isDarkMode ? AppThemeExtension.dark() : AppThemeExtension.light();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (spacing / 1.5).clamp(1.0, boxSize * 0.2)
      ..color = themeExt.heatmapTodayHighlight;

    final radiusKey = '${config.cornerRadius}_$effectiveScale';
    final radius = _radiusCache.putIfAbsent(
      radiusKey,
      () => Radius.circular(config.cornerRadius * effectiveScale),
    );

    final today = AppDateUtils.toDateOnly(AppDateUtils.nowLocal);
    final canPaintText = boxSize >= 12.0;

    for (final cell in cells) {
      final i = cell.dayIndex + weekdayOffset; // Apply calendar offset
      final col = i % columns;
      final row = i ~/ columns;

      final count = data.getContributionsForDate(cell.date);
      final level = HeatmapRenderer._getLevel(count);
      final cellColor = AppConstants.isValidContributionLevel(level)
          ? heatmapLevels[level]
          : heatmapLevels[0];

      boxPaint.color = cellColor.withValues(alpha: config.opacity);

      final x = xStart + (col * cellSize);
      final y = yStart + (row * cellSize);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxSize, boxSize),
        radius,
      );
      canvas.drawRRect(rect, boxPaint);

      if (AppDateUtils.isSameDay(AppDateUtils.toDateOnly(cell.date), today)) {
        canvas.drawRRect(rect, borderPaint);
      }

      if (canPaintText && count > 0) {
        final textColor = config.isDarkMode
            ? AppTheme.textWhite.withValues(alpha: 0.9)
            : AppTheme.textPrimary.withValues(alpha: 0.85);

        final painter = TextPainter(
          text: TextSpan(
            text: '$count',
            style: TextStyle(
              color: textColor,
              fontSize: boxSize * 0.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 1,
          textAlign: TextAlign.center,
        )..layout(maxWidth: boxSize);

        painter.paint(
          canvas,
          Offset(x + (boxSize - painter.width) / 2,
              y + (boxSize - painter.height) / 2),
        );
        painter.dispose();
      }
    }

    if (config.customQuote.isNotEmpty) {
      HeatmapRenderer._drawQuote(
        canvas,
        config,
        xStart,
        yStart + gridHeight + quoteGap,
        gridWidth,
        effectiveScale,
      );
    }
  }

  static void _drawError(
      Canvas canvas, Size size, WallpaperConfig config, double pixelRatio) {
    final effectiveScale = config.scale * pixelRatio;
    final color = config.isDarkMode ? AppTheme.bgLight : AppTheme.textPrimary;
    final painter = TextPainter(
      text: TextSpan(
        text: 'Invalid date',
        style: TextStyle(
          color: color.withValues(alpha: 0.8),
          fontSize: 16 * effectiveScale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
          (size.width - painter.width) / 2, (size.height - painter.height) / 2),
    );
    painter.dispose();
  }

  static void clearCaches() {
    _radiusCache.clear();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📨 FCM SERVICE
// ══════════════════════════════════════════════════════════════════════════

/// Firebase background message handler
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('FCM Background message received: ${message.messageId}');
    final type = message.data['type'] as String?;
    if (type == 'refresh' || type == 'daily_refresh') {
      await WallpaperService.performBackgroundUpdate(isIsolate: true);
    }
  } catch (e) {
    debugPrint('Background handler failed: $e');
    // Background handler cannot propagate errors
  }
}

/// Service for Firebase Cloud Messaging
class FcmService {
  /// Initialize FCM
  static Future<void> init() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Subscribe to topic
      await FirebaseMessaging.instance
          .subscribeToTopic(AppConstants.fcmTopicDailyUpdates);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) async {
        final type = message.data['type'] as String?;
        if ((type == 'refresh' || type == 'daily_refresh') &&
            StorageService.getAutoUpdate()) {
          await WallpaperService.performBackgroundUpdate();
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

// ══════════════════════════════════════════════════════════════════════════
// 🧩 PLATFORM WALLPAPER
// ══════════════════════════════════════════════════════════════════════════

@immutable
class DesiredWallpaperSize {
  final double width;
  final double height;

  const DesiredWallpaperSize({required this.width, required this.height});
}

class PlatformWallpaper {
  static const MethodChannel _channel =
      MethodChannel('github_wallpaper/wallpaper');

  static Future<DesiredWallpaperSize?> getDesiredMinimumSize() async {
    final result =
        await _channel.invokeMethod<dynamic>('getDesiredMinimumSize');
    if (result is! Map) return null;
    final w = result['width'];
    final h = result['height'];
    final width = (w is num) ? w.toDouble() : null;
    final height = (h is num) ? h.toDouble() : null;
    if (width == null || height == null) return null;
    if (width <= 0 || height <= 0) return null;
    return DesiredWallpaperSize(width: width, height: height);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ⚙️ APP CONFIG
// ══════════════════════════════════════════════════════════════════════════

/// Application configuration helper
class AppConfig {
  /// Initialize app configuration from context
  static Future<void> initializeFromContext(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final safeInsets = MediaQuery.of(context).viewPadding;

    await StorageService.saveDeviceMetrics(
      width: size.width,
      height: size.height,
      pixelRatio: ratio,
      safeInsets: safeInsets,
    );

    if (Platform.isAndroid) {
      try {
        final desired = await PlatformWallpaper.getDesiredMinimumSize();
        if (desired != null) {
          await StorageService.saveDesiredWallpaperSize(
            width: desired.width,
            height: desired.height,
          );
        }
      } catch (_) {}
    }
  }

  /// Dispose all services
  static void dispose() {
    GitHubService.dispose();
    HeatmapRenderer.clearCaches();
    MonthHeatmapRenderer.clearCaches();
  }
}
