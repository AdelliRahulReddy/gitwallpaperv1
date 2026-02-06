import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';

import 'app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════
// 📐 GRAPH LAYOUT
// ══════════════════════════════════════════════════════════════════════════

class GraphLayoutCalculator {
  static double baseGridWidth(int columns) {
    final baseCell =
        AppConstants.heatmapBoxSize + AppConstants.heatmapBoxSpacing;
    return (columns * baseCell) - AppConstants.heatmapBoxSpacing;
  }

  static double fitScale({
    required double availableWidth,
    required int columns,
    double fillFraction = 0.95,
  }) {
    final baseGrid = baseGridWidth(columns);
    if (availableWidth <= 0 || baseGrid <= 0) return 1.0;
    final target = availableWidth * fillFraction;
    return (target / baseGrid).clamp(0.1, 10.0);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎨 MONTH HEATMAP RENDERER
// ══════════════════════════════════════════════════════════════════════════

class MonthHeatmapCell {
  final DateTime date;
  final int dayIndex;

  const MonthHeatmapCell({
    required this.date,
    required this.dayIndex,
  });
}

class MonthHeatmapRenderer {
  static final AppThemeExtension _lightTheme = AppThemeExtension.light();
  static final AppThemeExtension _darkTheme = AppThemeExtension.dark();

  static List<MonthHeatmapCell> computeMonthCells({DateTime? referenceDate}) {
    final ref = (referenceDate ?? AppDateUtils.nowUtc).toUtc();
    final days = AppDateUtils.daysInMonth(ref.year, ref.month);
    return List<MonthHeatmapCell>.generate(
      days,
      (i) => MonthHeatmapCell(
          date: DateTime.utc(ref.year, ref.month, i + 1), dayIndex: i),
    );
  }

  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    DateTime? referenceDate,
    DateTime? todayUtc,
  }) {
    final themeExt = config.isDarkMode ? _darkTheme : _lightTheme;

    final bgPaint = Paint()
      ..color = config.isDarkMode ? AppTheme.githubDarkCard : AppTheme.bgWhite;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final DateTime ref = (referenceDate ?? AppDateUtils.nowUtc).toUtc();

    final cells = computeMonthCells(referenceDate: ref);

    final availableWidth =
        size.width - config.paddingLeft - config.paddingRight;
    final availableHeight =
        size.height - config.paddingTop - config.paddingBottom;

    final baseScale = config.autoFitWidth
        ? GraphLayoutCalculator.fitScale(
            availableWidth: availableWidth,
            columns: AppConstants.monthGridColumns,
            fillFraction: 0.95,
          )
        : config.scale;

    final effectiveScale = baseScale;
    final boxSize = AppConstants.heatmapBoxSize * effectiveScale;
    final spacing = AppConstants.heatmapBoxSpacing * effectiveScale;
    final cellSize = boxSize + spacing;
    final columns = AppConstants.monthGridColumns;

    // Calculate Calendar Layout
    final firstOfMonth = DateTime.utc(ref.year, ref.month, 1);
    final weekdayOffset = firstOfMonth.weekday % 7;
    final totalCells = cells.length + weekdayOffset;
    final dynamicRows = (totalCells / columns).ceil();

    final gridWidth = (columns * cellSize) - spacing;
    final gridHeight = (dynamicRows * cellSize) - spacing;

    final rawXStart = config.paddingLeft +
        ((availableWidth - gridWidth) * config.horizontalPosition);
    final maxX = size.width - config.paddingRight - gridWidth;
    final xStart = rawXStart.clamp(
      config.paddingLeft,
      maxX < config.paddingLeft ? config.paddingLeft : maxX,
    );

    final headerColor =
        (config.isDarkMode ? AppTheme.bgLight : AppTheme.textPrimary)
            .withValues(alpha: 0.8);
    final headerText = RenderUtils.headerTextForDate(ref);

    final headerPainter = RenderUtils.drawText(
      canvas: canvas,
      text: headerText,
      style: TextStyle(
        color: headerColor,
        fontSize: 16 * effectiveScale,
        fontWeight: FontWeight.bold,
      ),
      offset: Offset.zero,
      maxWidth: gridWidth,
      paint: false,
    );

    // Weekday Labels
    const dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final dayLabelStyle = TextStyle(
      color: headerColor.withValues(alpha: 0.6),
      fontSize: 7 * effectiveScale,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    final headerGap = (spacing * 3).clamp(spacing, boxSize);
    final labelsRowHeight = 12 * effectiveScale;
    final labelsGap = spacing * 2;

    double quoteHeight = 0.0;
    double quoteGap = 0.0;
    if (config.customQuote.isNotEmpty) {
      final quoteColor = config.isDarkMode
          ? AppTheme.textWhite.withValues(alpha: config.quoteOpacity)
          : AppTheme.textPrimary.withValues(alpha: config.quoteOpacity);

      final quotePainter = RenderUtils.drawText(
        canvas: canvas,
        text: config.customQuote,
        style: TextStyle(
          color: quoteColor,
          fontSize: config.quoteFontSize * effectiveScale,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: gridWidth,
        maxLines: 3,
        textAlign: TextAlign.center,
        offset: Offset.zero,
        paint: false,
      );
      quoteHeight = quotePainter.height;
      quotePainter.dispose();
      quoteGap = (spacing * 4).clamp(spacing, boxSize * 1.5);
    }

    final totalBlockHeight = headerPainter.height +
        headerGap +
        labelsRowHeight +
        labelsGap +
        gridHeight +
        quoteGap +
        quoteHeight;
    final rawYStartBlock = config.paddingTop +
        ((availableHeight - totalBlockHeight) * config.verticalPosition);
    final maxY = size.height - config.paddingBottom - totalBlockHeight;
    final yStartBlock = rawYStartBlock.clamp(
      config.paddingTop,
      maxY < config.paddingTop ? config.paddingTop : maxY,
    );
    final yHeader = yStartBlock;

    headerPainter.paint(canvas, Offset(xStart, yHeader));

    final yLabels = yHeader + headerPainter.height + headerGap;
    headerPainter.dispose();

    for (int i = 0; i < dayLabels.length; i++) {
      RenderUtils.drawText(
        canvas: canvas,
        text: dayLabels[i],
        style: dayLabelStyle,
        offset: Offset(xStart + (i * cellSize), yLabels),
        maxWidth: boxSize,
        textAlign: TextAlign.center,
      ).dispose();
    }

    final yStart = yLabels + labelsRowHeight + labelsGap;
    final heatmapLevels = themeExt.heatmapLevels;

    final boxPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (spacing / 1.5).clamp(1.0, boxSize * 0.2)
      ..color = themeExt.heatmapTodayHighlight;

    final radius =
        RenderUtils.getCachedRadius(config.cornerRadius, effectiveScale);
    final today =
        AppDateUtils.toDateOnlyUtc((todayUtc ?? AppDateUtils.nowUtc).toUtc());
    final canPaintText = boxSize >= 12.0;
    final textColor = config.isDarkMode
        ? AppTheme.textWhite.withValues(alpha: 0.9)
        : AppTheme.textPrimary.withValues(alpha: 0.85);
    final countTextStyle = TextStyle(
      color: textColor,
      fontSize: boxSize * 0.45,
      fontWeight: FontWeight.w600,
    );
    final countPainters = <int, TextPainter>{};

    TextPainter getCountPainter(int count) {
      return countPainters.putIfAbsent(
        count,
        () => RenderUtils.drawText(
          canvas: canvas,
          text: '$count',
          style: countTextStyle,
          offset: Offset.zero,
          maxWidth: boxSize,
          textAlign: TextAlign.center,
          maxLines: 1,
          paint: false,
        ),
      );
    }

    for (final cell in cells) {
      final i = cell.dayIndex + weekdayOffset; // Adjust for weekday
      final col = i % columns;
      final row = i ~/ columns;

      final count = data.getContributionsForDate(cell.date);
      // Audit Fix: Use dynamic quartiles from data
      final level =
          RenderUtils.getContributionLevel(count, quartiles: data.quartiles);

      final cellColor = heatmapLevels.length > level
          ? heatmapLevels[level]
          : heatmapLevels[0];
      boxPaint.color = cellColor.withValues(alpha: config.opacity);

      final x = xStart + (col * cellSize);
      final y = yStart + (row * cellSize);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxSize, boxSize),
        radius,
      );
      canvas.drawRRect(rect, boxPaint);

      if (AppDateUtils.isSameDay(cell.date, today)) {
        canvas.drawRRect(rect, borderPaint);
      }

      if (canPaintText && count > 0) {
        final textPainter = getCountPainter(count);

        final textY = y + (boxSize - textPainter.height) / 2;
        textPainter.paint(
            canvas, Offset(x + (boxSize - textPainter.width) / 2, textY));
      }
    }

    for (final painter in countPainters.values) {
      painter.dispose();
    }

    if (config.customQuote.isNotEmpty) {
      RenderUtils.drawText(
        canvas: canvas,
        text: config.customQuote,
        style: TextStyle(
          color: config.isDarkMode
              ? AppTheme.textWhite.withValues(alpha: config.quoteOpacity)
              : AppTheme.textPrimary.withValues(alpha: config.quoteOpacity),
          fontSize: config.quoteFontSize * effectiveScale,
          fontStyle: FontStyle.italic,
        ),
        maxWidth: gridWidth,
        offset: Offset(xStart, yStart + gridHeight + quoteGap),
        textAlign: TextAlign.center,
        maxLines: 3,
      ).dispose();
    }
  }
}
