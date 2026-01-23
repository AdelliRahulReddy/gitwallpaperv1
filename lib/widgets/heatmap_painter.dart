import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/contribution_data.dart';
import '../core/date_utils.dart';

class HeatmapPainter extends CustomPainter {
  final CachedContributionData data;
  final bool isDarkMode;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final double opacity;
  final String customQuote;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final double cornerRadius;
  final double quoteFontSize;
  final double quoteOpacity;

  HeatmapPainter({
    required this.data,
    required this.isDarkMode,
    required this.verticalPosition,
    required this.horizontalPosition,
    required this.scale,
    required this.opacity,
    required this.customQuote,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.cornerRadius = 0.0,
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ GUARD: Validate canvas size
    if (size.width <= 0 || size.height <= 0) {
      debugPrint('HeatmapPainter: Invalid canvas size: $size');
      return;
    }

    // ✅ GUARD: Validate parameters
    final safeScale = scale.clamp(0.3, 3.0);
    final safeOpacity = opacity.clamp(0.0, 1.0);
    final safeQuoteOpacity = quoteOpacity.clamp(0.0, 1.0);

    if (safeScale != scale || safeOpacity != opacity) {
      debugPrint('HeatmapPainter: Clamped invalid parameters');
    }

    try {
      _paintSafe(canvas, size, safeScale, safeOpacity, safeQuoteOpacity);
    } catch (e, stackTrace) {
      debugPrint('HeatmapPainter: Rendering error: $e');
      debugPrint('Stack trace: $stackTrace');

      // ✅ Draw error indicator instead of crashing
      _drawErrorState(canvas, size);
    }
  }

  void _paintSafe(
    Canvas canvas,
    Size size,
    double safeScale,
    double safeOpacity,
    double safeQuoteOpacity,
  ) {
    // Draw background
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Calculate layout
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final firstWeekday = AppDateUtils.getFirstWeekdayOfMonth();
    // Offset for Sunday start (0 = Sun, 1 = Mon, ..., 6 = Sat)
    final offset = firstWeekday % 7; 
    const cols = 7;
    final rows = ((daysInMonth + offset) / cols).ceil();

    // Use padding for margins
    final marginX = size.width * 0.05;
    final marginY = size.height * 0.08;

    final availableWidth = size.width - (marginX * 2);
    final availableHeight = size.height - (marginY * 2);

    // ✅ GUARD: Check available space
    if (availableWidth <= 0 || availableHeight <= 0) {
      debugPrint('HeatmapPainter: Insufficient space after margins');
      return;
    }

    // Calculate cell size
    const cellSpacingRatio = 0.15;
    final totalCellUnits = cols + (cols - 1) * cellSpacingRatio;

    // ✅ GUARD: Prevent division by zero
    if (totalCellUnits == 0) {
      debugPrint('HeatmapPainter: Invalid cell calculation');
      return;
    }

    final baseCellSize = availableWidth / totalCellUnits;
    final cellSize = baseCellSize * safeScale;

    // ✅ GUARD: Ensure minimum renderable cell size
    if (cellSize < 8.0) {
      debugPrint(
        'HeatmapPainter: Cell too small ($cellSize), using minimum 8.0',
      );
      // Still render, but with minimum size
    }

    final cellSpacing = cellSize * cellSpacingRatio;

    // Grid dimensions
    final heatmapWidth = (cols * cellSize) + ((cols - 1) * cellSpacing);
    final heatmapHeight = (rows * cellSize) + ((rows - 1) * cellSpacing);

    // Layout sections - Measure actual heights
    final headerPainter = _getHeaderPainter(heatmapWidth, cellSize, safeOpacity);
    final headerHeight = headerPainter.height;
    final headerGap = cellSize * 1.5; // ✅ INCREASED: from 0.8 to 1.5 to prevent collapsing

    final statsHeight = _getStatsHeight(heatmapWidth, cellSize);
    final statsGap = cellSize * 0.5;

    final quotePainter = customQuote.isNotEmpty 
        ? _getQuotePainter(heatmapWidth, cellSize, safeOpacity, safeQuoteOpacity)
        : null;
    final quoteHeight = quotePainter?.height ?? 0.0;

    final totalContentHeight =
        headerHeight +
        headerGap +
        heatmapHeight +
        statsGap +
        statsHeight +
        (quoteHeight > 0 ? statsGap * 1.5 + quoteHeight : 0);

    // Center content
    final centerX =
        marginX +
        (availableWidth - heatmapWidth) * horizontalPosition.clamp(0.0, 1.0);
    final centerY =
        marginY +
        (availableHeight - totalContentHeight) *
            verticalPosition.clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(centerX, centerY);

    double currentY = 0;

    // 1. Draw month header
    _drawCenteredHeaderFromPainter(canvas, heatmapWidth, headerPainter);
    currentY += headerHeight + headerGap;

    // 2. Draw heatmap grid
    canvas.save();
    canvas.translate(0, currentY);
    _drawHeatmapGrid(
      canvas,
      cellSize,
      cellSpacing,
      cols,
      rows,
      daysInMonth,
      offset, // Pass offset here
      safeOpacity,
    );
    canvas.restore();
    currentY += heatmapHeight + statsGap;

    // 3. Draw stats row
    canvas.save();
    canvas.translate(0, currentY);
    _drawCenteredStats(canvas, heatmapWidth, cellSize, safeOpacity);
    canvas.restore();
    currentY += statsHeight;

    // 4. Draw quote if provided
    if (quotePainter != null) {
      currentY += statsGap * 1.5; // Extra gap before quote
      canvas.save();
      canvas.translate(0, currentY);
      _drawCenteredQuoteFromPainter(canvas, heatmapWidth, quotePainter);
      canvas.restore();
    }

    canvas.restore();
  }

  TextPainter _getHeaderPainter(double heatmapWidth, double cellSize, double safeOpacity) {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final headerText = '$monthName $year';

    final painter = TextPainter(
      text: TextSpan(
        text: headerText,
        style: TextStyle(
          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(
            safeOpacity,
          ),
          fontSize: (cellSize * 1.8).clamp(14.0, 100.0), // ✅ Slightly larger min
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: heatmapWidth);
    return painter;
  }

  void _drawCenteredHeaderFromPainter(
    Canvas canvas,
    double heatmapWidth,
    TextPainter painter,
  ) {
    final headerX = (heatmapWidth - painter.width) / 2;
    painter.paint(canvas, Offset(headerX, 0));
  }

  void _drawHeatmapGrid(
    Canvas canvas,
    double cellSize,
    double cellSpacing,
    int cols,
    int rows,
    int daysInMonth,
    int offset,
    double safeOpacity,
  ) {
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    for (int day = 1; day <= daysInMonth; day++) {
      final index = day - 1 + offset;
      final row = index ~/ cols;
      final col = index % cols;

      final x = col * (cellSize + cellSpacing);
      final y = row * (cellSize + cellSpacing);

      final contributions = data.dailyContributions[day] ?? 0;
      final color = _getContributionColor(contributions);

      final cellPaint = Paint()
        ..color = color.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;

      final radius = cellSize * 0.15;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        Radius.circular(cornerRadius > 0 ? cornerRadius : radius),
      );

      canvas.drawRRect(rect, cellPaint);

      // Draw day number inside cell (only if cell is large enough)
      if (cellSize >= 12.0) {
        final dayPainter = TextPainter(
          text: TextSpan(
            text: '$day',
            style: TextStyle(
              color: _getTextColorForCell(
                contributions,
                day <= currentDay,
              ).withOpacity(safeOpacity),
              fontSize: (cellSize * 0.4).clamp(
                8.0,
                24.0,
              ), // ✅ Min/max font size
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        dayPainter.layout();

        final textX = x + (cellSize - dayPainter.width) / 2;
        final textY = y + (cellSize - dayPainter.height) / 2;
        dayPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  double _getStatsHeight(double heatmapWidth, double cellSize) {
    // Measure icons and labels
    final iconFontSize = (cellSize * 0.9).clamp(14.0, 48.0);
    final labelFontSize = (cellSize * 0.45).clamp(10.0, 20.0);
    // Rough estimate but safe: icon height + margin + label height
    // Better to use representative painters
    return iconFontSize + 4 + labelFontSize + 8;
  }

  void _drawCenteredStats(
    Canvas canvas,
    double heatmapWidth,
    double cellSize,
    double safeOpacity,
  ) {
    final stats = [
      {'label': 'Total', 'value': '${data.totalContributions}', 'icon': '📊'},
      {'label': 'Streak', 'value': '${data.currentStreak}d', 'icon': '🔥'},
      {'label': 'Today', 'value': '${data.todayCommits}', 'icon': '✨'},
    ];

    final statWidth = heatmapWidth / stats.length;

    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final centerX = statWidth * i + statWidth / 2;

      // Icon
      final iconPainter = TextPainter(
        text: TextSpan(
          text: stat['icon'],
          style: TextStyle(
            fontSize: (cellSize * 0.9).clamp(14.0, 48.0), 
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();

      // Value
      final valuePainter = TextPainter(
        text: TextSpan(
          text: stat['value'],
          style: TextStyle(
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(
              safeOpacity,
            ),
            fontSize: (cellSize * 0.7).clamp(12.0, 36.0), 
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: stat['label'],
          style: TextStyle(
            color: (isDarkMode ? Colors.white70 : Colors.black54).withOpacity(
              safeOpacity,
            ),
            fontSize: (cellSize * 0.45).clamp(10.0, 20.0), 
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      // Draw centered
      final totalStatWidth = iconPainter.width + 8 + valuePainter.width;
      final startX = centerX - totalStatWidth / 2;

      iconPainter.paint(canvas, Offset(startX, 0));
      valuePainter.paint(
        canvas,
        Offset(
          startX + iconPainter.width + 8,
          (iconPainter.height - valuePainter.height) / 2,
        ),
      );
      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, iconPainter.height + 4),
      );
    }
  }

  TextPainter _getQuotePainter(
    double heatmapWidth,
    double cellSize,
    double safeOpacity,
    double safeQuoteOpacity,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: '"$customQuote"',
        style: TextStyle(
          color: (isDarkMode ? Colors.white70 : Colors.black54).withOpacity(
            safeOpacity * safeQuoteOpacity,
          ),
          fontSize: (cellSize * 0.55).clamp(12.0, 24.0),
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    );
    painter.layout(maxWidth: heatmapWidth);
    return painter;
  }

  void _drawCenteredQuoteFromPainter(
    Canvas canvas,
    double heatmapWidth,
    TextPainter painter,
  ) {
    final quoteX = (heatmapWidth - painter.width) / 2;
    painter.paint(canvas, Offset(quoteX, 0));
  }

  /// ✅ GitHub contribution color scale (darker = more contributions)
  Color _getContributionColor(int contributions) {
    if (isDarkMode) {
      if (contributions == 0) {
        return const Color(0xFF161B22);
      } else if (contributions <= 3) {
        return const Color(0xFF0E4429);
      } else if (contributions <= 6) {
        return const Color(0xFF006D32);
      } else if (contributions <= 9) {
        return const Color(0xFF26A641);
      } else {
        return const Color(0xFF39D353);
      }
    } else {
      // Light Mode (GitHub standard light green scale)
      if (contributions == 0) {
        return const Color(0xFFEBEDF0);
      } else if (contributions <= 3) {
        return const Color(0xFF9BE9A8);
      } else if (contributions <= 6) {
        return const Color(0xFF40C463);
      } else if (contributions <= 9) {
        return const Color(0xFF30A14E);
      } else {
        return const Color(0xFF216E39);
      }
    }
  }

  Color _getTextColorForCell(int contributions, bool isPast) {
    if (!isPast) {
      return isDarkMode ? Colors.white24 : Colors.black26;
    }
    if (contributions == 0) {
      return isDarkMode ? Colors.white54 : Colors.black54;
    } else {
      return Colors.white;
    }
  }

  /// ✅ Draw error state if rendering fails
  void _drawErrorState(Canvas canvas, Size size) {
    final errorPaint = Paint()..color = Colors.red.withOpacity(0.1);
    canvas.drawRect(Offset.zero & size, errorPaint);

    final errorText = TextPainter(
      text: const TextSpan(
        text: 'Rendering Error',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    errorText.layout();
    errorText.paint(
      canvas,
      Offset(
        (size.width - errorText.width) / 2,
        (size.height - errorText.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) {
    return oldDelegate.verticalPosition != verticalPosition ||
        oldDelegate.horizontalPosition != horizontalPosition ||
        oldDelegate.scale != scale ||
        oldDelegate.opacity != opacity ||
        oldDelegate.customQuote != customQuote ||
        oldDelegate.paddingTop != paddingTop ||
        oldDelegate.paddingBottom != paddingBottom ||
        oldDelegate.paddingLeft != paddingLeft ||
        oldDelegate.paddingRight != paddingRight ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.quoteFontSize != quoteFontSize ||
        oldDelegate.quoteOpacity != quoteOpacity ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
