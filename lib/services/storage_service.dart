// ══════════════════════════════════════════════════════════════════════════
// 💾 STORAGE SERVICE - Unified Persistence Layer
// ══════════════════════════════════════════════════════════════════════════
// Handles both secure storage (tokens) and preferences (settings)
// Single API for all storage operations with automatic routing
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../models/models.dart';
import 'utils.dart';

class StorageService {
  // ════════════════════════════════════════════════════════════════════════
  // PRIVATE STORAGE INSTANCES
  // ════════════════════════════════════════════════════════════════════════

  static SharedPreferences? _prefs;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // [FIX] Removed resetOnError: true to prevent accidental wiping of data
      // during transient OS errors or updates.
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════

  /// Initialize storage service (call in main before runApp)
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _migrateTokenToSecureStorage();
      if (kDebugMode) debugPrint('✅ StorageService: Initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Init failed: $e');
      rethrow;
    }
  }

  /// Get SharedPreferences instance (async with auto-init)
  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get SharedPreferences instance (sync, throws if not initialized)
  static SharedPreferences get prefsSync {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() in main()');
    }
    return _prefs!;
  }

  /// Migrate old token from SharedPreferences to secure storage
  static Future<void> _migrateTokenToSecureStorage() async {
    try {
      final oldToken = _prefs?.getString(AppConfig.keyToken);

      if (oldToken != null && oldToken.isNotEmpty) {
        final hasSecure = await hasToken();

        if (!hasSecure) {
          await setToken(oldToken);
          if (kDebugMode) debugPrint('🔄 StorageService: Token migrated to secure storage');
        }

        // Remove from SharedPreferences
        await _prefs?.remove(AppConfig.keyToken);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ StorageService: Token migration failed: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // WALLPAPER CONFIG (Preferences)
  // ════════════════════════════════════════════════════════════════════════

  /// Get entire wallpaper config object
  static WallpaperConfig? getWallpaperConfig() {
    // Return null if critical data missing, or default
    return WallpaperConfig(
        isDarkMode: getDarkMode(),
        verticalPosition: getVerticalPosition(),
        horizontalPosition: getHorizontalPosition(),
        scale: getScale(),
        opacity: getOpacity(),
        customQuote: getCustomQuote(),
        quoteFontSize: getQuoteFontSize(),
        quoteOpacity: getQuoteOpacity(),
        paddingTop: getPaddingTop(),
        paddingBottom: getPaddingBottom(),
        paddingLeft: getPaddingLeft(),
        paddingRight: getPaddingRight(),
        cornerRadius: getCornerRadius(),
    );
  }

  /// Save wallpaper config
  static Future<void> saveWallpaperConfig(WallpaperConfig config) async {
    await _prefs?.setString(
      AppConfig.keyWallpaperConfig,
      json.encode(config.toJson()),
    );
  }



  // ════════════════════════════════════════════════════════════════════════
  // SECURE TOKEN STORAGE (uses FlutterSecureStorage)
  // ════════════════════════════════════════════════════════════════════════

  /// Store GitHub token securely
  static Future<void> setToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }

    // Validate token format
    if (!trimmed.startsWith('ghp_') && !trimmed.startsWith('github_pat_')) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ StorageService: Token format unexpected (not ghp_ or github_pat_)',
        );
      }
    }

    try {
      await _secureStorage.write(key: AppConfig.keyToken, value: trimmed);
      if (kDebugMode) debugPrint('✅ StorageService: Token stored securely');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Failed to store token: $e');
      throw StorageException('Could not save your token securely. Please try again.');
    }
  }

  /// Retrieve GitHub token securely with crash protection
  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: AppConfig.keyToken);
      return (token != null && token.isNotEmpty) ? token : null;
    } on PlatformException catch (e) {
      // [FIX] Changed behavior: Do NOT delete all keys on error.
      // Just return null so the user is prompted to login again harmlessly.
      // This prevents transient errors (like KeyStore busy) from wiping data.
      if (kDebugMode) {
        debugPrint(
          '⚠️ StorageService: Secure storage platform error: $e',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Failed to read token: $e');
      return null;
    }
  }

  /// Delete GitHub token
  static Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: AppConfig.keyToken);
      if (kDebugMode) debugPrint('✅ StorageService: Token deleted');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Failed to delete token: $e');
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Failed to check token: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // USER DATA (SharedPreferences)
  // ════════════════════════════════════════════════════════════════════════

  /// Store GitHub username
  static Future<void> setUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Username cannot be empty');
    }
    await (await prefs).setString(AppConfig.keyUsername, trimmed);
    if (kDebugMode) debugPrint('✅ StorageService: Username saved');
  }

  /// Get GitHub username
  static String? getUsername() {
    try {
      return prefsSync.getString(AppConfig.keyUsername);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Error reading username: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CACHED CONTRIBUTION DATA
  // ════════════════════════════════════════════════════════════════════════

  /// Store cached contribution data
  static Future<void> setCachedData(CachedContributionData data) async {
    try {
      final json = jsonEncode(data.toJson());
      await (await prefs).setString(AppConfig.keyCachedData, json);
      if (kDebugMode) debugPrint('✅ StorageService: Cache saved (${json.length} bytes)');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Cache save failed: $e');
      rethrow;
    }
  }

  /// Get cached contribution data
  static CachedContributionData? getCachedData() {
    try {
      final json = prefsSync.getString(AppConfig.keyCachedData);
      if (json == null || json.isEmpty) return null;

      return CachedContributionData.fromJson(jsonDecode(json));
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('⚠️ StorageService: Corrupted cache cleared: $e');
      prefsSync.remove(AppConfig.keyCachedData);
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ StorageService: Cache read failed: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // LAST UPDATE TIMESTAMP
  // ════════════════════════════════════════════════════════════════════════

  /// Store last update time
  static Future<void> setLastUpdate(DateTime dateTime) async {
    await (await prefs).setString(
      AppConfig.keyLastUpdate,
      dateTime.toIso8601String(),
    );
  }

  /// Get last update time
  static DateTime? getLastUpdate() {
    try {
      final str = prefsSync.getString(AppConfig.keyLastUpdate);
      if (str == null || str.isEmpty) return null;
      return DateTime.parse(str);
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('⚠️ StorageService: Corrupted date cleared: $e');
      prefsSync.remove(AppConfig.keyLastUpdate);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // APPEARANCE SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  /// Store dark mode preference
  static Future<void> setDarkMode(bool enabled) async {
    await (await prefs).setBool(AppConfig.keyDarkMode, enabled);
  }

  /// Get dark mode preference
  static bool getDarkMode() {
    try {
      return prefsSync.getBool(AppConfig.keyDarkMode) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // WALLPAPER POSITIONING
  // ════════════════════════════════════════════════════════════════════════

  /// Set vertical position (0.0 - 1.0)
  static Future<void> setVerticalPosition(double value) async {
    await _setValidatedDouble(
      AppConfig.keyVerticalPos,
      value,
      AppConfig.minVerticalPos,
      AppConfig.maxVerticalPos,
    );
  }

  /// Get vertical position
  static double getVerticalPosition() {
    return _getValidatedDouble(
      AppConfig.keyVerticalPos,
      AppConfig.defaultVerticalPosition,
      AppConfig.minVerticalPos,
      AppConfig.maxVerticalPos,
    );
  }

  /// Set horizontal position (0.0 - 1.0)
  static Future<void> setHorizontalPosition(double value) async {
    await _setValidatedDouble(AppConfig.keyHorizontalPos, value, 0.0, 1.0);
  }

  /// Get horizontal position
  static double getHorizontalPosition() {
    return _getValidatedDouble(
      AppConfig.keyHorizontalPos,
      AppConfig.defaultHorizontalPosition,
      0.0,
      1.0,
    );
  }

  /// Set scale (0.5 - 2.0)
  static Future<void> setScale(double value) async {
    await _setValidatedDouble(
      AppConfig.keyScale,
      value,
      AppConfig.minScale,
      AppConfig.maxScale,
    );
  }

  /// Get scale
  static double getScale() {
    return _getValidatedDouble(
      AppConfig.keyScale,
      AppConfig.defaultScale,
      AppConfig.minScale,
      AppConfig.maxScale,
    );
  }

  /// Set opacity (0.0 - 1.0)
  static Future<void> setOpacity(double value) async {
    await _setValidatedDouble(AppConfig.keyOpacity, value, 0.0, 1.0);
  }

  /// Get opacity
  static double getOpacity() {
    return _getValidatedDouble(AppConfig.keyOpacity, 1.0, 0.0, 1.0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // CUSTOM QUOTE & TEXT
  // ════════════════════════════════════════════════════════════════════════

  /// Set custom quote (max 100 chars)
  static Future<void> setCustomQuote(String quote) async {
    final trimmed = quote.trim();
    final limited = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;

    if (limited != trimmed) {
      if (kDebugMode) debugPrint('⚠️ StorageService: Quote truncated to 100 chars');
    }

    await (await prefs).setString(AppConfig.keyCustomQuote, limited);
  }

  /// Get custom quote
  static String getCustomQuote() {
    try {
      return prefsSync.getString(AppConfig.keyCustomQuote) ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Set quote font size (8.0 - 32.0)
  static Future<void> setQuoteFontSize(double value) async {
    await _setValidatedDouble(AppConfig.keyQuoteFontSize, value, 8.0, 32.0);
  }

  /// Get quote font size
  static double getQuoteFontSize() {
    return _getValidatedDouble(AppConfig.keyQuoteFontSize, 14.0, 8.0, 32.0);
  }

  /// Set quote opacity (0.0 - 1.0)
  static Future<void> setQuoteOpacity(double value) async {
    await _setValidatedDouble(AppConfig.keyQuoteOpacity, value, 0.0, 1.0);
  }

  /// Get quote opacity
  static double getQuoteOpacity() {
    return _getValidatedDouble(AppConfig.keyQuoteOpacity, 1.0, 0.0, 1.0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // PADDING SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  /// Set padding top (0.0 - 200.0)
  static Future<void> setPaddingTop(double value) async {
    await _setValidatedDouble(AppConfig.keyPaddingTop, value, 0.0, 200.0);
  }

  /// Get padding top
  static double getPaddingTop() {
    return _getValidatedDouble(AppConfig.keyPaddingTop, 0.0, 0.0, 200.0);
  }

  /// Set padding bottom (0.0 - 200.0)
  static Future<void> setPaddingBottom(double value) async {
    await _setValidatedDouble(AppConfig.keyPaddingBottom, value, 0.0, 200.0);
  }

  /// Get padding bottom
  static double getPaddingBottom() {
    return _getValidatedDouble(AppConfig.keyPaddingBottom, 0.0, 0.0, 200.0);
  }

  /// Set padding left (0.0 - 200.0)
  static Future<void> setPaddingLeft(double value) async {
    await _setValidatedDouble(AppConfig.keyPaddingLeft, value, 0.0, 200.0);
  }

  /// Get padding left
  static double getPaddingLeft() {
    return _getValidatedDouble(AppConfig.keyPaddingLeft, 0.0, 0.0, 200.0);
  }

  /// Set padding right (0.0 - 200.0)
  static Future<void> setPaddingRight(double value) async {
    await _setValidatedDouble(AppConfig.keyPaddingRight, value, 0.0, 200.0);
  }

  /// Get padding right
  static double getPaddingRight() {
    return _getValidatedDouble(AppConfig.keyPaddingRight, 0.0, 0.0, 200.0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // OTHER CUSTOMIZATION
  // ════════════════════════════════════════════════════════════════════════

  /// Set corner radius (0.0 - 50.0)
  static Future<void> setCornerRadius(double value) async {
    await _setValidatedDouble(AppConfig.keyCornerRadius, value, 0.0, 50.0);
  }

  /// Get corner radius
  static double getCornerRadius() {
    return _getValidatedDouble(AppConfig.keyCornerRadius, 0.0, 0.0, 50.0);
  }

  /// Set wallpaper target (home/lock/both)
  static Future<void> setWallpaperTarget(String target) async {
    if (!['home', 'lock', 'both'].contains(target)) {
      throw ArgumentError('Invalid target: $target');
    }
    await (await prefs).setString(AppConfig.keyWallpaperTarget, target);
  }

  /// Get wallpaper target
  static String getWallpaperTarget() {
    try {
      final target =
          prefsSync.getString(AppConfig.keyWallpaperTarget) ?? 'both';
      return ['home', 'lock', 'both'].contains(target) ? target : 'both';
    } catch (e) {
      return 'both';
    }
  }

  /// Set auto-update enabled
  static Future<void> setAutoUpdate(bool enabled) async {
    await (await prefs).setBool(AppConfig.keyAutoUpdate, enabled);
  }

  /// Get auto-update enabled
  static bool getAutoUpdate() {
    try {
      return prefsSync.getBool(AppConfig.keyAutoUpdate) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Set onboarding complete
  static Future<void> setOnboardingComplete(bool complete) async {
    await (await prefs).setBool(AppConfig.keyOnboardingComplete, complete);
  }

  /// Check if onboarding complete
  static bool isOnboardingComplete() {
    try {
      return prefsSync.getBool(AppConfig.keyOnboardingComplete) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // CLEAR DATA OPERATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Clear everything including token
  static Future<void> clearAll() async {
    await (await prefs).clear();
    await _secureStorage.deleteAll();
    if (kDebugMode) debugPrint('✅ StorageService: All data cleared');
  }

  /// Clear data but keep credentials (username + token)
  static Future<void> clearUserData() async {
    final p = await prefs;
    final username = p.getString(AppConfig.keyUsername);
    final token = await getToken();

    await p.clear();

    if (username != null) {
      await p.setString(AppConfig.keyUsername, username);
    }
    if (token != null) {
      await setToken(token);
    }

    if (kDebugMode) debugPrint('✅ StorageService: User data cleared (credentials kept)');
  }

  /// Clear only cache
  static Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(AppConfig.keyCachedData);
    await p.remove(AppConfig.keyLastUpdate);
    if (kDebugMode) debugPrint('✅ StorageService: Cache cleared');
  }

  /// Complete logout (remove everything)
  static Future<void> logout() async {
    await deleteToken();
    await (await prefs).clear();
    if (kDebugMode) debugPrint('✅ StorageService: Logged out');
  }

  // ════════════════════════════════════════════════════════════════════════
  // GENERIC HELPERS (for other values)
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
  // PRIVATE VALIDATION HELPERS
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> _setValidatedDouble(
    String key,
    double value,
    double min,
    double max,
  ) async {
    final clamped = value.clamp(min, max);
    if (clamped != value) {
      if (kDebugMode) debugPrint('⚠️ StorageService: $key clamped from $value to $clamped');
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

// ══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTION
// ══════════════════════════════════════════════════════════════════════════

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => message;
}
