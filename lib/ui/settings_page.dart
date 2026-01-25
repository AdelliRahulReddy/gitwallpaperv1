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

  Future<void> _loadSettings() async {
    final username = StorageService.getUsername();
    final autoUpdate = StorageService.getAutoUpdate();
    
    if (mounted) {
      setState(() {
        _username = username;
        _autoUpdate = autoUpdate;
      });
    }
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
    ).push(MaterialPageRoute(builder: (_) => SetupPage(onSuccess: () {
      // Refresh credentials after returning from setup
      _loadSettings();
      Navigator.pop(context); // Close setup page
    })));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.dialogLogoutTitle),
        content: const Text(AppStrings.dialogLogoutMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.labelLogout),
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
        title: const Text(AppStrings.dialogClearCacheTitle),
        content: const Text(AppStrings.dialogClearCacheMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.labelClearCache),
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
          content: SuccessBanner(message: AppStrings.cacheCleared),
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
        title: const Text(AppStrings.dialogClearAllTitle),
        content: const Text(
          AppStrings.dialogClearAllMsg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.actionDeleteAll),
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
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionHeader(AppStrings.sectionAccount, Icons.account_circle),
            _buildAccountSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Preferences section
            _buildSectionHeader(AppStrings.sectionPreferences, Icons.tune),
            _buildPreferencesSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Data Management section
            _buildSectionHeader(AppStrings.sectionData, Icons.storage),
            _buildDataSection(),

            const SizedBox(height: AppTheme.spacing24),

            // Help & Support section
            _buildSectionHeader(AppStrings.sectionHelp, Icons.help_outline),
            _buildHelpSection(),

            const SizedBox(height: AppTheme.spacing24),

            // About section
            _buildSectionHeader(AppStrings.sectionAbout, Icons.info_outline),
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
            title: AppStrings.labelUsername,
            subtitle: _username != null ? '@$_username' : 'Not set',
            trailing: const Icon(Icons.chevron_right),
            onTap: _updateToken,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.key,
            title: AppStrings.labelUpdateToken,
            subtitle: AppStrings.subUpdateToken,
            trailing: const Icon(Icons.chevron_right),
            onTap: _updateToken,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.logout,
            title: AppStrings.labelLogout,
            subtitle: AppStrings.subLogout,
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
            title: const Text(AppStrings.labelAutoUpdate),
            subtitle: const Text(AppStrings.subAutoUpdate),
            value: _autoUpdate,
            onChanged: (value) async {
              setState(() => _autoUpdate = value);
              await StorageService.setAutoUpdate(value);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? AppStrings.autoUpdateEnabled : AppStrings.autoUpdateDisabled,
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
                  ? '${AppStrings.lastUpdated} ${lastUpdate != null ? DateHelper.formatRelativeTime(lastUpdate) : 'Unknown'}'
                  : AppStrings.noCachedData,
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.delete_outline,
            title: AppStrings.labelClearCache,
            subtitle: AppStrings.subClearCache,
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.delete_forever,
            title: AppStrings.labelClearAll,
            subtitle: AppStrings.subClearAll,
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
            title: AppStrings.labelDocs,
            subtitle: AppStrings.subDocs,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(
              AppStrings.urlDocs,
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.bug_report,
            title: AppStrings.labelBug,
            subtitle: AppStrings.subBug,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(
              AppStrings.urlBug,
            ),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.star,
            title: AppStrings.labelRate,
            subtitle: AppStrings.subRate,
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.msgComingSoon)),
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
            title: const Text(AppStrings.appName),
            subtitle: Text('Version $_version (Build $_buildNumber)'),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.code,
            title: AppStrings.labelSource,
            subtitle: AppStrings.subSource,
            trailing: const Icon(Icons.open_in_new),
            onTap: () =>
                _launchURL(AppStrings.urlRepo),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.person,
            title: AppStrings.labelDev,
            subtitle: AppStrings.subDev,
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(AppStrings.urlProfile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text(AppStrings.labelLicense),
            subtitle: const Text(AppStrings.subLicense),
            onTap: () => _launchURL(
              AppStrings.urlLicense,
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
