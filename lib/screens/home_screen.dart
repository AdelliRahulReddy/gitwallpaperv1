import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import '../core/constants.dart';
import '../core/github_api.dart';
import '../core/wallpaper_service.dart';
import '../models/contribution_data.dart';
import '../widgets/heatmap_painter.dart';

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
    // ✅ IMPROVED: Auto-refresh on app open (smarter threshold)
    _autoRefreshOnOpen();
  }

  void _loadData() {
    setState(() {
      try {
        _cachedData = AppPreferences.getCachedData();
      } catch (e) {
        debugPrint('HomeScreen: Error loading cached data: $e');
        _cachedData = null;
      }
    });
  }

  /// ✅ IMPROVED: Auto refresh when app opens (smart threshold)
  /// Only refreshes if:
  /// - No cached data exists, OR
  /// - Last update was more than 6 hours ago (not too aggressive)
  Future<void> _autoRefreshOnOpen() async {
    try {
      final lastUpdate = AppPreferences.getLastUpdate();
      final now = DateTime.now();

      // ✅ IMPROVED: 6-hour threshold instead of 1-hour (less aggressive)
      if (_cachedData == null ||
          lastUpdate == null ||
          now.difference(lastUpdate).inHours >= 6) {
        debugPrint(
          'HomeScreen: Auto-refreshing data (last update: $lastUpdate)',
        );
        await _refreshData(showSnackbar: false);
      } else {
        debugPrint(
          'HomeScreen: Using cached data (${now.difference(lastUpdate).inHours}h old)',
        );
      }
    } catch (e) {
      debugPrint('HomeScreen: Auto-refresh failed: $e');
    }
  }

  Future<void> _refreshData({bool showSnackbar = true}) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || username.isEmpty) {
        throw Exception('GitHub username not configured');
      }

      if (token == null || token.isEmpty) {
        throw Exception('GitHub token not configured');
      }

      debugPrint('HomeScreen: Fetching contributions for $username');
      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      // Save to cache
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      debugPrint('HomeScreen: Data synced successfully');

      // ✅ FIXED: Regenerate and set wallpaper automatically
      final target = AppPreferences.getWallpaperTarget();
      final wallpaperSuccess = await WallpaperService.refreshAndSetWallpaper(
        target: target,
      );

      _loadData();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wallpaperSuccess
                  ? '✅ Data synced & wallpaper updated!'
                  : '✅ Data synced (wallpaper update skipped)',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('HomeScreen: Refresh error: $e');

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// 🧪 TEST: Trigger immediate background update (for testing only)
  Future<void> _testBackgroundUpdate() async {
    try {
      // Register one-time task with 5-second delay
      await Workmanager().registerOneOffTask(
        'test-bg-${DateTime.now().millisecondsSinceEpoch}',
        AppConstants.wallpaperTaskTag,
        initialDelay: const Duration(seconds: 5),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🧪 Background update scheduled in 5 seconds!\n\nCLOSE THE APP NOW to test!',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      debugPrint('🧪 Test background task registered');
    } catch (e) {
      debugPrint('🧪 Test background task failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // 70% Live Preview
            Expanded(
              flex: 7,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenPadding.left,
                ),
                child: _buildLivePreview(),
              ),
            ),

            // 30% Quick Info
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusRound),
                    topRight: Radius.circular(AppTheme.radiusRound),
                  ),
                ),
                child: _buildQuickInfo(),
              ),
            ),
          ],
        ),
      ),
      // 🧪 TEST BUTTON: Remove after testing
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testBackgroundUpdate,
        icon: const Icon(Icons.science),
        label: const Text('Test BG'),
        backgroundColor: Colors.orange,
        tooltip: 'Test background update (5 sec delay)',
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(context.screenPadding.left),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GitHub Wallpaper',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cachedData != null)
                  Text(
                    '@${_cachedData!.username}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          IconButton(
            onPressed: _isRefreshing ? null : () => _refreshData(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_outlined),
            style: IconButton.styleFrom(
              backgroundColor: context.primaryColor.withOpacity(0.1),
              foregroundColor: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Live Preview',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),

        // Phone Mockup with Wallpaper
        Flexible(
          child: AspectRatio(
            aspectRatio: 9 / 19.5,
            child: Container(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.spacing32),
                border: Border.all(
                  color: context.colorScheme.onBackground.withOpacity(0.1),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.spacing24),
                child: _cachedData == null
                    ? _buildLoadingState()
                    : CustomPaint(
                        painter: HeatmapPainter(
                          data: _cachedData!,
                          isDarkMode:
                              context.theme.brightness == Brightness.dark,
                          verticalPosition:
                              AppPreferences.getVerticalPosition(),
                          horizontalPosition:
                              AppPreferences.getHorizontalPosition(),
                          scale: AppPreferences.getScale(),
                          opacity: AppPreferences.getOpacity(),
                          customQuote: AppPreferences.getCustomQuote(),
                          paddingTop: AppPreferences.getPaddingTop(),
                          paddingBottom: AppPreferences.getPaddingBottom(),
                          paddingLeft: AppPreferences.getPaddingLeft(),
                          paddingRight: AppPreferences.getPaddingRight(),
                          cornerRadius: AppPreferences.getCornerRadius(),
                          quoteFontSize: AppPreferences.getQuoteFontSize(),
                          quoteOpacity: AppPreferences.getQuoteOpacity(),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRefreshing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Syncing...',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ] else ...[
            Icon(
              Icons.cloud_download_outlined,
              size: 48,
              color: context.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap refresh to sync',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    final lastUpdate = AppPreferences.getLastUpdate();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_cachedData != null) ...[
            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.calendar_month_outlined,
                    value: '${_cachedData!.totalContributions}',
                    label: 'This Month',
                    color: const Color(0xFF39D353),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '${_cachedData!.currentStreak}d',
                    label: 'Streak',
                    color: const Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.commit_outlined,
                    value: '${_cachedData!.todayCommits}',
                    label: 'Today',
                    color: const Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ],

          if (lastUpdate != null) ...[
            const SizedBox(height: AppTheme.spacing16),

            // ✅ FIXED: Last Update & Auto-update status (corrected text)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.autorenew, color: Colors.green, size: 16),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Auto-updates every 15 min (testing)',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
