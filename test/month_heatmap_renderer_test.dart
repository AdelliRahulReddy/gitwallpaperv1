import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/models.dart';
import 'package:github_wallpaper/services.dart';

void main() {
  group('AppDateUtils.daysInMonth', () {
    test('returns 28 for February in a non-leap year', () {
      expect(AppDateUtils.daysInMonth(2023, 2), 28);
    });

    test('returns 29 for February in a leap year', () {
      expect(AppDateUtils.daysInMonth(2024, 2), 29);
    });

    test('handles century years correctly', () {
      expect(AppDateUtils.daysInMonth(1900, 2), 28);
      expect(AppDateUtils.daysInMonth(2000, 2), 29);
    });

    test('returns 30 for April/June/September/November', () {
      expect(AppDateUtils.daysInMonth(2025, 4), 30);
      expect(AppDateUtils.daysInMonth(2025, 6), 30);
      expect(AppDateUtils.daysInMonth(2025, 9), 30);
      expect(AppDateUtils.daysInMonth(2025, 11), 30);
    });

    test('returns 31 for all other months', () {
      expect(AppDateUtils.daysInMonth(2025, 1), 31);
      expect(AppDateUtils.daysInMonth(2025, 3), 31);
      expect(AppDateUtils.daysInMonth(2025, 5), 31);
      expect(AppDateUtils.daysInMonth(2025, 7), 31);
      expect(AppDateUtils.daysInMonth(2025, 8), 31);
      expect(AppDateUtils.daysInMonth(2025, 10), 31);
      expect(AppDateUtils.daysInMonth(2025, 12), 31);
    });

    test('throws for invalid months', () {
      expect(() => AppDateUtils.daysInMonth(2025, 0), throwsArgumentError);
      expect(() => AppDateUtils.daysInMonth(2025, 13), throwsArgumentError);
    });
  });

  group('MonthHeatmapRenderer.computeMonthCells', () {
    test('creates 28 cells for February in a non-leap year', () {
      final cells = MonthHeatmapRenderer.computeMonthCells(
        referenceDate: DateTime(2023, 2, 10),
      );
      expect(cells.length, 28);
      expect(cells.first.date, DateTime(2023, 2, 1));
      expect(cells.last.date, DateTime(2023, 2, 28));
    });

    test('creates 29 cells for February in a leap year', () {
      final cells = MonthHeatmapRenderer.computeMonthCells(
        referenceDate: DateTime(2024, 2, 10),
      );
      expect(cells.length, 29);
      expect(cells.last.date, DateTime(2024, 2, 29));
    });

    test('creates 30 cells for a 30-day month', () {
      final cells = MonthHeatmapRenderer.computeMonthCells(
        referenceDate: DateTime(2025, 4, 10),
      );
      expect(cells.length, 30);
      expect(cells.last.date, DateTime(2025, 4, 30));
    });

    test('creates 31 cells for a 31-day month', () {
      final cells = MonthHeatmapRenderer.computeMonthCells(
        referenceDate: DateTime(2025, 1, 10),
      );
      expect(cells.length, 31);
      expect(cells.last.date, DateTime(2025, 1, 31));
    });
  });
}

