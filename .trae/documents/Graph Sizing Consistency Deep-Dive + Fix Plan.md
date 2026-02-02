## Findings (Root Causes)
- **Preview uses the preview widget’s canvas size as the “wallpaper viewport.”** In [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L333-L418), `_buildPreviewSection()` computes a preview container size (`previewWidth/previewHeight`) from layout constraints, then paints the graph with `CustomPaint` whose `Size` is *that preview size*. The painter then calls the renderer with `size: size` ([customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L799-L817)). This means the graph’s absolute box sizes (derived from constants + config scale) are rendered into a much smaller “viewport” than the real wallpaper, making the graph look proportionally larger in preview.
- **The renderer’s scale is effectively “absolute” in logical units, not proportional to the viewport.** The preview does not apply any transform to map wallpaper logical coordinates → preview coordinates. So a scale that “looks right” in preview often becomes too small on the actual wallpaper because the actual wallpaper viewport is much larger.
- **Preview does not simulate the wallpaper generation pipeline.** Wallpaper rendering uses a dedicated canvas sized from stored device dimensions (and potentially system scaling/cropping/parallax on home screen). The preview does not simulate any of that; it just paints directly into the preview box.
- **Preview is implicitly lock-screen oriented.** The preview painter applies `DeviceCompatibilityChecker.applyPlacement(... target: WallpaperTarget.lock)` ([customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L379-L387)) regardless of whether the user later applies to Home/Both, which can introduce additional mismatch.

## Primary Hypothesis (Why It’s “Correct in Preview” but “Small on Wallpaper”)
- The graph’s **absolute pixel/DP box sizes are not being normalized against the actual wallpaper viewport**. On the real wallpaper canvas, the graph occupies a smaller fraction of the screen than it does in the preview canvas.

## Plan (Targeted Fixes + Measurable Improvements)
### 1) Create a Technical Report Artifact
- Add a `docs/graph-sizing-report.md` documenting:
  - The exact preview sizing math (`previewPanelHeight`, `previewWidth/previewHeight`, aspect ratio constraints).
  - The mismatch mechanism: preview paints in preview coordinates rather than wallpaper coordinates.
  - Platform notes: home screen often applies system scaling/cropping (parallax), which preview currently does not emulate.
  - “Before/after” measurable metrics: graph width fraction, height fraction, and header+grid block fraction.

### 2) Make Preview Use the Same Coordinate Space as Wallpaper
- Update `_WallpaperPreviewPainter` to render in a **virtual wallpaper viewport** and then scale to the preview size:
  - Pass `wallpaperLogicalWidth/height` into the painter (from `StorageService.getDimensions()` fallback).
  - In `paint()`, do `canvas.save(); canvas.scale(size.width / wallpaperW, size.height / wallpaperH); renderer(size: Size(wallpaperW, wallpaperH)); canvas.restore();`
- Result: the preview becomes WYSIWYG with actual wallpaper output.
- Add a small target toggle (Home / Lock / Both) for the preview so the same placement logic used for the selected target is previewed.

### 3) Address Home Screen System Scaling (Parallax/Crop)
- Add an Android-only method-channel call to read `WallpaperManager.getDesiredMinimumWidth/Height` (or an equivalent) and store it.
- Use those desired dimensions when generating the wallpaper for Home/Both so the generated image matches what the launcher expects (reduces implicit system zoom-out that makes the graph look smaller).
- Mirror that same “effective wallpaper viewport” in the preview target toggle.

### 4) Normalize Graph Size Against Viewport (Optional, If Still Small After 2–3)
- If WYSIWYG preview reveals the graph is genuinely too small on-device, introduce an **auto-fit mode**:
  - Compute `boxSize/spacing` from available width and column count (weeks=53 or month columns=7), rather than relying solely on a capped `config.scale`.
  - Keep the existing slider as a multiplier but remove overly tight clamps that prevent reaching visually appropriate sizes on high-res/large-aspect devices.

### 5) Automated Regression Tests
- Add a pure-Dart `GraphLayoutCalculator` (no Flutter UI dependency) that returns:
  - computed `boxSize`, `spacing`, `gridWidth/Height`, header height, and block bounding rect.
- Tests verify:
  - **Preview/WP invariance:** after applying the preview transform, the graph block occupies the same *fractional* width/height of the viewport (within tolerance) for multiple device sizes/aspect ratios.
  - **Target variance:** Home vs Lock uses expected viewport sizing (especially when desired wallpaper dimensions differ).
  - Edge cases: missing dimensions, extreme aspect ratios, safe insets.

## Deliverables
- `docs/graph-sizing-report.md` (detailed technical report)
- Updated preview rendering to use wallpaper-coordinate scaling + target toggle
- Android desired wallpaper dimension support (home/both)
- Regression test suite around layout invariants

Confirm this plan and I’ll implement the fixes and the report in the repository.