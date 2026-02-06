## Agreement
- A: Agree — current streak should remain active when last contribution was today or yesterday.
- B: Agree — UTC/local mixing makes the “Today” border unreliable around midnight.
- C: Partially agree — since you’re Android-only for the starting phase, iOS support is not required, but the app should not fail silently if ever run on non-Android.

## Canonical Date Strategy
- Adopt a single “calendar day” basis for contributions, streaks, and heatmap rendering.
- Recommended: UTC date-only everywhere for contribution-derived logic and the “Today” highlight (matches existing `nowUtc` usage and avoids user-location drift).

## Implementation Steps
1. Date utilities (lib/utils.dart)
   - Add explicit helpers (or adjust existing ones) so code can request:
     - UTC date-only (`DateTime.utc(y,m,d)`) for contribution logic.
     - Local date-only when truly needed for UI-only display.
   - Update `parseIsoDate("YYYY-MM-DD")` to return UTC date-only deterministically (avoid `DateTime.parse` → local ambiguity).

2. Fix “Current Streak” logic (lib/models.dart)
   - In `ContributionStats._calculateStreaks()`:
     - Compute `today` and `lastActiveDay` using the UTC date-only helper.
     - Change the gate from `diffToToday == 0` to `diffToToday <= 1`.
     - Keep existing backward-walk logic to count contiguous days.

3. Fix heatmap “Today” highlight + month selection (lib/rendering.dart)
   - Ensure `referenceDate`, month cell generation, and the “today” highlight all use the same basis (UTC):
     - Build month cells with `DateTime.utc(ref.year, ref.month, day)`.
     - Compute `today` using UTC date-only.
   - This prevents the missing/shifted border and avoids rendering the wrong month near UTC/local boundaries.

4. Android-only wallpaper behavior (lib/services.dart, lib/pages/main_nav_page.dart)
   - Keep Android-only wallpaper application (`Platform.isAndroid`) since the starting phase is Android.
   - Make behavior explicit on non-Android:
     - UI: show “generated/saved image” instead of “wallpaper applied”, or disable/hide the action.
     - Background refresh: early return on non-Android to avoid wasted work.

## Verification
- Add/update unit tests for:
  - `parseIsoDate` returning stable UTC date-only.
  - `currentStreak` scenarios: contributed today, yesterday, 2+ days ago.
  - Heatmap “today” matching the expected cell when UTC/local days differ.

## Files Touched
- lib/utils.dart
- lib/models.dart
- lib/rendering.dart
- lib/services.dart
- lib/pages/main_nav_page.dart

If you confirm this plan, I’ll implement it as a minimal diff, run tests, and point you to the exact changed line ranges.