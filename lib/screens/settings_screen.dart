import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import '../main.dart'; // For restarting app
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // We can use synchronous access since we initialized Prefs in main.dart
    setState(() {
      _autoUpdateEnabled =
          AppPreferences.getBool('auto_update_enabled') ?? true;
    });
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    setState(() => _autoUpdateEnabled = value);
    await AppPreferences.setBool('auto_update_enabled', value);

    if (value) {
      // ✅ Register 24-Hour Task
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency: AppConstants.updateInterval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresStorageNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      if (mounted)
        _showSnack('✅ Daily auto-update enabled', AppTheme.brandGreen);
    } else {
      // 🛑 Cancel Task
      await Workmanager().cancelByUniqueName(AppConstants.wallpaperTaskName);
      if (mounted) _showSnack('🛑 Auto-update disabled', AppTheme.brandYellow);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will remove your account, token, and all cached stats. You will need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.brandRed),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Workmanager().cancelAll();
      await AppPreferences.clearAll();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SetupScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _editAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SetupScreen(canGoBack: true),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),

          SliverToBoxAdapter(
            child: Padding(
              padding: context.screenPadding,
              child: Column(
                children: [
                  // GENERAL SETTINGS
                  _buildSectionHeader('General'),
                  _buildSettingsGroup(
                    children: [
                      _buildSwitchTile(
                        title: 'Auto-Update Wallpaper',
                        subtitle: 'Refreshes background every 24 hours',
                        value: _autoUpdateEnabled,
                        onChanged: _toggleAutoUpdate,
                        icon: Icons.sync,
                        iconColor: AppTheme.brandBlue,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle: isDark
                            ? 'Midnight theme active'
                            : 'Light theme active',
                        value: isDark,
                        onChanged: (val) async {
                          await AppPreferences.setDarkMode(val);
                          if (mounted) MyApp.restartApp(context);
                        },
                        icon: Icons.dark_mode,
                        iconColor: AppTheme.brandPurple,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // ACCOUNT SETTINGS
                  _buildSectionHeader('Account'),
                  _buildSettingsGroup(
                    children: [
                      _buildActionTile(
                        title: 'GitHub Profile',
                        subtitle:
                            '@${AppPreferences.getUsername() ?? "Unknown"}',
                        icon: Icons.person,
                        iconColor: context.theme.iconTheme.color!,
                        onTap: _editAccount,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing32),

                  // DANGER ZONE
                  _buildSectionHeader('Danger Zone', color: AppTheme.brandRed),
                  _buildDangerZone(),

                  const SizedBox(height: AppTheme.spacing48),

                  // FOOTER
                  Center(
                    child: Text(
                      'GitHub Wallpaper v1.0.0\nMade with 💙 and Flutter',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: context.backgroundColor,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.symmetric(
          horizontal: context.screenPadding.left,
          vertical: 16,
        ),
        title: Text(
          'Settings',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: color ?? context.theme.hintColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: context.borderColor);
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.brandGreen,
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: context.textTheme.bodySmall),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: context.textTheme.bodySmall),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      trailing: Icon(Icons.chevron_right, color: context.theme.hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.brandRed.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: _clearCache,
        title: const Text(
          'Clear Data & Logout',
          style: TextStyle(
            color: AppTheme.brandRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Delete local cache and reset app'),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.brandRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppTheme.brandRed,
            size: 20,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
