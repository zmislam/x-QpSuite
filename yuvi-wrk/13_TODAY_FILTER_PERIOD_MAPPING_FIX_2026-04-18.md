# Today Filter Period Mapping Fix (2026-04-18)

## Purpose
Fix dashboard Today filter failures in QP Suite mobile by removing period value ambiguity between UI filter values and API query values.

## Root Cause (one sentence)
Dashboard UI encoded Today as period `0`, but backend treats `period=0` as all-time, so selecting Today could trigger expensive all-time queries and fail with connection-style errors.

## Data Flow (Before)
1. User taps Today in Overview period pills.
2. Provider stored `_period = 0` for Today.
3. Provider sent `GET /business-suite/:pageId/dashboard?period=0`.
4. Backend interpreted this as all-time mode (not Today), often resulting in slow/heavy processing and dashboard refresh failure.
5. UI showed warning banner: "Could not load dashboard. Check your connection."

## Data Flow (After)
1. User taps Today in Overview period pills.
2. Provider stores `_period = 1` for Today (`2` for Yesterday, `-1` for All).
3. Provider converts UI period to API period via `_toApiPeriod()`.
4. API receives correct value (`1` for Today, `2` for Yesterday, `0` only for All-time).
5. Dashboard refresh runs against expected date window and avoids all-time collision.

## Files Affected
- `lib/features/dashboard/providers/dashboard_provider.dart`
  - Updated `periodOptions` values to remove Today/All-time collision.
  - Added `_normalizeUiPeriod()` for backward compatibility with legacy `0` Today value.
  - Added `_toApiPeriod()` to centralize API mapping and prevent future regressions.
  - Updated `fetchDashboard()` and `setPeriod()` to use normalization/mapping.

## Related Recent Edits Considered
- Existing stale-request protection (`_requestNonce`) remains unchanged and continues to prevent out-of-order filter responses.
- Existing page-bound dashboard payload (`dataPageId`) remains unchanged and continues to prevent stale cross-page data rendering.
- Inline dashboard refresh warning behavior remains unchanged; this fix targets the incorrect period semantics causing false connection errors.

## Validation
- VS Code analyzer check on updated file: no errors.
