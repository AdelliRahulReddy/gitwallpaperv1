import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme.dart';
import 'core/preferences.dart';
import 'core/wallpaper_service.dart';
import 'core/constants.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';

/// Global key to restart app when theme changes
final GlobalKey<_MyAppState> appKey = GlobalKey<_MyAppState>();

/// ✅ Background task callback - runs daily via WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔄 Background wallpaper update started');
    debugPrint('📋 Task: $task');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      await AppPreferences.init();
      debugPrint('✅ Preferences initialized');

      final target = AppPreferences.getWallpaperTarget();
      debugPrint('🎯 Wallpaper target: $target');

      final success = await WallpaperService.refreshAndSetWallpaper(
        target: target,
      );

      if (success) {
        debugPrint('✅ Background wallpaper update completed successfully');
        return Future.value(true);
      } else {
        debugPrint('⚠️ Wallpaper update skipped or failed');
        return Future.value(true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Background wallpaper update failed: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App starting...');

  // Initialize preferences first
  await AppPreferences.init();
  debugPrint('✅ Preferences initialized');

  // Initialize WorkManager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  debugPrint('✅ WorkManager initialized');

  // Register periodic background task
  await Workmanager().registerPeriodicTask(
    AppConstants.wallpaperTaskName,
    AppConstants.wallpaperTaskTag,
    frequency: AppConstants.updateInterval,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresStorageNotLow: true,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 15),
  );

  if (AppConstants.updateInterval.inMinutes < 60) {
    debugPrint(
      '✅ WorkManager task registered (interval: ${AppConstants.updateInterval.inMinutes} minutes)',
    );
  } else {
    debugPrint(
      '✅ WorkManager task registered (interval: ${AppConstants.updateInterval.inHours} hours)',
    );
  }

  // Set status bar style
  _setSystemUI();

  runApp(MyApp(key: appKey));
}

/// Configure system UI
void _setSystemUI() {
  final isDarkMode = AppPreferences.getDarkMode();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDarkMode
          ? const Color(0xFF0D1117)
          : Colors.white,
      systemNavigationBarIconBrightness: isDarkMode
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void restartApp(BuildContext context) {
    appKey.currentState?.restartApp();
  }
}

class _MyAppState extends State<MyApp> {
  Key _appKey = UniqueKey();

  void restartApp() {
    setState(() {
      _appKey = UniqueKey();
      _updateSystemUI();
    });
  }

  void _updateSystemUI() {
    _setSystemUI();
  }

  @override
  void initState() {
    super.initState();
    _updateSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppPreferences.getDarkMode();

    return KeyedSubtree(
      key: _appKey,
      child: MaterialApp(
        title: 'GitHub Wallpaper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const AppInitializer(), // ✅ NEW: Auto-detect device first
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🚀 APP INITIALIZER - Detects device then navigates
// ══════════════════════════════════════════════════════════════════════════

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for first frame to get accurate screen dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Auto-detect device dimensions
      AppConstants.initializeFromContext(context);

      // Small delay to show splash
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to appropriate screen
      if (!mounted) return;
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    final username = AppPreferences.getUsername();
    final cachedData = AppPreferences.getCachedData();

    Widget destination;

    if (username != null && username.isNotEmpty && cachedData != null) {
      destination = const MainNavigation();
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppPreferences.getDarkMode();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0D1117) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.hub_outlined,
                size: 48,
                color: context.primaryColor,
              ),
            ),

            SizedBox(height: AppTheme.spacing24),

            // App Name
            Text(
              'GitHub Wallpaper',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: AppTheme.spacing8),

            // Loading indicator
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: context.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              ),
            ),

            SizedBox(height: AppTheme.spacing12),

            // Status text
            Text(
              'Initializing...',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
