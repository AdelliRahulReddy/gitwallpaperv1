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

// Import pages
import 'pages/onboarding_page.dart';
import 'pages/main_nav_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool storageReady = false;
  bool firebaseReady = false;

  try {
    await StorageService.init();
    storageReady = true;
  } catch (e) {
    debugPrint('Storage initialization failed: $e');
    try {
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    } catch (crashlyticsError) {
      debugPrint('Crashlytics logging failed during storage init: $crashlyticsError');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    try {
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    } catch (crashlyticsError) {
      debugPrint('Crashlytics logging failed during firebase init: $crashlyticsError');
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp(
    storageReady: storageReady,
    firebaseReady: firebaseReady,
  ));
}

class MyApp extends StatelessWidget {
  final bool storageReady;
  final bool firebaseReady;

  const MyApp({
    super.key,
    required this.storageReady,
    required this.firebaseReady,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: AppInitializer(
        storageReady: storageReady,
        firebaseReady: firebaseReady,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final bool storageReady;
  final bool firebaseReady;

  const AppInitializer({
    super.key,
    required this.storageReady,
    required this.firebaseReady,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Local state to allow retries
  late bool _storageReady;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _storageReady = widget.storageReady;
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // 1. Critical Dependency Check & Retry
    if (!_storageReady) {
      try {
        await StorageService.init();
        _storageReady = true;
      } catch (e) {
        debugPrint('Storage retry failed: $e');
        if (mounted) {
          setState(() {
            _error = AppStrings.errorStorageInit;
          });
        }
        return;
      }
    }

    // 2. Setup Lifecycle-dependent config
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _performContextDependentInit();
    });
  }

  Future<void> _performContextDependentInit() async {
    if (!mounted) return;

    try {
      await AppConfig.initializeFromContext(context);

      if (widget.firebaseReady) {
        await _initFirebaseServices();
      }

      final loggedIn = StorageService.isOnboardingComplete();

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        // Mask raw error with user-friendly message
        final friendlyMsg = ErrorHandler.getUserFriendlyMessage(e);
        setState(() => _error = friendlyMsg);
      }
    }
  }

  Future<void> _initFirebaseServices() async {
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
    }

    try {
      await FcmService.init();
    } catch (e) {
      debugPrint('FCM init failed: $e');
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
