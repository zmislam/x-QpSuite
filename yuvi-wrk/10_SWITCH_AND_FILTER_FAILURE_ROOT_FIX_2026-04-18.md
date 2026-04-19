# Switch + Filter Failure Root Fix (2026-04-18)

## Root Cause (one sentence)
When dashboard fetch failed after switching pages, the UI could keep rendering stale data from the previous page because dashboard payload ownership was not bound to active page identity.

## What Was Corrected
1. Dashboard payload is now page-bound via `dataPageId`.
2. Cross-page stale payload is cleared when a new page request starts.
3. Dashboard screen renders overview/trends only when payload page matches active page.
4. If current page data is unavailable, UI shows page-specific loading/retry card instead of old metrics.
5. Switch pickers trigger page switch and close immediately (no await-latency on UI close).
6. Shell reload guard keeps explicit switching reload path active.
7. Dashboard error messaging now distinguishes session/auth failure (`401`) from generic network failure.

## Files Changed
- `lib/features/dashboard/providers/dashboard_provider.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/page_switcher/providers/managed_pages_provider.dart`
- `lib/shared/bottom_nav_shell.dart`
- `lib/shared/widgets/page_switcher.dart`

## Validation
- API route reachability probe from Node: dashboard route responds (unauthenticated returns 401), confirming host/route availability.
- Flutter analyzer on all touched files: no issues.
