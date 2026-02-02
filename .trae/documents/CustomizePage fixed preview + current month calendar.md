## Goals
1. Always render a current-month calendar grid in the wallpaper preview (device local date).
2. Keep the preview panel fixed (50–60% viewport height), centered, and non-scrolling.
3. Ensure the calendar grid is perfectly centered with consistent padding on all screen sizes.
4. Make only the controls section scroll while the preview stays visible and updates live.

## Layout Changes (CustomizePage)
1. Replace the current `CustomScrollView` structure with a `Column`:
   - Top: a fixed-height preview panel `SizedBox(height: viewportHeight * 0.55)` (clamped to 0.50–0.60).
   - Bottom: `Expanded(child: SingleChildScrollView(...))` containing all controls and the Apply button.
2. Move the “Customize” title to an `AppBar` (or into the scrollable section) so the preview panel can remain vertically centered.
3. Keep the preview container aspect ratio based on device logical size, but size it to fit within the fixed panel on both phones and tablets.

## Calendar Rendering (Wallpaper Preview)
1. Replace `_WallpaperPreviewPainter`’s `HeatmapRenderer.render(...)` call with an in-file month calendar renderer that:
   - Determines the current month from `DateTime.now()` (local).
   - Computes the correct month grid (leading blanks, 5–6 week rows).
   - Colors each day using GitHub-style levels derived from `CachedContributionData.getContributionsForDate(date)`.
   - Highlights “today” with the same highlight color used elsewhere.
   - Supports light/dark via `config.isDarkMode` and `AppThemeExtension.light()/dark()`.
2. Centering/padding rules inside the painter:
   - Use a consistent outer padding based on the canvas size (clamped), then lay out title + day-of-week row + grid inside the remaining rect.
   - Compute a square `cellSize` that fits (respecting scale via a clamped zoom factor), then place the grid using `horizontalPosition`/`verticalPosition` within the padded area so 0.5/0.5 is perfectly centered.
3. Keep the optional quote overlay rendering (using the existing config fields) and ensure it doesn’t break centering.

## Live Updates
1. Ensure every control change calls `setState` as it already does; keep `shouldRepaint` keyed off `config`.
2. Pass a stable “month anchor” (year+month) into the painter and refresh it when needed.
   - Add a lightweight timer scheduled for the next local midnight; if the month changed, call `setState` so the preview flips months automatically.

## Deliverable
- Produce a single, self-contained updated Dart file at `lib/pages/customize_page.dart` (no other files changed) that compiles cleanly and keeps existing UX (theme toggle, sliders, apply flow) while meeting the fixed-preview + scroll-controls behavior.

## Verification
1. Run `flutter analyze` to confirm no static issues.
2. Run an app build (debug) and verify:
   - Preview panel remains fixed while controls scroll.
   - Preview stays centered and sized consistently on phone/tablet dimensions.
   - Month grid matches the current month and highlights today.
   - Any slider/text/theme change updates the preview immediately.