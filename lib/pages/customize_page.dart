// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/services.dart';
import 'package:github_wallpaper/models.dart';
import 'package:github_wallpaper/theme.dart';
import 'package:github_wallpaper/utils.dart';
import 'package:github_wallpaper/app_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CustomizePage extends StatefulWidget {
  final CachedContributionData? data;
  final Function(String) onSetWallpaper;
  final VoidCallback? onRequestSync;

  const CustomizePage({
    super.key,
    required this.data,
    required this.onSetWallpaper,
    this.onRequestSync,
  });

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  late WallpaperConfig _config;
  late TextEditingController _quoteController;
  bool _isGenerating = false;
  String _deviceName = 'Loading device info...';
  WallpaperTarget _previewTarget = WallpaperTarget.lock;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    _quoteController = TextEditingController(text: _config.customQuote);
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = 'Unknown Device';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.brand.toUpperCase()} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine;
      }
    } catch (e) {
      name = 'Mobile Device';
    }
    try {
      await StorageService.saveDeviceModel(name);
    } catch (_) {}
    if (mounted) {
      setState(() => _deviceName = name);
    }
  }

  void _fitToWidth() {
    final dims = StorageService.getDimensions();
    final wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    final effectiveConfig = DeviceCompatibilityChecker.applyPlacement(
      base: _config,
      target: _previewTarget,
    );
    final targetWidth =
        wallpaperWidth - effectiveConfig.paddingLeft - effectiveConfig.paddingRight;
    final columns = _previewTarget == WallpaperTarget.lock
        ? AppConstants.monthGridColumns
        : AppConstants.heatmapWeeks;
    final baseGraphWidth =
        (AppConstants.heatmapBoxSize + AppConstants.heatmapBoxSpacing) *
                columns -
            AppConstants.heatmapBoxSpacing;
    
    // Increased max scale from 3.0 to 8.0 to support Month view (Lock screen) correctly
    final newScale = (targetWidth / baseGraphWidth).clamp(0.5, 8.0);

    _updateConfig(_config.copyWith(
      scale: newScale,
      horizontalPosition: 0.5,
      verticalPosition: 0.5,
    ));
  }

  Future<void> _saveAndApply() async {
    final target = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set Wallpaper',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home Screen'),
                onTap: () => Navigator.pop(context, 'home'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Lock Screen'),
                onTap: () => Navigator.pop(context, 'lock'),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Both Screens'),
                onTap: () => Navigator.pop(context, 'both'),
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );

    if (target == null) return;

    // Validate quote
    final validationError = ValidationUtils.validateQuote(_config.customQuote);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppTheme.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await StorageService.saveWallpaperConfig(_config);
      await widget.onSetWallpaper(target);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Wallpaper updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _updateConfig(WallpaperConfig newConfig) {
    setState(() => _config = newConfig);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return _buildNoDataState();
    }

    final media = MediaQuery.of(context);
    final viewportHeight = media.size.height;
    final isLandscape = media.orientation == Orientation.landscape;
    final previewPanelHeight = (viewportHeight * (isLandscape ? 0.72 : 0.55)).clamp(
      viewportHeight * (isLandscape ? 0.60 : 0.50),
      viewportHeight * (isLandscape ? 0.82 : 0.60),
    );

    final previewPanel = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing20,
        vertical: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: _buildPreviewSection()),
    );

    final controlsPanel = Container(
      color: AppTheme.bgWhite,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeHeadline,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildThemeSection(),
              const SizedBox(height: AppTheme.spacing24),
              _buildCustomizationSection(),
              const SizedBox(height: AppTheme.spacing32),
              _buildApplyButton(),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: previewPanel),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(child: controlsPanel),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(height: previewPanelHeight, child: previewPanel),
        Expanded(child: controlsPanel),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // NO DATA STATE
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius3XLarge),
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 40,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLead,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            const Text(
              'Sync your GitHub data first',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onRequestSync,
                icon: const Icon(Icons.sync),
                label: const Text(
                  'Sync Now',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLead,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREVIEW SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPreviewSection() {
    final dims = StorageService.getDimensions();
    var wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    var wallpaperHeight = dims?['height'] ?? AppConstants.defaultWallpaperHeight;
    final wallpaperPixelRatio = dims?['pixelRatio'] ?? AppConstants.defaultPixelRatio;

    if (Platform.isAndroid &&
        (_previewTarget == WallpaperTarget.home ||
            _previewTarget == WallpaperTarget.both)) {
      final desired = StorageService.getDesiredWallpaperSize();
      if (desired != null) {
        wallpaperWidth = desired['width']!;
        wallpaperHeight = desired['height']!;
      }
    }

    final physicalWidth = (wallpaperWidth * wallpaperPixelRatio).round();
    final physicalHeight = (wallpaperHeight * wallpaperPixelRatio).round();

    final wallpaperAspectRatio = wallpaperWidth / wallpaperHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Increased infoHeight buffer from 60 to 100 to prevent vertical overflows on some devices
        final infoHeight = 100.0;
        final previewMaxHeight = (maxH - infoHeight).clamp(120.0, maxH);

        double previewHeight = previewMaxHeight;
        double previewWidth = previewHeight * wallpaperAspectRatio;

        if (previewWidth > maxW) {
          previewWidth = maxW;
          previewHeight = previewWidth / wallpaperAspectRatio;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 100% Unified: Removed target selector as requested ("ONE FIXED")
            // All targets (Home/Lock/Both) now share the exact same professional layout.
            const SizedBox(height: 10),
            Semantics(
              label:
                  'Wallpaper preview for $_deviceName. Resolution $physicalWidth by $physicalHeight pixels.',
              image: true,
              child: Container(
                height: previewHeight,
                width: previewWidth,
                decoration: BoxDecoration(
                  color: AppTheme.bgWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.previewBorder, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          key: ValueKey('${_config.hashCode}_${_previewTarget.name}'),
                          painter: _WallpaperPreviewPainter(
                            data: widget.data!,
                            wallpaperWidth: wallpaperWidth,
                            wallpaperHeight: wallpaperHeight,
                            target: _previewTarget,
                            config: DeviceCompatibilityChecker.applyPlacement(
                              base: _config,
                              target: _previewTarget,
                            ),
                          ),
                          child: Container(),
                        ),
                      ),
                      // Visual Guide for System UI
                      _buildSystemUiGuides(previewHeight / wallpaperHeight),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preview for $_deviceName',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Wallpaper: ${physicalWidth}x${physicalHeight}px',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // THEME SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLead,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeCard(
                label: 'Dark',
                icon: Icons.dark_mode,
                isSelected: _config.isDarkMode,
                onTap: () {
                  _updateConfig(_config.copyWith(isDarkMode: true));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeCard(
                label: 'Light',
                icon: Icons.light_mode,
                isSelected: !_config.isDarkMode,
                onTap: () {
                  _updateConfig(_config.copyWith(isDarkMode: false));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CUSTOMIZATION SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCustomizationSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Overlay',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBase,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quoteController,
            decoration: InputDecoration(
              labelText: 'Custom Quote',
              hintText: 'Enter your motivation...',
              filled: true,
              fillColor: AppTheme.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              _updateConfig(_config.copyWith(customQuote: value));
            },
          ),
          const SizedBox(height: 12),
          if (_config.customQuote.isNotEmpty) ...[
            _buildSlider(
              label: 'Quote Size',
              value: _config.quoteFontSize,
              min: 10.0,
              max: 40.0,
              divisions: 15,
              onChanged: (value) {
                _updateConfig(_config.copyWith(quoteFontSize: value));
              },
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Quote Opacity',
              value: _config.quoteOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) {
                _updateConfig(_config.copyWith(quoteOpacity: value));
              },
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          const Divider(),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scale',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _fitToWidth,
                icon: const Icon(Icons.fit_screen, size: 16),
                label: const Text('Fit Width', style: TextStyle(fontSize: AppTheme.fontSizeBody)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto Fit Width',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: _config.autoFitWidth,
                activeThumbColor: AppTheme.primaryBlue,
                onChanged: (value) {
                  _updateConfig(_config.copyWith(autoFitWidth: value));
                },
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryBlue,
              inactiveTrackColor: AppTheme.borderLight,
              thumbColor: AppTheme.primaryBlue,
              overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _config.scale,
              min: 0.5,
              max: 8.0,
              divisions: 75,
              onChanged: _config.autoFitWidth
                  ? null
                  : (value) {
                      _updateConfig(_config.copyWith(scale: value));
                    },
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Opacity',
            value: _config.opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            onChanged: (value) {
              _updateConfig(_config.copyWith(opacity: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Corner Radius',
            value: _config.cornerRadius,
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (value) {
              _updateConfig(_config.copyWith(cornerRadius: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Position (Vertical)',
            value: _config.verticalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              _updateConfig(_config.copyWith(verticalPosition: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Position (Horizontal)',
            value: _config.horizontalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              _updateConfig(_config.copyWith(horizontalPosition: value));
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SLIDER WIDGET
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSub,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryBlue,
            inactiveTrackColor: AppTheme.borderLight,
            thumbColor: AppTheme.primaryBlue,
            overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // APPLY BUTTON
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Semantics(
        button: true,
        enabled: !_isGenerating,
        label: 'Apply wallpaper',
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _saveAndApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: _isGenerating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textWhite,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Apply Wallpaper',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLead,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSystemUiGuides(double previewScale) {
    // Only show for Lock Screen mode to avoid clutter
    // 100% Unified: Guides now relevant for all targets since they share the same layout
    // if (_previewTarget != WallpaperTarget.lock) return const SizedBox.shrink(); 

    final safeInsets = StorageService.getSafeInsets();
    if (safeInsets == EdgeInsets.zero) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: [
          // Clock Area Indicator (approximate)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: safeInsets.top * previewScale + 60, // Padding + space for clock
            child: Container(
              color: Colors.red.withValues(alpha: 0.1),
              child: const Center(
                child: Text(
                  'SYSTEM CLOCK AREA',
                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Navigation / Gesture Indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: safeInsets.bottom * previewScale + 20,
            child: Container(
              color: Colors.blue.withValues(alpha: 0.1),
              child: const Center(
                child: Text(
                  'GESTURE AREA',
                  style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// THEME CARD WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? AppTheme.gradientShadow(AppTheme.primaryBlue)
                  : AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? AppTheme.textWhite : AppTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBase,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.textWhite : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER PREVIEW PAINTER
// ══════════════════════════════════════════════════════════════════════════

class _WallpaperPreviewPainter extends CustomPainter {
  final CachedContributionData data;
  final WallpaperConfig config;
  final double wallpaperWidth;
  final double wallpaperHeight;
  final WallpaperTarget target;

  _WallpaperPreviewPainter({
    required this.data,
    required this.config,
    required this.wallpaperWidth,
    required this.wallpaperHeight,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wallpaperWidth <= 0 || wallpaperHeight <= 0) return;
    final scaleX = size.width / wallpaperWidth;
    final scaleY = size.height / wallpaperHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    final wallpaperSize = Size(wallpaperWidth, wallpaperHeight);
    // 100% Unified: Always use MonthHeatmapRenderer for preview consistency
    MonthHeatmapRenderer.render(
      canvas: canvas,
      size: wallpaperSize,
      data: data,
      config: config,
      pixelRatio: 1.0,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WallpaperPreviewPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.data != data ||
        oldDelegate.wallpaperWidth != wallpaperWidth ||
        oldDelegate.wallpaperHeight != wallpaperHeight ||
        oldDelegate.target != target;
  }
}

class _PreviewTargetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PreviewTargetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label preview target',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.textWhite : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
