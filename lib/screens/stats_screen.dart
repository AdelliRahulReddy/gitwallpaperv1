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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      setState(() {
        _cachedData = AppPreferences.getCachedData();
      });
    } catch (e) {
      debugPrint('StatsScreen: Error loading data: $e');
      setState(() {
        _cachedData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(context.screenPadding.left),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${AppDateUtils.getCurrentMonthName()} ${DateTime.now().year}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onBackground.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            if (_cachedData != null && _cachedData!.days.isNotEmpty)
              SliverPadding(
                padding: context.screenPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Main Stats Grid (2x2)
                    _buildMainStatsGrid(),

                    SizedBox(height: context.cardSpacing),

                    // Monthly Overview Card
                    _buildMonthlyOverviewCard(),

                    SizedBox(height: context.cardSpacing),

                    // Contribution Breakdown
                    _buildContributionBreakdown(),

                    SizedBox(height: context.cardSpacing),

                    // Weekly Activity
                    _buildWeeklyActivity(),

                    SizedBox(height: context.cardSpacing),

                    // Best Day Card
                    _buildBestDayCard(),

                    const SizedBox(height: AppTheme.spacing24),
                  ]),
                ),
              )
            else
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 64,
                        color: context.colorScheme.onBackground.withOpacity(
                          0.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        'No data available',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Sync your GitHub data first',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - context.cardSpacing) / 2;

        return Wrap(
          spacing: context.cardSpacing,
          runSpacing: context.cardSpacing,
          children: [
            _buildStatCard(
              icon: Icons.commit_outlined,
              value: '${_cachedData!.totalContributions}',
              label: 'Total Contributions',
              color: const Color(0xFF26A641),
              width: cardWidth,
            ),
            _buildStatCard(
              icon: Icons.local_fire_department_outlined,
              value: '${_cachedData!.currentStreak}',
              label: 'Current Streak',
              color: const Color(0xFFFF9500),
              width: cardWidth,
              suffix: ' days',
            ),
            _buildStatCard(
              icon: Icons.trending_up_outlined,
              value: '${_cachedData!.longestStreak}',
              label: 'Longest Streak',
              color: const Color(0xFFA371F7),
              width: cardWidth,
              suffix: ' days',
            ),
            _buildStatCard(
              icon: Icons.calendar_today_outlined,
              value: '${_cachedData!.todayCommits}',
              label: 'Today',
              color: const Color(0xFF58A6FF),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required double width,
    String suffix = '',
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: context.colorScheme.onBackground.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(height: AppTheme.spacing16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (suffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacing4,
                    bottom: AppTheme.spacing4,
                  ),
                  child: Text(
                    suffix,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing4),

          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewCard() {
    final monthName = AppDateUtils.getCurrentMonthName();
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    // ✅ FIXED: Guard against division by zero
    final progress = currentDay > 0 ? currentDay / daysInMonth : 0.0;
    final averageDaily = currentDay > 0
        ? _cachedData!.totalContributions / currentDay
        : 0.0;
    final projectedTotal = currentDay > 0
        ? (averageDaily * daysInMonth).round()
        : 0;

    return Card(
      child: Padding(
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
                      '$monthName Overview',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'Day $currentDay of $daysInMonth',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onBackground.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing20),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.spacing8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: context.colorScheme.onBackground.withOpacity(
                  0.1,
                ),
                valueColor: AlwaysStoppedAnimation(context.primaryColor),
              ),
            ),

            const SizedBox(height: AppTheme.spacing20),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    label: 'Average/Day',
                    value: averageDaily.toStringAsFixed(1),
                    color: const Color(0xFF58A6FF),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: context.colorScheme.onBackground.withOpacity(0.1),
                ),
                Expanded(
                  child: _buildMetricItem(
                    label: 'Projected Total',
                    value: '$projectedTotal',
                    color: const Color(0xFF26A641),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: context.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContributionBreakdown() {
    final activeDays = _cachedData!.dailyContributions.values
        .where((count) => count > 0)
        .length;
    final inactiveDays = AppDateUtils.getCurrentDayOfMonth() - activeDays;

    // ✅ FIXED: Safe reduce with fallback
    final maxDaily = _cachedData!.dailyContributions.values.isNotEmpty
        ? _cachedData!.dailyContributions.values.reduce(
            (max, count) => count > max ? count : max,
          )
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contribution Breakdown',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppTheme.spacing20),

            _buildBreakdownRow(
              icon: Icons.check_circle_outline,
              label: 'Active Days',
              value: '$activeDays',
              color: const Color(0xFF26A641),
            ),

            const SizedBox(height: AppTheme.spacing12),

            _buildBreakdownRow(
              icon: Icons.cancel_outlined,
              label: 'Inactive Days',
              value: '$inactiveDays',
              color: const Color(0xFF8B949E),
            ),

            const SizedBox(height: AppTheme.spacing12),

            _buildBreakdownRow(
              icon: Icons.stars_outlined,
              label: 'Max in a Day',
              value: '$maxDaily',
              color: const Color(0xFFA371F7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: AppTheme.spacing12),

        Expanded(child: Text(label, style: context.textTheme.bodyLarge)),

        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyActivity() {
    final today = DateTime.now();
    final weekDays = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dayName = AppDateUtils.getDayName(date);
      final contributions = _cachedData!.dailyContributions[date.day] ?? 0;
      return {'day': dayName, 'count': contributions, 'date': date};
    });

    final maxCount = weekDays
        .map((d) => d['count'] as int)
        .reduce((max, count) => count > max ? count : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppTheme.spacing20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekDays.map((day) {
                final count = day['count'] as int;
                final height = (maxCount > 0 ? (count / maxCount) * 100 : 10.0);
                final isToday = (day['date'] as DateTime).day == today.day;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing4,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: count > 0
                                ? const Color(0xFF26A641)
                                : context.colorScheme.onBackground.withOpacity(
                                    0.4,
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Container(
                          height: height.clamp(10.0, 100.0),
                          decoration: BoxDecoration(
                            color: count > 0
                                ? const Color(0xFF26A641)
                                : context.colorScheme.onBackground.withOpacity(
                                    0.1,
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.spacing4),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          (day['day'] as String).substring(0, 1),
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? context.primaryColor
                                : context.colorScheme.onBackground.withOpacity(
                                    0.6,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDayCard() {
    final entries = _cachedData!.dailyContributions.entries.toList();

    // ✅ FIXED: Check if entries is empty before accessing
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    final bestDay = entries.first;
    final date = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      bestDay.key,
    );
    final dayName = AppDateUtils.getDayName(date);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withOpacity(0.1),
              const Color(0xFFFF9500).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),

            const SizedBox(width: AppTheme.spacing16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best Day',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '$dayName, ${AppDateUtils.getCurrentMonthName()} ${bestDay.key}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '${bestDay.value}',
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
