import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import '../core/wallpaper_service.dart';
import '../core/constants.dart';
import '../models/contribution_data.dart';
import '../widgets/heatmap_painter.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE SCREEN - ACCURATE DEVICE PREVIEW
// ══════════════════════════════════════════════════════════════════════════

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({Key? key}) : super(key: key);

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen>
    with SingleTickerProviderStateMixin {
  late CachedContributionData? _cachedData;
  late TabController _tabController;
  bool _isApplying = false;

  // Position settings
  late double _verticalPosition;
  late double _horizontalPosition;

  // Style settings
  late double _scale;
  late double _opacity;
  late double _cornerRadius;

  // Content settings
  late String _customQuote;
  late double _quoteFontSize;
  late double _quoteOpacity;
  late TextEditingController _quoteController;

  // Wallpaper target (String: "home", "lock", "both")
  late String _wallpaperTarget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    _cachedData = AppPreferences.getCachedData();

    _verticalPosition = AppPreferences.getVerticalPosition();
    _horizontalPosition = AppPreferences.getHorizontalPosition();

    _scale = AppPreferences.getScale();
    _opacity = AppPreferences.getOpacity();
    _cornerRadius = AppPreferences.getCornerRadius();

    _customQuote = AppPreferences.getCustomQuote();
    _quoteFontSize = AppPreferences.getQuoteFontSize();
    _quoteOpacity = AppPreferences.getQuoteOpacity();
    _quoteController = TextEditingController(text: _customQuote);

    // Load wallpaper target (String)
    _wallpaperTarget = AppPreferences.getWallpaperTarget();
  }

  Future<void> _applyWallpaper() async {
    if (_isApplying) return;

    HapticFeedback.mediumImpact();
    setState(() => _isApplying = true);

    try {
      await WallpaperService.refreshAndSetWallpaper(target: _wallpaperTarget);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppTheme.spacing12),
                Text(_getSuccessMessage()),
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
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  String _getSuccessMessage() {
    switch (_wallpaperTarget) {
      case 'home':
        return 'Home screen wallpaper applied!';
      case 'lock':
        return 'Lock screen wallpaper applied!';
      case 'both':
        return 'Both screens wallpaper applied!';
      default:
        return 'Wallpaper applied!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Customize'),
        actions: [
          IconButton(
            icon: _isApplying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.primaryColor,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isApplying ? null : _applyWallpaper,
            tooltip: 'Apply',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final previewHeight = availableHeight * 0.70;
          final controlsHeight = availableHeight * 0.30;

          return Column(
            children: [
              SizedBox(height: previewHeight, child: _buildAccuratePreview()),
              SizedBox(height: controlsHeight, child: _buildControls()),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📱 ACCURATE PREVIEW (Renders at actual wallpaper dimensions)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAccuratePreview() {
    if (_cachedData == null) {
      return Center(
        child: Text(
          'No Preview Available',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
        ),
      );
    }

    return Container(
      color: context.backgroundColor,
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: context.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
            child: AspectRatio(
              aspectRatio:
                  AppConstants.wallpaperWidth / AppConstants.wallpaperHeight,
              child: Container(
                color: AppPreferences.getDarkMode()
                    ? AppConstants.heatmapDarkBg
                    : AppConstants.heatmapLightBg,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: AppConstants.wallpaperWidth,
                    height: AppConstants.wallpaperHeight,
                    child: CustomPaint(
                      painter: HeatmapPainter(
                        data: _cachedData!,
                        isDarkMode: AppPreferences.getDarkMode(),
                        verticalPosition: _verticalPosition,
                        horizontalPosition: _horizontalPosition,
                        scale: _scale,
                        opacity: _opacity,
                        customQuote: _customQuote,
                        paddingTop: AppPreferences.getPaddingTop(),
                        paddingBottom: AppPreferences.getPaddingBottom(),
                        paddingLeft: AppPreferences.getPaddingLeft(),
                        paddingRight: AppPreferences.getPaddingRight(),
                        cornerRadius: _cornerRadius,
                        quoteFontSize: _quoteFontSize,
                        quoteOpacity: _quoteOpacity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎚️ CONTROLS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.primaryColor,
              indicatorWeight: 3,
              labelColor: context.primaryColor,
              unselectedLabelColor: context.theme.hintColor,
              labelStyle: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'POSITION'),
                Tab(text: 'STYLE'),
                Tab(text: 'CONTENT'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPositionTab(),
                _buildStyleTab(),
                _buildContentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionTab() {
    return ListView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      children: [
        _buildSlider(
          label: 'Vertical',
          value: _verticalPosition,
          percentage: (_verticalPosition * 100).round(),
          onChanged: (v) {
            setState(() => _verticalPosition = v);
            AppPreferences.setVerticalPosition(v);
          },
        ),
        _buildSlider(
          label: 'Horizontal',
          value: _horizontalPosition,
          percentage: (_horizontalPosition * 100).round(),
          onChanged: (v) {
            setState(() => _horizontalPosition = v);
            AppPreferences.setHorizontalPosition(v);
          },
        ),
      ],
    );
  }

  Widget _buildStyleTab() {
    return ListView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      children: [
        _buildSlider(
          label: 'Scale',
          value: _scale,
          percentage: (_scale * 100).round(),
          min: 0.5,
          max: 2.0,
          onChanged: (v) {
            setState(() => _scale = v);
            AppPreferences.setScale(v);
          },
        ),
        _buildSlider(
          label: 'Opacity',
          value: _opacity,
          percentage: (_opacity * 100).round(),
          onChanged: (v) {
            setState(() => _opacity = v);
            AppPreferences.setOpacity(v);
          },
        ),
        _buildSlider(
          label: 'Corner',
          value: _cornerRadius,
          percentage: (_cornerRadius * 10).round(),
          min: 0,
          max: 10,
          onChanged: (v) {
            setState(() => _cornerRadius = v);
            AppPreferences.setCornerRadius(v);
          },
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    return ListView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      children: [
        // ✅ WALLPAPER TARGET SELECTION
        _buildWallpaperTargetSelector(),

        SizedBox(height: AppTheme.spacing24),

        // Quote TextField
        TextField(
          controller: _quoteController,
          onChanged: (value) {
            setState(() => _customQuote = value);
            AppPreferences.setCustomQuote(value);
          },
          decoration: const InputDecoration(
            labelText: 'Quote',
            hintText: 'Your motivation...',
          ),
          maxLength: 50,
        ),
        SizedBox(height: AppTheme.spacing16),
        _buildSlider(
          label: 'Font Size',
          value: _quoteFontSize,
          percentage: _quoteFontSize.round(),
          min: 10,
          max: 24,
          onChanged: (v) {
            setState(() => _quoteFontSize = v);
            AppPreferences.setQuoteFontSize(v);
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎯 WALLPAPER TARGET SELECTOR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildWallpaperTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppTheme.spacing8),
            Text(
              'Apply To',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing12),

        // Home Screen
        _buildTargetOption(
          value: 'home',
          icon: Icons.home,
          title: 'Home Screen',
          subtitle: 'Set as home wallpaper only',
        ),

        // Lock Screen
        _buildTargetOption(
          value: 'lock',
          icon: Icons.lock,
          title: 'Lock Screen',
          subtitle: 'Set as lock wallpaper only',
        ),

        // Both
        _buildTargetOption(
          value: 'both',
          icon: Icons.phone_android,
          title: 'Both Screens',
          subtitle: 'Set as home & lock wallpaper',
        ),
      ],
    );
  }

  Widget _buildTargetOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _wallpaperTarget == value;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _wallpaperTarget = value);
        AppPreferences.setWallpaperTarget(value);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing8),
        padding: EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? context.primaryColor : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryColor.withOpacity(0.2)
                    : context.theme.hintColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? context.primaryColor
                    : context.theme.hintColor,
              ),
            ),
            SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.primaryColor
                          : context.textTheme.bodyMedium?.color,
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
            if (isSelected)
              Icon(Icons.check_circle, color: context.primaryColor, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.theme.hintColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎚️ SLIDER WIDGET
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSlider({
    required String label,
    required double value,
    required int percentage,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) {
                onChanged(v);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$percentage%',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
