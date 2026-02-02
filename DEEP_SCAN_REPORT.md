# Deep Scan Report — Logic, Calendar, UX & Code Quality

**Date:** February 3, 2025  
**Scope:** `lib/` (main.dart, models, services, utils, pages, graph_layout, app_constants, theme, exceptions)

---

## Executive summary

- **Critical:** 2 logic bugs (home heatmap week grouping, streak “yesterday” grace period).
- **High:** 1 storage/dimensions logic issue; duplicate level logic in 3 places.
- **Medium:** Dead code, minor UX/consistency, optional fixes.
- **Low:** Duplicate strings, reserved-username bypass.

---

## 1. Critical logic issues

### 1.1 Home page — Activity Graph week grouping (CALENDAR BUG)

**File:** `lib/pages/home_page.dart` — `_ScrollableHeatmapGrid`

**Issue:** Weeks are built incorrectly. The code does:

- For each day: `weekdayIndex = day.date.weekday % 7` (0=Sun … 6=Sat).
- `currentWeek[weekdayIndex] = day` (overwrites that weekday slot).
- When `weekdayIndex == 6` (Saturday), it pushes `currentWeek` and resets.

So each “week” is the **last occurrence of each weekday** before the next Saturday, not a real calendar week. Columns do not represent “week 1, week 2, …” and dates are wrong.

**Fix:** Group days by calendar week (e.g. week start = Sunday). For each day compute:

- `weekStart = date.subtract(Duration(days: date.weekday % 7))` (or equivalent).
- `weekIndex` from the ordered set of week starts.
- `dayIndex = date.weekday % 7`.
- `weeks[weekIndex][dayIndex] = day`.

Then build columns from `weeks` so each column is one calendar week and rows are Sun–Sat.

**Status:** To be fixed in code.

---

### 1.2 ContributionStats — “yesterday” streak grace period

**File:** `lib/models.dart` — `ContributionStats._calculateStreaks`

**Issue:** When today has no contributions, the code tries to give a “grace period” using yesterday:

```dart
if (!streakActive && currentStreak == 0) {
  final yesterdayDay = sortedDays.firstWhere(..., orElse: () => ContributionDay(...));
  if (yesterdayDay.isActive) {
    currentStreak = tempStreak;  // BUG: tempStreak is often 0 here
  }
}
```

`tempStreak` is not updated to include yesterday’s contribution, so we set `currentStreak = 0` even when yesterday had contributions. The intent (streak continues through “yesterday” when today is empty) is not achieved.

**Fix:** When yesterday is active and today is not, set `currentStreak` to the streak that ends yesterday (e.g. recompute from yesterday backward or set to 1 + the streak length ending yesterday), not `tempStreak`.

**Status:** To be fixed in code.

---

## 2. High‑priority issues

### 2.1 StorageService.getDimensions — logical vs physical

**File:** `lib/services.dart` — `StorageService.getDimensions()`

**Issue:** `saveDeviceMetrics` is called with `MediaQuery.of(context).size` (logical pixels) and `devicePixelRatio`. So stored width/height are **logical**. In `getDimensions()` the code does:

- If `pixelRatio > 1.0` and `(width > 2000 || height > 2000)`, it treats stored values as physical and divides by `pixelRatio` to get “logical”.

On large logical sizes (e.g. tablet 2560×1600 logical), this double-converts and returns wrong dimensions.

**Fix:** Do not convert when the stored values are already logical (which they are from `saveDeviceMetrics`). Remove or guard this conversion so it only runs when the stored values are known to be physical (e.g. from a different code path that stores physical size).

**Status:** To be fixed in code.

---

### 2.2 Duplicate contribution level logic (0–4)

**Files:**

- `lib/models.dart`: `ContributionDay.intensityLevel` (0–4 from count).
- `lib/services.dart`: `HeatmapRenderer._getLevel(int count)` (same thresholds).
- `lib/pages/home_page.dart`: `_HeatmapCell._getColorForLevel(int count)` (same thresholds).

**Issue:** Same mapping (0 → 0, 1–3 → 1, 4–6 → 2, 7–9 → 3, 10+ → 4) is implemented in three places. Changes (e.g. new tiers) must be done in three places and can drift.

