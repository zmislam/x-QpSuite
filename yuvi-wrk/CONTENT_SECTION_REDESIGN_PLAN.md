# Content Section Redesign Plan

## Reference Design (Meta Business Suite Style)

### Layout Structure
```
┌──────────────────────────────────┐
│ Content                   Create │  ← Header (title + create button)
├──────────────────────────────────┤
│ Posts | Reels | Stories | ...    │  ← Scrollable tab bar
├──────────────────────────────────┤
│ [Published ▼]        [⊕ Feed]   │  ← Filter row (per tab)
├──────────────────────────────────┤
│                                  │
│   Post Cards / Grid / Empty      │  ← Tab content
│                                  │
└──────────────────────────────────┘
```

### Tabs & Features

| Tab | Filter | Content | API |
|-----|--------|---------|-----|
| **Posts** | Published/Scheduled/Drafts dropdown + Feed toggle | Full PostCard (reuse from home) with See Insights + Create Ad | `/get-pages-posts` + content API |
| **Reels** | (none) | 3-column grid with platform icons (IG/FB) | Content API with `type=reel` |
| **Stories** | Active/Expired dropdown | Empty state with Create Story button OR Story cards | Content API with `type=story` |
| **Mentions & Tags** | Facebook/Instagram chip toggle | Full PostCard showing tagged/mention posts | Content API with mentions filter |
| **Photos** | (none) | Albums horizontal scroll + All photos grid | Content API with `type=photo` |

### Shared Components
- **PostCard** → Already exists at `features/posts/widgets/post_card.dart` - USE AS-IS
- **CommentModal** → Already exists - USE AS-IS  
- **ReactionsBottomSheet** → Already exists - USE AS-IS
- **PostProvider** (reactions, comments) → Already exists - USE AS-IS

### Files to Create/Modify
1. `content_screen.dart` → Complete rewrite with TabBar
2. `content/widgets/content_post_card.dart` → Wrapper adding See Insights + Create Ad to PostCard
3. `content/widgets/reels_grid.dart` → 3-column grid for reels
4. `content/widgets/stories_tab.dart` → Stories empty/active state
5. `content/widgets/mentions_tab.dart` → Mentions & tags with platform filter
6. `content/widgets/photos_tab.dart` → Albums + all photos grid

### API Endpoints Used
- `POST /get-pages-posts` → Fetch page posts (existing)
- `GET /business-suite/{pageId}/content?type=X` → Content by type
- `POST /save-reaction-main-post` → React on post (existing)
- `GET /get-all-comments-direct-post/{postId}` → Comments (existing)
- `POST /save-user-comment-by-post` → Send comment (existing)
- `GET /reaction-user-lists-of-direct-post/{postId}` → Reaction users (existing)

### Implementation Status
- [x] Research & plan
- [ ] Content screen with tabs
- [ ] Posts tab with PostCard
- [ ] Reels grid tab
- [ ] Stories tab
- [ ] Mentions & Tags tab
- [ ] Photos tab
- [ ] Build & test
