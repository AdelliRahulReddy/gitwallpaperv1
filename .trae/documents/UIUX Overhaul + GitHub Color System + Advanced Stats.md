## Goals
- Redesign all 5 screens (Onboarding, MainNav shell, Home/Dashboard, Customize, Settings) into a cohesive, modern UI with consistent spacing, typography hierarchy, and responsive layouts.
- Correct contribution intensity colors so minimal activity is light green and high activity is darker/more saturated green across all screens and visualizations.
- Upgrade the Home/Dashboard to surface comprehensive statistics and interactive visualizations: total commits, trends, active repositories, streaks, top languages, and user activity metrics.

## Design System (App-Wide)
- Introduce a GitHub-inspired design token set (colors, neutrals, elevations, radii, spacing) and apply it consistently across pages.
- Define a single contribution palette used everywhere (UI heatmap + wallpaper preview + breakdown cards) with an explicit “low → light green, high → dark green” mapping.
- Standardize typography using the existing Inter font: clear headline/title/body/caption styles and consistent line heights.
- Create a small reusable component set for consistency:
  - Page scaffold/header (title, subtitle, actions)
  - Stat tiles (KPI cards)
  - Section headers
  - Data cards (consistent padding, border, shadow)
  - Empty/loading/error states

## Data & Stats Expansion (Models + GitHub API)
- Extend the GraphQL query used by `GitHubService.fetchContributions` to fetch repository and language metadata needed by the dashboard:
  - `commitContributionsByRepository { repository { nameWithOwner, url, isPrivate, primaryLanguage { name color }, languages(...) { edges { size node { name color }}} } contributions { totalCount } }`
- Add new model fields to `CachedContributionData` to store:
  - Active repositories + per-repo commit totals (for “active repos” and repo ranking)
  - Language aggregation data (for “top languages”)
  - Derived time-series aggregates (weekly totals, moving averages) computed client-side from daily contribution counts
- Maintain backward-compatible cache parsing so older stored JSON still loads (new fields optional with safe defaults).

## Home / Dashboard Overhaul (Primary Focus)
- Replace the current “basic” layout with a structured analytics dashboard:
  - **Header**: user identity + last sync + quick actions (refresh, open profile, jump to Customize).
  - **KPI Row/Grid**: total commits, current streak, longest streak, active repositories, active days, avg/day (responsive grid).
  - **Trends Module**: interactive commit frequency trend chart (e.g., 30/90 day view) with deltas vs previous period.
  - **Contribution Heatmap**: keep the 6‑month graph but upgrade presentation (legend, better spacing, month labels, tooltips/bottom sheet).
  - **Repositories**: “Most Active Repos” list with contribution counts and optional language badge.
  - **Languages**: “Top Languages” visualization (horizontal bar chart) using GitHub language colors when available.
  - **Activity Insights**: weekday distribution + weekend/weekday ratio + peak day/week.
- Ensure all chart colors and legends follow the corrected GitHub-style green gradient.

## Other Pages (Consistency + Modernization)
- **Onboarding**: simplify to a clean 2–3 step flow (intro → credentials → success), unify with the new typography and card styles, and replace any non-standard heatmap greens with the shared GitHub palette.
- **Customize**: redesign into a professional “editor” layout:
  - Strong preview panel styling
  - Controls grouped into collapsible sections (Placement, Appearance, Quote)
  - Consistent sliders/switches/buttons
- **Settings**: convert to a polished settings layout with consistent section cards, clearer hierarchy, and improved action affordances (logout, clear cache, about).
- **MainNav**: update background/elevation and selected-state styling to match the new system.

## Interactive Elements & Visualizations (No New Dependencies)
- Implement lightweight charts with `CustomPainter` + gestures:
  - Sparkline/area trend chart with tap-to-inspect
  - Language bar chart with percentages
  - Repo list with tap → details sheet
- Keep existing bottom sheets for heatmap cells, but restyle and expand them (show date, commits, running streak context, and comparison to average).

## Verification
- Add unit tests for:
  - Contribution level → color mapping (ensures low=light, high=dark)
  - Repo/language aggregation correctness
  - Trend computations (weekly totals, deltas)
- Run existing integration tests and update any goldens/expectations impacted by the UI overhaul.

If you confirm this plan, I’ll proceed to implement it end-to-end (theme + shared components + API/model updates + redesigned UIs + tests), then run the full test suite.