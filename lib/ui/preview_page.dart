// ══════════════════════════════════════════════════════════════════════════
// 👁️ PREVIEW PAGE - Wallpaper Preview Before Applying
// ══════════════════════════════════════════════════════════════════════════
// Shows full-screen preview of how wallpaper will look with current settings
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/storage_service.dart';
import '../services/wallpaper_service.dart';
import '../models/models.dart';
import 'theme.dart';
import 'widgets.dart';

class PreviewPage extends StatefulWidget {
  final CachedContributionData data;

  const PreviewPage({
    super.key,
    required this.data,
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _isApplying = false;

  Future<void> _applyWallpaper() async {
    setState(() => _isApplying = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(message: 'Setting wallpaper...'),
          ],
        ),
      ),
    );

    try {
      // Load current settings
      final config = StorageService.getWallpaperConfig() ?? WallpaperConfig.defaults();

      final target = StorageService.getWallpaperTarget();

      await WallpaperService.generateAndSetWallpaper(
        data: widget.data,
        config: config,
        target: target,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SuccessBanner(message: 'Wallpaper applied! 🎉'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Go back to previous screen
      await Future.delayed(AppTheme.animationSlow);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply: $e'),
          backgroundColor: AppTheme.error,
        ),
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
    final isDarkMode = StorageService.getDarkMode();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Preview area (takes most of screen)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          child: CustomPaint(
                            painter: HeatmapPainter(
                              data: widget.data,
                              config: WallpaperConfig.defaults().copyWith(
                                isDarkMode: isDarkMode,
                                scale: StorageService.getScale() * 0.8,
                                opacity: StorageService.getOpacity(),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: AppTheme.animationNormal)
                          .scale(begin: const Offset(0.95, 0.95)),
                    ),
          
                    // Info text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                      child: Text(
                        'This is a scaled preview. Actual wallpaper will fit your screen perfectly.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
          
                    const SizedBox(height: AppTheme.spacing16),
          
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Row(
                        children: [
                          // Back button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isApplying ? null : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                            ),
                          ),
          
                          const SizedBox(width: AppTheme.spacing12),
          
                          // Apply button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isApplying ? null : _applyWallpaper,
                              icon: _isApplying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label:
                                  Text(_isApplying ? 'Applying...' : 'Apply Wallpaper'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
