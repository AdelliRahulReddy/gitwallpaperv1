import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import '../core/wallpaper_service.dart';
import '../widgets/heatmap_painter.dart';
import '../models/contribution_data.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({Key? key}) : super(key: key);

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  // Simplified settings - only essentials
  double _scale = AppConstants.defaultScale;
  String _customQuote = '';

  bool _isSettingWallpaper = false;
  late TextEditingController _quoteController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      _scale = AppPreferences.getScale();
      _customQuote = AppPreferences.getCustomQuote();
      _quoteController = TextEditingController(text: _customQuote);
    } catch (e) {
      debugPrint('CustomizeScreen: Error loading settings: $e');
      _quoteController = TextEditingController();
    }
  }

  Future<void> _saveSettings() async {
    try {
      await AppPreferences.setScale(_scale);
      await AppPreferences.setCustomQuote(
        _customQuote.trim(),
      ); // ✅ Trim whitespace
    } catch (e) {
      debugPrint('CustomizeScreen: Error saving settings: $e');
    }
  }

  Future<void> _setWallpaper() async {
    // Show dialog to select wallpaper target
    final target = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Wallpaper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lock_outline, color: context.primaryColor),
              title: const Text('Lock Screen'),
              onTap: () => Navigator.pop(context, 'lock'),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined, color: context.primaryColor),
              title: const Text('Home Screen'),
              onTap: () => Navigator.pop(context, 'home'),
            ),
            ListTile(
              leading: Icon(
                Icons.phone_android_outlined,
                color: context.primaryColor,
              ),
              title: const Text('Both Screens'),
              onTap: () => Navigator.pop(context, 'both'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (target == null) return;

    setState(() => _isSettingWallpaper = true);

    try {
      // Save settings first
      await _saveSettings();

      // Save target preference for background updates
      await AppPreferences.setWallpaperTarget(target);

      // ✅ Get cached data with error handling
      final data = AppPreferences.getCachedData();

      if (data == null) {
        throw Exception('No data. Please sync first from Home screen.');
      }

      debugPrint('CustomizeScreen: Setting wallpaper (target: $target)');

      // ✅ FIXED: Use correct method name
      final success = await WallpaperService.refreshAndSetWallpaper(
        target: target,
      );

      if (!success) {
        throw Exception('Wallpaper update was skipped (already updated today)');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Wallpaper set successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('CustomizeScreen: Set wallpaper error: $e');

      if (mounted) {
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
        setState(() => _isSettingWallpaper = false);
      }
    }
  }

  Future<void> _resetSettings() async {
    try {
      setState(() {
        _scale = AppConstants.defaultScale;
        _customQuote = '';
        _quoteController.text = '';
      });

      await _saveSettings();

      // Reset all preferences to defaults
      await AppPreferences.setVerticalPosition(
        AppConstants.defaultVerticalPosition,
      );
      await AppPreferences.setHorizontalPosition(
        AppConstants.defaultHorizontalPosition,
      );
      await AppPreferences.setOpacity(1.0);
      await AppPreferences.setPaddingTop(0.0);
      await AppPreferences.setPaddingBottom(0.0);
      await AppPreferences.setPaddingLeft(0.0);
      await AppPreferences.setPaddingRight(0.0);
      await AppPreferences.setCornerRadius(0.0);
      await AppPreferences.setQuoteFontSize(14.0);
      await AppPreferences.setQuoteOpacity(1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Settings reset to defaults'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('CustomizeScreen: Reset error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedData = AppPreferences.getCachedData();
    final isDarkMode = context.theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // 65% Phone Preview
            Expanded(
              flex: 65,
              child: _buildPreviewSection(cachedData, isDarkMode),
            ),

            // 35% Simple Controls
            Expanded(
              flex: 35,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusRound),
                    topRight: Radius.circular(AppTheme.radiusRound),
                  ),
                ),
                child: _buildSimpleControls(),
              ),
            ),
          ],
        ),
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
                  'Customize',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Adjust your wallpaper',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetSettings,
            icon: const Icon(Icons.restart_alt_outlined),
            tooltip: 'Reset to defaults',
            style: IconButton.styleFrom(
              backgroundColor: context.colorScheme.error.withOpacity(0.1),
              foregroundColor: context.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(CachedContributionData? data, bool isDarkMode) {
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

        // Phone Mockup
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
                child: _buildWallpaperPreview(data, isDarkMode),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperPreview(CachedContributionData? data, bool isDarkMode) {
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync_outlined,
              size: 48,
              color: context.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sync data from Home first',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return CustomPaint(
      painter: HeatmapPainter(
        data: data,
        isDarkMode: isDarkMode,
        verticalPosition: AppPreferences.getVerticalPosition(),
        horizontalPosition: AppPreferences.getHorizontalPosition(),
        scale: _scale,
        opacity: AppPreferences.getOpacity(),
        customQuote: _customQuote,
        paddingTop: AppPreferences.getPaddingTop(),
        paddingBottom: AppPreferences.getPaddingBottom(),
        paddingLeft: AppPreferences.getPaddingLeft(),
        paddingRight: AppPreferences.getPaddingRight(),
        cornerRadius: AppPreferences.getCornerRadius(),
        quoteFontSize: AppPreferences.getQuoteFontSize(),
        quoteOpacity: AppPreferences.getQuoteOpacity(),
      ),
    );
  }

  Widget _buildSimpleControls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scale slider
          Text('Size', style: context.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Icon(
                Icons.zoom_out,
                size: 20,
                color: context.colorScheme.onBackground.withOpacity(0.5),
              ),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: AppConstants.minScale,
                  max: AppConstants.maxScale,
                  divisions: 30,
                  onChanged: (value) {
                    setState(() => _scale = value);
                  },
                  onChangeEnd: (value) => _saveSettings(),
                ),
              ),
              Icon(
                Icons.zoom_in,
                size: 20,
                color: context.colorScheme.onBackground.withOpacity(0.5),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Quote input
          Text('Quote (optional)', style: context.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: _quoteController,
            onChanged: (value) {
              // ✅ IMPROVED: Trim whitespace and limit length
              final trimmed = value.trim();
              setState(() => _customQuote = trimmed);
              _saveSettings();
            },
            maxLines: 2,
            maxLength:
                100, // ✅ Increased from 80 to match preferences.dart limit
            style: context.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter a motivational quote...',
              filled: true,
              fillColor: context.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              counterStyle: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onBackground.withOpacity(0.4),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Set Wallpaper Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSettingWallpaper ? null : _setWallpaper,
              icon: _isSettingWallpaper
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.wallpaper_outlined),
              label: Text(_isSettingWallpaper ? 'Setting...' : 'Set Wallpaper'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacing16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }
}
