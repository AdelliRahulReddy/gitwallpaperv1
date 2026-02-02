// ══════════════════════════════════════════════════════════════════════════
// 🏠 HOME PAGE - Production Dashboard
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/services.dart';
import 'package:github_wallpaper/models.dart';
import 'package:github_wallpaper/theme.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;

  const HomePage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Motivation quotes for the "Daily Inspiration" card
  static const List<String> _quotes = [
    "Code is poetry written with logic.",
    "Consistency is the key to mastery.",
    "Small commits every day lead to big changes.",
    "Don't wish for it, work for it.",
    "Your future is created by what you do today.",
    "Focus on progress, not perfection.",
    "Every error is a learning opportunity.",
    "Build things that matter.",
  ];

  String _getRandomQuote() {
    final index = DateTime.now().day % _quotes.length;
    return _quotes[index];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final username = StorageService.getUsername() ?? 'Developer';

    if (widget.isLoading && widget.data == null) {
      return _buildLoadingState();
    }

    if (widget.loadError != null && widget.data == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 1. Production Header
            _buildDashboardHeader(username),
            if (widget.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppTheme.bgWhite,
                color: AppTheme.primaryBlue,
              ),

            // 2. Main Content
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20, vertical: AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.loadError != null && widget.data != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.warningOrange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.warningOrange,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Text(
                              widget.loadError!,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeBase,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                  ],
                  if (widget.data != null) ...[
                    // New: Today's Hero Card
                    _buildTodayHeroCard(widget.data!),
                    const SizedBox(height: AppTheme.spacing24),

                    // Stats Grid
                    _buildStatsGrid(widget.data!),

                    const SizedBox(height: AppTheme.spacing24),

                    // Heatmap
                    _buildHeatmapContainer(widget.data!),

                    const SizedBox(height: AppTheme.spacing24),

                    // Weekend vs Weekday
                    _buildWeekendAnalysis(widget.data!),

                    const SizedBox(height: AppTheme.spacing24),

                    // Contribution Level Breakdown
                    _buildContributionBreakdown(widget.data!),

                    const SizedBox(height: AppTheme.spacing24),

                    // Motivation Card
                    _buildMotivationCard(),
                  ],
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDashboardHeader(String username) {
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing24, AppTheme.spacing24, AppTheme.spacing24, AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radius2XLarge)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${_getGreeting()},',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeTitle,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeDisplay,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Avatar / Profile Icon
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded,
                  color: AppTheme.primaryBlue, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TODAY HERO CARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildTodayHeroCard(CachedContributionData data) {
    // Determine status
    String status = "Ready to Start";
    Color statusColor = AppTheme.textSecondary;
    IconData statusIcon = Icons.hourglass_empty;

    if (data.todayCommits > 0) {
      status = "On Track";
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle;
    }
    if (data.todayCommits >= 5) {
      status = "On Fire!";
      statusColor = AppTheme.statOrange;
      statusIcon = Icons.local_fire_department;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        gradient: const LinearGradient(
          colors: [AppTheme.githubDarkBg, AppTheme.githubDarkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius2XLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Circular Progress or Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.2),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(
                '${data.todayCommits}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeHeadline,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Contribution",
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeBase,
                    color: AppTheme.whiteMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATS GRID
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(CachedContributionData data) {
    return Column(
      children: [
        // Row 1: 3-Column Key Stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                label: 'Streak',
                value: '${data.currentStreak}',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.statOrange,
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _StatCard(
                label: 'Best',
                value: '${data.longestStreak}',
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.statAmber,
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: _formatCompact(data.totalContributions),
                icon: Icons.diamond_rounded,
                iconColor: AppTheme.statBlue,
                isCompact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Row 2: 2-Column Insights
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                label: 'Peak Day',
                value: '${data.peakDay}',
                suffix: ' commits',
                icon: Icons.landscape_rounded,
                iconColor: AppTheme.statPurple,
                bgColor: AppTheme.bgWhite,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _StatCard(
                label: 'Active Day',
                value: data.mostActiveWeekday,
                icon: Icons.calendar_today_rounded,
                iconColor: AppTheme.statTeal,
                bgColor: AppTheme.bgWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCompact(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }

  Color _heatmapColor(int level) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    if (ext != null && level >= 0 && level < ext.heatmapLevels.length) {
      return ext.heatmapLevels[level];
    }
    return AppThemeExtension.light().heatmapLevels[level.clamp(0, 4)];
  }

  // ══════════════════════════════════════════════════════════════════════
  // HEATMAP (Real Grid)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildHeatmapContainer(CachedContributionData data) {
    final displayDays =
        data.days.length > 180 ? data.days.sublist(data.days.length - 180) : data.days;
    final displayTotal = displayDays.fold<int>(
      0,
      (sum, d) => sum + d.contributionCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity Graph',
              style: TextStyle(
                fontSize: AppTheme.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Last 6 Months',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        Semantics(
          label:
              'Activity graph for the last 6 months. Total contributions: $displayTotal. Current streak: ${data.stats.currentStreak} days. Longest streak: ${data.stats.longestStreak} days.',
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: AppTheme.whiteCard(),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: displayDays.isEmpty
                ? const Center(child: Text("No activity data available"))
                : _ScrollableHeatmapGrid(days: displayDays, heatmapColor: _heatmapColor),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // WEEKEND & LEVELS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildWeekendAnalysis(CachedContributionData data) {
    int weekendTotal = 0;
    int weekdayTotal = 0;

    for (var day in data.days) {
      if (day.date.weekday >= 6) {
        weekendTotal += day.contributionCount;
      } else {
        weekdayTotal += day.contributionCount;
      }
    }

    final total = weekendTotal + weekdayTotal;
    final weekendPct = total > 0 ? weekendTotal / total : 0.0;
    final weekdayPct = total > 0 ? weekdayTotal / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekend Warrior?',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: total > 0 ? ((weekdayPct * 100).toInt()).clamp(1, 99) : 1,
                    child: Container(color: AppTheme.primaryBlue),
                  ),
                  Expanded(
                    flex: total > 0 ? ((weekendPct * 100).toInt()).clamp(1, 99) : 1,
                    child: Container(color: AppTheme.statOrange),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                  'Weekdays',
                  '$weekdayTotal',
                  '${(weekdayPct * 100).toStringAsFixed(0)}%',
                  AppTheme.primaryBlue),
              _buildMiniStat('Weekends', '$weekendTotal',
                  '${(weekendPct * 100).toStringAsFixed(0)}%', AppTheme.statOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: AppTheme.fontSizeBody, color: AppTheme.textSecondary)),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                Text(' ($pct)',
                    style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall, color: AppTheme.textTertiary)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContributionBreakdown(CachedContributionData data) {
    final levels = [0, 0, 0, 0, 0]; // 0, 1, 2, 3, 4

    for (var day in data.days) {
      if (day.contributionCount == 0) continue;
      // Using intensityLevel getter from ContributionDay (0-4)
      if (day.intensityLevel >= 0 && day.intensityLevel < levels.length) {
        levels[day.intensityLevel]++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Impact Level',
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLevelCard(
                'Low', '${levels[1]}', _heatmapColor(1)),
            _buildLevelCard(
                'Med', '${levels[2]}', _heatmapColor(2)),
            _buildLevelCard(
                'High', '${levels[3]}', _heatmapColor(3)),
            _buildLevelCard(
                'Max', '${levels[4]}', _heatmapColor(4)),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(count,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeLead,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: AppTheme.spacing4),
            Text(label,
                style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall, color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spacing8),
            Container(
                width: 20,
                height: AppTheme.spacing4,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(AppTheme.radiusXSmall))),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MOTIVATION CARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.githubDarkBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.githubDarkBg.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [AppTheme.githubDarkCard, AppTheme.githubDarkBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppTheme.whiteSubtle, size: 30),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            _getRandomQuote(),
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.w500,
              height: 1.5,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.textWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(color: AppTheme.whiteBorder),
                ),
                child: const Text(
                  'Daily Insight',
                  style: TextStyle(
                    color: AppTheme.whiteMuted,
                    fontSize: AppTheme.fontSizeCaption,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // LOADING & ERROR STATES
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
          const SizedBox(height: AppTheme.spacing16),
          Text(widget.loadError ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
              onPressed: widget.onRefresh, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isCompact;

  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
    required this.iconColor,
    this.bgColor = AppTheme.bgWhite,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 100 : 120),
      padding: EdgeInsets.all(isCompact ? AppTheme.spacing12 : AppTheme.spacing16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              size: isCompact ? 18 : 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isCompact ? AppTheme.fontSizeXLarge : AppTheme.fontSizeHeadline,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (suffix != null && !isCompact)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppTheme.spacing4),
                        child: Text(
                          suffix!,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeCaption,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? AppTheme.fontSizeSmall : AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollableHeatmapGrid extends StatelessWidget {
  final List<ContributionDay> days;
  final Color Function(int level) heatmapColor;

  const _ScrollableHeatmapGrid({
    required this.days,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    // Process data into weeks (last ~180 days)
    final displayDays =
        days.length > 180 ? days.sublist(days.length - 180) : days;
    if (displayDays.isEmpty) {
      return const Center(child: Text('No activity data'));
    }

    // Group by calendar week: week start = Sunday (row 0), then Mon..Sat (rows 1..6).
    // Dart: weekday 1=Mon, 7=Sun → index 0=Sun is weekday % 7 (7→0, 1→1, ..., 6→6).
    final Map<String, List<ContributionDay?>> weekKeyToSlots = {};
    for (var day in displayDays) {
      final d = day.date;
      final weekStart = DateTime(d.year, d.month, d.day)
          .subtract(Duration(days: d.weekday % 7));
      final key = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      weekKeyToSlots.putIfAbsent(key, () => List.filled(7, null));
      weekKeyToSlots[key]![d.weekday % 7] = day;
    }

    final sortedKeys = weekKeyToSlots.keys.toList()..sort();
    final List<List<ContributionDay?>> weeks =
        sortedKeys.map((k) => List<ContributionDay?>.from(weekKeyToSlots[k]!)).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      reverse: true, // Show newest on the right
      itemCount: weeks.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing4),
      itemBuilder: (context, index) {
        // Reverse indexing logic for reverse list view
        // index 0 is the NEWEST week (last in our list)
        final weekData = weeks[weeks.length - 1 - index];

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (dayIndex) {
            final day = weekData[dayIndex];
            return _HeatmapCell(day: day, heatmapColor: heatmapColor);
          }),
        );
      },
      padding: EdgeInsets.zero,
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final ContributionDay? day;
  final Color Function(int level) heatmapColor;

  const _HeatmapCell({
    required this.day,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox.square(dimension: 22);
    }

    final color = _getColorForLevel(day!.contributionCount);

    // Format date carefully
    final dateStr =
        "${day!.date.year}-${day!.date.month.toString().padLeft(2, '0')}-${day!.date.day.toString().padLeft(2, '0')}";

    return Semantics(
      button: true,
      label: '$dateStr. ${day!.contributionCount} commits.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppTheme.bgWhite,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        '${day!.contributionCount} commits',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLead,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForLevel(int count) {
    if (count == 0) return AppTheme.bgLight.withValues(alpha: 0.5);
    if (count <= 3) return heatmapColor(1);
    if (count <= 6) return heatmapColor(2);
    if (count <= 9) return heatmapColor(3);
    return heatmapColor(4);
  }
}
