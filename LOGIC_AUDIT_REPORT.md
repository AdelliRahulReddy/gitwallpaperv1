# Logic Audit Report

**Date:** January 31, 2025  
**Scope:** App flow, setup, stats, customize, settings, background, Firebase

---

## ✅ What Works

### 1. **Setup (Onboarding)**
- Validates username & token via `GitHubService.fetchContributions` (real API call)
- Saves credentials to secure storage
- Caches contribution data
- Navigates to MainNavPage on success
- Error handling for token/user/network issues

### 2. **Stats (From GitHub – NOT Hardcoded)**
- `GitHubService` fetches via GraphQL: `contributionsCollection.contributionCalendar`
- Parses real `contributionDays` (date, contributionCount, contributionLevel)
- `ContributionStats.fromDays()` computes:
  - **Current streak** – consecutive days from today backwards
  - **Longest streak** – max consecutive days
  - **Today's contributions** – from API data
  - **Peak day** – max contributions in a single day
  - **Most active weekday** – by contribution count
- All stats derived from live GitHub data ✓

### 3. **Customize – Device-Based**
- `AppConfig.initializeFromContext()` saves `width * pixelRatio`, `height * pixelRatio`, `pixelRatio` on app open
- `WallpaperService._generateWallpaperImage()` uses `StorageService.getDimensions()` for canvas size
- Preview uses `MediaQuery.size` + `devicePixelRatio` – matches device
- Sliders (scale, opacity, position, quote) update config correctly

### 4. **Controls**
- Home: Refresh, stats, heatmap, weekend analysis, motivation – all working
- Customize: Theme toggle, quote, scale, opacity, position – all wired
- Settings: Logout, Clear Cache – working

### 5. **Firebase**
- Firebase init ✓
- FCM init ✓
- Topic subscription: `daily-updates` ✓
- Cloud Function: sends to `daily-updates` every 15 min ✓
- App Check configured ✓

---

## ✅ Issues Fixed

### 1. **FCM Type Mismatch** – FIXED
- **Was:** Cloud Function sent `daily_refresh`, app checked `refresh` → never matched
- **Fix:** App now accepts both `refresh` and `daily_refresh`; Cloud Function sends `refresh`

### 2. **Auto Update Toggle Not Used** – FIXED
- **Fix:** All update paths now check `StorageService.getAutoUpdate()`:
  - FCM foreground handler
  - FCM background handler (after init in isolate)
  - `performBackgroundUpdate` (when not in isolate)
  - `_checkAutoUpdate` and `_checkBackgroundSync` in MainNavPage

### 3. **Dimensions Saved Only on First Open** – FIXED
- **Fix:** `AppConfig.initializeFromContext(context)` now called in `_checkAutoUpdate` when app resumes → dimensions updated on rotate/resize

### 4. **Settings Page – Misleading Text** – FIXED
- **Fix:** Updated to "Refresh wallpaper when push notification arrives"

---

## Background Behavior

| Scenario | Expected | Actual |
|----------|----------|--------|
| App in foreground | FCM message → trigger update | Type mismatch → no update |
| App in background | FCM message → background handler → update | Type mismatch → no update |
| App killed | FCM wakes app → handler → update | Type mismatch → no update |
| App resumed (no FCM) | Sync if >30 min stale | ✓ `_checkAutoUpdate` runs |
| Silent sync when >1 hr stale | Background sync | ✓ `_checkBackgroundSync` runs |

---

## Recommendations

1. **Fix FCM type** – Align `"daily_refresh"` and `"refresh"` (either in cloud function or app)
2. **Respect Auto Update** – Check `getAutoUpdate()` in FCM handlers and background sync
3. **Re-save dimensions on resume** – Call `AppConfig.initializeFromContext` when app resumes (if context available)
4. **Update Settings copy** – Clarify that toggle controls FCM-triggered updates
