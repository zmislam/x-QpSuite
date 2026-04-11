# 07 - Scheduled Video Preview Hardening

## Purpose
Fix remaining cases where scheduled video previews were still missing in Business Suite, even after local picker previews were added.

## Root Cause
Some scheduled uploads were classified as non-video because backend detection relied only on MIME type, and frontend scheduled grids attempted to render video URLs as images when thumbnail paths were missing or invalid.

## Data Flow
User uploads scheduled media -> API classifies media type and generates thumbnail when video -> ScheduledContent stores `url/type/thumbnail_url` -> Flutter scheduled cards request display URL -> if thumbnail is unavailable, UI now falls back to first-frame video rendering via `video_player`.

## Files Affected
- qp-api/controller/BusinessSuite/ContentController.js
- x-QpSuite/lib/core/constants/api_constants.dart
- x-QpSuite/lib/features/content/widgets/network_video_preview.dart (new)
- x-QpSuite/lib/features/content/screens/content_screen.dart
- x-QpSuite/lib/features/content/screens/scheduled_posts_screen.dart
- x-QpSuite/lib/features/content/widgets/edit_scheduled_modal.dart

## What Changed
1. Backend upload hardening:
   - Expanded scheduled/post media extension allowlist to include `mkv` and `m4v`.
   - In scheduled upload handler, video detection now uses MIME OR file extension.
   - This ensures thumbnails are generated for browser uploads that send weak MIME metadata.

2. Scheduled thumbnail URL normalization:
   - Added handling for `thumbnails/...` values in scheduled thumbnail URL builder.
   - Prevents malformed URL construction for legacy/inconsistent thumbnail formats.

3. Frontend fallback preview path:
   - Added reusable `NetworkVideoPreview` widget for remote video frame rendering.
   - Scheduled card grids (`Content` tab and `Scheduled Posts` screen) now fall back to video-frame preview when image thumbnail loading fails or is absent.
   - Edit Scheduled modal now uses the same fallback for existing scheduled videos.

## Validation
- `dart analyze` on all touched Flutter files: no issues.
- `flutter build web --release`: success.
- `node --check qp-api/controller/BusinessSuite/ContentController.js`: success.

## Notes
- No newsfeed logic was modified.
- Changes are backward-compatible with existing scheduled media records.
