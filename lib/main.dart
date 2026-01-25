// ══════════════════════════════════════════════════════════════════════════
// 🚀 GITHUB WALLPAPER - Main Entry Point
// ══════════════════════════════════════════════════════════════════════════
// Initializes services, configures system UI, and routes to appropriate page
// Calm & Focus premium light theme - Glass & Depth design system
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/utils.dart';
import 'ui/theme.dart';
import 'ui/onboarding_page.dart';
import 'ui/setup_page.dart';
import 'ui/navigation_hub.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  await _configureSystemUI();

  // Initialize services
  await _initializeServices();

  // Initialize & Schedule Background Service
  await BackgroundService.init();
  await BackgroundService.registerPeriodicTask();

  // Run app
  runApp(const MyApp());
}

// ══════════════════════════════════════════════════════════════════════════
// SYSTEM CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

Future<void> _configureSystemUI() async {
  try {
    // Lock to portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlays for light theme (Calm & Focus)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    if (kDebugMode) debugPrint('✅ System UI configured');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ System UI configuration failed: $e');
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SERVICE INITIALIZATION
// ══════════════════════════════════════════════════════════════════════════

Future<void> _initializeServices() async {
  try {
    // Initialize storage service (critical - must complete)
    await StorageService.init();

    if (kDebugMode) debugPrint('✅ All services initialized');
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Service initialization failed: $e');
    // App can still run with default values
  }
}

// ══════════════════════════════════════════════════════════════════════════
// APP ROOT
// ══════════════════════════════════════════════════════════════════════════

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Wallpaper',
      debugShowCheckedModeBanner: false,

      // Universal theme - Calm & Focus premium light
      theme: AppTheme.theme,

      // Initial route
      home: const AppInitializer(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ROUTE DETERMINER - Decides which page to show first
// ══════════════════════════════════════════════════════════════════════════

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Initialize wallpaper dimensions from context
    AppConfig.initializeFromContext(context);

    // Determine which page to show
    Widget nextPage;

    // Check onboarding status
    final isOnboardingComplete = StorageService.isOnboardingComplete();

    if (!isOnboardingComplete) {
      // First launch - show onboarding
      nextPage = const OnboardingPage();
      if (kDebugMode) debugPrint('🎯 Route: Onboarding (first launch)');
    } else {
      // Check if user has credentials
      final hasToken = await StorageService.hasToken();

      if (!mounted) return;

      final username = StorageService.getUsername();

      if (hasToken && username != null) {
        // User is logged in - go to navigation hub
        nextPage = const NavigationHub();
        if (kDebugMode) debugPrint('🎯 Route: NavigationHub (logged in as @$username)');
      } else {
        // Credentials missing - go to setup
        nextPage = const SetupPage();
        if (kDebugMode) debugPrint('🎯 Route: Setup (no credentials)');
      }
    }

    // Navigate with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash/loading screen while determining route
    final theme = Theme.of(context);

    return Scaffold(
      // Match Calm & Focus background
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo with calm/focus blue gradient
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.accentBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.code,
                size: 64,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // App name
            Text(
              'GitHub Wallpaper',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Your coding journey, visualized',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
