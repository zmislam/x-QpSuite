# Content Page: Instant Refresh + Edit/Delete Actions

## Date: 2025-01-XX

## Purpose
Two fixes for the Content page in x-QpSuite Business Suite:
1. Posts now refresh instantly after creating from the SchedulePostModal
2. Action bar on each post card now includes Edit, Delete, and Boost buttons (matching web)

## Files Changed

### 1. `lib/features/content/screens/content_screen.dart`
- **Create button** now `await`s `SchedulePostModal.show()` and on success (`true`), calls `PostProvider.fetchPagePosts(pageId, refresh: true)` immediately
- Also schedules a delayed refresh (20s) to catch cron-published "Post Now" content

### 2. `lib/features/content/widgets/schedule_post_modal.dart`
- `show()` return type changed from `Future<void>` to `Future<bool?>` so callers know if content was posted
- Both success `Navigator.pop` calls now pass `true` as the result value

### 3. `lib/features/posts/providers/post_provider.dart`
- Added `deletePost(pageId, postId)` — DELETE to `/business-suite/:pageId/published-posts/:postId`, removes from local list
- Added `editPost(pageId, postId, {description, addMedia, removeMediaIds})` — PATCH to same endpoint, updates local state

### 4. `lib/features/content/widgets/content_post_card.dart`
- Replaced "See Insights + Create Ad" action bar with 4-button layout matching web:
  - **Insights** — navigates to post insights
  - **Edit** — opens EditPostModal for description editing
  - **Delete** — confirmation dialog → calls `PostProvider.deletePost()`
  - **Boost Post** — button placeholder (same as web)
- Added import for `ManagedPagesProvider` and `EditPostModal`

### 5. `lib/features/content/widgets/edit_post_modal.dart` (NEW)
- Full-screen bottom sheet for editing a published post's description
- Shows existing media as read-only thumbnails
- Calls `PostProvider.editPost()` on save, returns `true` on success
- Refreshes post list after successful edit

## Data Flow
- **Instant refresh**: User → Create button → SchedulePostModal → success → `Navigator.pop(context, true)` → content_screen awaits → calls `PostProvider.fetchPagePosts()` + delayed 20s refresh
- **Edit**: ContentPostCard Edit tap → EditPostModal → save → `PostProvider.editPost()` → PATCH API → local state update → refresh posts
- **Delete**: ContentPostCard Delete tap → confirmation dialog → `PostProvider.deletePost()` → DELETE API → remove from local list → SnackBar feedback

## API Endpoints Used
- `DELETE /business-suite/:pageId/published-posts/:postId` — soft-delete post
- `PATCH /business-suite/:pageId/published-posts/:postId` — edit description/media
