// ══════════════════════════════════════════════════════════════════════════
// 🏠 HOME PAGE - Production Dashboard
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_state.dart';
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
  static const int _daysInSixMonths = 180;
  static const int _trendDays = 30;



  Color _heatmapColor(int level) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    if (ext != null && level >= 0 && level < ext.heatmapLevels.length) {
      return ext.heatmapLevels[level];
    }
    return AppThemeExtension.light().heatmapLevels[level.clamp(0, 4)];
  }

  TrendSummary _computeTrend(List<ContributionDay> days, {required int window}) {
    if (days.isEmpty) {
      return const TrendSummary(current: 0, previous: 0);
    }

    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<int> counts = sorted.map((d) => d.contributionCount).toList();
    final end = counts.length;
    final start = (end - window).clamp(0, end);
    final prevStart = (start - window).clamp(0, start);

    final current = counts.sublist(start, end).fold<int>(0, (a, b) => a + b);
    final previous =
        counts.sublist(prevStart, start).fold<int>(0, (a, b) => a + b);
    return TrendSummary(current: current, previous: previous);
  }

  List<ContributionDay> _sortedDays(List<ContributionDay> days) {
    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  List<ContributionDay> _lastDays(List<ContributionDay> days, int count) {
    if (days.isEmpty) return const [];
    final sorted = _sortedDays(days);
    final start = (sorted.length - count).clamp(0, sorted.length);
    return sorted.sublist(start);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final username = StorageService.getUsername() ?? 'Developer';

    if (widget.isLoading && widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadError != null && widget.data == null) {
      return _buildErrorState();
    }

    final data = widget.data;
    final trend7d = data == null
        ? const TrendSummary(current: 0, previous: 0)
        : _computeTrend(data.days, window: 7);
    final trend30d = data == null
        ? const TrendSummary(current: 0, previous: 0)
        : _computeTrend(data.days, window: 30);

    final titleDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: scheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: AppTheme.spacing20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleDate.toUpperCase(),
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontSizeCaption,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${PresentationFormatter.getGreeting()}, $username',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: AppTheme.fontSizeTitle,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: widget.isLoading ? null : widget.onRefresh,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottom: widget.isLoading
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  )
                : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing20,
              AppTheme.spacing16,
              AppTheme.spacing20,
              AppTheme.spacing32,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (widget.loadError != null && data != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: scheme.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Text(
                              widget.loadError!,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontSize: AppTheme.fontSizeBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                  ],
                  if (data == null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(
                            title: 'No data yet',
                            subtitle: 'Pull to refresh to sync your GitHub activity.',
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.onRefresh,
                              child: const Text('Sync Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildOverview(
                      data,
                      trend7d: trend7d,
                      trend30d: trend30d,
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildTrendsSection(data),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildHeatmapSection(data),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildRepositoriesSection(data),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildLanguagesSection(data),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildActivityInsights(data),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    CachedContributionData data, {
    required TrendSummary trend7d,
    required TrendSummary trend30d,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final updated = 'Updated ${PresentationFormatter.formatTimeAgoCompact(data.lastUpdated)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Overview',
          subtitle: updated,
          trailing: FilledButton.tonalIcon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Sync'),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w >= 980 ? 4 : w >= 680 ? 3 : 2;
            final aspect = w >= 680 ? 1.9 : 1.75;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppTheme.spacing12,
              mainAxisSpacing: AppTheme.spacing12,
              childAspectRatio: aspect,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricTile(
                  label: 'Total commits',
                  value: PresentationFormatter.formatCompactNumber(data.totalContributions),
                  icon: Icons.commit_rounded,
                  iconColor: scheme.primary,
                ),
                MetricTile(
                  label: 'Today',
                  value: '${data.todayCommits}',
                  icon: Icons.today_rounded,
                  iconColor: scheme.secondary,
                ),
                MetricTile(
                  label: 'Current streak',
                  value: '${data.currentStreak}d',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.statOrange,
                ),
                MetricTile(
                  label: 'Longest streak',
                  value: '${data.longestStreak}d',
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.statPurple,
                ),
                MetricTile(
                  label: 'Active repos',
                  value: '${data.activeRepositoriesCount}',
                  icon: Icons.inventory_2_rounded,
                  iconColor: scheme.primary,
                ),
                MetricTile(
                  label: 'Active days',
                  value: '${data.activeDaysCount}',
                  icon: Icons.event_available_rounded,
                  iconColor: scheme.secondary,
                ),
                MetricTile(
                  label: '7-day trend',
                  value: PresentationFormatter.formatCompactNumber(trend7d.current),
                  helper: trend7d.deltaLabel,
                  icon: Icons.show_chart_rounded,
                  iconColor: scheme.primary,
                ),
                MetricTile(
                  label: '30-day trend',
                  value: PresentationFormatter.formatCompactNumber(trend30d.current),
                  helper: trend30d.deltaLabel,
                  icon: Icons.timeline_rounded,
                  iconColor: scheme.primary,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeatmapSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final days = data.days.length > _daysInSixMonths
        ? data.days.sublist(data.days.length - _daysInSixMonths)
        : data.days;
    final total = days.fold<int>(0, (sum, d) => sum + d.contributionCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Activity graph',
          subtitle: 'Last 6 months • ${PresentationFormatter.formatCompactNumber(total)} commits',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: AppTheme.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  ...List.generate(
                    5,
                    (i) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _heatmapColor(i),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXSmall),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    'More',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: AppTheme.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                height: 200,
                child: days.isEmpty
                    ? Center(
                        child: Text(
                          'No activity data available',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                      )
                    : _ScrollableHeatmapGrid(
                        days: days,
                        quartiles: data.quartiles,
                        heatmapColor: _heatmapColor,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final days = _lastDays(data.days, _trendDays);
    final values = days.map((d) => d.contributionCount.toDouble()).toList();
    final total = days.fold<int>(0, (a, d) => a + d.contributionCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Commit frequency',
          subtitle: 'Last $_trendDays days • ${PresentationFormatter.formatCompactNumber(total)} commits',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                child: values.isEmpty
                    ? Center(
                        child: Text(
                          'No recent activity to chart.',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _SparklineChart(
                        values: values,
                        lineColor: scheme.primary,
                        fillColor: scheme.primary,
                        onIndexSelected: (index) {
                          final day = days[index];
                          final label = DateFormat('EEE, d MMM')
                              .format(day.date.toLocal());
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: scheme.surface,
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
                                      label,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: AppTheme.fontSizeTitle,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing12),
                                    Text(
                                      '${day.contributionCount} commits',
                                      style: TextStyle(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.72),
                                        fontSize: AppTheme.fontSizeLead,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing20),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Tap the chart to inspect a day.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.60),
                  fontSize: AppTheme.fontSizeCaption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepositoriesSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final repos = data.repositories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Active repositories',
          subtitle: '${data.activeRepositoriesCount} repositories with commits',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          padding: EdgeInsets.zero,
          child: repos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  child: Text(
                    'No repository activity found for this period.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: repos.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.55),
                  ),
                  itemBuilder: (context, index) {
                    final r = repos[index];
                    final lang = r.primaryLanguageName;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: 6,
                      ),
                      title: Text(
                        r.nameWithOwner,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: lang == null || lang.isEmpty
                          ? null
                          : Text(
                              lang,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      trailing: Text(
                        '${PresentationFormatter.formatCompactNumber(r.commitCount)} commits',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w700,
                          fontSize: AppTheme.fontSizeBody,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final langs = data.topLanguages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Top languages',
          subtitle: 'Estimated from your active repositories',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          child: langs.isEmpty
              ? Text(
                  'No language data available for this period.',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  children: [
                    for (final l in langs) ...[
                      _LanguageRow(
                        name: l.name,
                        color: _parseHexColor(l.color) ?? scheme.primary,
                        percent: l.percent,
                      ),
                      if (l != langs.last)
                        const SizedBox(height: AppTheme.spacing12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActivityInsights(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    int weekendTotal = 0;
    int weekdayTotal = 0;
    final levels = [0, 0, 0, 0, 0];

    for (final day in data.days) {
      if (day.date.weekday >= 6) {
        weekendTotal += day.contributionCount;
      } else {
        weekdayTotal += day.contributionCount;
      }

      if (day.contributionCount == 0) continue;
      final level = RenderUtils.getContributionLevel(
        day.contributionCount,
        quartiles: data.quartiles,
      );
      if (level >= 0 && level < levels.length) levels[level]++;
    }

    final total = weekendTotal + weekdayTotal;
    final weekendPct = total > 0 ? weekendTotal / total : 0.0;
    final weekdayPct = total > 0 ? weekdayTotal / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Activity insights',
          subtitle: 'Patterns across your recent contribution history',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekend vs weekday',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontSizeLead,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: total > 0
                            ? ((weekdayPct * 100).toInt()).clamp(1, 99)
                            : 1,
                        child: Container(color: scheme.primary),
                      ),
                      Expanded(
                        flex: total > 0
                            ? ((weekendPct * 100).toInt()).clamp(1, 99)
                            : 1,
                        child: Container(color: scheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(
                    label: 'Weekdays',
                    value: PresentationFormatter.formatCompactNumber(weekdayTotal),
                    pct: '${(weekdayPct * 100).toStringAsFixed(0)}%',
                    color: scheme.primary,
                  ),
                  _MiniStat(
                    label: 'Weekends',
                    value: PresentationFormatter.formatCompactNumber(weekendTotal),
                    pct: '${(weekendPct * 100).toStringAsFixed(0)}%',
                    color: scheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Impact levels',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontSizeLead,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  _ImpactChip(label: 'Low', count: levels[1], color: _heatmapColor(1)),
                  const SizedBox(width: AppTheme.spacing8),
                  _ImpactChip(label: 'Med', count: levels[2], color: _heatmapColor(2)),
                  const SizedBox(width: AppTheme.spacing8),
                  _ImpactChip(label: 'High', count: levels[3], color: _heatmapColor(3)),
                  const SizedBox(width: AppTheme.spacing8),
                  _ImpactChip(label: 'Max', count: levels[4], color: _heatmapColor(4)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // LOADING & ERROR STATES
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildErrorState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: AppTheme.spacing16),
          Text(widget.loadError ?? 'Unknown error',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72))),
          const SizedBox(height: AppTheme.spacing16),
          FilledButton(onPressed: widget.onRefresh, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════

@immutable
class TrendSummary {
  final int current;
  final int previous;

  const TrendSummary({
    required this.current,
    required this.previous,
  });

  double get deltaRatio {
    if (previous <= 0) {
      return current <= 0 ? 0.0 : 1.0;
    }
    return (current - previous) / previous;
  }

  String get deltaLabel {
    final pct = (deltaRatio * 100).toStringAsFixed(0);
    if (deltaRatio > 0) return '+$pct% vs prev';
    if (deltaRatio < 0) return '$pct% vs prev';
    return '0% vs prev';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String pct;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  ' ($pct)',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: scheme.onSurface.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ImpactChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.65)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String name;
  final Color color;
  final double percent;

  const _LanguageRow({
    required this.name,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pctLabel = '${(percent * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              pctLabel,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SparklineChart extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final ValueChanged<int> onIndexSelected;

  const _SparklineChart({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.onIndexSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final dx = details.localPosition.dx.clamp(0.0, width);
            final t = width <= 0 ? 0.0 : (dx / width);
            final raw = (t * (values.length - 1));
            onIndexSelected(raw.round().clamp(0, values.length - 1));
          },
          child: CustomPaint(
            size: Size(width, constraints.maxHeight),
            painter: _SparklinePainter(
              values: values,
              lineColor: lineColor,
              fillColor: fillColor,
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.length == 1) return;
    if (size.width <= 0 || size.height <= 0) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();

    Offset pointAt(int i) {
      final t = i / (values.length - 1);
      final x = t * size.width;
      final normalized = range <= 0 ? 0.0 : ((values[i] - minV) / range);
      final y = size.height - (normalized * size.height);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.22),
          fillColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.trim();
  if (cleaned.isEmpty) return null;
  final normalized = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  if (normalized.length == 6) {
    return Color(0xFF000000 | value);
  }
  if (normalized.length == 8) {
    return Color(value);
  }
  return null;
}

class _ScrollableHeatmapGrid extends StatelessWidget {
  final List<ContributionDay> days;
  final Quartiles quartiles;
  final Color Function(int level) heatmapColor;

  const _ScrollableHeatmapGrid({
    required this.days,
    required this.quartiles,
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
            return _HeatmapCell(
              day: day,
              quartiles: quartiles,
              heatmapColor: heatmapColor,
            );
          }),
        );
      },
      padding: EdgeInsets.zero,
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final ContributionDay? day;
  final Quartiles quartiles;
  final Color Function(int level) heatmapColor;

  const _HeatmapCell({
    required this.day,
    required this.quartiles,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox.square(dimension: 22);
    }

    final scheme = Theme.of(context).colorScheme;
    final color = _getColorForLevel(day!.contributionCount, quartiles);

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
              backgroundColor: scheme.surface,
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
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        '${day!.contributionCount} commits',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLead,
                          color: scheme.onSurface.withValues(alpha: 0.72),
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
                border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForLevel(int count, Quartiles quartiles) {
    final level = RenderUtils.getContributionLevel(count, quartiles: quartiles);
    return heatmapColor(level);
  }
}
