import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/date_utils.dart';
import '../core/preferences.dart';
import '../models/contribution_data.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  CachedContributionData? _cachedData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  String _getMotivation(int streak) {
    if (streak == 0) return "Let's start a streak today! 🚀";
    if (streak < 3) return "Warming up the engines... 🏎️";
    if (streak < 7) return "You're consistent! Keep it up ⚡";
    if (streak < 14) return "You are on FIRE! 🔥";
    if (streak < 30) return "Unstoppable force! 🌪️";
    return "Legendary Status 👑";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: _cachedData == null
          ? _buildEmptyState()
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. HEADER
                _buildHeader(),

                // 2. MOTIVATION BANNER
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacing20,
                    AppTheme.spacing16,
                    AppTheme.spacing20,
                    AppTheme.spacing16,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildMotivationCard()),
                ),

                // 3. WEEKLY CHART
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                  sliver: SliverToBoxAdapter(child: _buildWeeklyChart()),
                ),

                SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing20)),

                // 4. STATS GRID
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                  sliver: SliverToBoxAdapter(child: _buildMainStatsGrid()),
                ),

                SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing20)),

                // 5. BEST DAY CARD
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacing20,
                    0,
                    AppTheme.spacing20,
                    100, // Bottom padding for nav bar
                  ),
                  sliver: SliverToBoxAdapter(child: _buildBestDayCard()),
                ),
              ],
            ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📋 HEADER - FIXED (No overflow)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacing20,
            AppTheme.spacing16,
            AppTheme.spacing20,
            AppTheme.spacing12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Statistics',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppTheme.spacing4),
              Text(
                '${AppDateUtils.getCurrentMonthName()} ${DateTime.now().year}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔥 MOTIVATION CARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMotivationCard() {
    final streak = _cachedData!.currentStreak;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandYellow.withOpacity(0.15),
            context.theme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.brandYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.brandYellow.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: AppTheme.brandYellow,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMotivation(streak),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppTheme.spacing4),
                Text(
                  '$streak Day Streak',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppTheme.brandYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📊 WEEKLY CHART
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildWeeklyChart() {
    final today = DateTime.now();

    // Generate data for last 7 days
    final weekDays = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dayName = AppDateUtils.getDayName(date).substring(0, 1);
      final count = _cachedData!.dailyContributions[date.day] ?? 0;
      return {'day': dayName, 'count': count, 'isToday': index == 6};
    });

    final maxCount = weekDays
        .map((e) => e['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Last 7 Days',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weekDays.map((data) {
                    final count = data['count'] as int;
                    final isToday = data['isToday'] as bool;
                    final heightPct = maxCount > 0 ? (count / maxCount) : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (count > 0) ...[
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? AppTheme.brandGreen
                                      : context.theme.hintColor,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing4),
                            ],

                            // Animated Bar
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: heightPct),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, _) {
                                return Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    minHeight: 4,
                                    maxHeight: 60,
                                  ),
                                  height: 4 + (56 * value),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? (isToday
                                              ? AppTheme.brandGreen
                                              : AppTheme.brandGreen.withOpacity(
                                                  0.5,
                                                ))
                                        : context.theme.hintColor.withOpacity(
                                            0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekDays.map((data) {
                  final isToday = data['isToday'] as bool;
                  return Expanded(
                    child: Text(
                      data['day'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday
                            ? context.textTheme.bodyLarge?.color
                            : context.theme.hintColor,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📈 STATS GRID
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMainStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppTheme.spacing12;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildStatBox(
                    label: 'Total Commits',
                    value: '${_cachedData!.totalContributions}',
                    icon: Icons.functions,
                    color: AppTheme.brandBlue,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatBox(
                    label: 'Today',
                    value: '${_cachedData!.todayCommits}',
                    icon: Icons.today,
                    color: AppTheme.brandGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildStatBox(
                    label: 'Max Streak',
                    value: '${_cachedData!.longestStreak}',
                    icon: Icons.history,
                    color: AppTheme.brandPurple,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatBox(
                    label: 'Average/Day',
                    value: _calculateAverage(),
                    icon: Icons.analytics_outlined,
                    color: AppTheme.brandBlue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _calculateAverage() {
    final dayOfMonth = DateTime.now().day;
    if (dayOfMonth == 0) return '0.0';
    return (_cachedData!.totalContributions / dayOfMonth).toStringAsFixed(1);
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.theme.hintColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🏆 BEST DAY CARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBestDayCard() {
    final entries = _cachedData!.dailyContributions.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    entries.sort((a, b) => b.value.compareTo(a.value));
    final bestDay = entries.first;

    if (bestDay.key > 31) return const SizedBox.shrink();

    final date = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      bestDay.key,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Personal Record',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.brandYellow.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandYellow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${bestDay.value} Commits',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandYellow,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${AppDateUtils.getDayName(date)}, ${AppDateUtils.getCurrentMonthName()} ${bestDay.key}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTheme.spacing12),
              Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.brandYellow,
                size: 40,
              ),
            ],
          ),
        ),
      ],
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
              Icons.bar_chart_rounded,
              size: 64,
              color: context.theme.hintColor.withOpacity(0.3),
            ),
            SizedBox(height: AppTheme.spacing16),
            Text('No stats available', style: context.textTheme.titleMedium),
            SizedBox(height: AppTheme.spacing8),
            Text(
              'Sync your data from the Dashboard',
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
