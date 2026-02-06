// ══════════════════════════════════════════════════════════════════════════
// 🧭 MAIN NAVIGATION PAGE - Shell for Home, Customize, Settings
// ══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_utils.dart';

// Import sub-pages
import 'home_page.dart';
import 'customize_page.dart';
import 'settings_page.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  CachedContributionData? _data;
  bool _isLoading = false;
  String? _loadError;
  late final VoidCallback _requestSyncFromCustomize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestSyncFromCustomize = () {
      _onItemTapped(0);
      _syncData(force: true);
    };
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoUpdate();
    }
  }

  Future<void> _checkAutoUpdate() async {
    if (!mounted) return;

    // Re-save device dimensions (may have changed on rotate/resize)
    await AppConfig.initializeFromPlatformDispatcher();
    if (!mounted) return;

    // Refresh data if needed when app resumes
    if (!StorageService.getAutoUpdate()) return;
    final lastUpdate = StorageService.getLastUpdate();
    if (lastUpdate != null) {
      final diff = DateTime.now().difference(lastUpdate);
      if (diff.inMinutes > 30) {
        _syncData(silent: true);
      }
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return; // Prevent race conditions

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1. Try to load from cache
      final cached = StorageService.getCachedData();

      if (cached != null) {
        // Check if cache is "complete" (has at least 3 months of data)
        if (cached.days.length < 90) {
          await _syncData(force: true);
        } else {
          setState(() {
            _data = cached;
            _loadError = null;
            _isLoading = false;
          });
          _checkBackgroundSync();
        }
      } else {
        await _syncData(force: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _checkBackgroundSync() {
    if (!StorageService.getAutoUpdate()) return;
    final lastUpdate = StorageService.getLastUpdate();
    if (lastUpdate != null) {
      final diff = DateTime.now().difference(lastUpdate);
      if (diff.inHours >= 1) {
        _syncData(silent: true);
      }
    }
  }

  Future<void> _syncData({bool silent = false, bool force = false}) async {
    if (!mounted) return;
    if (_isLoading && !force) return;

    setState(() {
      _isLoading = true;
      if (!silent) {
        _loadError = null;
      }
    });

    try {
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials missing. Please login again.');
      }

      final newData = await GitHubService.fetchContributions(
        username: username,
        token: token,
      );

      await StorageService.setCachedData(newData);
      await StorageService.setLastUpdate(DateTime.now());

      if (mounted) {
        setState(() {
          _data = newData;
          _isLoading = false;
        });

        if (!silent) {
          ErrorHandler.showSuccess(context, 'Data synced successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        if (!silent) {
          setState(() {
            _loadError = e.toString().replaceAll('Exception:', '').trim();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleSetWallpaper(String target) async {
    if (_data == null) return;

    try {
      final config = StorageService.getWallpaperConfig();

      // Convert string to WallpaperTarget enum
      WallpaperTarget targetEnum;
      switch (target) {
        case 'home':
          targetEnum = WallpaperTarget.home;
          break;
        case 'lock':
          targetEnum = WallpaperTarget.lock;
          break;
        default:
          targetEnum = WallpaperTarget.both;
      }

      await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
        target: targetEnum,
      );

      if (mounted) {
        if (Platform.isAndroid) {
          ErrorHandler.showSuccess(context, AppStrings.wallpaperApplied);
        } else {
          ErrorHandler.showSuccess(
              context, 'Wallpaper image generated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(context, e);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Screens
    final List<Widget> screens = [
      HomePage(
        data: _data,
        isLoading: _isLoading,
        loadError: _loadError,
        onRefresh: () => _syncData(silent: false),
      ),
      CustomizePage(
        data: _data,
        onSetWallpaper: _handleSetWallpaper,
        onRequestSync: _requestSyncFromCustomize,
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: scheme.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette, color: scheme.primary),
            label: 'Customize',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: scheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
