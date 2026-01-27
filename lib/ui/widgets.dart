// ══════════════════════════════════════════════════════════════════════════
// 🎨 WIDGETS - Reusable UI Components
// ══════════════════════════════════════════════════════════════════════════
// Custom painters, empty states, error views, and common UI elements
// Updated for universal GitHub Universe theme
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'dart:ui' as ui;

import '../models/models.dart';
import '../services/utils.dart';
import 'theme.dart';
import '../services/heatmap_renderer.dart'; // Added import

// ══════════════════════════════════════════════════════════════════════════
// HEATMAP PAINTER - GitHub Contribution Calendar Renderer
// ══════════════════════════════════════════════════════════════════════════

class HeatmapPainter extends CustomPainter {
  final CachedContributionData data;
  final WallpaperConfig config;
  final bool showHeader;
  final bool showQuote;
  final bool showLegend;

  HeatmapPainter({
    required this.data,
    required this.config,
    this.showHeader = true,
    this.showQuote = true,
    this.showLegend = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Delegate to shared renderer
    HeatmapRenderer.render(
      canvas: canvas,
      size: size,
      data: data,
      config: config.copyWith(customQuote: showQuote ? config.customQuote : ''),
      drawBackground: false, // Transparent for preview
      pixelRatio: 1.0,
      showHeader: showHeader,
    );

    // Draw Legend (Manual handling since Renderer doesn't support it yet)
    if (showLegend) {
       final daysInMonth = DateHelper.getDaysInCurrentMonth();
       final firstWeekday = DateHelper.getFirstWeekdayOfMonth();
       final boxSize = AppConfig.boxSize * config.scale;
       final boxSpacing = AppConfig.boxSpacing * config.scale;
       final cellSize = boxSize + boxSpacing;
       final numWeeks = ((daysInMonth + firstWeekday - 1) / 7).ceil();
       final gridWidth = numWeeks * cellSize;
       final gridHeight = 7 * cellSize;
       
       final contentWidth = gridWidth + (25.0 * config.scale); // grid + labels
       
       // Improved layout calculation to prevent overflow
       final effectiveHPos = (contentWidth > size.width) ? 0.5 : config.horizontalPosition;
       final xOffset = (size.width - contentWidth) * effectiveHPos + config.paddingLeft - config.paddingRight; 
       final yOffset = (size.height - gridHeight) * config.verticalPosition + config.paddingTop - config.paddingBottom;
       
       final legendY = yOffset + gridHeight + (showQuote ? 100 : 40) * config.scale;
       _drawLegend(canvas, xOffset, legendY);
    }
  }



  /// Draws contribution level legend
  void _drawLegend(Canvas canvas, double x, double y) {
    final boxSize = AppConfig.boxSize * config.scale * 0.7;
    final spacing = AppConfig.boxSpacing * config.scale;

    final textColor = config.isDarkMode
        ? AppConfig.heatmapDarkBox.withOpacity(0.6)
        : AppConfig.heatmapLightBox.withOpacity(0.6);

    // "Less" label
    final lessTextPainter = TextPainter(
      text: TextSpan(
        text: AppStrings.legendLess,
        style: TextStyle(color: textColor, fontSize: 10 * config.scale),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    lessTextPainter.paint(canvas, Offset(x, y));

    // Color boxes
    final startX = x + lessTextPainter.width + 8 * config.scale;
    for (int i = 0; i < 5; i++) {
      final color = HeatmapRenderer.getContributionColor(i * 3, config.isDarkMode); // 0, 3, 6, 9, 12
      final paint = Paint()
        ..color = color.withOpacity(config.opacity)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + i * (boxSize + spacing), y, boxSize, boxSize),
        Radius.circular(config.cornerRadius * config.scale * 0.5),
      );
      canvas.drawRRect(rect, paint);
    }

    // "More" label
    final moreTextPainter = TextPainter(
      text: TextSpan(
        text: AppStrings.legendMore,
        style: TextStyle(color: textColor, fontSize: 10 * config.scale),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    moreTextPainter.paint(
      canvas,
      Offset(startX + 5 * (boxSize + spacing) + 8 * config.scale, y),
    );
  }



  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) {
     if (oldDelegate.data != data) return true;
     if (oldDelegate.config != config) return true;
     if (oldDelegate.showHeader != showHeader) return true;
     if (oldDelegate.showQuote != showQuote) return true;
     if (oldDelegate.showLegend != showLegend) return true;
     return false;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EMPTY STATE - Shows when no data is available
// ══════════════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderDefault,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: AppTheme.iconXL,
                color: AppTheme.textMuted,
              ),
            )
                .animate()
                .scale(duration: AppTheme.animationSlow - 100.ms, curve: Curves.easeOutBack)
                .fadeIn(),

            const SizedBox(height: AppTheme.spacing24),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: AppTheme.spacing8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ERROR VIEW - Shows error messages with retry option
// ══════════════════════════════════════════════════════════════════════════

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool showRetry;

  const ErrorView({
    super.key,
    this.title = AppStrings.errorDefault,
    required this.message,
    this.onRetry,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppTheme.iconXL,
                color: AppTheme.error,
              ),
            )
                .animate()
                .scale(duration: AppTheme.animationSlow - 100.ms, curve: Curves.easeOutBack)
                .shake(duration: AppTheme.animationSlow),

            const SizedBox(height: AppTheme.spacing24),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: AppTheme.spacing8),

            // Error message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            // Retry button
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: AppTheme.iconSmall),
                label: const Text(AppStrings.tryAgain),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// LOADING SHIMMER - Animated loading placeholder
// ══════════════════════════════════════════════════════════════════════════

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.radiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = AppTheme.surfaceElevated;
    const highlightColor = AppTheme.surfaceHover;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: highlightColor, angle: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// STAT CARD - Displays a statistic with icon and gradient
// ══════════════════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient? gradient;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Gradient Accent (Subtle)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: gradient?.withOpacity(0.1) ??
                    LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05)
                      ],
                    ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
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
}

extension GradientExtension on Gradient {
  Gradient withOpacity(double opacity) {
    if (this is LinearGradient) {
      final g = this as LinearGradient;
      return LinearGradient(
        colors: g.colors.map((c) => c.withOpacity(opacity)).toList(),
        begin: g.begin,
        end: g.end,
        stops: g.stops,
        tileMode: g.tileMode,
        transform: g.transform,
      );
    }
    return this;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// LOADING INDICATOR - Full screen loading with message
// ══════════════════════════════════════════════════════════════════════════

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({super.key, this.message = AppStrings.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.greenPrimary),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SUCCESS BANNER - Animated success message
// ══════════════════════════════════════════════════════════════════════════

class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.success,
            size: AppTheme.iconMedium,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.animationNormal)
        .slideY(begin: -0.5, end: 0, duration: AppTheme.animationNormal, curve: Curves.easeOut);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SETTINGS TILE - Reusable settings list item
// ══════════════════════════════════════════════════════════════════════════

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading:
          Icon(icon, size: AppTheme.iconLarge, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