**Recommendation:** Use a single source of truth: e.g. a static helper that takes `count` and returns level 0–4, and use `ContributionDay.intensityLevel` or that helper everywhere (heatmap renderers and home grid).

---

## 3. Medium‑priority issues

### 3.1 Dead / unused code

- **`DeviceCompatibilityChecker._clampDouble`** (`lib/services.dart`): Defined but never called. Safe to remove or use where clamping is needed.
- **`HeatmapRenderer`** (`lib/services.dart`): Only `MonthHeatmapRenderer` is used for wallpaper and customize preview. `HeatmapRenderer.render` is not referenced. Either remove it, or document it as “reserved for full‑year heatmap” if you plan to use it.

### 3.2 Main nav — loadError not cleared on cache hit

**File:** `lib/pages/main_nav_page.dart` — `_loadData()`

When we load from cache (`cached.days.length >= 90`) we set `_data` and `_isLoading = false` but do not clear `_loadError`. A previous failed load can leave the error banner visible until the next sync.

**Recommendation:** In that branch, set `_loadError = null` in the same `setState`.

### 3.3 Success message inconsistency

- `lib/pages/customize_page.dart`: `'Wallpaper updated successfully!'`
- `lib/pages/main_nav_page.dart`: `'Wallpaper updated successfully! 🎨'`

**Recommendation:** Use one string (e.g. from `AppStrings`) for both.

### 3.4 Customize preview — “desired size” branch never used

**File:** `lib/pages/customize_page.dart` — `_buildPreviewSection()`

Code uses `getDesiredWallpaperSize()` when `_previewTarget == WallpaperTarget.home || _previewTarget == WallpaperTarget.both`, but `_previewTarget` is a const `WallpaperTarget.lock`. So this branch is dead.

**Recommendation:** Remove the branch or reintroduce a non-const preview target if you want Home/Both previews.

---

## 4. Low‑priority / minor

### 4.1 Impact Level (home) — level 0 not shown

**File:** `lib/pages/home_page.dart` — `_buildContributionBreakdown`

Only levels 1–4 (Low, Med, High, Max) are shown; level 0 (no contributions) is not. Likely intentional; document if “active days only” is the design.

### 4.2 Reserved username only in ValidationUtils

**File:** `lib/utils.dart` — `ValidationUtils.validateUsername` has a reserved list. `StorageService.setUsername` does not re-check reserved names. If the UI is bypassed, a reserved name could be stored. Low risk; optional: add the same check in `setUsername`.

### 4.3 CachedContributionData.toJson — redundant keys

`toJson` writes `currentStreak`, `longestStreak`, `todayCommits`; `fromJson` recomputes stats from `days`. No bug, but the keys are redundant. Optional: remove them from `toJson` to avoid confusion.

---

## 5. UI/UX notes (no bugs)

- **Customize preview:** Fixed to lock screen layout (`MonthHeatmapRenderer`) and single target; matches “one fixed layout” design.
- **MonthHeatmapRenderer:** Uses `firstOfMonth.weekday % 7` and `dayIndex + weekdayOffset` for cell index; layout is consistent with Sunday = column 0.
- **HeatmapRenderer (full-year):** Aligns to Sunday with `daysToSubtract = startDate.weekday % 7`; no calendar bug there.
- **Onboarding:** `AnimationController(vsync: this)` is correct; `TickerProviderStateMixin` / `SingleTickerProviderStateMixin` are used where needed.

---

## 6. Summary table

| Severity  | Count | Area                          |
|-----------|-------|-------------------------------|
| Critical  | 2     | Home heatmap weeks, streak    |
| High      | 2     | getDimensions, duplicate level|
| Medium    | 4     | Dead code, loadError, strings, preview branch |
| Low       | 3     | Impact level 0, reserved, toJson |

---

## 7. Recommended fix order

1. Fix **Home _ScrollableHeatmapGrid** week grouping (critical, user-visible).
2. Fix **ContributionStats** yesterday grace period (critical, stats accuracy).
3. Fix **getDimensions** logical/physical handling (high, layout/wallpaper).
4. Unify **contribution level** logic (high, maintainability).
5. Clear **loadError** on cache hit; unify **success** strings; remove or document dead code and unused preview branch.
