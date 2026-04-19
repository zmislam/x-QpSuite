# Page Switch + Stale Dashboard Binding Fix (2026-04-18)

## Purpose
Eliminate the perception that page switching is broken when dashboard API calls fail after switching pages.

## Root Cause (one sentence)
Dashboard state was not bound to the currently selected page, so after a page switch failure the UI could continue rendering previous-page dashboard payloads, making switching appear ineffective.

## Corrected Data Flow
1. User selects a different managed page.
2. Provider updates active page immediately and triggers reload pipeline.
3. Dashboard provider tracks which page id its payload belongs to.
4. Dashboard UI renders overview/trends only when payload page id matches active page id.
5. If mismatch/failure occurs, UI shows page-specific loading/retry state instead of stale old-page metrics.

## Files Updated
- `lib/features/dashboard/providers/dashboard_provider.dart`
  - Added `dataPageId` tracking.
  - Clears stale cross-page payload when a different page request starts.
  - Sets `dataPageId` only on successful fetch.
- `lib/features/dashboard/screens/dashboard_screen.dart`
  - Added `hasCurrentPageData` guard.
  - Hero and follower count now fall back to active page when dashboard payload is not for active page.
  - Overview section now displays page-specific loading/error/retry state when current-page data is unavailable.
  - Onboarding section is hidden when current-page data is unavailable (prevents stale display).
  - Page picker closes immediately while switch runs, keeping UX responsive.
- `lib/shared/widgets/page_switcher.dart`
  - Shared page picker now closes immediately after triggering switch.

## Validation
- `flutter analyze` run on touched switching/dashboard files.
- Result: no analyzer issues.
