import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'services.dart';
import 'theme.dart';
import 'firebase_options.dart';
import 'utils.dart';
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

  bool storageReady = false;
  bool firebaseReady = false;
  Object? storageError;
  StackTrace? storageStack;

  // 1 & 6. Initialization with Timeouts & Firebase order
  try {
    await StorageService.init().timeout(const Duration(seconds: 10));
    storageReady = true;
  } catch (e, stack) {
    debugPrint('Storage initialization failed: $e');
    storageError = e;
    storageStack = stack;
  }

  try {
    // 3. Unsafe Firebase Service Calls: Fix initialization order
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    firebaseReady = true;
    
    // 1. Fatal Bug Fix: Log actual storage error safely now
    if (!storageReady && storageError != null) {
      // We can only log if Firebase initialized successfully
      await FirebaseCrashlytics.instance.recordError(
        storageError,
        storageStack,
        reason: 'Storage init failed during boot',
        fatal: true, // Mark as fatal since app relies on storage
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // If Firebase fails, we can't log to Crashlytics, but app might still run locally
  }

  runApp(MyApp(
    initResult: (storageReady: storageReady, firebaseReady: firebaseReady),
  ));
}

// 7. Awkward Boolean Passing Pattern: Using a record instead
typedef AppInitResult = ({bool storageReady, bool firebaseReady});

class MyApp extends StatelessWidget {
  final AppInitResult initResult;

  const MyApp({
    super.key,
    required this.initResult,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: AppInitializer(initResult: initResult),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final AppInitResult initResult;

  const AppInitializer({
    super.key,
    required this.initResult,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late bool _storageReady;
  bool _firebaseReady = false;
  bool _firebaseServicesReady = false;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _storageReady = widget.initResult.storageReady;
    _firebaseReady = widget.initResult.firebaseReady;
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      // 1. Critical Dependency Check & Retry
      if (!_storageReady) {
        await StorageService.init().timeout(const Duration(seconds: 10));
        _storageReady = true;
      }

      // 4. Retry button must re-attempt Firebase services
      if (!_firebaseReady) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 15));
          _firebaseReady = true;
        } catch (_) {}
      }

      if (_firebaseReady && !_firebaseServicesReady) {
        await _initFirebaseServices();
        _firebaseServicesReady = true;
      }

      // 2 & 3. Remove delay and add timeout to AppConfig
      if (mounted) {
        await AppConfig.initializeFromContext(context)
            .timeout(const Duration(seconds: 5));
      }

      final loggedIn = StorageService.isOnboardingComplete();

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isInitialized = true;
        });
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
