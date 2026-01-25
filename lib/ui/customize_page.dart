// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization Controls
// ══════════════════════════════════════════════════════════════════════════
// Interactive controls for positioning, scaling, theming, and styling
// Auto-saves settings and provides live preview
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/storage_service.dart';
import '../services/wallpaper_service.dart';
import '../services/utils.dart';
import '../models/models.dart';
import 'theme.dart';
import 'widgets.dart';

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  CachedContributionData? _data;

  // Positioning (ValueNotifiers for performance)
  late final ValueNotifier<double> _scale;
  late final ValueNotifier<double> _opacity;
  late final ValueNotifier<double> _quoteFontSize;

  // Other state
  late double _verticalPosition;
  late double _horizontalPosition;
  late bool _isDarkMode;
  late String _wallpaperTarget;
  late TextEditingController _quoteController;
  late double _quoteOpacity;
  late double _margin;
  late double _cornerRadius;
  
  final _debouncer = Debouncer(milliseconds: 500);

  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _scale.dispose();
    _opacity.dispose();
    _quoteFontSize.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _loadData() {
    _data = StorageService.getCachedData();
  }

  void _loadSettings() {
    _verticalPosition = StorageService.getVerticalPosition();
    _horizontalPosition = StorageService.getHorizontalPosition();
    
    // Initialize Notifiers
    _scale = ValueNotifier(StorageService.getScale());
    _opacity = ValueNotifier(StorageService.getOpacity());
    
    _isDarkMode = StorageService.getDarkMode();
    _wallpaperTarget = StorageService.getWallpaperTarget();
    _quoteController = TextEditingController(
      text: StorageService.getCustomQuote(),
    );
    
    _quoteFontSize = ValueNotifier(StorageService.getQuoteFontSize());
    
    _quoteOpacity = StorageService.getQuoteOpacity();
    _margin = StorageService.getPaddingTop();
    _cornerRadius = StorageService.getCornerRadius();
  }

  Future<void> _saveSettings() async {
    await StorageService.setVerticalPosition(_verticalPosition);
    await StorageService.setHorizontalPosition(_horizontalPosition);
    await StorageService.setScale(_scale.value);
    await StorageService.setOpacity(_opacity.value);
    await StorageService.setDarkMode(_isDarkMode);
    await StorageService.setWallpaperTarget(_wallpaperTarget);
    await StorageService.setCustomQuote(_quoteController.text);
    await StorageService.setQuoteFontSize(_quoteFontSize.value);
    await StorageService.setQuoteOpacity(_quoteOpacity);
    await StorageService.setPaddingTop(_margin);
    await StorageService.setPaddingBottom(_margin);
    await StorageService.setPaddingLeft(_margin);
    await StorageService.setPaddingRight(_margin);
    await StorageService.setCornerRadius(_cornerRadius);
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _verticalPosition = AppConfig.defaultVerticalPosition;
      _horizontalPosition = AppConfig.defaultHorizontalPosition;
      
      _scale.value = AppConfig.defaultScale;
      _opacity.value = 1.0;
      
      _isDarkMode = false;
      _wallpaperTarget = 'both';
      _quoteController.text = '';
      
      _quoteFontSize.value = 14.0;
      
      _quoteOpacity = 1.0;
      _margin = 0.0;
      _cornerRadius = 12.0;
    });

    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SuccessBanner(message: AppStrings.resetDefaults),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _applyWallpaper() async {
    if (_data == null) return;

    setState(() => _isApplying = true);
    await _saveSettings();

    if (!mounted) return;
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
      final config = StorageService.getWallpaperConfig() ?? WallpaperConfig.defaults();

      await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
        target: _wallpaperTarget,
      );

      if (!mounted) return;
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.of(context).pop(); // Pop dialog

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop(); // Pop page

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
        SnackBar(content: Text('${AppStrings.error}: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_data == null) {
      return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.customizeTitle)),
        body: EmptyState(
          icon: Icons.palette_outlined,
          title: AppStrings.noDataTitle,
          message: AppStrings.noDataMsg,
          actionLabel: AppStrings.goBack,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    // Dynamic preview height based on screen size, but ensuring it doesn't take up too much vertical space
    // on smaller screens. We use a scrollable layout now so it's less critical.
    final previewHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resize for keyboard
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppStrings.customizeTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore, color: AppTheme.textPrimary),
            tooltip: 'Reset',
          ),
          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Preview Area
            SizedBox(
              height: previewHeight + MediaQuery.of(context).padding.top + kToolbarHeight,
              child: _buildPreview(),
            ),

            // Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
              ),
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing24, AppTheme.spacing16, AppTheme.spacing24),
              child: _buildControlPanel(),
            ),
            
            // Apply Button (Scrolls with content)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: _buildApplyButton(),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // Extra padding for safety
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isApplying ? null : _applyWallpaper,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          elevation: 4,
        ),
        icon: _isApplying
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle, size: 24),
        label: Text(
          _isApplying ? AppStrings.applying : AppStrings.applyWallpaper,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPreview() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final availableHeight = MediaQuery.of(context).size.height * AppLayout.previewHeightRatio;
    final frameHeight = availableHeight * AppLayout.frameHeightRatio;
    final frameWidth = frameHeight * AppLayout.phoneAspectRatio; 

    return Container(
      padding: EdgeInsets.only(top: topPadding + AppTheme.spacing8),
      child: Center(
        child: Container(
          height: frameHeight,
          width: frameWidth,
          decoration: BoxDecoration(
            color: _isDarkMode ? AppConfig.heatmapDarkBg : AppConfig.heatmapLightBg,
            borderRadius: BorderRadius.circular(AppLayout.frameRadius),
            border: Border.all(color: Colors.black87, width: AppLayout.frameBorderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate scaling ratio:
              // The wallpaper is rendered at wallpaperWidth x wallpaperHeight (physical pixels)
              // The preview is rendered at constraints.maxWidth x constraints.maxHeight (logical pixels)
              // To make preview match, we need to scale everything by: preview_width / wallpaper_width
              
              // Preview ratio = preview logical size / wallpaper logical size
              // Wallpaper is in physical pixels, so convert to logical first
              final previewWidth = constraints.maxWidth;
              final previewHeight = constraints.maxHeight;
              
              // Scaling factor: preview size / wallpaper logical size
              final scaleRatio = previewWidth / (AppConfig.wallpaperWidth / AppConfig.devicePixelRatio);
              
              return ListenableBuilder(
                listenable: Listenable.merge([_scale, _opacity, _quoteFontSize]),
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(previewWidth, previewHeight),
                    painter: HeatmapPainter(
                      data: _data!,
                      config: WallpaperConfig(
                        isDarkMode: _isDarkMode,
                        scale: _scale.value * scaleRatio,
                        opacity: _opacity.value,
                        verticalPosition: _verticalPosition,
                        horizontalPosition: _horizontalPosition,
                        customQuote: _quoteController.text,
                        quoteFontSize: _quoteFontSize.value * _scale.value * scaleRatio,
                        quoteOpacity: _quoteOpacity,
                        paddingTop: _margin * scaleRatio,
                        paddingBottom: _margin * scaleRatio,
                        paddingLeft: _margin * scaleRatio,
                        paddingRight: _margin * scaleRatio,
                        cornerRadius: _cornerRadius * scaleRatio,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Column(
      children: [
        _buildSection(AppStrings.sectionScaling, [
        _buildSlider(AppStrings.labelScale, _scale, AppConfig.minScale, AppConfig.maxScale, (v) {
            _scale.value = v;
            _debouncer.run(_saveSettings);
          }, Icons.zoom_in),
          const SizedBox(height: AppTheme.spacing16),
          _buildSlider(AppStrings.labelOpacity, _opacity, 0.1, 1.0, (v) {
             _opacity.value = v;
            _debouncer.run(_saveSettings);
          }, Icons.opacity),
          const SizedBox(height: AppTheme.spacing16),
          _buildSlider(AppStrings.labelPadding, ValueNotifier(_margin), 0.0, 100.0, (v) {
             setState(() => _margin = v);
            _debouncer.run(_saveSettings);
          }, Icons.padding),
        ]),
        const SizedBox(height: AppTheme.spacing16),
        _buildSection(AppStrings.sectionOverlay, [
          _buildQuoteInput(),
          const SizedBox(height: AppTheme.spacing16),
          _buildSlider(AppStrings.labelFontSize, _quoteFontSize, 12.0, 72.0, (v) {
             _quoteFontSize.value = v;
             _debouncer.run(_saveSettings);
           }, Icons.format_size),
           const SizedBox(height: AppTheme.spacing16),
           SwitchListTile(
             title: const Text(AppStrings.darkMode, style: TextStyle(fontWeight: FontWeight.w600)),
             contentPadding: EdgeInsets.zero,
             value: _isDarkMode,
             onChanged: (v) {
               setState(() => _isDarkMode = v);
               _debouncer.run(_saveSettings);
             },
           ),
        ]),
        const SizedBox(height: AppTheme.spacing64), // Extra space for bottom bar
      ],
    );
  }



  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.1)),
          const SizedBox(height: AppTheme.spacing16),
          ...children,
        ],
      ),
    );
  }





  Widget _buildSlider(String label, ValueNotifier<double> notifier, double min, double max, ValueChanged<double> onChanged, IconData icon) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacing8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${(value * 100).toInt()}%', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuoteInput() {
    return TextFormField(
      controller: _quoteController,
      maxLength: 80,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: AppStrings.customQuote,
        hintText: AppStrings.quoteHint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        counterStyle: TextStyle(
          color: AppTheme.textTertiary,
          fontSize: 11,
        ),
      ),
      onChanged: (v) {
        setState(() {}); // Rebuild preview with new quote
        _debouncer.run(_saveSettings);
      },
    );
  }

}
