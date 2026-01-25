// ══════════════════════════════════════════════════════════════════════════
// 📊 STATS PAGE - Detailed Contribution Statistics
// ══════════════════════════════════════════════════════════════════════════
// Comprehensive analytics, charts, and detailed contribution breakdown
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/storage_service.dart';
import '../services/github_service.dart';
import '../services/utils.dart';
import '../models/models.dart';
import 'theme.dart';
import 'widgets.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  CachedContributionData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

  Future<void> _syncData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials not found');
      }

      final service = GitHubService(token: token);
      final data = await service.fetchContributions(username);

      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SuccessBanner(message: 'Stats updated! ✅'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Detailed Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _syncData,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppTheme.textPrimary),
            tooltip: 'Refresh',
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
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return const LoadingIndicator(message: 'Analyzing your contributions...');
    }

    if (_errorMessage != null && _data == null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadData);
    }

    if (_data == null) {
      return EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No Data Found',
        message: 'Sync your contributions to view detailed analytics.',
        actionLabel: 'Sync Now',
        onAction: _syncData,
      );
    }

    return _buildStats();
  }

  Widget _buildStats() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + AppTheme.spacing16;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppTheme.spacing16, topPadding, AppTheme.spacing16, AppTheme.spacing32),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionTitle('Key Performance Metrics', Icons.query_stats),
          const SizedBox(height: AppTheme.spacing16),
          _buildMetricsGrid(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionTitle('Contribution Calendar', Icons.calendar_view_month),
          const SizedBox(height: AppTheme.spacing16),
          _buildHeatmapCard(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionTitle('Weekly Activity Breakdown', Icons.bar_chart),
          const SizedBox(height: AppTheme.spacing16),
          _buildActivityCard(),
          const SizedBox(height: AppTheme.spacing32),
          _buildSectionTitle('Contribution Density', Icons.layers_outlined),
          const SizedBox(height: AppTheme.spacing16),
          _buildLevelsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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

  Widget _buildMonthHeader() {
    final monthName = DateHelper.getCurrentMonthName();
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName $year',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      '${_data!.days.length} days of coding history',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryHeaderItem('TOTAL', _data!.totalContributions.toString(), AppTheme.primaryBlue),
              _buildSummaryHeaderItem('ACTIVE', _data!.activeDaysCount.toString(), AppTheme.successGreen),
              _buildSummaryHeaderItem('AVG/DAY', _data!.averagePerActiveDay.toStringAsFixed(1), AppTheme.alertOrange),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryHeaderItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacing16,
          crossAxisSpacing: AppTheme.spacing16,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Current Streak',
              value: '${_data!.currentStreak} d',
              icon: Icons.local_fire_department,
              color: AppTheme.alertOrange,
              gradient: AppTheme.accentOrange,
            ).animate().fadeIn(delay: 100.ms).scale(delay: 100.ms),
            StatCard(
              label: 'Longest Streak',
              value: '${_data!.longestStreak} d',
              icon: Icons.emoji_events,
              color: AppTheme.successGreen,
              gradient: AppTheme.accentGreen,
            ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
            StatCard(
              label: 'Average Commits',
              value: _data!.averagePerActiveDay.toStringAsFixed(1),
              icon: Icons.analytics,
              color: AppTheme.primaryBlue,
              gradient: AppTheme.accentBlue,
            ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
            StatCard(
              label: 'Active Ratio',
              value: '${((_data!.activeDaysCount / _data!.days.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.pie_chart,
              color: AppTheme.brandPurple,
              gradient: AppTheme.accentPurple,
            ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms),
          ],
        );
      },
    );
  }

  Widget _buildHeatmapCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: HeatmapPainter(
                data: _data!,
                isDarkMode: isDark,
                scale: 0.85,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Visual history of your contributions over the past month.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityCard() {
    final weekdayContributions = <int, int>{};
    for (int i = 1; i <= 7; i++) {
        weekdayContributions[i] = 0;
    }

    for (var day in _data!.days) {
      final weekday = day.date.weekday;
      weekdayContributions[weekday] = (weekdayContributions[weekday] ?? 0) + day.contributionCount;
    }

    final maxVal = weekdayContributions.values.isEmpty ? 1 : weekdayContributions.values.reduce((a, b) => a > b ? a : b);
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final count = weekdayContributions[weekday] ?? 0;
          final percentage = maxVal > 0 ? count / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    weekdayNames[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentBlue,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                      ).animate().scaleX(duration: 800.ms, curve: Curves.easeOutBack, alignment: Alignment.centerLeft),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                SizedBox(
                  width: 30,
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLevelsCard() {
    final levels = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
    for (var day in _data!.days) {
      final level = day.intensityLevel;
      levels[level] = (levels[level] ?? 0) + 1;
    }

    final levelNames = [
      'Quiet Days',
      'Low Activity',
      'Balanced',
      'High Output',
      'Peak Coding',
    ];

    final levelColors = [
      AppConfig.heatmapLightBox,
      AppConfig.heatmapLightLevel1,
      AppConfig.heatmapLightLevel2,
      AppConfig.heatmapLightLevel3,
      AppConfig.heatmapLightLevel4,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        children: List.generate(5, (index) {
          final count = levels[index] ?? 0;
          final percentage = _data!.days.isEmpty ? 0 : (count / _data!.days.length * 100);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: levelColors[index],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Text(
                    levelNames[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Text(
                  '$count d (${percentage.toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0);
  }
}
