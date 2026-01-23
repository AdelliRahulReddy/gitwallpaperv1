import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive data (GitHub tokens)
/// Uses Android Keystore (API 23+) and iOS Keychain
class SecureStorage {
  // Configure secure storage with platform-specific options
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences:
          true, // Use EncryptedSharedPreferences on Android
      resetOnError:
          true, // ✅ CRITICAL: Re-create key if corrupted/decryption fails
    ),
    iOptions: IOSOptions(
      accessibility:
          KeychainAccessibility.first_unlock, // Available after first unlock
    ),
  );

  // Storage keys
  static const String _keyToken = 'github_token_secure';

  // ══════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT (SECURE)
  // ══════════════════════════════════════════════════════════════════════════

  /// Securely store GitHub token
  static Future<void> setToken(String token) async {
    try {
      final trimmed = token.trim();
      if (trimmed.isEmpty) {
        debugPrint('SecureStorage: Cannot store empty token');
        return;
      }

      await _storage.write(key: _keyToken, value: trimmed);
      debugPrint('SecureStorage: Token stored securely');
    } catch (e) {
      debugPrint('SecureStorage: Failed to store token: $e');
      // Don't rethrow here to prevent app crash on save failure, just log it
    }
  }

  /// Retrieve GitHub token securely with crash protection
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _keyToken);
      if (token == null || token.isEmpty) {
        // debugPrint('SecureStorage: No token found'); // Reduce noise
        return null;
      }
      return token;
    } on PlatformException catch (e) {
      // ✅ CRITICAL: If Keystore is corrupted, clear it to prevent crash loop
      // This is a known issue on some Android devices after OS updates
      debugPrint(
        'SecureStorage: Keystore corruption detected. Resetting storage. Error: $e',
      );
      await _storage.deleteAll();
      return null;
    } catch (e) {
      debugPrint('SecureStorage: Failed to read token: $e');
      return null;
    }
  }

  /// Delete GitHub token
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _keyToken);
      debugPrint('SecureStorage: Token deleted');
    } catch (e) {
      debugPrint('SecureStorage: Failed to delete token: $e');
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    try {
      // We use getToken() here to leverage the crash protection logic above
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('SecureStorage: Failed to check token: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MIGRATION HELPER (Move from SharedPreferences to Secure Storage)
  // ══════════════════════════════════════════════════════════════════════════

  /// Migrate token from SharedPreferences to SecureStorage
  /// Call this once on app startup for existing users
  static Future<void> migrateFromSharedPreferences(String? oldToken) async {
    if (oldToken != null && oldToken.isNotEmpty) {
      try {
        // Check if already migrated
        final hasSecureToken = await hasToken();
        if (!hasSecureToken) {
          await setToken(oldToken);
          debugPrint('SecureStorage: Successfully migrated token');
        }
      } catch (e) {
        debugPrint('SecureStorage: Migration failed: $e');
      }
    }
  }

  /// Clear all secure storage (for testing/logout)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('SecureStorage: All data cleared');
    } catch (e) {
      debugPrint('SecureStorage: Failed to clear all: $e');
    }
  }
}
