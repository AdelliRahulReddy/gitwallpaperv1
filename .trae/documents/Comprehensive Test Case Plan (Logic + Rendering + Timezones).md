# Comprehensive Test Case Plan (Logic + Rendering + Timezones)

## Scope Map (Deep Scan Targets)
- **Core domain models & algorithms**: [models.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/models.dart) (`ContributionDay`, `ContributionStats`, `CachedContributionData`).
- **Date/time utilities & validation**: [utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart) (`ValidationUtils`, `AppDateUtils`, `RenderUtils`, quartiles/levels).
- **GitHub GraphQL fetch + parsing + retries**: [services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart) (`GitHubService.fetchContributions`, `_makeRequest`, `_validateResponse`, `_parseResponse`).
- **Cache + refresh orchestration**: [services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart) (`StorageService`, `WallpaperService.refreshWallpaper`).
- **Calendar/month rendering math** (layout + “today” highlight + scaling): [rendering.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/rendering.dart) (`MonthHeatmapRenderer`).
- **GitHub-style week grid UI (last 180 days)**: [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart) (`_ScrollableHeatmapGrid` week grouping and ordering).
- **App sync decisions** (cache completeness & timestamps): [main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart) (`_loadData`, `_syncData`, lastUpdate logic).
- **Cloud scheduler push trigger**: [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js) (message payload + retry loop).

## Test Strategy (Three Layers)
- **Unit tests**: pure functions/algorithms, deterministic inputs/outputs; no platform channels.
- **Integration tests**: combine 2–4 real modules (HTTP parsing + caching, wallpaper byte generation), using fakes/mocks for platform I/O.
- **End-to-end (E2E)**: user flows across pages + background refresh behavior on Android emulator/device.

## Test Tooling (Planned)
- **Unit/widget tests**: `flutter_test` (already present).
- **HTTP stubbing**: `package:http/testing.dart` `MockClient` (no extra dependency).
- **Integration/E2E**: add `integration_test` (not currently in `pubspec.yaml`).
- **Golden/image tests** (rendering correctness): use `flutter_test` goldens via `matchesGoldenFile` (optional: add `golden_toolkit` later if needed).
- **Node (functions) tests**: use Node 22 built-in `node:test` (no Jest required); stub `firebase-admin` manually.

## Unit Test Suites (Detailed Case Plan)

