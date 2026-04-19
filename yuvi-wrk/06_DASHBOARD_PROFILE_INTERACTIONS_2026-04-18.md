# Dashboard Profile Interaction Fixes (2026-04-18)

## Purpose
Improve key interaction behavior on the Business Suite dashboard hero section:
- Tapping profile picture or cover photo now opens a full-screen image preview.
- Tapping follower count now opens a follower list with follower profile pictures.
- Tapping Advertise now shows a clear "coming soon" feedback message.

These changes align the Flutter dashboard behavior with expected mobile UX from QA screenshots.

## Data Flow
1. User taps Followers count on dashboard hero.
2. Flutter dashboard screen calls API endpoint /get-all-followers with page_id.
3. API returns populated follower list entries.
4. UI renders follower name, profile picture, and followed date in a bottom sheet.

## Files Affected
- lib/features/dashboard/screens/dashboard_screen.dart
  - Added image preview viewer route/widget.
  - Added followers list bottom sheet and follower-item mapping.
  - Connected hero interactions (cover/profile/followers tap handlers).
  - Updated Advertise quick action tap behavior.
- lib/core/constants/api_constants.dart
  - Added allFollowers endpoint constant.

## API Contract Used
- Endpoint: /get-all-followers
- Request body: { page_id: <string> }
- Response list item expected shape:
  - user_id.first_name
  - user_id.last_name
  - user_id.username
  - user_id.profile_pic
  - createdAt

## Compatibility Notes
- No newsfeed logic was modified.
- Existing create post/reel/story/photo behavior remains unchanged.
- Follower list handles loading, empty, and error states safely.

## Validation
- flutter analyze lib/features/dashboard/screens/dashboard_screen.dart
- Result: No issues found.
