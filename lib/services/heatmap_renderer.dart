
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/models.dart';
import 'utils.dart'; // For AppConfig and DateHelper

/// Shared renderer for drawing the GitHub contribution heatmap.
/// Used by both the live preview (HeatmapPainter) and the wallpaper generator (WallpaperService).
class HeatmapRenderer {
  
  /// Renders the full heatmap to the given canvas.
  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    double pixelRatio = 1.0,
    bool showHeader = true,
    bool drawBackground = true,
  }) {
    // Background
    if (drawBackground) {
      final bgPaint = Paint()
        ..color = config.isDarkMode
            ? AppConfig.heatmapDarkBg
            : AppConfig.heatmapLightBg;
      
      // Fill the entire canvas/size with background
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }

    final daysInMonth = DateHelper.getDaysInCurrentMonth();
    final firstWeekday = DateHelper.getFirstWeekdayOfMonth();

    // Scale calculation:
    // Preview: pixelRatio = 1.0 -> effectiveScale = config.scale
    // Wallpaper: pixelRatio = devicePixelRatio -> effectiveScale = config.scale * DPR
    final double effectiveScale = config.scale * pixelRatio; 

    final boxSize = AppConfig.boxSize * effectiveScale;
    final boxSpacing = AppConfig.boxSpacing * effectiveScale;
    final cellSize = boxSize + boxSpacing;

    final numWeeks = ((daysInMonth + firstWeekday - 1) / 7).ceil();
    final gridWidth = numWeeks * cellSize;
    final gridHeight = 7 * cellSize;

    // Calculate offsets
    final leftLabelWidth = 25.0 * effectiveScale;
    final contentWidth = gridWidth + leftLabelWidth;

    // Fix Padding: Scaling should apply consistently
    // If pixelRatio represents DPR, we might need to scale padding too, 
    // but typically config.padding is in logical pixels.
    // If effectiveScale includes DPR, then we should probably scale padding by effectiveScale?
    // Wait, let's stick to pixelRatio for padding to match screen density, 
    // BUT config.padding is usually small (0-100), so let's use effectiveScale for visual consistency with the grid size.
    
    // CHANGED: Using effectiveScale for padding to ensure it grows/shrinks with the heatmap
    final paddingMultiplier = effectiveScale; 

    final adjustedXOffset = (size.width - contentWidth) * config.horizontalPosition + 
        (config.paddingLeft * paddingMultiplier) - 
        (config.paddingRight * paddingMultiplier);
        
    final adjustedYOffset = (size.height - gridHeight) * config.verticalPosition + 
        (config.paddingTop * paddingMultiplier) - 
        (config.paddingBottom * paddingMultiplier);

    // 1. Draw Header
    if (showHeader) {
      _drawHeader(
        canvas: canvas, 
        x: adjustedXOffset + leftLabelWidth, 
        y: adjustedYOffset - 30 * effectiveScale, 
        width: gridWidth, 
        scale: effectiveScale, 
        isDarkMode: config.isDarkMode
      );
    }

    // 2. Draw Grid
    _drawContributionGrid(
      canvas: canvas,
      data: data,
      xOffset: adjustedXOffset + leftLabelWidth,
      yOffset: adjustedYOffset,
      boxSize: boxSize,
      cellSize: cellSize,
      firstWeekday: firstWeekday,
      daysInMonth: daysInMonth,
      config: config,
      paddingMultiplier: paddingMultiplier,
    );

    // 3. Weekday Labels
    _drawWeekdayLabels(
      canvas: canvas,
      x: adjustedXOffset,
      y: adjustedYOffset,
      cellSize: cellSize,
      scale: effectiveScale,
      isDarkMode: config.isDarkMode,
    );

    // 4. Quote
    if (config.customQuote.isNotEmpty) {
      _drawQuote(
        canvas: canvas,
        config: config,
        x: adjustedXOffset,
        y: adjustedYOffset + gridHeight + 20 * effectiveScale,
        width: gridWidth,
        effectiveScale: effectiveScale,
      );
    }
  }

  // Cache DateFormat to avoid re-creation on every render
  static final _monthFormatter = intl.DateFormat('MMM yyyy');

  static void _drawHeader({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double scale,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode
        ? AppConfig.heatmapDarkBox.withOpacity(0.8)
        : AppConfig.heatmapLightBox.withOpacity(0.8);

    final monthName = _monthFormatter.format(DateTime.now());
    final monthPainter = TextPainter(
      text: TextSpan(
        text: monthName,
        style: TextStyle(
          color: textColor,
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    monthPainter.paint(canvas, Offset(x, y));
  }

  static void _drawWeekdayLabels({
    required Canvas canvas,
    required double x,
    required double y,
    required double cellSize,
    required double scale,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode
        ? AppConfig.heatmapDarkBox.withOpacity(0.6)
        : AppConfig.heatmapLightBox.withOpacity(0.6);

    final labels = ['Mon', 'Wed', 'Fri'];
    final indices = [1, 3, 5];

    for (int i = 0; i < labels.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: textColor,
            fontSize: 10 * scale,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final yPos = y + (indices[i] * cellSize) + (cellSize - painter.height) / 2;
      painter.paint(canvas, Offset(x, yPos));
    }
  }

  static void _drawContributionGrid({
    required Canvas canvas,
    required CachedContributionData data,
    required double xOffset,
    required double yOffset,
    required double boxSize,
    required double cellSize,
    required int firstWeekday,
    required int daysInMonth,
    required WallpaperConfig config,
    required double paddingMultiplier,
  }) {
    final today = DateHelper.getCurrentDayOfMonth();
    final boxPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConfig.todayBorderWidth * paddingMultiplier
      ..color = AppConfig.todayHighlight;

    for (int day = 1; day <= daysInMonth; day++) {
      final dayIndex = day + firstWeekday - 2;
      final week = dayIndex ~/ 7;
      final weekday = dayIndex % 7;

      final x = xOffset + week * cellSize;
      final y = yOffset + weekday * cellSize;

      final contributions = data.getContributionsForDay(day);
      final color = getContributionColor(contributions, config.isDarkMode);

      boxPaint.color = color.withOpacity(config.opacity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxSize, boxSize),
        Radius.circular(config.cornerRadius * paddingMultiplier),
      );
      canvas.drawRRect(rect, boxPaint);

      if (day == today) {
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  static void _drawQuote({
    required Canvas canvas,
    required WallpaperConfig config,
    required double x,
    required double y,
    required double width,
    required double effectiveScale,
  }) {
    final textColor = config.isDarkMode
        ? Colors.white.withOpacity(config.quoteOpacity)
        : Colors.black.withOpacity(config.quoteOpacity);

    final quotePainter = TextPainter(
      text: TextSpan(
        text: config.customQuote,
        style: TextStyle(
          color: textColor,
          fontSize: config.quoteFontSize * effectiveScale,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);

    quotePainter.paint(canvas, Offset(x + (width - quotePainter.width) / 2, y));
  }

  static Color getContributionColor(int count, bool isDarkMode) {
    if (isDarkMode) {
      if (count == 0) return AppConfig.heatmapDarkBox;
      if (count <= 3) return AppConfig.heatmapDarkLevel1;
      if (count <= 6) return AppConfig.heatmapDarkLevel2;
      if (count <= 9) return AppConfig.heatmapDarkLevel3;
      return AppConfig.heatmapDarkLevel4;
    } else {
      if (count == 0) return AppConfig.heatmapLightBox;
      if (count <= 3) return AppConfig.heatmapLightLevel1;
      if (count <= 6) return AppConfig.heatmapLightLevel2;
      if (count <= 9) return AppConfig.heatmapLightLevel3;
      return AppConfig.heatmapLightLevel4;
    }
  }
}
