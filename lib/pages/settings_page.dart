// ══════════════════════════════════════════════════════════════════════════
// ⚙️ SETTINGS PAGE - Account & Preferences
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/services.dart';
import 'package:github_wallpaper/theme.dart';
import 'package:github_wallpaper/utils.dart';
import 'package:github_wallpaper/pages/onboarding_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;
  DateTime? _lastUpdate;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  void _loadSettings() {
    setState(() {
      _username = StorageService.getUsername();
      _autoUpdate = StorageService.getAutoUpdate();
      _lastUpdate = StorageService.getLastUpdate();
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // Fallback to hardcoded version
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? This will clear all your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      await StorageService.logout();

      if (!mounted) return;

      // Clear entire navigation stack so user can't go back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (route) => false,
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will remove cached contribution data. You\'ll need to sync again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
      _loadSettings();
    }
  }

  String _getTimeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing16),

          // Title
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeadline,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account and preferences',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBase,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

          // Account Section
          _buildAccountSection(),

          const SizedBox(height: AppTheme.spacing20),

          // Preferences Section
          _buildPreferencesSection(),

          const SizedBox(height: AppTheme.spacing20),

          // Data Section
          _buildDataSection(),

          const SizedBox(height: AppTheme.spacing20),

          // About Section
          _buildAboutSection(),

          const SizedBox(height: AppTheme.spacing20),

          // Logout Button
          _buildLogoutButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ACCOUNT SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Username
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.textWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GitHub Account',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Last Sync
          if (_lastUpdate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last synced: ${_getTimeSince(_lastUpdate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Auto Update Toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius10),
                ),
                child: const Icon(
                  Icons.autorenew,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto Update',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Refresh wallpaper when push notification arrives',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeBody,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoUpdate,
                onChanged: (value) async {
                  await StorageService.setAutoUpdate(value);
                  if (mounted) {
                    setState(() => _autoUpdate = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DATA SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDataSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Clear Cache Button
          _buildSettingButton(
            icon: Icons.cleaning_services,
            iconColor: AppTheme.warningOrange,
            title: 'Clear Cache',
            subtitle: 'Remove cached contribution data',
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ABOUT SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // App Version
          _buildSettingButton(
            icon: Icons.info_outline,
            iconColor: AppTheme.primaryBlue,
            title: 'Version',
            subtitle: _appVersion,
            onTap: null, // Read-only
          ),

          const SizedBox(height: 12),

          // Developer
          _buildSettingButton(
            icon: Icons.developer_mode,
            iconColor: AppTheme.accentPurple,
            title: 'Developer',
            subtitle: 'Adelli Rahulreddy',
            onTap: null, // Read-only
          ),

          const SizedBox(height: 12),

          // Help & Support
          _buildSettingButton(
            icon: Icons.chat_bubble_outline,
            iconColor: AppTheme.successGreen,
            title: 'Need Help?',
            subtitle: 'Chat on WhatsApp',
            trailing: Icons.open_in_new,
            onTap: () async {
              if (!context.mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final phone = AppStrings.supportPhone.replaceAll(RegExp(r'[^\d]'), '');
              final uri = Uri.parse('https://wa.me/$phone');

              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw Exception('Could not launch WhatsApp');
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ErrorHandler.getUserFriendlyMessage(e),
                    ),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SETTING BUTTON WIDGET
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSettingButton({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(
                trailing,
                color: AppTheme.textTertiary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // LOGOUT BUTTON
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorRed,
          side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLead,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
