import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/widgets.dart';
import 'storage_service.dart';
import 'github_service.dart';
import 'wallpaper_service.dart';
import '../models/models.dart';

// unique task name
const String simplePeriodicTask = "com.github_wallpaper.periodic_task";

// callbackDispatcher needs to be a top-level function
@pragma('vm:entry-point') // Mandatory if App will be obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Initialize Flutter Bindings first
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Initialize Storage (headless)
      await StorageService.init();

      // 3. Get Credentials
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        if (kDebugMode) print("❌ [Background] Missing credentials, aborting.");
        return Future.value(false);
      }

      // 4. Fetch Data
      if (kDebugMode) print("🔄 [Background] Fetching data for $username...");
      final gitHubService = GitHubService(token: token);
      final contributions = await gitHubService.fetchContributions(username);

      // 5. Update Storage
      await StorageService.setCachedData(contributions);
      await StorageService.setLastUpdate(DateTime.now());

      // 6. Generate & Set Wallpaper
      if (kDebugMode) print("🎨 [Background] Generating wallpaper...");
      
      // Load saved config or default
      final savedConfig = StorageService.getWallpaperConfig() ?? WallpaperConfig.defaults();
      
      // Use the public API that handles everything
      await WallpaperService.generateAndSetWallpaper(
         data: contributions, 
         config: savedConfig,
      );
      
      if (kDebugMode) print("✅ [Background] Wallpaper updated successfully!");
      return Future.value(true);

    } catch (e, stackTrace) {
      if (kDebugMode) print("❌ [Background] Error: $e\n$stackTrace");
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    if (kDebugMode) print("✅ BackgroundService: Initialized");
  }

  static Future<void> registerPeriodicTask() async {
    // Calculate initial delay to 12:00 AM
    final now = DateTime.now();
    
    // Target: Next 12:00 AM (Midnight)
    // If it's 11 PM, we want 1AM tomorrow.
    // If it's 1 AM, we passed it (technically) but we want the NEXT midnight.
    // Actually user said "every 24 hours at night 12am".
    
    var nextMidnight = DateTime(now.year, now.month, now.day + 1); // Tomorrow 00:00
    Duration initialDelay = nextMidnight.difference(now);

    if (kDebugMode) {
      print("🕒 [Scheduler] Current: $now");
      print("🎯 [Scheduler] Target: $nextMidnight");
      print("⏳ [Scheduler] Delay: ${initialDelay.inMinutes} minutes");
    }

    try {
      await Workmanager().registerPeriodicTask(
        simplePeriodicTask,
        simplePeriodicTask,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected, // Needs internet
          requiresBatteryNotLow: true,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update, // Update schedule
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 10),
      );
      if (kDebugMode) print("✅ [Scheduler] Task registered for daily update.");
    } catch (e) {
      if (kDebugMode) print("❌ [Scheduler] Failed to register task: $e");
    }
  }
  
  // Helper to cancel if needed
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
