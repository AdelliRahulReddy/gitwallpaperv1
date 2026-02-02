import 'app_constants.dart';

class GraphLayoutCalculator {
  static double baseGridWidth(int columns) {
    final baseCell = AppConstants.heatmapBoxSize + AppConstants.heatmapBoxSpacing;
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

