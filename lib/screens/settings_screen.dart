import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import '../main.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // ✅ FIXED: Use async prefs properly
      final prefs = await AppPreferences.prefs;
      setState(() {
        _autoUpdateEnabled = prefs.getBool('auto_update_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SettingsScreen: Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await AppPreferences.prefs;
      await prefs.setBool('auto_update_enabled', _autoUpdateEnabled);
    } catch (e) {
      debugPrint('SettingsScreen: Error saving settings: $e');
    }
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    setState(() => _autoUpdateEnabled = value);
    await _saveSettings();

    if (value) {
      // ✅ FIXED: Register with proper constraints and 24-hour interval
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency:
            AppConstants.updateInterval, // ✅ Uses 24 hours from constants
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true, // ✅ Battery safe
          requiresStorageNotLow: true, // ✅ Storage safe
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Daily auto-update enabled'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('SettingsScreen: Auto-update enabled (24h interval)');
    } else {
      await Workmanager().cancelByUniqueName(AppConstants.wallpaperTaskName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Auto-update disabled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('SettingsScreen: Auto-update disabled');
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will log you out and remove all settings. You\'ll need to set up the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear & Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel WorkManager tasks
        await Workmanager().cancelAll();

        // Clear all preferences
        await AppPreferences.clearAll();

        debugPrint('SettingsScreen: All data cleared, returning to setup');

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SetupScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('SettingsScreen: Error clearing data: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Navigate to edit account - user can come back!
  Future<void> _editAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SetupScreen(canGoBack: true),
      ),
    );

    // If account was updated, refresh the UI
    if (result == true && mounted) {
      setState(() {}); // Refresh to show new username
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: context.screenPadding,
          children: [
            // Auto-Update Section
            _buildSectionHeader('Wallpaper Updates'),
            const SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.autorenew_outlined,
              title: 'Auto-Update Wallpaper',
              subtitle: _autoUpdateEnabled
                  ? 'Active - updates daily' // ✅ FIXED: Changed from "every X hours"
                  : 'Disabled',
              trailing: Switch(
                value: _autoUpdateEnabled,
                onChanged: _toggleAutoUpdate,
                activeColor: context.primaryColor,
              ),
            ),

            const SizedBox(height: AppTheme.spacing12),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'How it works',
              subtitle:
                  'Your wallpaper automatically updates with the latest GitHub contributions once per day, even when the app is closed.', // ✅ FIXED
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Appearance Section
            _buildSectionHeader('Appearance'),
            const SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: isDarkMode ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) async {
                  await AppPreferences.setDarkMode(value);
                  // Restart entire app to apply theme everywhere
                  if (mounted) {
                    MyApp.restartApp(context);
                  }
                },
                activeColor: context.primaryColor,
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Account Section
            _buildSectionHeader('Account'),
            const SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: 'GitHub Account',
              subtitle: '@${AppPreferences.getUsername() ?? 'Not connected'}',
              trailing: Icon(
                Icons.edit_outlined,
                size: 20,
                color: context.primaryColor,
              ),
              onTap: _editAccount,
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Data Section
            _buildSectionHeader('Data'),
            const SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.delete_outline,
              title: 'Clear All Data & Logout',
              subtitle: 'Remove everything and start fresh',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.colorScheme.error,
              ),
              onTap: _clearCache,
              isDestructive: true,
            ),

            const SizedBox(height: AppTheme.spacing24),

            // About Section
            _buildSectionHeader('About'),
            const SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: '1.0.0',
            ),

            const SizedBox(height: AppTheme.spacing40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacing4),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? context.colorScheme.error.withOpacity(0.1)
                      : context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? context.colorScheme.error
                      : context.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: isDestructive ? context.colorScheme.error : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(subtitle, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.spacing12),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
