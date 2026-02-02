# Graph Sizing Inconsistency: Preview vs Applied Wallpaper

## Summary
The graph appears correctly sized inside the Customize preview but renders noticeably smaller when applied as the actual wallpaper (lock screen and home screen). The primary root cause is a viewport mismatch: the preview paints the graph into the preview widget’s canvas size, while the generated wallpaper paints the graph into the device wallpaper viewport. Because the renderer’s sizing is mostly absolute (constants × `config.scale`) rather than proportional to the viewport, the same config yields different *relative* sizes across contexts.

## Affected Areas
- Customize preview layout and painting pipeline: [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart)
- Wallpaper generation pipeline (canvas sizing, scaling, target-specific behavior): [services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart)

## How The Preview Currently Works
### Preview viewport is the preview widget, not the wallpaper
The preview computes a “phone-shaped” container size based on the current screen constraints and the device aspect ratio:
- `_buildPreviewSection()` calculates `previewWidth`/`previewHeight` from `LayoutBuilder` constraints and `wallpaperAspectRatio` ([customize_page.dart:L333-L418](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L333-L418)).

The graph is then painted directly into that preview box:
- `_WallpaperPreviewPainter.paint()` calls `MonthHeatmapRenderer.render(... size: size ...)` where `size` is the preview box size ([customize_page.dart:L799-L817](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L799-L817)).

**Implication:** The renderer treats the preview box as the full wallpaper viewport. Any sizing decisions based on constants and `config.scale` are applied to a small canvas, making the graph occupy a larger fraction of the preview than it will on the full wallpaper.

### Preview is implicitly lock-screen oriented
The preview config is adjusted via `DeviceCompatibilityChecker.applyPlacement(... target: WallpaperTarget.lock)` ([customize_page.dart:L379-L387](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L379-L387)).

**Implication:** If the user applies to Home or Both, the preview may not match the target-specific layout.

## How The Wallpaper Rendering Works
The wallpaper generator creates an image based on stored device dimensions, then renders the graph into a canvas sized to that wallpaper viewport:
- `WallpaperService._generateWallpaperImage(...)` chooses a renderer by target and paints into `Size(width, height)` (logical) after scaling the canvas to physical pixels ([services.dart:L300-L351](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L300-L351)).

**Key difference from preview:** The wallpaper viewport is the actual device wallpaper viewport, not the preview widget.

## Root Cause (Primary)
### Viewport mismatch + “absolute” graph sizing
Graph sizing is mostly driven by:
- `AppConstants.heatmapBoxSize` / `heatmapBoxSpacing`
- `config.scale`

Because these are applied in the current drawing coordinate system, rendering into:
- a small preview viewport vs
- a larger wallpaper viewport

produces different *relative* sizes (graph fraction of the viewport), even if the absolute box size in logical units is identical.

## Secondary Contributors (Platform Differences)
### Home screen wallpaper scaling/cropping/parallax (Android)
Many Android launchers treat the home wallpaper as a larger surface than the visible viewport (parallax/scrolling), which can result in implicit scaling that changes perceived size. The current implementation does not query Android’s desired wallpaper minimum size or crop hints, so the system/launcher may “zoom out” the image, making the graph appear smaller than intended.

## Measurable Metrics For Regression
The following metrics are sufficient to detect sizing drift across contexts:
- `graphBlockWidthFraction = graphBlockWidth / viewportWidth`
- `graphBlockHeightFraction = graphBlockHeight / viewportHeight`
- `gridWidthFraction = gridWidth / viewportWidth`
- `gridHeightFraction = gridHeight / viewportHeight`

Target expectation:
- For preview vs applied wallpaper, fractions should match within a small tolerance when preview uses the same effective viewport.

## Recommended Fix Strategy
1. Make preview paint the graph in a virtual wallpaper coordinate space (the actual wallpaper logical width/height), then scale the canvas down to the preview size. This makes preview WYSIWYG.\n+2. Add target selection for preview (Home/Lock/Both) so placement and viewport assumptions match what will be applied.\n+3. (Android) Read `WallpaperManager` desired minimum dimensions for Home/Both and generate wallpaper using those dimensions to avoid launcher-induced zoom-out.\n+4. If the graph is still too small after a WYSIWYG preview, introduce optional auto-fit scaling to compute box size from available width rather than relying solely on a bounded `config.scale`.

