import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/graph_layout.dart';

void main() {
  group('GraphLayoutCalculator.fitScale', () {
    test('fits grid width to fillFraction for year columns', () {
      const availableWidth = 1000.0;
      const columns = 53;
      const fillFraction = 0.95;

      final scale = GraphLayoutCalculator.fitScale(
        availableWidth: availableWidth,
        columns: columns,
        fillFraction: fillFraction,
      );

      final baseGrid = GraphLayoutCalculator.baseGridWidth(columns);
      final scaledGrid = baseGrid * scale;
      expect(scaledGrid, closeTo(availableWidth * fillFraction, 0.0001));
    });

    test('fits grid width to fillFraction for month columns', () {
      const availableWidth = 360.0;
      const columns = 7;
      const fillFraction = 0.95;

      final scale = GraphLayoutCalculator.fitScale(
        availableWidth: availableWidth,
        columns: columns,
        fillFraction: fillFraction,
      );

      final baseGrid = GraphLayoutCalculator.baseGridWidth(columns);
      final scaledGrid = baseGrid * scale;
      expect(scaledGrid, closeTo(availableWidth * fillFraction, 0.0001));
    });
  });

  group('Preview transform invariance', () {
    test('fractional width is invariant under wallpaper-to-preview scaling', () {
      const wallpaperWidth = 1080.0;
      const previewWidth = 324.0;
      const gridWidthInWallpaperCoords = 540.0;

      final scaleX = previewWidth / wallpaperWidth;
      final gridWidthInPreviewCoords = gridWidthInWallpaperCoords * scaleX;

      final wallpaperFraction = gridWidthInWallpaperCoords / wallpaperWidth;
      final previewFraction = gridWidthInPreviewCoords / previewWidth;

      expect(previewFraction, closeTo(wallpaperFraction, 0.0000001));
    });
  });
}

