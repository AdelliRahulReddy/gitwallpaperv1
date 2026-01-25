// ══════════════════════════════════════════════════════════════════════════
// ⚙️ SETTINGS PAGE - App Configuration & Account Management
// ══════════════════════════════════════════════════════════════════════════
// Preferences, credentials, cache management, and app information
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/storage_service.dart';
import '../services/wallpaper_service.dart';
import '../services/utils.dart';
import 'theme.dart';
import 'widgets.dart';
import 'setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;
  String _version = '...';
  String _buildNumber = '...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  void _loadSettings() {
    setState(() {
      _username = StorageService.getUsername();
      _autoUpdate = StorageService.getAutoUpdate();
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      debugPrint('Failed to load app info: $e');
    }
  }

  Future<void> _updateToken() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SetupPage()));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? This will clear all your data including cached contributions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupPage()),
        (route) => false,
      );
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove cached contribution data. Your settings and credentials will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearCache();
      await WallpaperService.cleanupOldWallpapers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SuccessBanner(message: 'Cache cleared successfully'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          '⚠️ This will delete ALL app data including your credentials, settings, and cache. You will need to set up the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAll();
      await WallpaperService.cleanupOldWallpapers();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupPage()),
        (route) => false,
      );
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionHeader('Account', Icons.account_circle),
            _buildAccountSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Preferences section
            _buildSectionHeader('Preferences', Icons.tune),
            _buildPreferencesSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Data Management section
            _buildSectionHeader('Data Management', Icons.storage),
            _buildDataSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Help & Support section
            _buildSectionHeader('Help & Support', Icons.help_outline),
            _buildHelpSection(),

            const SizedBox(height: AppTheme.spacing24),

            // About section
            _buildSectionHeader('About', Icons.info_outline),
            _buildAboutSection(),

            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Icon(icon, size: AppTheme.iconMedium),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.person,
            title: 'Username',
            subtitle: _username != null ? '@$_username' : 'Not set',
            trailing: const Icon(Icons.chevron_right),
            onTap: _updateToken,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.key,
            title: 'Update Token',
            subtitle: 'Change your GitHub personal access token',
            trailing: const Icon(Icons.chevron_right),
            onTap: _updateToken,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Clear all data and logout',
            trailing: const Icon(Icons.chevron_right),
            onTap: _logout,
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.animationNormal).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('Auto-Update'),
            subtitle: const Text('Automatically sync contributions daily'),
            value: _autoUpdate,
            onChanged: (value) async {
              setState(() => _autoUpdate = value);
              await StorageService.setAutoUpdate(value);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Auto-update enabled' : 'Auto-update disabled',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: AppTheme.animationNormal)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDataSection() {
    final cachedData = StorageService.getCachedData();
    final lastUpdate = StorageService.getLastUpdate();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Cache Status'),
            subtitle: Text(
              cachedData != null
                  ? 'Last updated: ${lastUpdate != null ? DateHelper.formatRelativeTime(lastUpdate) : 'Unknown'}'
                  : 'No cached data',
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove cached contribution data',
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            subtitle: 'Reset app to initial state',
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearAllData,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: AppTheme.animationNormal)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildHelpSection() {
    return Card(
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.book,
            title: 'Documentation',
            subtitle: 'Learn how to use the app',
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(
              'https://github.com/yourusername/github-wallpaper#readme',
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.bug_report,
            title: 'Report Bug',
            subtitle: 'Found an issue? Let us know',
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(
              'https://github.com/yourusername/github-wallpaper/issues',
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.star,
            title: 'Rate on Play Store',
            subtitle: 'Support us with a review',
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon on Play Store!')),
              );
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: AppTheme.animationNormal)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('GitHub Wallpaper'),
            subtitle: Text('Version $_version (Build $_buildNumber)'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.code,
            title: 'View Source Code',
            subtitle: 'This app is open source',
            trailing: const Icon(Icons.open_in_new),
            onTap: () =>
                _launchURL('https://github.com/yourusername/github-wallpaper'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.person,
            title: 'Developer',
            subtitle: 'Made with ❤️ by Your Name',
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL('https://github.com/yourusername'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('License'),
            subtitle: const Text('MIT License'),
            onTap: () => _launchURL(
              'https://github.com/yourusername/github-wallpaper/blob/main/LICENSE',
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: AppTheme.animationNormal)
        .slideY(begin: 0.1, end: 0);
  }
}
