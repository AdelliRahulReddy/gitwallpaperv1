import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'services.dart';
import 'pages.dart';
import 'theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (kDebugMode) {
      debugPrint('--------- FIREBASE INITIALIZING ---------');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('--------- FIREBASE INITIALIZED SUCCESS ---------');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ FIREBASE INIT FAILED: $e');
    }
  }

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  if (kDebugMode) {
    debugPrint('✅ System UI configured');
  }

  // Initialize StorageService
  try {
    await StorageService.init();
    if (kDebugMode) {
      debugPrint('✅ StorageService initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ StorageService init failed: $e');
    }
  }

  if (kDebugMode) {
    debugPrint('🚀 Running app...');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🎨 MyApp building...');
    }

    return MaterialApp(
      title: 'GitHub Wallpaper',
      theme: AppTheme.theme,
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
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if user is logged in
    _isLoggedIn = StorageService.isOnboardingComplete();
    if (kDebugMode) {
      debugPrint('🔐 User logged in: $_isLoggedIn');
    }

    // ✅ FIXED: Show UI immediately, initialize services in background
    setState(() => _isInitialized = true);

    // Initialize AppConfig and Firebase features after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        // Initialize AppConfig
        AppConfig.initializeFromContext(context);
        if (kDebugMode) {
          debugPrint('✅ AppConfig initialized');
        }

        // Initialize Firebase App Check with debug provider for development
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: kDebugMode
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider:
                kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
          );
          if (kDebugMode) {
            debugPrint('✅ Firebase App Check initialized');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ App Check init failed (non-critical): $e');
          }
        }

        // Initialize FCM (non-blocking)
        try {
          await FcmService.init();
          if (kDebugMode) {
            debugPrint('✅ FCM initialized');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ FCM init failed (non-critical): $e');
          }
        }

        // Initialize Background Service (non-blocking)
        try {
          await BackgroundService.init();
          if (kDebugMode) {
            debugPrint('✅ Background Service initialized');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Background Service init failed (non-critical): $e');
          }
        }

        if (kDebugMode) {
          debugPrint('🎉 All async services initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Async initialization error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading only if not initialized
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Navigate based on login status
    if (kDebugMode) {
      debugPrint(
          '🏠 AppInitializer: rendering ${_isLoggedIn ? "DashboardPage" : "SetupPage"}');
    }

    return _isLoggedIn ? const DashboardPage() : const SetupPage();
  }
}
