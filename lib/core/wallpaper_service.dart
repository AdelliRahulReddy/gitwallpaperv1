import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../models/contribution_data.dart';
import '../widgets/heatmap_painter.dart';
import 'constants.dart';
import 'preferences.dart';

import 'github_api.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🖼️ WALLPAPER SERVICE - CLEAN & ROBUST
// ══════════════════════════════════════════════════════════════════════════
// Handles wallpaper generation and setting with safety checks
// ══════════════════════════════════════════════════════════════════════════

class WallpaperService {
  // Prevent parallel execution
  static bool _isRunning = false;

  // Timeouts
  static const Duration _networkTimeout = Duration(seconds: 30);
  static const Duration _imageTimeout = Duration(seconds: 15);
  static const Duration _setWallpaperTimeout = Duration(seconds: 10);

  // Limits
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  // ════════════════════════════════════════════════════════════════════════
  // 🎯 PUBLIC API
  // ════════════════════════════════════════════════════════════════════════

  /// Refresh and set wallpaper (returns true if successful)
  static Future<bool> refreshAndSetWallpaper({String target = 'both'}) async {
    if (_isRunning) {
      debugPrint('WallpaperService: Already running, skipping');
      return false;
    }

    _isRunning = true;

    try {
      final now = DateTime.now();

      // 1. Validate credentials
      final username = AppPreferences.getUsername();
      final token = await AppPreferences.getToken();

      if (username == null || username.isEmpty) {
        throw WallpaperException('GitHub username not configured');
      }

      if (token == null || token.isEmpty) {
        throw WallpaperException('GitHub token not configured');
      }

      debugPrint('WallpaperService: Starting for $username');

      // 2. Fetch data
      final api = GitHubAPI(token: token);
      final data = await api
          .fetchContributions(username)
          .timeout(
            _networkTimeout,
            onTimeout: () => throw TimeoutException('GitHub API timeout'),
          );

      if (data.days.isEmpty) {
        throw WallpaperException('No contribution data found');
      }

      debugPrint('WallpaperService: Fetched ${data.days.length} days');

      // 3. Generate image
      final file = await _generateWallpaper(data).timeout(
        _imageTimeout,
        onTimeout: () => throw TimeoutException('Image generation timeout'),
      );

      // 4. Validate file
      _validateFile(file);

      final fileSize = await file.length();
      debugPrint(
        'WallpaperService: Image ready (${(fileSize / 1024).round()}KB)',
      );

      // 5. Set wallpaper
      final location = _getLocationCode(target);
      await WallpaperManagerPlus()
          .setWallpaper(file, location)
          .timeout(
            _setWallpaperTimeout,
            onTimeout: () =>
                throw TimeoutException('Wallpaper setting timeout'),
          );

      debugPrint('WallpaperService: Success!');

      // 6. Save state
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(now);

      return true;
    } on TimeoutException catch (e) {
      debugPrint('WallpaperService: Timeout - $e');
      return false;
    } on SocketException catch (e) {
      debugPrint('WallpaperService: Network error - $e');
      return false;
    } on WallpaperException catch (e) {
      debugPrint('WallpaperService: Error - ${e.message}');
      return false;
    } catch (e, stack) {
      debugPrint('WallpaperService: Crash - $e\n$stack');
      return false;
    } finally {
      _isRunning = false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════

  /// Generate wallpaper PNG file
  static Future<File> _generateWallpaper(CachedContributionData data) async {
    final isDarkMode = AppPreferences.getDarkMode();
    final width = AppConstants.wallpaperWidth.toDouble();
    final height = AppConstants.wallpaperHeight.toDouble();
    final size = Size(width, height);

    // Setup canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    final bgPaint = Paint()
      ..color = isDarkMode
          ? AppConstants.heatmapDarkBg
          : AppConstants.heatmapLightBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw heatmap
    final painter = HeatmapPainter(
      data: data,
      isDarkMode: isDarkMode,
      verticalPosition: AppPreferences.getVerticalPosition(),
      horizontalPosition: AppPreferences.getHorizontalPosition(),
      scale: AppPreferences.getScale(),
      opacity: AppPreferences.getOpacity(),
      customQuote: AppPreferences.getCustomQuote(),
      paddingTop: AppPreferences.getPaddingTop(),
      paddingBottom: AppPreferences.getPaddingBottom(),
      paddingLeft: AppPreferences.getPaddingLeft(),
      paddingRight: AppPreferences.getPaddingRight(),
      cornerRadius: AppPreferences.getCornerRadius(),
      quoteFontSize: AppPreferences.getQuoteFontSize(),
      quoteOpacity: AppPreferences.getQuoteOpacity(),
    );

    painter.paint(canvas, size);

    // Export to PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw WallpaperException('Failed to encode PNG');
    }

    // Save file atomically
    return await _saveFileAtomic(
      byteData.buffer.asUint8List(),
      'github_wallpaper.png',
    );
  }

  /// Save file atomically (write to temp, then rename)
  static Future<File> _saveFileAtomic(List<int> bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    final tempFile = File('${file.path}.tmp');

    // Write to temp
    await tempFile.writeAsBytes(bytes, flush: true);

    // Atomic rename
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);

    return file;
  }

  /// Validate generated file
  static Future<void> _validateFile(File file) async {
    if (!await file.exists()) {
      throw WallpaperException('Generated file missing');
    }

    final fileSize = await file.length();

    if (fileSize == 0) {
      throw WallpaperException('Generated file is empty');
    }

    if (fileSize > _maxFileSizeBytes) {
      final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);
      throw WallpaperException('Wallpaper too large: ${sizeMB}MB');
    }
  }

  /// Convert target string to location code
  static int _getLocationCode(String target) {
    switch (target.toLowerCase()) {
      case 'lock':
        return WallpaperManagerPlus.lockScreen;
      case 'home':
        return WallpaperManagerPlus.homeScreen;
      case 'both':
      default:
        return WallpaperManagerPlus.bothScreens;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ⚠️ CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class WallpaperException implements Exception {
  final String message;
  WallpaperException(this.message);

  @override
  String toString() => message;
}
