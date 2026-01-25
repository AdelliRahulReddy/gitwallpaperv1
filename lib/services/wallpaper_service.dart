// ══════════════════════════════════════════════════════════════════════════
// 🖼️ WALLPAPER SERVICE - Image Generation & Setting
// ══════════════════════════════════════════════════════════════════════════
// Generates wallpaper from contribution data and sets as Android wallpaper
// Handles canvas rendering, PNG export, and wallpaper application
// ══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../models/models.dart';
import 'utils.dart';
import 'heatmap_renderer.dart';

class WallpaperService {
  // ════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ════════════════════════════════════════════════════════════════════════

  static const Duration _renderTimeout = Duration(seconds: 15);
  static const Duration _exportTimeout = Duration(seconds: 10);
  static const Duration _setWallpaperTimeout = Duration(seconds: 10);
  static const int _maxFileSizeMB = 10;

  // ════════════════════════════════════════════════════════════════════════
  // EXECUTION LOCK (prevent concurrent wallpaper generation)
  // ════════════════════════════════════════════════════════════════════════

  static bool _isRunning = false;

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC API - GENERATE & SET WALLPAPER
  // ════════════════════════════════════════════════════════════════════════

  /// Generates and sets wallpaper from contribution data
  static Future<String> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    String target = 'both',
  }) async {
    // Prevent concurrent execution
    if (_isRunning) {
      throw WallpaperException(
        'Wallpaper generation already in progress. Please wait.',
      );
    }

    _isRunning = true;

    try {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('🖼️ WallpaperService: Starting generation');
        debugPrint('═══════════════════════════════════════════════');
      }

      // Step 1: Generate image
      if (kDebugMode) debugPrint('📐 Step 1/3: Rendering heatmap...');
      final imageBytes = await _generateWallpaperImage(data, config);
      if (kDebugMode) {
        debugPrint(
          '✅ Rendered (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)',
        );
      }

      // Step 2: Save to file
      if (kDebugMode) debugPrint('💾 Step 2/3: Saving to file...');
      final filePath = await _saveToFile(imageBytes);
      if (kDebugMode) debugPrint('✅ Saved: $filePath');

      // Step 3: Set as wallpaper
      if (kDebugMode) debugPrint('🎨 Step 3/3: Setting wallpaper... Target: $target');
      if (target == 'both') {
        if (kDebugMode) debugPrint('🏠 Setting Home Screen...');
        await _setWallpaper(filePath, 'home');
        if (kDebugMode) debugPrint('🔒 Setting Lock Screen...');
        await _setWallpaper(filePath, 'lock');
      } else {
        await _setWallpaper(filePath, target);
      }
      if (kDebugMode) debugPrint('✅ Wallpaper set successfully');

      // Optional: Cleanup old files to save space
      await cleanupOldWallpapers();

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('🎉 WallpaperService: Complete!');
        debugPrint('═══════════════════════════════════════════════');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WallpaperService: Failed: $e');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - IMAGE GENERATION
  // ════════════════════════════════════════════════════════════════════════

  /// Generates wallpaper image from contribution data
  static Future<Uint8List> _generateWallpaperImage(
    CachedContributionData data,
    WallpaperConfig config,
  ) async {
    try {
      // Ensure dimensions are initialized
      if (!AppConfig.isInitialized) {
        throw WallpaperException(
          'Wallpaper dimensions not initialized. Call AppConfig.initializeFromContext() first.',
        );
      }

      final width = AppConfig.wallpaperWidth;
      final height = AppConfig.wallpaperHeight;

      if (kDebugMode) debugPrint('📐 Rendering Canvas: ${width.toInt()}x${height.toInt()}');
      if (width <= 0 || height <= 0) {
        throw WallpaperException(
            'Invalid canvas dimensions: ${width}x$height');
      }

      // Create recorder for drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // Render heatmap to canvas
      await _renderHeatmap(
        canvas,
        data,
        config,
        width,
        height,
      ).timeout(_renderTimeout);

      // 1. End recording to get Picture
      final picture = recorder.endRecording();

      try {
        // 2. Convert to Image
        final image = await picture
            .toImage(width.toInt(), height.toInt())
            .timeout(_exportTimeout);

        try {
          // [Optimization] Yield execution briefly to let UI spinner frame update
          await Future.delayed(Duration.zero);

          // 3. Convert to PNG bytes (Heavy Operation)
          final byteData = await image
              .toByteData(format: ui.ImageByteFormat.png)
              .timeout(_exportTimeout);

          if (byteData == null) {
            throw WallpaperException('Failed to export image to PNG format');
          }

          final bytes = byteData.buffer.asUint8List();

          // Validate file size
          final sizeMB = bytes.length / (1024 * 1024);
          if (sizeMB > _maxFileSizeMB) {
            throw WallpaperException(
              'Generated image too large: ${sizeMB.toStringAsFixed(1)} MB (max $_maxFileSizeMB MB)',
            );
          }

          return bytes;
        } finally {
          // [FIX] CRITICAL: Release native memory for the image
          image.dispose();
        }
      } finally {
        // [FIX] CRITICAL: Release native memory for the picture
        picture.dispose();
      }
    } on TimeoutException {
      throw WallpaperException('Image generation timed out. Please try again.');
    } catch (e) {
      if (e is WallpaperException) rethrow;
      throw WallpaperException('Failed to generate image: $e');
    }
  }

  /// Renders GitHub contribution heatmap to canvas
  /// Renders GitHub contribution heatmap to canvas
  static Future<void> _renderHeatmap(
    Canvas canvas,
    CachedContributionData data,
    WallpaperConfig config,
    double width,
    double height,
  ) async {
    // Delegate to shared renderer
    // We pass devicePixelRatio as the multiplier because we are drawing to a high-res image
    HeatmapRenderer.render(
      canvas: canvas,
      size: Size(width, height),
      data: data,
      config: config,
      pixelRatio: AppConfig.devicePixelRatio,
    );
  }



  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - FILE OPERATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Saves image bytes to file with atomic write
  static Future<String> _saveToFile(Uint8List bytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/github_wallpaper_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists()) {
        throw WallpaperException('File was not created at $filePath');
      }

      if (kDebugMode) {
        debugPrint(
            '💾 Saved to temp: $filePath (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
      }
      return filePath;
    } catch (e) {
      throw WallpaperException('Failed to save file: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE - WALLPAPER SETTING
  // ════════════════════════════════════════════════════════════════════════

  /// Sets wallpaper on device
  static Future<void> _setWallpaper(String filePath, String target) async {
    try {
      int location;
      switch (target) {
        case 'home':
          location = WallpaperManagerPlus.homeScreen;
          break;
        case 'lock':
          location = WallpaperManagerPlus.lockScreen;
          break;
        case 'both':
        default:
          location = WallpaperManagerPlus.bothScreens;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw WallpaperException('Wallpaper file not found');
      }

      if (kDebugMode) debugPrint('🎬 Calling WallpaperManagerPlus... Location: $location');

      final result = await WallpaperManagerPlus()
          .setWallpaper(file, location)
          .timeout(_setWallpaperTimeout);

      if (kDebugMode) debugPrint('📡 WallpaperManagerPlus Result: $result');

      if (result == null || result.isEmpty) {
        throw WallpaperException(
            'Plugin returned failure while setting wallpaper');
      }
    } on TimeoutException {
      throw WallpaperException('Setting wallpaper timed out');
    } catch (e) {
      throw WallpaperException('Failed to set wallpaper: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ════════════════════════════════════════════════════════════════════════

  /// Cleans up old wallpaper files (keeps last 3)
  static Future<void> cleanupOldWallpapers() async {
    try {
      // [FIX] Changed to TemporaryDirectory to match _saveToFile
      final directory = await getTemporaryDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.contains('github_wallpaper_') && f.path.endsWith('.png'),
          )
          .toList();

      // Sort by modification time (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // Delete all except the last 3
      if (files.length > 3) {
        for (var i = 3; i < files.length; i++) {
          await files[i].delete();
          if (kDebugMode) debugPrint('🗑️ Deleted old wallpaper: ${files[i].path}');
        }
      }

      if (kDebugMode) debugPrint('✅ Cleanup complete (kept ${files.length.clamp(0, 3)} files)');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Cleanup failed: $e');
      // Non-critical, don't throw
    }
  }

  /// Checks if wallpaper generation is currently running
  static bool get isRunning => _isRunning;
}

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class WallpaperException implements Exception {
  final String message;

  WallpaperException(this.message);

  @override
  String toString() => message;
}
