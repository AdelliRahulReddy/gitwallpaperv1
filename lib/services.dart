// ══════════════════════════════════════════════════════════════════════════
// 🔧 SERVICES - All app services consolidated
// ══════════════════════════════════════════════════════════════════════════
// This file contains: GitHub API, Wallpaper Generation, Storage, Utils
// Simplified for easy understanding and debugging
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart' as intl;

import 'models.dart';
import 'firebase_options.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🌐 GITHUB SERVICE - Fetches contribution data from GitHub API
// ══════════════════════════════════════════════════════════════════════════

class GitHubService {
  static final http.Client _client = http.Client();

  /// Fetch GitHub contributions for the current year
  static Future<CachedContributionData> fetchContributions({
    required String username,
    required String token,
  }) async {
    try {
      final response = await _makeRequest(username, token);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      _validateResponse(response, data, username);

      return _parseResponse(data, username);
    } catch (e) {
      debugPrint('❌ GitHub API Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> _makeRequest(
      String username, String token) async {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, 1, 1).toIso8601String();
    final to = now.toIso8601String();

    return await _client
        .post(
          Uri.parse('https://api.github.com/graphql'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': '''
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
        ''',
            'variables': {'login': username, 'from': from, 'to': to},
          }),
        )
        .timeout(const Duration(seconds: 30));
  }

  static void _validateResponse(
    http.Response response,
    Map<String, dynamic> data,
    String username,
  ) {
    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode}');
    }

    if (data['errors'] != null) {
      final errors = data['errors'] as List;
      throw Exception('GraphQL error: ${errors.first['message']}');
    }

    if (data['data']?['user']?['contributionsCollection'] == null) {
      throw Exception('No contributions data found for $username');
    }
  }

  static CachedContributionData _parseResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    final collection = json['data']['user']['contributionsCollection'];
    final calendar = collection['contributionCalendar'] as Map<String, dynamic>;
    final weeksJson = calendar['weeks'] as List;
    final totalContributions = calendar['totalContributions'] as int;

    // Flatten all days
    final allDays = <ContributionDay>[];
    for (var week in weeksJson) {
      final daysJson = week['contributionDays'] as List;
      for (var day in daysJson) {
        allDays.add(ContributionDay(
          date: DateTime.parse("${day['date']}T00:00:00Z"),
          contributionCount: day['contributionCount'] as int,
          contributionLevel: day['contributionLevel'] as String?,
        ));
      }
    }

    // Calculate stats
    allDays.sort((a, b) => a.date.compareTo(b.date));
    int currentStreak = 0, longestStreak = 0, todayCommits = 0;
    int tempStreak = 0;
    DateTime? lastActiveDate;
    final today = DateTime.now();

    for (var day in allDays) {
      if (day.date.day == today.day && day.date.month == today.month) {
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
      final daysSince = today.difference(lastActiveDate).inDays;
      currentStreak = daysSince <= 1 ? tempStreak : 0;
    }

    // Filter for current month
    final currentMonthDays = allDays
        .where((d) => d.date.month == today.month && d.date.year == today.year)
        .toList();

    final dailyContributions = <int, int>{};
    for (var day in currentMonthDays) {
      dailyContributions[day.date.day] = day.contributionCount;
    }

    return CachedContributionData(
      username: username,
      totalContributions: totalContributions,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      todayCommits: todayCommits,
      days: currentMonthDays,
      dailyContributions: dailyContributions,
      lastUpdated: DateTime.now(),
    );
  }

  /// Validate GitHub token format
  static bool isValidTokenFormat(String token) {
    final trimmed = token.trim();
    if (trimmed.startsWith('ghp_')) {
      return RegExp(r'^ghp_[a-zA-Z0-9]{36}$').hasMatch(trimmed);
    } else if (trimmed.startsWith('github_pat_')) {
      return RegExp(r'^github_pat_[a-zA-Z0-9_]{50,}$').hasMatch(trimmed);
    }
    return false;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🖼️ WALLPAPER SERVICE - Generates and sets wallpapers
// ══════════════════════════════════════════════════════════════════════════

class WallpaperService {
  static bool _isGenerating = false;

  /// Generate wallpaper image and set it as device wallpaper
  static Future<String> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    String target = 'both',
  }) async {
    if (_isGenerating)
      throw Exception('Wallpaper generation already in progress');

    _isGenerating = true;
    try {
      debugPrint('🖼️ Generating wallpaper...');

      // Step 1: Generate image
      final imageBytes = await _generateWallpaperImage(data, config);

      // Step 2: Save to file
      final filePath = await _saveToFile(imageBytes);
      debugPrint('💾 Saved to: $filePath');

      // Step 3: Set as wallpaper (Android only)
      if (Platform.isAndroid) {
        if (target == 'both') {
          await _setWallpaper(filePath, 'home');
          await _setWallpaper(filePath, 'lock');
        } else {
          await _setWallpaper(filePath, target);
        }
        debugPrint('✅ Wallpaper set successfully');
      }

      return filePath;
    } finally {
      _isGenerating = false;
    }
  }

  static Future<Uint8List> _generateWallpaperImage(
    CachedContributionData data,
    WallpaperConfig config,
  ) async {
    double width, height, pixelRatio;

    if (AppConfig.isInitialized) {
      width = AppConfig.wallpaperWidth;
      height = AppConfig.wallpaperHeight;
      pixelRatio = AppConfig.pixelRatio;
    } else {
      // Background Mode: Try to load from storage
      final dims = StorageService.getDimensions();
      if (dims != null) {
        width = dims['width']!;
        height = dims['height']!;
        pixelRatio = dims['pixelRatio']!;
        debugPrint(
            '📱 Loaded dimensions from storage: ${width.toInt()}x${height.toInt()}');
      } else {
        // Fallback: Default to standard 1080p
        width = 1080.0;
        height = 1920.0;
        pixelRatio = 1.0;
        debugPrint('⚠️ No dimensions found, using fallback 1080p');
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Render heatmap
    HeatmapRenderer.render(
      canvas: canvas,
      size: Size(width, height),
      data: data,
      config: config,
      pixelRatio: pixelRatio,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (byteData == null) throw Exception('Failed to export image');
    return byteData.buffer.asUint8List();
  }

  static Future<String> _saveToFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/github_wallpaper_$timestamp.png';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }

  static Future<void> _setWallpaper(String filePath, String target) async {
    int location;
    switch (target) {
      case 'home':
        location = WallpaperManagerPlus.homeScreen;
        break;
      case 'lock':
        location = WallpaperManagerPlus.lockScreen;
        break;
      default:
        location = WallpaperManagerPlus.bothScreens;
    }

    final file = File(filePath);
    if (!await file.exists()) throw Exception('Wallpaper file not found');

    await WallpaperManagerPlus().setWallpaper(file, location);
  }

  /// 🔄 Perform the full update process (Fetch -> Generate -> Set)
  /// Used by Background Service and Manual Debug
  static Future<bool> performBackgroundUpdate({bool isIsolate = false}) async {
    try {
      debugPrint("🔄 Starting background update (Isolate: $isIsolate)...");

      if (isIsolate) {
        WidgetsFlutterBinding.ensureInitialized();

        // ✅ FIX: Check if Firebase is already initialized
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            debugPrint("✅ Firebase initialized in isolate");
          } else {
            debugPrint("✅ Firebase already initialized");
          }
        } catch (e) {
          debugPrint('⚠️ Firebase init warning: $e');
        }

        await StorageService.init();
      }

      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        debugPrint("⚠️ No credentials found, skipping update.");
        return false;
      }

      // Fetch
      final data = await GitHubService.fetchContributions(
          username: username, token: token);
      await StorageService.setCachedData(data);

      // Config
      final config = StorageService.getWallpaperConfig();

      await generateAndSetWallpaper(data: data, config: config);
      debugPrint("✅ Background update successful!");
      return true;
    } catch (e) {
      debugPrint("❌ Background update failed: $e");
      return false;
    }
  }
} // ← THIS CLOSING BRACE CLOSES WallpaperService CLASS!

// ══════════════════════════════════════════════════════════════════════════
// 💾 STORAGE SERVICE - Local data persistence
// ══════════════════════════════════════════════════════════════════════════

class StorageService {
  static SharedPreferences? _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Initialize storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Storage initialized');
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw Exception('Storage not initialized');
    return _prefs!;
  }

  // === Token (Secure) ===
  static Future<void> setToken(String token) async {
    await _secureStorage.write(key: 'github_token', value: token.trim());
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'github_token');
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'github_token');
  }

  // === Username ===
  static Future<void> setUsername(String username) async {
    await _p.setString('username', username.trim());
  }

  static String? getUsername() => _p.getString('username');

  // === Cached Data ===
  static Future<void> setCachedData(CachedContributionData data) async {
    await _p.setString('cached_data', jsonEncode(data.toJson()));
  }

  static CachedContributionData? getCachedData() {
    final json = _p.getString('cached_data');
    if (json == null) return null;
    return CachedContributionData.fromJson(jsonDecode(json));
  }

  // === Wallpaper Config ===
  static Future<void> saveWallpaperConfig(WallpaperConfig config) async {
    await _p.setString('wallpaper_config', jsonEncode(config.toJson()));
  }

  static WallpaperConfig getWallpaperConfig() {
    final json = _p.getString('wallpaper_config');
    if (json == null) return WallpaperConfig.defaults();
    return WallpaperConfig.fromJson(jsonDecode(json));
  }

  // === Preferences ===
  static Future<void> setAutoUpdate(bool enabled) async {
    await _p.setBool('auto_update', enabled);
  }

  static bool getAutoUpdate() => _p.getBool('auto_update') ?? true;

  static Future<void> setOnboardingComplete(bool complete) async {
    await _p.setBool('onboarding_complete', complete);
  }

  static bool isOnboardingComplete() =>
      _p.getBool('onboarding_complete') ?? false;

  // === Last Update Time ===
  static Future<void> setLastUpdate(DateTime dateTime) async {
    await _p.setString('last_update', dateTime.toIso8601String());
  }

  static DateTime? getLastUpdate() {
    final str = _p.getString('last_update');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // === Clear Data ===
  static Future<void> clearCache() async {
    await _p.remove('cached_data');
    await _p.remove('last_update');
  }

  static Future<void> logout() async {
    await deleteToken();
    await _p.clear();
  }

  // === Screen Dimensions ===
  static Future<void> saveDimensions(
      double width, double height, double pixelRatio) async {
    await _p.setDouble('screen_width', width);
    await _p.setDouble('screen_height', height);
    await _p.setDouble('pixel_ratio', pixelRatio);
  }

  static Map<String, double>? getDimensions() {
    final w = _p.getDouble('screen_width');
    final h = _p.getDouble('screen_height');
    final pr = _p.getDouble('pixel_ratio');
    if (w != null && h != null && pr != null) {
      return {'width': w, 'height': h, 'pixelRatio': pr};
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎨 HEATMAP RENDERER - Draws the contribution heatmap
// ══════════════════════════════════════════════════════════════════════════

class HeatmapRenderer {
  /// Renders the GitHub contribution heatmap to canvas
  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    double pixelRatio = 1.0,
  }) {
    // Background
    final bgPaint = Paint()
      ..color = config.isDarkMode
          ? AppConfig.heatmapDarkBg
          : AppConfig.heatmapLightBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;

    final effectiveScale = config.scale * pixelRatio;
    final boxSize = AppConfig.boxSize * effectiveScale;
    final cellSize = boxSize + (AppConfig.boxSpacing * effectiveScale);

    final numWeeks = ((daysInMonth + firstWeekday - 1) / 7).ceil();
    final gridWidth = numWeeks * cellSize;
    final gridHeight = 7 * cellSize;

    final xOffset = (size.width - gridWidth) * config.horizontalPosition;
    final yOffset = (size.height - gridHeight) * config.verticalPosition;

    // Draw header
    _drawHeader(canvas, xOffset, yOffset - 30 * effectiveScale, effectiveScale,
        config.isDarkMode);

    // Draw contribution grid
    _drawGrid(canvas, data, xOffset, yOffset, boxSize, cellSize, firstWeekday,
        daysInMonth, config);

    // Draw quote if present
    if (config.customQuote.isNotEmpty) {
      _drawQuote(
          canvas,
          config,
          xOffset,
          yOffset + gridHeight + 20 * effectiveScale,
          gridWidth,
          effectiveScale);
    }
  }

  static void _drawHeader(
      Canvas canvas, double x, double y, double scale, bool isDarkMode) {
    final textColor = isDarkMode
        ? AppConfig.heatmapDarkBox.withValues(alpha: 0.8)
        : AppConfig.heatmapLightBox.withValues(alpha: 0.8);

    final monthName = intl.DateFormat('MMM yyyy').format(DateTime.now());
    final painter = TextPainter(
      text: TextSpan(
        text: monthName,
        style: TextStyle(
            color: textColor,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(x, y));
  }

  static void _drawGrid(
    Canvas canvas,
    CachedContributionData data,
    double xOffset,
    double yOffset,
    double boxSize,
    double cellSize,
    int firstWeekday,
    int daysInMonth,
    WallpaperConfig config,
  ) {
    final today = DateTime.now().day;
    final boxPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppConfig.todayHighlight;

    for (int day = 1; day <= daysInMonth; day++) {
      final dayIndex = day + firstWeekday - 2;
      final week = dayIndex ~/ 7;
      final weekday = dayIndex % 7;

      final x = xOffset + week * cellSize;
      final y = yOffset + weekday * cellSize;

      final contributions = data.getContributionsForDay(day);
      final color = _getContributionColor(contributions, config.isDarkMode);

      boxPaint.color = color.withValues(alpha: config.opacity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxSize, boxSize),
        Radius.circular(config.cornerRadius),
      );

      canvas.drawRRect(rect, boxPaint);

      if (day == today) {
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  static void _drawQuote(Canvas canvas, WallpaperConfig config, double x,
      double y, double width, double scale) {
    final textColor = config.isDarkMode
        ? Colors.white.withValues(alpha: config.quoteOpacity)
        : Colors.black.withValues(alpha: config.quoteOpacity);

    final painter = TextPainter(
      text: TextSpan(
        text: config.customQuote,
        style: TextStyle(
            color: textColor,
            fontSize: config.quoteFontSize * scale,
            fontStyle: FontStyle.italic),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);

    painter.paint(canvas, Offset(x + (width - painter.width) / 2, y));
  }

  static Color _getContributionColor(int count, bool isDarkMode) {
    if (isDarkMode) {
      if (count == 0) return AppConfig.heatmapDarkBox;
      if (count <= 3) return AppConfig.heatmapDarkLevel1;
      if (count <= 6) return AppConfig.heatmapDarkLevel2;
      if (count <= 9) return AppConfig.heatmapDarkLevel3;
      return AppConfig.heatmapDarkLevel4;
    } else {
      if (count == 0) return AppConfig.heatmapLightBox;
      if (count <= 3) return AppConfig.heatmapLightLevel1;
      if (count <= 6) return AppConfig.heatmapLightLevel2;
      if (count <= 9) return AppConfig.heatmapLightLevel3;
      return AppConfig.heatmapLightLevel4;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📨 FIREBASE MESSAGING - Background wallpaper updates
// ══════════════════════════════════════════════════════════════════════════

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background update triggered');

  // Call the shared update logic, signaling we are in a background isolate
  await WallpaperService.performBackgroundUpdate(isIsolate: true);
}

class FcmService {
  static Future<void> init() async {
    try {
      debugPrint('📨 FCM: Starting initialization...');

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      debugPrint('📨 FCM: Background handler set');

      // Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('📨 FCM: Permission status: ${settings.authorizationStatus}');

      // Get FCM token for debugging
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('📱 FCM Token: ${token?.substring(0, 20)}...');

      // Subscribe to topic
      await FirebaseMessaging.instance.subscribeToTopic('daily-updates');
      debugPrint('📨 FCM: Subscribed to daily-updates topic');

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📬 Foreground FCM received: ${message.data}');
        if (message.data['type'] == 'daily_refresh') {
          debugPrint('🔄 Triggering foreground wallpaper update...');
          await WallpaperService.performBackgroundUpdate(isIsolate: false);
        }
      });

      debugPrint('✅ FCM initialized (foreground + background)');
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🕒 BACKGROUND SERVICE - Placeholder for future expansion
// ══════════════════════════════════════════════════════════════════════════

class BackgroundService {
  static Future<void> init() async {
    // Currently, updates are handled via FCM 'daily-updates' topic
    // This class is preserved for future advanced scheduling if needed
    debugPrint('✅ Background Service (Placeholder) initialized');
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ⚙️ APP CONFIG - Constants and configuration
// ══════════════════════════════════════════════════════════════════════════

class AppConfig {
  // Heatmap colors - Dark mode
  static const Color heatmapDarkBg = Color(0xFF0D1117);
  static const Color heatmapDarkBox = Color(0xFF161B22);
  static const Color heatmapDarkLevel1 = Color(0xFF0E4429);
  static const Color heatmapDarkLevel2 = Color(0xFF006D32);
  static const Color heatmapDarkLevel3 = Color(0xFF26A641);
  static const Color heatmapDarkLevel4 = Color(0xFF39D353);

  // Heatmap colors - Light mode
  static const Color heatmapLightBg = Color(0xFFFFFFFF);
  static const Color heatmapLightBox = Color(0xFFEBEDF0);
  static const Color heatmapLightLevel1 = Color(0xFF9BE9A8);
  static const Color heatmapLightLevel2 = Color(0xFF40C463);
  static const Color heatmapLightLevel3 = Color(0xFF30A14E);
  static const Color heatmapLightLevel4 = Color(0xFF216E39);

  static const Color todayHighlight = Color(0xFFFF9500);

  // Heatmap layout
  static const double boxSize = 15.0;
  static const double boxSpacing = 3.0;

  // Wallpaper dimensions (initialized from device)
  static late double wallpaperWidth;
  static late double wallpaperHeight;
  static double pixelRatio = 1.0;
  static bool _isInitialized = false;

  static void initializeFromContext(BuildContext context) {
    if (_isInitialized) return;

    final size = MediaQuery.of(context).size;
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    wallpaperWidth = size.width * pixelRatio;
    wallpaperHeight = size.height * pixelRatio;
    _isInitialized = true;

    debugPrint(
        '📱 Screen: ${wallpaperWidth.toInt()}x${wallpaperHeight.toInt()}px @ ${pixelRatio}x');

    // Save for background service
    StorageService.saveDimensions(wallpaperWidth, wallpaperHeight, pixelRatio);
  }

  static bool get isInitialized => _isInitialized;
}
