# Page Switching Regression Fix (2026-04-18)

## Purpose
Fix regression where selecting a different managed page showed no effective change in dashboard content.

## Root Cause
Page switching notification was emitted only after awaiting local persistence (`StorageService.setString`), so UI/provider listeners could miss or delay switch updates when persistence was slow/failing. This made page change appear to have no effect.

## Data Flow Fix
1. User selects a page in switcher.
2. Provider updates in-memory active page and switching state immediately.
3. Provider notifies listeners immediately.
4. Shell detects `activePageId` change and triggers provider reloads.
5. Persistence of last selected page runs without blocking UI update path.

## Files Updated
- `lib/features/page_switcher/providers/managed_pages_provider.dart`
  - `setActivePage` now notifies immediately and does not block on storage write.
  - Storage persistence failures are safely ignored for UI continuity.
- `lib/shared/bottom_nav_shell.dart`
  - Reload trigger now also runs for explicit switching events even if shell page-id cache is in first-load state.
- `lib/features/dashboard/screens/dashboard_screen.dart`
  - Dashboard page picker now awaits switch operation before closing picker for deterministic behavior.
- `lib/shared/widgets/page_switcher.dart`
  - Shared switcher picker uses same deterministic switch ordering.

## Validation
- `flutter analyze` run on all touched switching files.
- No analyzer errors.
