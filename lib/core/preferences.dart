import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/contribution_data.dart';
import 'constants.dart';

class AppPreferences {
  static const String _keyUsername = 'github_username';
  static const String _keyToken = 'github_token';
  static const String _keyCachedData = 'cached_data';
  static const String _keyLastUpdate = 'last_update';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyVerticalPosition = 'vertical_position';
  static const String _keyHorizontalPosition = 'horizontal_position';
  static const String _keyScale = 'scale';
  static const String _keyOpacity = 'opacity';
  static const String _keyCustomQuote = 'custom_quote';
  static const String _keyPaddingTop = 'padding_top';
  static const String _keyPaddingBottom = 'padding_bottom';
  static const String _keyPaddingLeft = 'padding_left';
  static const String _keyPaddingRight = 'padding_right';
  static const String _keyCornerRadius = 'corner_radius';
  static const String _keyQuoteFontSize = 'quote_font_size';
  static const String _keyQuoteOpacity = 'quote_opacity';
  static const String _keyWallpaperTarget = 'wallpaper_target';

  static SharedPreferences? _prefs;

  /// ✅ Initialize SharedPreferences - MUST be called in main()
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('AppPreferences: Initialized successfully');
    } catch (e) {
      debugPrint('AppPreferences: Initialization failed: $e');
      rethrow;
    }
  }

  /// ✅ Safe getter with automatic initialization fallback
  static Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      debugPrint('AppPreferences: Not initialized, initializing now...');
      await init();
    }
    return _prefs!;
  }

  /// ✅ Synchronous getter (throws if not initialized)
  static SharedPreferences get prefsSync {
    if (_prefs == null) {
      throw Exception(
        'AppPreferences not initialized. Call init() first in main().',
      );
    }
    return _prefs!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERNAME
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    await (await prefs).setString(_keyUsername, trimmed);
    debugPrint('AppPreferences: Username saved');
  }

  static String? getUsername() {
    try {
      return prefsSync.getString(_keyUsername);
    } catch (e) {
      debugPrint('AppPreferences: Error reading username: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOKEN (⚠️ SECURITY WARNING: Stored in plain text)
  // ══════════════════════════════════════════════════════════════════════════
  // TODO: For production, migrate to flutter_secure_storage
  // SharedPreferences stores data in plain text XML files that can be accessed
  // by rooted devices, backup tools, or malware. Consider using:
  // https://pub.dev/packages/flutter_secure_storage
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }
    if (!trimmed.startsWith('ghp_') && !trimmed.startsWith('github_pat_')) {
      debugPrint(
        'AppPreferences: Warning - Token does not match GitHub format',
      );
    }
    await (await prefs).setString(_keyToken, trimmed);
    debugPrint('AppPreferences: Token saved (length: ${trimmed.length})');
  }

  static String? getToken() {
    try {
      return prefsSync.getString(_keyToken);
    } catch (e) {
      debugPrint('AppPreferences: Error reading token: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CACHED DATA (with error recovery)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setCachedData(CachedContributionData data) async {
    try {
      final json = jsonEncode(data.toJson());
      await (await prefs).setString(_keyCachedData, json);
      debugPrint('AppPreferences: Cached data saved (${json.length} bytes)');
    } catch (e) {
      debugPrint('AppPreferences: Error saving cached data: $e');
      rethrow;
    }
  }

  static CachedContributionData? getCachedData() {
    try {
      final json = prefsSync.getString(_keyCachedData);
      if (json == null || json.isEmpty) return null;

      final decoded = jsonDecode(json);
      return CachedContributionData.fromJson(decoded);
    } on FormatException catch (e) {
      debugPrint(
        'AppPreferences: Corrupted cached data (JSON parse error): $e',
      );
      // Clear corrupted data to prevent repeated errors
      prefsSync.remove(_keyCachedData);
      return null;
    } catch (e) {
      debugPrint('AppPreferences: Error reading cached data: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAST UPDATE (with error recovery)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setLastUpdate(DateTime dateTime) async {
    await (await prefs).setString(_keyLastUpdate, dateTime.toIso8601String());
    debugPrint('AppPreferences: Last update time saved: $dateTime');
  }

  static DateTime? getLastUpdate() {
    try {
      final str = prefsSync.getString(_keyLastUpdate);
      if (str == null || str.isEmpty) return null;

      return DateTime.parse(str);
    } on FormatException catch (e) {
      debugPrint('AppPreferences: Corrupted last update date: $e');
      // Clear corrupted data
      prefsSync.remove(_keyLastUpdate);
      return null;
    } catch (e) {
      debugPrint('AppPreferences: Error reading last update: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK MODE
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setDarkMode(bool enabled) async {
    await (await prefs).setBool(_keyDarkMode, enabled);
  }

  static bool getDarkMode() {
    try {
      return prefsSync.getBool(_keyDarkMode) ?? false;
    } catch (e) {
      debugPrint('AppPreferences: Error reading dark mode: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POSITION & SCALE (with validation)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setVerticalPosition(double value) async {
    final clamped = value.clamp(
      AppConstants.minVerticalPos,
      AppConstants.maxVerticalPos,
    );
    if (clamped != value) {
      debugPrint(
        'AppPreferences: Vertical position clamped from $value to $clamped',
      );
    }
    await (await prefs).setDouble(_keyVerticalPosition, clamped);
  }

  static double getVerticalPosition() {
    try {
      final value = prefsSync.getDouble(_keyVerticalPosition);
      if (value == null) return AppConstants.defaultVerticalPosition;

      // Validate stored value
      return value.clamp(
        AppConstants.minVerticalPos,
        AppConstants.maxVerticalPos,
      );
    } catch (e) {
      debugPrint('AppPreferences: Error reading vertical position: $e');
      return AppConstants.defaultVerticalPosition;
    }
  }

  static Future<void> setHorizontalPosition(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped != value) {
      debugPrint(
        'AppPreferences: Horizontal position clamped from $value to $clamped',
      );
    }
    await (await prefs).setDouble(_keyHorizontalPosition, clamped);
  }

  static double getHorizontalPosition() {
    try {
      final value = prefsSync.getDouble(_keyHorizontalPosition);
      if (value == null) return AppConstants.defaultHorizontalPosition;

      return value.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('AppPreferences: Error reading horizontal position: $e');
      return AppConstants.defaultHorizontalPosition;
    }
  }

  static Future<void> setScale(double value) async {
    final clamped = value.clamp(AppConstants.minScale, AppConstants.maxScale);
    if (clamped != value) {
      debugPrint('AppPreferences: Scale clamped from $value to $clamped');
    }
    await (await prefs).setDouble(_keyScale, clamped);
  }

  static double getScale() {
    try {
      final value = prefsSync.getDouble(_keyScale);
      if (value == null) return AppConstants.defaultScale;

      return value.clamp(AppConstants.minScale, AppConstants.maxScale);
    } catch (e) {
      debugPrint('AppPreferences: Error reading scale: $e');
      return AppConstants.defaultScale;
    }
  }

  static Future<void> setOpacity(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped != value) {
      debugPrint('AppPreferences: Opacity clamped from $value to $clamped');
    }
    await (await prefs).setDouble(_keyOpacity, clamped);
  }

  static double getOpacity() {
    try {
      final value = prefsSync.getDouble(_keyOpacity);
      if (value == null) return 1.0;

      return value.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('AppPreferences: Error reading opacity: $e');
      return 1.0;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOM QUOTE
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setCustomQuote(String quote) async {
    final trimmed = quote.trim();
    // Limit quote length to prevent wallpaper overflow
    final limited = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
    if (limited != trimmed) {
      debugPrint('AppPreferences: Quote truncated to 100 characters');
    }
    await (await prefs).setString(_keyCustomQuote, limited);
  }

  static String getCustomQuote() {
    try {
      return prefsSync.getString(_keyCustomQuote) ?? '';
    } catch (e) {
      debugPrint('AppPreferences: Error reading custom quote: $e');
      return '';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PADDING (with validation)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setPaddingTop(double value) async {
    final clamped = value.clamp(0.0, 200.0);
    await (await prefs).setDouble(_keyPaddingTop, clamped);
  }

  static double getPaddingTop() {
    try {
      return prefsSync.getDouble(_keyPaddingTop)?.clamp(0.0, 200.0) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> setPaddingBottom(double value) async {
    final clamped = value.clamp(0.0, 200.0);
    await (await prefs).setDouble(_keyPaddingBottom, clamped);
  }

  static double getPaddingBottom() {
    try {
      return prefsSync.getDouble(_keyPaddingBottom)?.clamp(0.0, 200.0) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> setPaddingLeft(double value) async {
    final clamped = value.clamp(0.0, 200.0);
    await (await prefs).setDouble(_keyPaddingLeft, clamped);
  }

  static double getPaddingLeft() {
    try {
      return prefsSync.getDouble(_keyPaddingLeft)?.clamp(0.0, 200.0) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> setPaddingRight(double value) async {
    final clamped = value.clamp(0.0, 200.0);
    await (await prefs).setDouble(_keyPaddingRight, clamped);
  }

  static double getPaddingRight() {
    try {
      return prefsSync.getDouble(_keyPaddingRight)?.clamp(0.0, 200.0) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OTHER SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> setCornerRadius(double value) async {
    final clamped = value.clamp(0.0, 50.0);
    await (await prefs).setDouble(_keyCornerRadius, clamped);
  }

  static double getCornerRadius() {
    try {
      return prefsSync.getDouble(_keyCornerRadius)?.clamp(0.0, 50.0) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> setQuoteFontSize(double value) async {
    final clamped = value.clamp(8.0, 32.0);
    await (await prefs).setDouble(_keyQuoteFontSize, clamped);
  }

  static double getQuoteFontSize() {
    try {
      return prefsSync.getDouble(_keyQuoteFontSize)?.clamp(8.0, 32.0) ?? 14.0;
    } catch (e) {
      return 14.0;
    }
  }

  static Future<void> setQuoteOpacity(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await (await prefs).setDouble(_keyQuoteOpacity, clamped);
  }

  static double getQuoteOpacity() {
    try {
      return prefsSync.getDouble(_keyQuoteOpacity)?.clamp(0.0, 1.0) ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  static Future<void> setWallpaperTarget(String target) async {
    if (!['home', 'lock', 'both'].contains(target)) {
      throw ArgumentError('Invalid wallpaper target: $target');
    }
    await (await prefs).setString(_keyWallpaperTarget, target);
  }

  static String getWallpaperTarget() {
    try {
      final target = prefsSync.getString(_keyWallpaperTarget) ?? 'both';
      // Validate
      if (['home', 'lock', 'both'].contains(target)) {
        return target;
      }
      return 'both';
    } catch (e) {
      return 'both';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLEAR DATA (with options)
  // ══════════════════════════════════════════════════════════════════════════

  /// ✅ Clear all data (use with caution)
  static Future<void> clearAll() async {
    await (await prefs).clear();
    debugPrint('AppPreferences: All data cleared');
  }

  /// ✅ Clear data but preserve credentials (safer for logout)
  static Future<void> clearUserData() async {
    final p = await prefs;

    // Save credentials
    final username = p.getString(_keyUsername);
    final token = p.getString(_keyToken);

    // Clear everything
    await p.clear();

    // Restore credentials
    if (username != null) await p.setString(_keyUsername, username);
    if (token != null) await p.setString(_keyToken, token);

    debugPrint('AppPreferences: User data cleared (credentials preserved)');
  }

  /// ✅ Clear only cached wallpaper data (safe)
  static Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(_keyCachedData);
    await p.remove(_keyLastUpdate);
    debugPrint('AppPreferences: Cache cleared');
  }
}
