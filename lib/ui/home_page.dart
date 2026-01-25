// ══════════════════════════════════════════════════════════════════════════
// 🏠 HOME PAGE - Main Dashboard
// ══════════════════════════════════════════════════════════════════════════
// Central hub displaying stats, heatmap preview, and sync functionality
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/storage_service.dart';
import '../services/github_service.dart';
import '../services/wallpaper_service.dart';
import '../services/utils.dart';
import '../models/models.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CachedContributionData? _data;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load cached data and check if refresh needed
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cachedData = StorageService.getCachedData();
      if (cachedData != null) {
        setState(() {
          _data = cachedData;
          _isLoading = false;
        });

        if (cachedData.isStale(AppConfig.autoRefreshThreshold)) {
          await _syncData(silent: true);
        }
      } else {
        await _syncData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Fetch fresh data from GitHub
  Future<void> _syncData({bool silent = false}) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials not found. Please set up again.');
      }

      final service = GitHubService(token: token);
      final data = await service.fetchContributions(username);

      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());

      if (!mounted) return;

      setState(() {
        _data = data;
        _isSyncing = false;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SuccessBanner(message: AppStrings.syncSuccess),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isSyncing = false;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateWallpaper() async {
    if (_data == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(message: AppStrings.applying),
          ],
        ),
      ),
    );

    try {
      final config = WallpaperConfig(
        isDarkMode: StorageService.getDarkMode(),
        verticalPosition: StorageService.getVerticalPosition(),
        horizontalPosition: StorageService.getHorizontalPosition(),
        scale: StorageService.getScale(),
        opacity: StorageService.getOpacity(),
        customQuote: StorageService.getCustomQuote(),
        quoteFontSize: StorageService.getQuoteFontSize(),
        quoteOpacity: StorageService.getQuoteOpacity(),
        paddingTop: StorageService.getPaddingTop(),
        paddingBottom: StorageService.getPaddingBottom(),
        paddingLeft: StorageService.getPaddingLeft(),
        paddingRight: StorageService.getPaddingRight(),
        cornerRadius: StorageService.getCornerRadius(),
      );

      final target = StorageService.getWallpaperTarget();

      await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
        target: target,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SuccessBanner(message: AppStrings.wallpaperApplied),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update wallpaper: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'GitHub Wallpaper',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _syncData,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppTheme.textPrimary),
            tooltip: 'Sync data',
          ),
          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: RefreshIndicator(
          onRefresh: _syncData,
          color: AppTheme.primaryBlue,
          child: _buildBody(),
        ),
      ),
      floatingActionButton: _data != null
          ? FloatingActionButton.extended(
              onPressed: _updateWallpaper,
              backgroundColor: AppTheme.primaryBlue,
              icon: const Icon(Icons.wallpaper, color: Colors.white),
              label: const Text('Set Wallpaper',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              elevation: 8,
            ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack)
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return const LoadingIndicator(message: 'Loading your contributions...');
    }

    if (_errorMessage != null && _data == null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadData);
    }

    if (_data == null) {
      return EmptyState(
        icon: Icons.bar_chart,
        title: 'No Data Yet',
        message: 'Sync your GitHub contributions to get started.',
        actionLabel: 'Sync Now',
        onAction: _syncData,
      );
    }

    return _buildDashboard();
  }

  Widget _buildDashboard() {
    final username = StorageService.getUsername() ?? 'User';
    final topPadding = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        AppTheme.spacing16;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppTheme.spacing16, topPadding,
          AppTheme.spacing16, AppTheme.spacing64 + 40),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(username),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionHeader('Dashboard Overview', Icons.dashboard_outlined),
          const SizedBox(height: AppTheme.spacing16),
          _buildStatsGrid(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionHeader('Activity Heatmap', Icons.auto_graph_outlined),
          const SizedBox(height: AppTheme.spacing16),
          _buildHeatmapPreview(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionHeader('Explore & Configure', Icons.explore_outlined),
          const SizedBox(height: AppTheme.spacing16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              gradient: AppTheme.accentBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppTheme.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $username!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                Text(
                  'Keep the coding streak alive.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.animationNormal)
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacing16,
          crossAxisSpacing: AppTheme.spacing16,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Total Code',
              value: _data!.totalContributions.toString(),
              icon: Icons.code,
              color: AppTheme.primaryBlue,
              gradient: AppTheme.accentBlue,
            ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
            StatCard(
              label: 'Current Streak',
              value: '${_data!.currentStreak} d',
              icon: Icons.local_fire_department,
              color: AppTheme.alertOrange,
              gradient: AppTheme.accentOrange,
            ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms),
            StatCard(
              label: 'Longest Streak',
              value: '${_data!.longestStreak} d',
              icon: Icons.emoji_events,
              color: AppTheme.successGreen,
              gradient: AppTheme.accentGreen,
            ).animate().fadeIn(delay: 500.ms).scale(delay: 500.ms),
            StatCard(
              label: 'Today',
              value: '${_data!.todayCommits}',
              icon: Icons.today,
              color: AppTheme.brandPurple,
              gradient: AppTheme.accentPurple,
            ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),
          ],
        );
      },
    );
  }

  Widget _buildHeatmapPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateHelper.getCurrentMonthName(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  _buildLastUpdated(),
                ],
              ),
              TextButton(
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(1);
                  }
                },
                child: const Text('FULL STATS'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: HeatmapPainter(
                  data: _data!,
                  isDarkMode: isDark,
                  scale: 0.85,
                  verticalPosition: 0.5,
                  horizontalPosition: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLastUpdated() {
    final lastUpdate = StorageService.getLastUpdate();
    final timeAgo = lastUpdate != null
        ? DateHelper.formatRelativeTime(lastUpdate)
        : 'Never';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing6),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.spacing6),
          Text(
            'Updated $timeAgo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.palette_outlined,
            iconColor: AppTheme.primaryBlue,
            title: 'Visual Designer',
            subtitle: 'Customize colors, scale & position',
            index: 2,
          ),
          const Divider(indent: 70, endIndent: 20),
          _buildActionTile(
            icon: Icons.insights_outlined,
            iconColor: AppTheme.successGreen,
            title: 'Performance Insight',
            subtitle: 'Deep dive into your coding habits',
            index: 1,
          ),
          const Divider(indent: 70, endIndent: 20),
          _buildActionTile(
            icon: Icons.settings_outlined,
            iconColor: AppTheme.textSecondary,
            title: 'System Settings',
            subtitle: 'Account & sync preferences',
            index: 3,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing20, vertical: AppTheme.spacing8),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(index);
        }
      },
    );
  }
}
