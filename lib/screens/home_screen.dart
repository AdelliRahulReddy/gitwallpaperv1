import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import '../core/wallpaper_service.dart';
import '../models/contribution_data.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🏠 HOME SCREEN - MISSION CONTROL DASHBOARD
// ══════════════════════════════════════════════════════════════════════════
// No preview - Focus on insights, actions, and motivation
// ══════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;
  CachedContributionData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoRefreshOnOpen();
  }

  void _loadData() {
    setState(() {
      try {
        _cachedData = AppPreferences.getCachedData();
      } catch (e) {
        _cachedData = null;
      }
    });
  }

  Future<void> _autoRefreshOnOpen() async {
    try {
      final lastUpdate = AppPreferences.getLastUpdate();
      final now = DateTime.now();

      if (_cachedData == null ||
          lastUpdate == null ||
          now.difference(lastUpdate).inHours >= 6) {
        await _refreshData(showSnackbar: false);
      }
    } catch (e) {
      debugPrint('Auto-refresh failed: $e');
    }
  }

  Future<void> _refreshData({bool showSnackbar = true}) async {
    if (_isRefreshing) return;

    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    try {
      final username = AppPreferences.getUsername();
      final token = await AppPreferences.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials missing');
      }

      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      final target = AppPreferences.getWallpaperTarget();
      await WallpaperService.refreshAndSetWallpaper(target: target);

      _loadData();

      if (mounted && showSnackbar) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppTheme.spacing12),
                const Text('Synced & wallpaper updated!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header with Greeting
          _buildHeroHeader(),

          // Motivation Card
          if (_cachedData != null) ...[
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
              sliver: SliverToBoxAdapter(child: _buildMotivationHero()),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing24)),

            // Today's Focus
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
              sliver: SliverToBoxAdapter(child: _buildTodayFocus()),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing24)),

            // Quick Actions
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
              sliver: SliverToBoxAdapter(child: _buildQuickActions()),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing24)),

            // Achievements
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
              sliver: SliverToBoxAdapter(child: _buildAchievements()),
            ),
          ],

          // Empty State
          if (_cachedData == null)
            SliverFillRemaining(child: _buildEmptyState()),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 👋 HERO HEADER
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getGreeting(),
                      style: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing4),
                    if (_cachedData != null)
                      Text(
                        '@${_cachedData!.username}',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // Sync Button
              Container(
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isRefreshing ? null : () => _refreshData(),
                  icon: _isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Sync Now',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good\nMorning';
    if (hour < 17) return 'Good\nAfternoon';
    return 'Good\nEvening';
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔥 MOTIVATION HERO
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMotivationHero() {
    final streak = _cachedData!.currentStreak;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandYellow.withOpacity(0.2),
            AppTheme.brandYellow.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppTheme.brandYellow.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.brandYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: AppTheme.brandYellow,
                  size: 32,
                ),
              ),
              SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak Day Streak',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandYellow,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing4),
                    Text(
                      _getMotivation(streak),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  String _getMotivation(int streak) {
    if (streak == 0) return "Start your journey today! 🚀";
    if (streak < 3) return "Building momentum... 💪";
    if (streak < 7) return "You're on fire! Keep going! 🔥";
    if (streak < 14) return "Unstoppable! 🌟";
    if (streak < 30) return "Legendary commitment! 👑";
    return "Hall of Fame! 🏆";
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎯 TODAY'S FOCUS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTodayFocus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Today',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildFocusCard(
                icon: Icons.commit_rounded,
                value: '${_cachedData!.todayCommits}',
                label: 'Commits',
                color: AppTheme.brandGreen,
                isLarge: true,
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
            ),
            SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildFocusCard(
                icon: Icons.calendar_today,
                value: '${DateTime.now().day}',
                label: _getMonthShort(),
                color: AppTheme.brandBlue,
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isLarge ? 32 : 24),
          SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style:
                (isLarge
                        ? context.textTheme.displaySmall
                        : context.textTheme.headlineMedium)
                    ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.theme.hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthShort() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[DateTime.now().month - 1];
  }

  // ════════════════════════════════════════════════════════════════════════
  // ⚡ QUICK ACTIONS - FIXED
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            // Apply Wallpaper
            Expanded(
              child: _buildActionCard(
                icon: Icons.wallpaper,
                title: 'Apply Now',
                subtitle: 'Update wallpaper',
                color: AppTheme.brandPurple,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    final target = AppPreferences.getWallpaperTarget();
                    await WallpaperService.refreshAndSetWallpaper(
                      target: target,
                    );
                    if (mounted) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              SizedBox(width: AppTheme.spacing12),
                              const Text('Wallpaper applied!'),
                            ],
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            ),

            SizedBox(width: AppTheme.spacing12),

            // Refresh Data
            Expanded(
              child: _buildActionCard(
                icon: Icons.refresh,
                title: 'Refresh',
                subtitle: 'Sync data now',
                color: AppTheme.brandBlue,
                onTap: () {
                  _refreshData();
                },
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🏆 ACHIEVEMENTS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Milestones',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing12),
        _buildAchievementItem(
          icon: Icons.emoji_events,
          title: 'Total Contributions',
          value: '${_cachedData!.totalContributions}',
          color: AppTheme.brandYellow,
        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2, end: 0),
        SizedBox(height: AppTheme.spacing12),
        _buildAchievementItem(
          icon: Icons.trending_up,
          title: 'Longest Streak',
          value: '${_cachedData!.longestStreak} days',
          color: AppTheme.brandGreen,
        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
                Text(
                  value,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.theme.hintColor,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📭 EMPTY STATE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_sync_outlined,
              size: 80,
              color: context.theme.hintColor.withOpacity(0.3),
            ),
            SizedBox(height: AppTheme.spacing24),
            Text(
              'Ready to Sync',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacing8),
            Text(
              'Tap the sync button to fetch your\nGitHub contributions',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
