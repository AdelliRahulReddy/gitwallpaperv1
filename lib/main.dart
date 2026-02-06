import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app_services.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'app_utils.dart';
import 'pages/onboarding_page.dart';
import 'pages/main_nav_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 5. SystemChrome Configuration Timing: Set early to avoid flash of unstyled UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _storageReady = false;
  bool _firebaseReady = false;
  bool _firebaseServicesReady = false;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      Object? storageError;
      StackTrace? storageStack;

      if (!_storageReady) {
        try {
          await StorageService.init().timeout(const Duration(seconds: 10));
          _storageReady = true;
        } catch (e, stack) {
          storageError = e;
          storageStack = stack;
          _storageReady = false;
        }
      }

      if (!_firebaseReady) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 15));
          _firebaseReady = true;

          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(!kDebugMode);

          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
        } catch (_) {}
      }

      if (!_storageReady) {
        if (_firebaseReady && storageError != null) {
          await FirebaseCrashlytics.instance.recordError(
            storageError,
            storageStack,
            reason: 'Storage init failed during boot',
            fatal: true,
          );
        }
        throw storageError ?? Exception('Storage initialization failed');
      }

      if (_firebaseReady && !_firebaseServicesReady) {
        await _initFirebaseServices();
        _firebaseServicesReady = true;
      }

      // 2 & 3. Remove delay and add timeout to AppConfig
      await AppConfig.initializeFromPlatformDispatcher()
          .timeout(const Duration(seconds: 5));

      final loggedIn = StorageService.isOnboardingComplete();
      final pendingWallpaperRefresh =
          loggedIn && StorageService.hasPendingWallpaperRefresh();

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isInitialized = true;
        });
      }

      if (pendingWallpaperRefresh) {
        unawaited(() async {
          final shouldRefresh =
              await StorageService.consumePendingWallpaperRefresh();
          if (!shouldRefresh) return;
          await WallpaperService.refreshWallpaper();
        }());
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        final friendlyMsg = ErrorHandler.getUserFriendlyMessage(e);
        setState(() => _error = friendlyMsg);
      }

      // 3. Unsafe Firebase Service Calls: Verify readiness before recording
      if (_firebaseReady) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }
  }

  Future<void> _initFirebaseServices() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    // 2. App Check Initialization Order
    try {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint('AppCheck init failed: $e');
      rethrow; // Rethrow to allow retry logic to track success
    }

    try {
      await FcmService.init();
    } catch (e) {
      debugPrint('FCM init failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isInitialized = false;
                      _firebaseServicesReady = false;
                    });
                    _startInitialization();
                  },
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainNavPage() : const OnboardingPage();
  }
}