### 1) Validation & Input Boundaries (ValidationUtils)
File target: [utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart#L167-L238)
- **VAL-USER-01**: valid usernames (min length 1, max 39, hyphen in middle).
- **VAL-USER-02**: boundary length 39 accepted; 40 rejected.
- **VAL-USER-03**: invalid formats (starts/ends with `-`, underscore, consecutive `--`).
- **VAL-USER-04**: reserved usernames blocked (`admin`, `api`, `www`, `github`, `support`).
- **VAL-TOKEN-01**: empty/whitespace rejected.
- **VAL-TOKEN-02**: tokens < 10 chars rejected; tokens with spaces rejected.
- **VAL-QUOTE-01**: null/empty accepted.
- **VAL-QUOTE-02**: 200 chars accepted; 201 rejected.
- **VAL-QUOTE-03**: script/iframe/javascript patterns rejected (case-insensitive).

### 2) Date/Time Handling (UTC vs Local, Parsing, Leap Year)
File target: [AppDateUtils](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart#L245-L327)
- **DATE-ISO-01**: `YYYY-MM-DD` parses to UTC midnight (existing test covers basic).
- **DATE-ISO-02**: full ISO with offset (e.g. `2026-02-05T23:30:00+05:30`) normalizes to UTC date-only.
- **DATE-ISO-03**: invalid strings return null; failure counter increments but no crash.
- **DATE-NORM-01**: `toDateOnlyUtc()` strips time and forces UTC.
- **DATE-NORM-02**: `toDateOnlyLocal()` strips time and stays local.
- **DATE-LEAP-01**: leap year rules (2000 true, 1900 false, 2024 true, 2023 false).
- **DATE-LEAP-02**: invalid year/month throws `ArgumentError`.
- **DATE-MONTH-01**: `daysInMonth` for each month, including Feb 28/29.

Timezone/DST edge matrix (run in unit tests via ISO offsets):
- **TZ-01**: offsets `+14:00`, `-12:00` near day boundaries.
- **TZ-02**: times around 00:00 local that map to previous/next UTC date.
- **TZ-03**: DST transition dates represented as offset strings (no system timezone dependency).

### 3) Contribution Intensity & Quartiles (RenderUtils)
File target: [RenderUtils](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart#L562-L601)
- **QTL-EMPTY-01**: all zero counts → `Quartiles(1,2,3)` fallback.
- **QTL-SMALL-01**: 1–3 non-zero days → thresholds strictly increasing.
- **QTL-DUP-01**: identical non-zero counts → thresholds forced to ascending (`t2=t1+1`, `t3=t2+1`).
- **LVL-BOUND-01**: boundary classification uses `<=` (e.g., count==q1→level1, q1+1→level2).
- **LVL-NOQ-01**: default quartiles 3/6/9 used when none provided.

### 4) Stats & Streak Algorithms (ContributionStats)
File target: [ContributionStats](file:///c:/Users/adell/Desktop/github_wallpaper/lib/models.dart#L95-L284)
Core correctness tests (deterministic days list):
- **STREAK-01**: increasing consecutive active days → longest=current=length.
- **STREAK-02**: inactive day resets streak (tempStreak=0).
- **STREAK-03**: missing date creates gap and resets.
- **STREAK-04**: unsorted input still yields correct streaks.
- **STREAK-05**: last active day = today (UTC) → current streak counts back.
- **STREAK-06**: last active day = yesterday (UTC) → current streak still counts.
- **STREAK-07**: last active day ≤ 2 days ago → current streak 0.
- **STATS-01**: today contributions computed correctly when today missing from list.
- **STATS-02**: mostActiveWeekday matches max sum; tie-break behavior (first max index) documented and tested.

Stability note (testability improvement): current streak depends on `AppDateUtils.nowUtc`. To avoid flaky tests, add a way to inject “now” into streak/today calculations (e.g., optional `DateTime nowUtc` in `ContributionStats.fromDays`).

### 5) CachedContributionData (Lookup/Serialization/Staleness)
File target: [CachedContributionData](file:///c:/Users/adell/Desktop/github_wallpaper/lib/models.dart#L290-L426)
- **CACHE-JSON-01**: roundtrip `toJson()` then `fromJson()` preserves day dates/counts.
- **CACHE-JSON-02**: invalid day JSON entries are skipped (ensure remaining days still parsed).
- **CACHE-LOOKUP-01**: `getContributionsForDate()` returns correct values for known date.
- **CACHE-LOOKUP-02**: lookup for unknown date returns 0.
- **CACHE-STALE-01**: `isStale()` honors `cacheExpiry` threshold.

Timezone risk test:
- **CACHE-TZ-01**: passing a local `DateTime` that represents the same instant but different Y-M-D can mismatch `toIsoDateString()`; test should expose and document whether callers must pass UTC date-only.

### 6) Month Calendar Layout Math (MonthHeatmapRenderer.computeMonthCells)
File target: [rendering.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/rendering.dart#L44-L53)
- **MONTH-01**: correct day count for all months (including leap Feb).
- **MONTH-02**: all generated cells are UTC date-only.
- **MONTH-03**: first cell = 1st of month; last cell = last day.

### 7) Week Grid Grouping Logic (GitHub-style contribution grid)
File target: [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L871-L931)
- **WEEKGRID-01**: week start computed as Sunday via `d.weekday % 7`.
- **WEEKGRID-02**: days map into correct row index (Sun=0, Mon=1, … Sat=6).
- **WEEKGRID-03**: reverse ListView shows newest week on the right (`reverse: true` + reverse indexing).
- **WEEKGRID-04**: display window trims to last 180 days.
- **WEEKGRID-05**: null slots render blank squares and do not crash.

Test technique: widget tests that feed a synthetic `days` list with known dates and assert cell semantics labels and ordering.

## Integration Test Plan

### 1) GitHubService end-to-end parsing (MockClient)
File targets: [GitHubService](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L306-L543), [ContributionDay.fromJson](file:///c:/Users/adell/Desktop/github_wallpaper/lib/models.dart#L31-L51)
- **GH-OK-01**: valid GraphQL response parses all days; computed total equals sum of days.
- **GH-SCHEMA-01**: missing `data` / missing `user` / missing `contributionsCollection` → correct exception (`UserNotFoundException` or `GitHubException`).
- **GH-ERRORS-01**: response with `errors` array throws `GitHubException(message)`.
- **GH-HTTP-01**: non-200 + non-JSON body triggers `GitHubException.fromResponse`.
- **GH-RETRY-5XX-01**: 500/502 retries up to 3 times with backoff; succeeds on later attempt.
- **GH-RETRY-NET-01**: `SocketException`/`TimeoutException` retry behavior.

### 2) StorageService + SharedPreferences + Secure Storage behavior
File target: [StorageService](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L31-L300)
- **STORE-INIT-01**: access before `init()` throws `StateError`.
- **STORE-USER-01**: username set/get with trimming and validation.
- **STORE-TOKEN-01**: invalid token format rejects.
- **STORE-CACHE-01**: cached contribution data roundtrip through JSON.
- **STORE-LASTUPD-01**: lastUpdate stored/retrieved correctly.
- **STORE-CLEAR-01**: `clearCache()` removes cached data and last update.

Testability note: `FlutterSecureStorage` is a platform channel; for integration tests on host, mock MethodChannel calls or add a small injectable storage adapter.

### 3) Wallpaper generation bytes + sizing
File target: [WallpaperService._generateWallpaperImage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L735-L790)
- **WP-BYTES-01**: returns non-empty PNG bytes; `ui.instantiateImageCodec` decodes.
- **WP-SIZE-01**: respects stored device dimensions/pixelRatio when present.
- **WP-PLACEMENT-01**: `DeviceCompatibilityChecker.applyPlacement` adjusts padding for target and metrics.

## End-to-End (E2E) Scenarios (integration_test)

### 1) Onboarding / Login / Validation
- **E2E-LOGIN-01**: invalid username blocks continue (format/reserved/length).
- **E2E-LOGIN-02**: invalid token blocks continue.
- **E2E-LOGIN-03**: valid credentials + mocked GitHub response → lands in home with stats + heatmap.

### 2) Home Heatmap and Stats Accuracy
- **E2E-HOME-01**: stats cards match computed totals/streaks from fixture data.
- **E2E-HOME-02**: tapping a heatmap cell opens bottom sheet with correct date/count.
- **E2E-HOME-03**: last 180 days display rule holds.

### 3) Sync / Cache / Refresh Logic
File target: [main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L74-L173)
- **E2E-SYNC-01**: cache missing → forced sync.
- **E2E-SYNC-02**: cache present but <90 days → forced sync.
- **E2E-SYNC-03**: cache present ≥90 days → shows cache immediately, then background sync after 1h.
- **E2E-SYNC-04**: lastUpdate threshold triggers sync on resume (>30 min).

Timezone consistency check (important): `_syncData` uses `DateTime.now()` while background refresh stores UTC (`AppDateUtils.nowUtc`). Add E2E/regression tests to detect drift around midnight local time.

### 4) Customize + Wallpaper Apply (Android-first)
- **E2E-WP-01**: change scale/opacity/quote → preview updates, no crash.
- **E2E-WP-02**: apply wallpaper (home/lock/both) succeeds on Android emulator.
- **E2E-WP-03**: non-Android path results in “generated image” messaging (no silent failure). <mccoremem id="01KGQGG8Q48HBFZYA0MV3GMG7S" />

### 5) Offline / Error Handling
- **E2E-OFFLINE-01**: no connectivity → refresh no-ops, cached data still displayed.
- **E2E-ERR-01**: GitHub 401/403/timeout → user-friendly error message surfaced; no token printed.

## Rendering & Visualization Verification

### Golden Tests (Recommended)
- **GOLD-MONTH-01..12**: one golden per month start weekday pattern (pick representative months) to catch weekdayOffset regressions.
- **GOLD-THEME-01**: dark vs light mode rendering.
- **GOLD-TODAY-01**: “today” border highlight lands on correct cell (use injected `referenceDate` + controlled “today”).

Alternative (if goldens aren’t desired): render to image bytes and sample specific pixel regions for expected cell colors.

## Data Accuracy & Consistency Checks
- Ensure computed totals match sum of day counts; if mismatch, treat as test failure (currently only logs warning in [GitHubService._parseResponse](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L488-L503)).
- Validate that date lookup keys are consistent (UTC date-only keys throughout the pipeline).

## Cloud Functions (Node) Test Plan
File target: [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js)
- **FN-MSG-01**: payload contains `data.type` in {`refresh`,`daily_refresh`}, topic `daily-updates`, and android priority/ttl set.
- **FN-RETRY-01**: `admin.messaging().send` fails twice then succeeds → total 3 attempts.
- **FN-RETRY-02**: all attempts fail → returns null and logs error.

Test technique: wrap message-build and send-with-retry into exportable functions (small refactor), then test with stubs via `node:test`.

## Deliverables (What I will add if you confirm)
- A structured `test/` suite expansion covering unit + widget tests for all logic modules above.
- An `integration_test/` directory with 3–6 high-value E2E flows.
- Golden tests (optional but recommended) for rendering regressions.
- A `functions/test/` (or similar) Node test file for Cloud Scheduler logic.

## Acceptance Criteria
- Deterministic tests (no dependence on wall clock time).
- Coverage across: edge cases, boundary conditions, error handling, timezone correctness, and visualization regressions.
- Tests clearly map to the modules listed in Scope Map and fail loudly on data inconsistencies.
