# 08 - Instant Post Queue With Upload Status

## Purpose
Improve Business Suite Create Post UX so tapping `Post Now` or `Schedule` is instant.

Previous behavior blocked the modal while media upload + schedule/publish APIs completed.
New behavior closes the modal immediately, renders a local optimistic card in Content, and updates status while background upload/publish continues.

## Root Cause
The submit flow in `schedule_post_modal.dart` awaited all network-heavy steps before `Navigator.pop`, so users were stuck on the modal during upload.

## Data Flow (New)
1. User taps `Post Now` or `Schedule` in the create modal.
2. App creates a local optimistic queue item in `ContentProvider`.
3. Modal closes immediately.
4. Background task uploads media and calls schedule/publish endpoints.
5. Content screen shows queue card status transitions:
   - `Queued`
   - `Uploading`
   - `Scheduling` or `Publishing`
   - `Scheduled` / `Published` or `Failed`
6. On success, real server lists refresh and the temporary optimistic item is removed.

## Files Updated
- `x-QpSuite/lib/features/content/models/content_models.dart`
  - Added `PendingUploadMedia` and `PendingContentUpload` models.
- `x-QpSuite/lib/features/content/providers/content_provider.dart`
  - Added optimistic pending queue state and status update helpers.
- `x-QpSuite/lib/features/content/widgets/schedule_post_modal.dart`
  - Refactored submit flow to instant-close + background processing.
  - Added background upload/schedule/publish helper functions.
- `x-QpSuite/lib/features/content/screens/content_screen.dart`
  - Added pending upload cards in both `Published` and `Scheduled` filters.
  - Added local media preview rendering and status chips.
  - Removed immediate forced refresh after modal close to avoid extra delay.

## UX Result
- Buttons respond instantly.
- User is returned to Content immediately.
- Upload progress is visible in-app without waiting on the modal.

## Validation
- `dart format` ran on all touched files.
- `flutter analyze` run for content module.
- No compile errors in changed files:
  - `content_models.dart`
  - `content_provider.dart`
  - `schedule_post_modal.dart`
  - `content_screen.dart`
