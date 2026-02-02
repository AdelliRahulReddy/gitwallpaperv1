## Scope and UX Baseline
- **Screens/components scanned:** [OnboardingPage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/onboarding_page.dart), [MainNavPage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart), [HomePage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart), [CustomizePage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart), [SettingsPage](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart), design tokens in [theme.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/theme.dart), shared UX utilities in [utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart).
- **Business requirements inferred from code:** connect GitHub → view dashboard → customize wallpaper → apply wallpaper → background refresh via FCM.
- **UX principles used:** predictable navigation, clear system status/feedback, error recovery, accessibility (touch targets, screen reader, text scaling), responsive layouts across small screens/split-screen/tablets, consistent design tokens.

## UI/UX Issues Found (Documented)
Each issue includes severity, affected segments, and business impact.

### Critical / High
1) **Auto-sync shows intrusive success toast on resume (unexpected feedback + context mismatch)**
- **Where:** [MainNavPage._checkAutoUpdate](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L49-L64) calls `_syncData()` non-silent, which triggers `Data synced successfully` even when user didn’t request it [main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L114-L165).
- **Severity:** High
- **Affected segments:** all users; especially users resuming frequently
- **Business impact:** annoyance → lower retention, poorer reviews

2) **Loading state not communicated when data already exists (silent work, unclear system status)**
- **Where:** Home only shows full-screen loading when `isLoading && data == null` [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L58-L65). When syncing with existing cached data, users get no clear progress indicator.
- **Severity:** High
- **Affected segments:** slow networks, first-time after cache
- **Business impact:** perceived slowness/bugs → lower trust

3) **Accessibility: no explicit semantics anywhere (screen reader experience weak)**
- **Where:** No `Semantics` usage across `lib/` (scan). Custom interactive UI relies on defaults.
- **Severity:** High
- **Affected segments:** TalkBack/VoiceOver users
- **Business impact:** accessibility complaints, lower ratings, higher support burden

4) **Touch target and usability risk in heatmap rendering (very small cells)**
- **Where:** Heatmap cells are tiny and not interactive/accessible [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L878-L909).
- **Severity:** High
- **Affected segments:** all users on small screens; low-vision users
- **Business impact:** feature feels “pretty but unusable”; reduces engagement

### Medium
5) **Customize “No data” state is a dead end (broken journey)**
- **Where:** shows message only, no CTA to go sync [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L245-L286).
- **Severity:** Medium
- **Affected segments:** new users, users who cleared cache
- **Business impact:** drop-off from key activation step (apply wallpaper)

6) **Responsive layout risk from magic spacer based on screen height**
- **Where:** `SizedBox(height: screenHeight * 0.58)` to reserve preview space [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L167-L190).
- **Severity:** Medium
- **Affected segments:** small screens, landscape, split-screen
- **Business impact:** clipped UI, frustration, higher bounce

7) **Hard-coded header padding likely causes cramped or awkward spacing**
- **Where:** Home header top padding is fixed at 60 [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L128-L136), plus global SafeArea wrapping in MainNav.
- **Severity:** Medium
- **Affected segments:** small devices, large text
- **Business impact:** layout looks “off”, perceived low quality

8) **Interactive elements use GestureDetector without Material affordances (no ripple/focus)**
- **Where:** Theme cards use GestureDetector [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L666-L676).
- **Severity:** Medium
- **Affected segments:** keyboard users, accessibility users
- **Business impact:** reduced perceived responsiveness and polish

9) **Typography tokens are very small by default (readability/accessibility risk)**
- **Where:** caption/body sizes include 10–12sp [theme.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/theme.dart#L183-L194).
- **Severity:** Medium
- **Affected segments:** low vision, older users, sunlight usage
- **Business impact:** higher abandonment, negative reviews

### Low
10) **Design consistency: emojis in titles and mixed token usage**
- **Where:** Settings title includes emoji [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L135-L144); multiple raw sizes in several pages.
- **Severity:** Low
- **Affected segments:** all users
- **Business impact:** inconsistent branding/polish

11) **Error copy can be overly technical in settings external launch**
- **Where:** SnackBar includes exception text [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L450-L463).
- **Severity:** Low
- **Affected segments:** users without WhatsApp
- **Business impact:** confusion, more support contacts

## Prioritized Implementation Plan (Fixes + Steps)
### Milestone 1 — Navigation + Feedback correctness (highest user impact)
- Make auto-refresh on resume **silent by default**, and show a subtle UI indicator when syncing.
- Add a consistent “sync in progress” indicator on Home when cached data exists.
- Add CTA from Customize “No data” state to Dashboard + trigger sync.

### Milestone 2 — Accessibility foundations
- Add `Semantics` labels and roles for major regions and primary actions.
- Ensure minimum tap targets (≥48dp) for key actions; provide accessible summary of the heatmap and stats.
- Verify text scaling (large font) doesn’t break layouts.

### Milestone 3 — Responsive layout refactors
- Replace Customize “magic spacer” with a layout that measures/allocates preview height (e.g., `CustomScrollView` + slivers or `LayoutBuilder`).
- Reduce fixed paddings that ignore SafeArea and small screens.

### Milestone 4 — Design system alignment
- Normalize typography usage to tokens, adjust baseline sizes upward where needed.
- Replace GestureDetector interactions with Material components (`InkWell`, `ListTile`) to restore affordances.
- Standardize titles (remove emojis if desired) and error message mapping.

## Remediation Details (Per Issue)
- **Auto-sync snackbar:** call `_syncData(silent: true)` from `_checkAutoUpdate`; optionally add a “Last synced …” inline indicator.
- **Home sync visibility:** show a `LinearProgressIndicator` or a top “Syncing…” banner whenever `isLoading == true`.
- **No Semantics:** wrap main cards/preview/actions with `Semantics(label: ..., button: true)`; add meaningful labels to icons.
- **Heatmap usability:** provide an alternate accessible representation (summary + drilldown) and/or increase cell size in a dedicated detail view.
- **Customize no-data:** add button to switch tabs to Dashboard and start sync.
- **Responsive spacer:** refactor to layout preview as part of scroll or pinned header using slivers.
- **Hard-coded padding:** replace with `SafeArea`-aware padding and/or `MediaQuery.padding.top`.
- **GestureDetector:** use `InkWell`/`Card`/`ListTile` for focus + ripple.
- **Typography:** adjust AppTheme fontSizeBody/base upward; ensure text respects `MediaQuery.textScaleFactor`.

## Success Metrics and Testing Criteria
- **Functional:** no broken journeys (Customize no-data leads to a recoverable path); syncing state visible; no unexpected snackbars.
- **Accessibility:** TalkBack/VoiceOver can identify primary actions; minimum touch target compliance; no clipped text at large font.
- **Responsive:** no RenderFlex overflow across common sizes (small phone, large phone, tablet, landscape).
- **Quality:** consistent component patterns and token usage.

## QA Procedures
- **Automated:** widget tests for navigation + sync states; golden tests for 3–4 screen sizes; semantics tests for key widgets.
- **Manual:** TalkBack/VoiceOver pass; large text (≥1.3x); landscape + split-screen; offline/slow network flows.

## Ownership (Role-Based)
- **Flutter engineer:** implement UI changes, tests, refactors.
- **UX designer:** approve interaction feedback, typography adjustments, accessibility copy.
- **QA engineer:** run device matrix + accessibility checklist.

If you approve, I will start implementing Milestone 1 first (navigation + feedback fixes) and produce a running checklist of resolved issues with before/after verification.