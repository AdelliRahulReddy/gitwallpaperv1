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

class WallpaperService {
  // 🔒 Prevent parallel execution
  static bool _isRunning = false;

  // ⏱️ Safety timeouts
  static const Duration _networkTimeout = Duration(seconds: 30);
  static const Duration _imageGenerationTimeout = Duration(seconds: 15);
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// 🎯 PUBLIC API - Refresh wallpaper (once per day max)
  /// Returns: true if successful, false if failed or already updated today
  static Future<bool> refreshAndSetWallpaper({String target = 'both'}) async {
    // Prevent parallel execution
    if (_isRunning) {
      debugPrint('WallpaperService: Already running, skipping');
      return false;
    }

    _isRunning = true;

    try {
      // Note: Guards removed for better user control and manual updates
      final now = DateTime.now();

      // 🔑 Validate credentials
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || username.isEmpty) {
        throw WallpaperException('GitHub username not configured');
      }

      if (token == null || token.isEmpty) {
        throw WallpaperException('GitHub token not configured');
      }

      debugPrint('WallpaperService: Starting wallpaper update for $username');

      // 🌐 Fetch GitHub data (with timeout)
      final api = GitHubAPI(token: token);
      final data = await api
          .fetchContributions(username)
          .timeout(
            _networkTimeout,
            onTimeout: () =>
                throw TimeoutException('GitHub API request timed out'),
          );

      if (data.days.isEmpty) {
        throw WallpaperException('No contribution data received from GitHub');
      }

      debugPrint(
        'WallpaperService: Fetched ${data.days.length} contribution days',
      );

      // 🎨 Generate wallpaper image (with timeout)
      final file = await _generateWallpaper(data).timeout(
        _imageGenerationTimeout,
        onTimeout: () => throw TimeoutException('Image generation timed out'),
      );

      // ✅ Validate generated file
      if (!await file.exists()) {
        throw WallpaperException('Generated wallpaper file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw WallpaperException('Generated wallpaper file is empty');
      }

      if (fileSize > _maxFileSizeBytes) {
        throw WallpaperException(
          'Generated wallpaper file too large: ${fileSize ~/ 1024 ~/ 1024}MB',
        );
      }

      debugPrint(
        'WallpaperService: Generated wallpaper (${fileSize ~/ 1024}KB)',
      );

      // 🖼️ Set wallpaper using wallpaper_manager_plus
      final locationCode = _convertTargetToLocation(target);

      await WallpaperManagerPlus()
          .setWallpaper(file, locationCode)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Wallpaper setting timed out'),
          );

      debugPrint('WallpaperService: Wallpaper set successfully ($target)');

      // ✅ Save state ONLY after confirmed success
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(now);

      return true;
    } on TimeoutException catch (e) {
      debugPrint('WallpaperService timeout: $e');
      return false;
    } on SocketException catch (e) {
      debugPrint('WallpaperService network error: $e');
      return false;
    } on WallpaperException catch (e) {
      debugPrint('WallpaperService error: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('WallpaperService unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      _isRunning = false;
    }
  }

  /// Convert target string to wallpaper_manager_plus location code
  static int _convertTargetToLocation(String target) {
    switch (target.toLowerCase()) {
      case 'lock':
        return WallpaperManagerPlus.lockScreen;
      case 'home':
        return WallpaperManagerPlus.homeScreen;
      case 'both':
        return WallpaperManagerPlus.bothScreens;
      default:
        return WallpaperManagerPlus.homeScreen;
    }
  }

  /// 🎨 Generates wallpaper PNG file from contribution data
  static Future<File> _generateWallpaper(CachedContributionData data) async {
    final isDarkMode = AppPreferences.getDarkMode();

    // Use default dimensions (wallpaper_manager_plus doesn't provide dimension query)
    int targetWidth = AppConstants.wallpaperWidth;
    int targetHeight = AppConstants.wallpaperHeight;

    debugPrint(
      'WallpaperService: Using dimensions ${targetWidth}x$targetHeight',
    );

    final size = Size(targetWidth.toDouble(), targetHeight.toDouble());

    // Create canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    final bgPaint = Paint()
      ..color = isDarkMode
          ? AppConstants.darkBackground
          : AppConstants.lightBackground;

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

    // Render to image
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw WallpaperException('Failed to encode image to PNG');
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/github_wallpaper.png');

    // Write atomically (temp file + rename)
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

    // Atomic rename
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);

    return file;
  }
}

/// Custom exception for wallpaper-specific errors
class WallpaperException implements Exception {
  final String message;
  WallpaperException(this.message);

  @override
  String toString() => 'WallpaperException: $message';
}
