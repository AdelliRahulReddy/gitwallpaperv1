import 'package:flutter/material.dart';
import '../models/contribution_data.dart';
import '../core/date_utils.dart';
import '../core/constants.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🎨 HEATMAP PAINTER - CLEAN & EFFICIENT
// ══════════════════════════════════════════════════════════════════════════
// Renders GitHub contribution heatmap on canvas for wallpaper generation
// ══════════════════════════════════════════════════════════════════════════

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
    this.cornerRadius = 2.0,
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
  });

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 MAIN PAINT
  // ════════════════════════════════════════════════════════════════════════

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final safeScale = scale.clamp(0.1, 5.0);
    final safeOpacity = opacity.clamp(0.0, 1.0);

    // Background
    final bgPaint = Paint()..color = _getBackgroundColor();
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Content (with error handling)
    try {
      _paintContent(canvas, size, safeScale, safeOpacity);
    } catch (e) {
      debugPrint('HeatmapPainter Error: $e');
      _drawError(canvas, size);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📐 CONTENT LAYOUT
  // ════════════════════════════════════════════════════════════════════════

  void _paintContent(
    Canvas canvas,
    Size size,
    double safeScale,
    double safeOpacity,
  ) {
    // Calculate grid dimensions
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final firstWeekday = AppDateUtils.getFirstWeekdayOfMonth();
    final offset = firstWeekday % 7;
    const cols = 7;
    final rows = ((daysInMonth + offset) / cols).ceil();

    // Calculate cell size
    final baseMargin = size.width * 0.05;
    final effectiveWidth =
        size.width - (baseMargin * 2) - paddingLeft - paddingRight;

    final baseCellSize = effectiveWidth / 8.5;
    final cellSize = baseCellSize * safeScale;
    final cellSpacing = cellSize * 0.2;

    // Grid dimensions
    final gridWidth = (cols * cellSize) + ((cols - 1) * cellSpacing);
    final gridHeight = (rows * cellSize) + ((rows - 1) * cellSpacing);

    // Section heights
    final headerHeight = cellSize * 1.5;
    final statsHeight = cellSize * 2.0;
    final quoteHeight = customQuote.isNotEmpty ? cellSize * 3.0 : 0.0;

    final gapLarge = cellSize * 1.0;
    final gapSmall = cellSize * 0.5;

    final totalHeight =
        headerHeight +
        gapLarge +
        gridHeight +
        gapSmall +
        statsHeight +
        (quoteHeight > 0 ? gapLarge + quoteHeight : 0);

    // Positioning
    final anchorX =
        (size.width - gridWidth) * horizontalPosition.clamp(0.0, 1.0);
    final anchorY =
        (size.height - totalHeight) * verticalPosition.clamp(0.0, 1.0);
    final startX = anchorX + paddingLeft - paddingRight;
    final startY = anchorY + paddingTop - paddingBottom;

    // Draw sections
    canvas.save();
    canvas.translate(startX, startY);

    double currentY = 0;

    // Header
    _drawHeader(canvas, gridWidth, cellSize, safeOpacity);
    currentY += headerHeight + gapLarge;

    // Grid
    canvas.save();
    canvas.translate(0, currentY);
    _drawGrid(
      canvas,
      cellSize,
      cellSpacing,
      cols,
      daysInMonth,
      offset,
      safeOpacity,
    );
    canvas.restore();
    currentY += gridHeight + gapSmall;

    // Stats
    canvas.save();
    canvas.translate(0, currentY);
    _drawStats(canvas, gridWidth, cellSize, safeOpacity);
    canvas.restore();
    currentY += statsHeight;

    // Quote
    if (customQuote.isNotEmpty) {
      currentY += gapLarge;
      canvas.save();
      canvas.translate(0, currentY);
      _drawQuote(canvas, gridWidth, safeOpacity);
      canvas.restore();
    }

    canvas.restore();
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🖼️ DRAWING COMPONENTS
  // ════════════════════════════════════════════════════════════════════════

  void _drawHeader(Canvas canvas, double width, double cellSize, double alpha) {
    final text = '${AppDateUtils.getCurrentMonthName()} ${DateTime.now().year}'
        .toUpperCase();
    final fontSize = (cellSize * 1.2).clamp(12.0, 48.0);

    _drawCenteredText(
      canvas,
      text,
      width,
      0,
      TextStyle(
        color: _getTextColor().withOpacity(alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
      ),
    );
  }

  void _drawGrid(
    Canvas canvas,
    double size,
    double spacing,
    int cols,
    int days,
    int offset,
    double alpha,
  ) {
    final now = DateTime.now();

    for (int i = 1; i <= days; i++) {
      final index = i - 1 + offset;
      final col = index % cols;
      final row = index ~/ cols;

      final x = col * (size + spacing);
      final y = row * (size + spacing);

      final count = data.dailyContributions[i] ?? 0;
      final color = _getCellColor(count);

      // Draw cell
      final paint = Paint()..color = color.withOpacity(alpha);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, size, size),
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(rect, paint);

      // Today indicator
      if (i == now.day) {
        final borderPaint = Paint()
          ..color = AppConstants.todayHighlight.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.15;
        canvas.drawRRect(rect.deflate(size * 0.05), borderPaint);
      }
    }
  }

  void _drawStats(Canvas canvas, double width, double cellSize, double alpha) {
    final stats = [
      'TOTAL: ${data.totalContributions}',
      'STREAK: ${data.currentStreak}',
      'TODAY: ${data.todayCommits}',
    ];

    final fontSize = (cellSize * 0.5).clamp(8.0, 16.0);
    final sectionWidth = width / stats.length;

    for (int i = 0; i < stats.length; i++) {
      final x = sectionWidth * i;
      _drawCenteredText(
        canvas,
        stats[i],
        sectionWidth,
        x,
        TextStyle(
          color: _getTextColor().withOpacity(alpha * 0.7),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        verticalCenter: cellSize * 2.0,
      );
    }
  }

  void _drawQuote(Canvas canvas, double width, double alpha) {
    final painter = TextPainter(
      text: TextSpan(
        text: '"$customQuote"',
        style: TextStyle(
          color: _getTextColor().withOpacity(alpha * quoteOpacity),
          fontSize: quoteFontSize,
          fontStyle: FontStyle.italic,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );
    painter.layout(maxWidth: width);
    painter.paint(canvas, Offset((width - painter.width) / 2, 0));
  }

  void _drawError(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red.withOpacity(0.3);
    canvas.drawRect(Offset.zero & size, paint);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ════════════════════════════════════════════════════════════════════════

  void _drawCenteredText(
    Canvas canvas,
    String text,
    double width,
    double offsetX,
    TextStyle style, {
    double? verticalCenter,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: width);

    final x = offsetX + (width - painter.width) / 2;
    final y = verticalCenter != null
        ? (verticalCenter - painter.height) / 2
        : 0.0; // ← FIXED: Changed 0 to 0.0

    painter.paint(canvas, Offset(x, y));
  }

  Color _getCellColor(int count) {
    if (isDarkMode) {
      if (count == 0) return AppConstants.heatmapDarkBox;
      if (count <= 3) return AppConstants.heatmapDarkLevel1;
      if (count <= 6) return AppConstants.heatmapDarkLevel2;
      if (count <= 9) return AppConstants.heatmapDarkLevel3;
      return AppConstants.heatmapDarkLevel4;
    } else {
      if (count == 0) return AppConstants.heatmapLightBox;
      if (count <= 3) return AppConstants.heatmapLightLevel1;
      if (count <= 6) return AppConstants.heatmapLightLevel2;
      if (count <= 9) return AppConstants.heatmapLightLevel3;
      return AppConstants.heatmapLightLevel4;
    }
  }

  Color _getBackgroundColor() {
    return isDarkMode
        ? AppConstants.heatmapDarkBg
        : AppConstants.heatmapLightBg;
  }

  Color _getTextColor() {
    return isDarkMode ? Colors.white : Colors.black;
  }

  @override
  bool shouldRepaint(HeatmapPainter old) {
    return old.verticalPosition != verticalPosition ||
        old.horizontalPosition != horizontalPosition ||
        old.scale != scale ||
        old.opacity != opacity ||
        old.customQuote != customQuote ||
        old.isDarkMode != isDarkMode ||
        old.cornerRadius != cornerRadius ||
        old.paddingTop != paddingTop ||
        old.paddingBottom != paddingBottom ||
        old.paddingLeft != paddingLeft ||
        old.paddingRight != paddingRight ||
        old.quoteFontSize != quoteFontSize ||
        old.quoteOpacity != quoteOpacity;
  }
}
