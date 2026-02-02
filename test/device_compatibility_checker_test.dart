import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/models.dart';
import 'package:github_wallpaper/services.dart';

void main() {
  group('DeviceCompatibilityChecker.applyPlacement', () {
    test('keeps user paddings when they exceed computed insets', () {
      const metrics = DeviceMetrics(
        width: 1080,
        height: 2400,
        pixelRatio: 3.0,
        safeInsets: EdgeInsets.fromLTRB(0, 24, 0, 0),
        model: 'PIXEL 8',
      );

      final base = WallpaperConfig.defaults().copyWith(
        paddingTop: 500,
        paddingBottom: 400,
        paddingLeft: 100,
        paddingRight: 120,
      );

      final effective = DeviceCompatibilityChecker.applyPlacement(
        base: base,
        target: WallpaperTarget.lock,
        metrics: metrics,
      );

      expect(effective.paddingTop, 500);
      expect(effective.paddingBottom, 400);
      expect(effective.paddingLeft, 100);
      expect(effective.paddingRight, 120);
    });

    test('adds safe insets for non-lock targets without extra overlays', () {
      const metrics = DeviceMetrics(
        width: 1080,
        height: 2400,
        pixelRatio: 3.0,
        safeInsets: EdgeInsets.fromLTRB(0, 30, 0, 20),
        model: 'GENERIC',
      );

      final base = WallpaperConfig.defaults();
      final effective = DeviceCompatibilityChecker.applyPlacement(
        base: base,
        target: WallpaperTarget.home,
        metrics: metrics,
      );

      expect(effective.paddingTop, 30);
      expect(effective.paddingBottom, 20);
    });

    test('applies lock overlay padding and model adjustments', () {
      const metricsSamsung = DeviceMetrics(
        width: 1080,
        height: 2400,
        pixelRatio: 3.0,
        safeInsets: EdgeInsets.fromLTRB(0, 24, 0, 0),
        model: 'SAMSUNG SM-G991B',
      );
      const metricsGeneric = DeviceMetrics(
        width: 1080,
        height: 2400,
        pixelRatio: 3.0,
        safeInsets: EdgeInsets.fromLTRB(0, 24, 0, 0),
        model: 'GENERIC',
      );

      final base = WallpaperConfig.defaults();
      final samsung = DeviceCompatibilityChecker.applyPlacement(
        base: base,
        target: WallpaperTarget.lock,
        metrics: metricsSamsung,
      );
      final generic = DeviceCompatibilityChecker.applyPlacement(
        base: base,
        target: WallpaperTarget.lock,
        metrics: metricsGeneric,
      );

      expect(samsung.paddingTop, greaterThan(generic.paddingTop));
      expect(samsung.paddingTop, greaterThan(metricsSamsung.safeInsets.top));
    });

    test('does not throw when model is null', () {
      const metrics = DeviceMetrics(
        width: 1080,
        height: 2400,
        pixelRatio: 3.0,
        safeInsets: EdgeInsets.zero,
        model: null,
      );

      final base = WallpaperConfig.defaults();
      final effective = DeviceCompatibilityChecker.applyPlacement(
        base: base,
        target: WallpaperTarget.lock,
        metrics: metrics,
      );

      expect(effective.paddingTop, greaterThanOrEqualTo(0));
    });
  });
}

