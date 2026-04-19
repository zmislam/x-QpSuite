# Dashboard Filter Loading & Trends Fix (2026-04-18)

## Purpose
Ensure dashboard filters in Overview and Performance Trends behave reliably and give clear visual feedback after selection.

## Problem Summary
- Period filter selections could trigger overlapping network requests, allowing stale responses to overwrite newer filter selections.
- Overview refresh had no obvious in-screen loading feedback after filter selection when data already existed.
- Trend and KPI sparkline charts could become unstable with flat/zero-only datasets, reducing confidence that filters applied correctly.

## Data Flow (Updated)
1. User selects a dashboard period filter.
2. `DashboardProvider.setPeriod()` triggers `fetchDashboard(pageId)`.
3. Provider assigns a request nonce to each fetch and ignores stale responses.
4. UI immediately shows loading state in Overview/Trends while new data is fetched.
5. Updated KPI/trend datasets render safely even when values are all equal or zero.

## Files Updated
- `lib/features/dashboard/providers/dashboard_provider.dart`
  - Added request nonce guard to prevent stale filter responses from overriding latest selection.
- `lib/features/dashboard/screens/dashboard_screen.dart`
  - Added visible loading status text/spinner for Overview and Trends refresh.
  - Added non-blocking inline error banner when refresh fails.
  - Passed provider loading state into `PeriodFilter`.
- `lib/features/dashboard/widgets/period_filter.dart`
  - Added optional `isLoading` indicator to show active refresh state next to filter chips.
- `lib/features/dashboard/widgets/trend_chart_section.dart`
  - Added safe y-axis resolver to handle flat/zero values for all trend charts.
- `lib/features/dashboard/widgets/kpi_grid.dart`
  - Hardened sparkline bounds for flat/zero datasets.

## Validation
- `flutter analyze` run on all modified dashboard/provider/widget files.
- Result: no analyzer errors.
