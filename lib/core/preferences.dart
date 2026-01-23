import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/contribution_data.dart';
import 'constants.dart';
import 'secure_storage.dart';

// ══════════════════════════════════════════════════════════════════════════
// 💾 APP PREFERENCES - CLEAN & SECURE
// ══════════════════════════════════════════════════════════════════════════
// Handles all app settings with secure token storage
// ══════════════════════════════════════════════════════════════════════════

class AppPreferences {
  static SharedPreferences? _prefs;

  // ════════════════════════════════════════════════════════════════════════
  // 🚀 INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════

  /// Initialize (call in main before runApp)
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _migrateTokenToSecureStorage();
      debugPrint('AppPreferences: Initialized');
    } catch (e) {
      debugPrint('AppPreferences: Init failed: $e');
      rethrow;
    }
  }

  /// Migrate token from SharedPreferences to SecureStorage (one-time)
  static Future<void> _migrateTokenToSecureStorage() async {
    try {
      final oldToken = _prefs?.getString(AppConstants.keyToken);

      if (oldToken != null && oldToken.isNotEmpty) {
        final hasSecure = await SecureStorage.hasToken();

        if (!hasSecure) {
          await SecureStorage.setToken(oldToken);
          debugPrint('AppPreferences: Token migrated to secure storage');
        }
        await _prefs?.remove(AppConstants.keyToken);
      }
    } catch (e) {
      debugPrint('AppPreferences: Migration failed: $e');
    }
  }

  /// Get SharedPreferences (async with auto-init)
  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get SharedPreferences (sync, throws if not initialized)
  static SharedPreferences get prefsSync {
    if (_prefs == null) {
      throw Exception('AppPreferences not initialized. Call init() in main()');
    }
    return _prefs!;
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔧 GENERIC HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static bool? getBool(String key) => prefsSync.getBool(key);
  static Future<void> setBool(String key, bool value) async =>
      await (await prefs).setBool(key, value);

  static String? getString(String key) => prefsSync.getString(key);
  static Future<void> setString(String key, String value) async =>
      await (await prefs).setString(key, value);

  static double? getDouble(String key) => prefsSync.getDouble(key);
  static Future<void> setDouble(String key, double value) async =>
      await (await prefs).setDouble(key, value);

  static int? getInt(String key) => prefsSync.getInt(key);
  static Future<void> setInt(String key, int value) async =>
      await (await prefs).setInt(key, value);

  // ════════════════════════════════════════════════════════════════════════
  // 👤 USERNAME
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) throw ArgumentError('Username cannot be empty');
    await (await prefs).setString(AppConstants.keyUsername, trimmed);
    debugPrint('AppPreferences: Username saved');
  }

  static String? getUsername() {
    try {
      return prefsSync.getString(AppConstants.keyUsername);
    } catch (e) {
      debugPrint('AppPreferences: Error reading username: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔐 TOKEN (SECURE STORAGE)
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) throw ArgumentError('Token cannot be empty');

    if (!trimmed.startsWith('ghp_') && !trimmed.startsWith('github_pat_')) {
      debugPrint('AppPreferences: Warning - Token format unexpected');
    }

    await SecureStorage.setToken(trimmed);
    debugPrint('AppPreferences: Token saved securely');
  }

  static Future<String?> getToken() async {
    try {
      return await SecureStorage.getToken();
    } catch (e) {
      debugPrint('AppPreferences: Error reading token: $e');
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await SecureStorage.deleteToken();
      debugPrint('AppPreferences: Token deleted');
    } catch (e) {
      debugPrint('AppPreferences: Error deleting token: $e');
    }
  }

  static Future<bool> hasToken() async {
    try {
      return await SecureStorage.hasToken();
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 💾 CACHED DATA
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setCachedData(CachedContributionData data) async {
    try {
      final json = jsonEncode(data.toJson());
      await (await prefs).setString(AppConstants.keyCachedData, json);
      debugPrint('AppPreferences: Cache saved (${json.length} bytes)');
    } catch (e) {
      debugPrint('AppPreferences: Cache save failed: $e');
      rethrow;
    }
  }

  static CachedContributionData? getCachedData() {
    try {
      final json = prefsSync.getString(AppConstants.keyCachedData);
      if (json == null || json.isEmpty) return null;

      return CachedContributionData.fromJson(jsonDecode(json));
    } on FormatException catch (e) {
      debugPrint('AppPreferences: Corrupted cache (cleared): $e');
      prefsSync.remove(AppConstants.keyCachedData);
      return null;
    } catch (e) {
      debugPrint('AppPreferences: Cache read failed: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ⏰ LAST UPDATE
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setLastUpdate(DateTime dateTime) async {
    await (await prefs).setString(
      AppConstants.keyLastUpdate,
      dateTime.toIso8601String(),
    );
  }

  static DateTime? getLastUpdate() {
    try {
      final str = prefsSync.getString(AppConstants.keyLastUpdate);
      if (str == null || str.isEmpty) return null;
      return DateTime.parse(str);
    } on FormatException catch (e) {
      debugPrint('AppPreferences: Corrupted date (cleared): $e');
      prefsSync.remove(AppConstants.keyLastUpdate);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 APPEARANCE
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setDarkMode(bool enabled) async {
    await (await prefs).setBool(AppConstants.keyDarkMode, enabled);
  }

  static bool getDarkMode() {
    try {
      return prefsSync.getBool(AppConstants.keyDarkMode) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📐 POSITION & SCALE
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setVerticalPosition(double value) async {
    await _setValidatedDouble(
      AppConstants.keyVerticalPos,
      value,
      AppConstants.minVerticalPos,
      AppConstants.maxVerticalPos,
    );
  }

  static double getVerticalPosition() {
    return _getValidatedDouble(
      AppConstants.keyVerticalPos,
      AppConstants.defaultVerticalPosition,
      AppConstants.minVerticalPos,
      AppConstants.maxVerticalPos,
    );
  }

  static Future<void> setHorizontalPosition(double value) async {
    await _setValidatedDouble(AppConstants.keyHorizontalPos, value, 0.0, 1.0);
  }

  static double getHorizontalPosition() {
    return _getValidatedDouble(
      AppConstants.keyHorizontalPos,
      AppConstants.defaultHorizontalPosition,
      0.0,
      1.0,
    );
  }

  static Future<void> setScale(double value) async {
    await _setValidatedDouble(
      AppConstants.keyScale,
      value,
      AppConstants.minScale,
      AppConstants.maxScale,
    );
  }

  static double getScale() {
    return _getValidatedDouble(
      AppConstants.keyScale,
      AppConstants.defaultScale,
      AppConstants.minScale,
      AppConstants.maxScale,
    );
  }

  static Future<void> setOpacity(double value) async {
    await _setValidatedDouble(AppConstants.keyOpacity, value, 0.0, 1.0);
  }

  static double getOpacity() {
    return _getValidatedDouble(AppConstants.keyOpacity, 1.0, 0.0, 1.0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📝 CUSTOM QUOTE
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setCustomQuote(String quote) async {
    final trimmed = quote.trim();
    final limited = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;

    if (limited != trimmed) {
      debugPrint('AppPreferences: Quote truncated to 100 chars');
    }

    await (await prefs).setString(AppConstants.keyCustomQuote, limited);
  }

  static String getCustomQuote() {
    try {
      return prefsSync.getString(AppConstants.keyCustomQuote) ?? '';
    } catch (e) {
      return '';
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📏 PADDING
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setPaddingTop(double value) async {
    await _setValidatedDouble(AppConstants.keyPaddingTop, value, 0.0, 200.0);
  }

  static double getPaddingTop() {
    return _getValidatedDouble(AppConstants.keyPaddingTop, 0.0, 0.0, 200.0);
  }

  static Future<void> setPaddingBottom(double value) async {
    await _setValidatedDouble(AppConstants.keyPaddingBottom, value, 0.0, 200.0);
  }

  static double getPaddingBottom() {
    return _getValidatedDouble(AppConstants.keyPaddingBottom, 0.0, 0.0, 200.0);
  }

  static Future<void> setPaddingLeft(double value) async {
    await _setValidatedDouble(AppConstants.keyPaddingLeft, value, 0.0, 200.0);
  }

  static double getPaddingLeft() {
    return _getValidatedDouble(AppConstants.keyPaddingLeft, 0.0, 0.0, 200.0);
  }

  static Future<void> setPaddingRight(double value) async {
    await _setValidatedDouble(AppConstants.keyPaddingRight, value, 0.0, 200.0);
  }

  static double getPaddingRight() {
    return _getValidatedDouble(AppConstants.keyPaddingRight, 0.0, 0.0, 200.0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎛️ OTHER SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> setCornerRadius(double value) async {
    await _setValidatedDouble(AppConstants.keyCornerRadius, value, 0.0, 50.0);
  }

  static double getCornerRadius() {
    return _getValidatedDouble(AppConstants.keyCornerRadius, 0.0, 0.0, 50.0);
  }

  static Future<void> setQuoteFontSize(double value) async {
    await _setValidatedDouble(AppConstants.keyQuoteFontSize, value, 8.0, 32.0);
  }

  static double getQuoteFontSize() {
    return _getValidatedDouble(AppConstants.keyQuoteFontSize, 14.0, 8.0, 32.0);
  }

  static Future<void> setQuoteOpacity(double value) async {
    await _setValidatedDouble(AppConstants.keyQuoteOpacity, value, 0.0, 1.0);
  }

  static double getQuoteOpacity() {
    return _getValidatedDouble(AppConstants.keyQuoteOpacity, 1.0, 0.0, 1.0);
  }

  static Future<void> setWallpaperTarget(String target) async {
    if (!['home', 'lock', 'both'].contains(target)) {
      throw ArgumentError('Invalid target: $target');
    }
    await (await prefs).setString(AppConstants.keyWallpaperTarget, target);
  }

  static String getWallpaperTarget() {
    try {
      final target =
          prefsSync.getString(AppConstants.keyWallpaperTarget) ?? 'both';
      return ['home', 'lock', 'both'].contains(target) ? target : 'both';
    } catch (e) {
      return 'both';
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🧹 CLEAR DATA
  // ════════════════════════════════════════════════════════════════════════

  /// Clear everything including token
  static Future<void> clearAll() async {
    await (await prefs).clear();
    await SecureStorage.clearAll();
    debugPrint('AppPreferences: All data cleared');
  }

  /// Clear data but keep credentials
  static Future<void> clearUserData() async {
    final p = await prefs;
    final username = p.getString(AppConstants.keyUsername);
    final token = await getToken();

    await p.clear();

    if (username != null) await p.setString(AppConstants.keyUsername, username);
    if (token != null) await setToken(token);

    debugPrint('AppPreferences: User data cleared (credentials kept)');
  }

  /// Clear only cache
  static Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(AppConstants.keyCachedData);
    await p.remove(AppConstants.keyLastUpdate);
    debugPrint('AppPreferences: Cache cleared');
  }

  /// Complete logout
  static Future<void> logout() async {
    await deleteToken();
    await (await prefs).clear();
    debugPrint('AppPreferences: Logged out');
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔧 PRIVATE VALIDATION HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> _setValidatedDouble(
    String key,
    double value,
    double min,
    double max,
  ) async {
    final clamped = value.clamp(min, max);
    if (clamped != value) {
      debugPrint('AppPreferences: $key clamped from $value to $clamped');
    }
    await (await prefs).setDouble(key, clamped);
  }

  static double _getValidatedDouble(
    String key,
    double defaultValue,
    double min,
    double max,
  ) {
    try {
      final value = prefsSync.getDouble(key);
      if (value == null) return defaultValue;
      return value.clamp(min, max);
    } catch (e) {
      return defaultValue;
    }
  }
}
