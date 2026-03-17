# QP Suite — Master Implementation Plan

> **Date:** 2026-03-16  
> **App Name:** QP Suite  
> **Scope:** World-class Facebook Business Suite-class mobile application for iOS & Android  
> **Framework:** Flutter  
> **Target Users:** Billion-scale  
> **Reference Docs:** `MOBILE_APP_BUSINESS_SUITE_GUIDE.md`, `MOBILE_APP_ADS_MANAGER_GUIDE.md`  
> **Reference Apps:** x-QpApsMain (Flutter/GetX), x-QpMessenger (Flutter/Provider/GoRouter)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technology Stack](#2-technology-stack)
3. [Project Structure](#3-project-structure)
4. [Navigation Architecture](#4-navigation-architecture)
5. [Implementation Phases](#5-implementation-phases)
6. [Key Architectural Decisions](#6-key-architectural-decisions)
7. [UI/UX Design Targets](#7-uiux-design-targets)
8. [Dependencies](#8-dependencies)
9. [Scalability Considerations](#9-scalability-considerations)
10. [Summary Counts](#10-summary-counts)

---

## 1. Executive Summary

**QP Suite** is a Facebook Business Suite-class mobile application for iOS & Android, built with **Flutter**, enabling businesses to manage their QP Pages, content, inbox, insights, ads, and audience — all from one app. Based on thorough review of:

- `MOBILE_APP_BUSINESS_SUITE_GUIDE.md` (1195 lines, 28 sections)
- `MOBILE_APP_ADS_MANAGER_GUIDE.md` (1192 lines, 30 sections)
- **x-QpApsMain** (Flutter, GetX, 100+ routes, Dio, Firebase)
- **x-QpMessenger** (Flutter, Provider + GoRouter, Dio, Socket.IO, Hive, WebRTC)

---

## 2. Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Framework** | **Flutter 3.x** | Cross-platform iOS/Android, consistent with x-QpApsMain & x-QpMessenger |
| **State Management** | **Provider + ChangeNotifier** | Proven in x-QpMessenger, simpler than GetX, excellent for team familiarity |
| **Navigation** | **GoRouter** | Type-safe, deep-link ready, auth guards, shell routes for bottom nav (proven in x-QpMessenger) |
| **HTTP Client** | **Dio** | Interceptors for JWT auth, retry logic, consistent with both existing apps |
| **Local Storage** | **Hive** (cache) + **flutter_secure_storage** (tokens) | Offline-first, encrypted token storage |
| **Realtime** | **Socket.IO** (for inbox messaging) | Consistent with existing infra |
| **Charts** | **fl_chart** | Beautiful, customizable charts for insights dashboards |
| **Push Notifications** | **Firebase Cloud Messaging** | Already configured in both apps |
| **Payments** | **Stripe Flutter SDK** | For ads billing (SetupIntent → card sheet) |
| **Image Caching** | **cached_network_image** | Proven in both apps |
| **Internationalization** | **flutter_localizations + intl** | Billion-user scale requires i18n |

---

## 3. Project Structure (Feature-First Architecture)

```
x-QpSuite/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── app.dart                           # Root MaterialApp.router
│   ├── firebase_options.dart              # Firebase config
│   │
│   ├── core/                              # Shared infrastructure
│   │   ├── constants/
│   │   │   ├── api_constants.dart         # All API endpoints
│   │   │   ├── app_constants.dart         # App name, deep links
│   │   │   ├── design_tokens.dart         # Colors, spacing, typography tokens
│   │   │   └── storage_keys.dart          # Local storage key constants
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # QP brand + FB Business Suite palette
│   │   │   ├── app_theme.dart             # Light & dark ThemeData
│   │   │   └── app_typography.dart        # Text styles
│   │   ├── router/
│   │   │   └── app_router.dart            # GoRouter with auth guard + shell routes
│   │   ├── services/
│   │   │   ├── api_service.dart           # Dio client + JWT interceptor
│   │   │   ├── storage_service.dart       # Hive + Secure storage init
│   │   │   ├── push_notification_service.dart
│   │   │   ├── socket_service.dart        # Socket.IO for inbox realtime
│   │   │   └── deep_link_service.dart     # Universal/deep link handling
│   │   ├── models/
│   │   │   ├── api_response.dart          # Generic API response wrapper
│   │   │   └── pagination.dart            # Pagination model
│   │   ├── providers/
│   │   │   ├── page_context_provider.dart # Active page context (pageId)
│   │   │   └── theme_provider.dart        # Dark/light mode
│   │   ├── widgets/                       # Shared reusable widgets
│   │   │   ├── qp_app_bar.dart
│   │   │   ├── qp_bottom_sheet.dart
│   │   │   ├── qp_card.dart
│   │   │   ├── qp_loading.dart
│   │   │   ├── kpi_card.dart
│   │   │   ├── trend_chart.dart
│   │   │   ├── empty_state.dart
│   │   │   ├── error_state.dart
│   │   │   ├── media_picker.dart
│   │   │   ├── date_range_picker.dart
│   │   │   ├── page_switcher.dart
│   │   │   └── status_badge.dart
│   │   └── utils/
│   │       ├── formatters.dart            # Currency (cents→display), numbers, dates
│   │       ├── validators.dart
│   │       └── media_utils.dart
│   │
│   ├── features/                          # Feature modules
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── splash_screen.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   │
│   │   ├── page_switcher/
│   │   │   ├── screens/
│   │   │   │   └── page_selector_screen.dart
│   │   │   ├── models/
│   │   │   │   └── managed_page_model.dart
│   │   │   └── providers/
│   │   │       └── managed_pages_provider.dart
│   │   │
│   │   ├── dashboard/                     # HOME TAB
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── kpi_grid.dart
│   │   │   │   ├── trend_chart_section.dart
│   │   │   │   ├── top_posts_section.dart
│   │   │   │   ├── recent_activity_section.dart
│   │   │   │   ├── onboarding_card.dart
│   │   │   │   └── todo_summary_card.dart
│   │   │   ├── models/
│   │   │   │   └── dashboard_model.dart
│   │   │   └── providers/
│   │   │       └── dashboard_provider.dart
│   │   │
│   │   ├── content/                       # CONTENT TAB
│   │   │   ├── screens/
│   │   │   │   ├── content_screen.dart         # Main content list
│   │   │   │   ├── schedule_content_screen.dart
│   │   │   │   ├── edit_published_post_screen.dart
│   │   │   │   ├── scheduled_posts_screen.dart
│   │   │   │   └── content_calendar_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── published_post_card.dart
│   │   │   │   ├── scheduled_post_card.dart
│   │   │   │   ├── content_type_filter.dart
│   │   │   │   └── calendar_day_view.dart
│   │   │   ├── models/
│   │   │   │   ├── content_model.dart
│   │   │   │   └── scheduled_content_model.dart
│   │   │   └── providers/
│   │   │       ├── content_provider.dart
│   │   │       └── schedule_provider.dart
│   │   │
│   │   ├── inbox/                         # INBOX TAB
│   │   │   ├── screens/
│   │   │   │   ├── inbox_screen.dart           # Thread list
│   │   │   │   └── thread_detail_screen.dart   # Chat view
│   │   │   ├── widgets/
│   │   │   │   ├── thread_tile.dart
│   │   │   │   ├── message_bubble.dart
│   │   │   │   └── reply_composer.dart
│   │   │   ├── models/
│   │   │   │   ├── thread_model.dart
│   │   │   │   └── message_model.dart
│   │   │   └── providers/
│   │   │       └── inbox_provider.dart
│   │   │
│   │   ├── insights/                      # INSIGHTS TAB
│   │   │   ├── screens/
│   │   │   │   ├── insights_overview_screen.dart
│   │   │   │   ├── audience_screen.dart
│   │   │   │   ├── content_insights_screen.dart
│   │   │   │   └── post_insights_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── insight_kpi_card.dart
│   │   │   │   ├── line_chart_widget.dart
│   │   │   │   ├── pie_chart_widget.dart
│   │   │   │   ├── bar_chart_widget.dart
│   │   │   │   └── demographic_section.dart
│   │   │   ├── models/
│   │   │   │   ├── insights_model.dart
│   │   │   │   └── audience_model.dart
│   │   │   └── providers/
│   │   │       └── insights_provider.dart
│   │   │
│   │   ├── more/                          # MORE TAB
│   │   │   ├── screens/
│   │   │   │   └── more_screen.dart        # Grid menu (notifications, ads, planner, settings...)
│   │   │   └── widgets/
│   │   │       └── menu_grid_item.dart
│   │   │
│   │   ├── notifications/
│   │   │   ├── screens/
│   │   │   │   └── notifications_screen.dart
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart
│   │   │   └── providers/
│   │   │       └── notifications_provider.dart
│   │   │
│   │   ├── todos/
│   │   │   ├── screens/
│   │   │   │   └── todos_screen.dart
│   │   │   ├── models/
│   │   │   │   └── todo_model.dart
│   │   │   └── providers/
│   │   │       └── todos_provider.dart
│   │   │
│   │   ├── boost/
│   │   │   ├── screens/
│   │   │   │   ├── boosted_posts_screen.dart
│   │   │   │   └── boost_flow_sheet.dart
│   │   │   ├── models/
│   │   │   │   └── boosted_post_model.dart
│   │   │   └── providers/
│   │   │       └── boost_provider.dart
│   │   │
│   │   ├── ads_manager/                   # Full Ads Manager Module
│   │   │   ├── screens/
│   │   │   │   ├── ads_overview_screen.dart
│   │   │   │   ├── campaigns_screen.dart
│   │   │   │   ├── campaign_detail_screen.dart
│   │   │   │   ├── campaign_wizard/
│   │   │   │   │   ├── step1_campaign_setup.dart
│   │   │   │   │   ├── step2_adset_config.dart
│   │   │   │   │   └── step3_ad_creative.dart
│   │   │   │   ├── ad_sets_screen.dart
│   │   │   │   ├── ad_detail_screen.dart
│   │   │   │   ├── audiences_screen.dart
│   │   │   │   ├── leads_screen.dart
│   │   │   │   ├── funnel_screen.dart
│   │   │   │   ├── ab_test_screen.dart
│   │   │   │   └── reports_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── campaign_card.dart
│   │   │   │   ├── ad_preview_card.dart
│   │   │   │   ├── objective_picker.dart
│   │   │   │   ├── audience_builder.dart
│   │   │   │   ├── placement_selector.dart
│   │   │   │   ├── budget_slider.dart
│   │   │   │   └── cta_picker.dart
│   │   │   ├── models/
│   │   │   │   ├── campaign_model.dart
│   │   │   │   ├── ad_set_model.dart
│   │   │   │   ├── ad_model.dart
│   │   │   │   ├── ad_account_model.dart
│   │   │   │   └── audience_model.dart
│   │   │   └── providers/
│   │   │       ├── campaigns_provider.dart
│   │   │       ├── ad_sets_provider.dart
│   │   │       ├── ads_provider.dart
│   │   │       └── audiences_provider.dart
│   │   │
│   │   ├── billing/                       # Stripe Billing Module
│   │   │   ├── screens/
│   │   │   │   ├── billing_screen.dart
│   │   │   │   ├── payment_method_screen.dart
│   │   │   │   ├── billing_history_screen.dart
│   │   │   │   └── cost_breakdown_screen.dart
│   │   │   ├── models/
│   │   │   │   ├── billing_status_model.dart
│   │   │   │   └── billing_cycle_model.dart
│   │   │   └── providers/
│   │   │       └── billing_provider.dart
│   │   │
│   │   ├── onboarding/
│   │   │   ├── screens/
│   │   │   │   └── advertiser_onboarding_screen.dart
│   │   │   └── providers/
│   │   │       └── onboarding_provider.dart
│   │   │
│   │   └── settings/
│   │       ├── screens/
│   │       │   ├── settings_screen.dart
│   │       │   └── profile_management_screen.dart
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   └── shared/                            # Cross-feature shared widgets
│       ├── bottom_nav_shell.dart           # 5-tab bottom navigation
│       └── page_aware_scaffold.dart        # Scaffold that checks page context
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── animations/                        # Lottie animations
│   └── fonts/
│
├── android/                               # Native Android config
├── ios/                                   # Native iOS config
├── test/                                  # Unit + widget tests
├── integration_test/                      # E2E tests
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 4. Navigation Architecture (Bottom Tabs)

```
┌──────────────────────────────────────────────────────────────┐
│    Home    │   Content   │   Inbox   │  Insights  │   More   │
│    🏠      │     📄      │    📬     │     📊     │    ≡     │
└──────────────────────────────────────────────────────────────┘
```

| Tab | Primary Screen | Sub-Screens |
|-----|---------------|-------------|
| **Home** | Dashboard (KPIs, charts, top posts, activity, todos, onboarding) | - |
| **Content** | Published + Scheduled content list | Schedule new, Edit post, Calendar, Scheduled posts |
| **Inbox** | Thread list (page messages) | Thread detail, Reply |
| **Insights** | Overview with KPI + charts | Audience demographics, Content performance, Post insights |
| **More** | Grid menu | Notifications, Ads Manager, Boosted Posts, Billing, Planner, Todos, Settings, Profile Mgmt |

**Page Switcher:** Header dropdown on all tabs (like Facebook Business Suite) — tap page avatar to switch between managed pages.

---

## 5. Implementation Phases

### Phase 1: Foundation & Core (Week 1-2)

| # | Task | Details |
|---|------|---------|
| 1.1 | **Project scaffolding** | Create Flutter project, configure pubspec.yaml, set up folder structure |
| 1.2 | **Design system** | Colors, typography, theme (light + dark), design tokens, shared widgets |
| 1.3 | **Core services** | ApiService (Dio + JWT), StorageService (Hive + SecureStorage), DeepLinkService |
| 1.4 | **Auth flow** | Login screen, JWT token management, auto-refresh, splash/session restore |
| 1.5 | **GoRouter setup** | Route tree, auth guard, StatefulShellRoute for 5-tab bottom nav |
| 1.6 | **Page context system** | ManagedPagesProvider, PageSwitcher widget, persistent last-selected page |
| 1.7 | **Shared widgets** | KpiCard, StatusBadge, EmptyState, ErrorState, LoadingShimmer, MediaPicker |

### Phase 2: Dashboard (Home) (Week 2-3)

| # | Task | Details |
|---|------|---------|
| 2.1 | **Dashboard provider** | Fetch `/dashboard?period=7`, state management, error handling |
| 2.2 | **KPI cards grid** | 8 KPI cards (followers, reach, engagement, impressions, clicks, page views, messages, posts) with trend arrows |
| 2.3 | **Trend chart** | Line chart (fl_chart) with metric selector + period toggle (7d/14d/30d/all) |
| 2.4 | **Top posts section** | Horizontal scroll with post cards showing engagement stats |
| 2.5 | **Recent activity feed** | Vertical list with user avatars, action messages, timestamps |
| 2.6 | **Onboarding checklist** | Progress bar + 4 checkpoints with action CTAs |
| 2.7 | **Todo summary card** | Pending action items with priority indicators |

### Phase 3: Content Management (Week 3-4)

| # | Task | Details |
|---|------|---------|
| 3.1 | **Content list** | Tab control (All/Published/Scheduled), type filter pills, paginated list |
| 3.2 | **Published post card** | Media grid, stats row, boost badge, 3-dot menu (Edit/Delete/Boost/Insights) |
| 3.3 | **Scheduled post card** | Status badge, content preview, scheduled time, menu (Edit/Cancel/Publish Now) |
| 3.4 | **Schedule content flow** | FAB → text editor + media picker + content type + date/time picker + preview |
| 3.5 | **Edit published post** | Inline text edit + add/remove media |
| 3.6 | **Content calendar** | Month grid with dot indicators, day detail, quick schedule on tap |
| 3.7 | **Publish now** | Bypass cron for immediate publish |

### Phase 4: Inbox (Week 4-5)

| # | Task | Details |
|---|------|---------|
| 4.1 | **Thread list** | Contact avatar, last message, timestamp, unread indicator, pull-to-refresh |
| 4.2 | **Thread detail** | Chat bubble UI (page=right, visitor=left), auto-scroll, mark-as-read |
| 4.3 | **Reply composer** | Text input + send button |
| 4.4 | **Socket.IO integration** | Real-time message delivery, typing indicators |
| 4.5 | **Unread badge** | Badge count on inbox tab icon |

### Phase 5: Insights (Week 5-6)

| # | Task | Details |
|---|------|---------|
| 5.1 | **Insights overview** | Date range picker, summary KPI cards, line chart with metric selector |
| 5.2 | **Audience demographics** | Gender pie chart, age bar chart, top countries/cities ranked lists |
| 5.3 | **Content performance** | Per-post table sortable by reach/engagement/clicks |
| 5.4 | **Post-level insights** | Post preview + metric cards + engagement pie + demographics + hourly chart |

### Phase 6: More Menu & Supporting Features (Week 6-7)

| # | Task | Details |
|---|------|---------|
| 6.1 | **More screen** | 4x3 icon grid (Notifications, Ads, Planner, Appointments, Events, Payouts, Orders, Insights, Leads Centre, Settings, Billing, Help) |
| 6.2 | **Notifications** | Feed list, badge count, swipe to dismiss, mark all read, deep link on tap |
| 6.3 | **Todos** | Priority-sorted list, swipe actions (done/dismiss), category filter pills |
| 6.4 | **Boosted posts** | Active/paused/completed list, pause/resume actions |
| 6.5 | **Boost flow** | Bottom sheet: post preview, budget slider, duration, audience targeting, CTA picker |
| 6.6 | **Push notifications** | FCM setup, notification handler, deep link routing |
| 6.7 | **Profile management** | Profile picture, cover photo, bio, details editing |

### Phase 7: Ads Manager (Week 7-9)

| # | Task | Details |
|---|------|---------|
| 7.1 | **Ads overview dashboard** | Active campaigns, total spend chart, KPIs |
| 7.2 | **Campaigns list** | Filterable by status, campaign cards with ad set count |
| 7.3 | **Campaign detail** | Full hierarchy view (Campaign → Ad Sets → Ads) |
| 7.4 | **Campaign creation wizard** | 3-step: Campaign setup → Ad Set config → Ad creative |
| 7.5 | **Ad set builder** | Budget, schedule, audience builder, placements, optimization |
| 7.6 | **Ad creative editor** | Media upload, text fields, CTA, destination, UTM tracking, preview |
| 7.7 | **Campaign analytics** | Summary, daily charts, demographics breakdown |
| 7.8 | **Audiences module** | Saved, custom (CSV), retargeting, lookalike audiences |
| 7.9 | **Leads module** | Lead form builder, submissions viewer, CSV export |
| 7.10 | **Funnels** | Visual funnel builder (Awareness→Interest→Decision→Action) |
| 7.11 | **A/B testing** | Test wizard, side-by-side results comparison |
| 7.12 | **Reports & export** | Summary + CSV/PDF export via share sheet |
| 7.13 | **Bulk actions** | Multi-select → pause/activate/archive |

### Phase 8: Billing & Payments (Week 9-10)

| # | Task | Details |
|---|------|---------|
| 8.1 | **Billing dashboard** | Account state, unbilled spend, threshold progress |
| 8.2 | **Stripe payment method** | SetupIntent flow, card sheet, card summary display |
| 8.3 | **Cost breakdown** | Charts by campaign, by event type, daily spend |
| 8.4 | **Billing history** | Cycle list, cycle detail |
| 8.5 | **Advertiser onboarding** | Profile setup, business type, verification |

### Phase 9: Polish & Production (Week 10-12)

| # | Task | Details |
|---|------|---------|
| 9.1 | **Offline & caching** | Hive-backed API response cache, offline indicators |
| 9.2 | **Error handling** | Global error boundary, retry patterns, toast notifications |
| 9.3 | **Loading states** | Shimmer loaders for all list/card views |
| 9.4 | **Pull-to-refresh** | All list screens |
| 9.5 | **Infinite scroll** | Paginated lists with auto-load on scroll |
| 9.6 | **Dark mode** | Full dark theme verification across all screens |
| 9.7 | **Animations** | Page transitions, card tap feedback, chart animations |
| 9.8 | **i18n foundation** | Localization setup for English (expandable) |
| 9.9 | **Deep links** | Handle `qp://suite/...` links for notifications |
| 9.10 | **App icons & splash** | Branded launch screen, app icons (iOS/Android) |
| 9.11 | **Testing** | Unit tests for providers, widget tests for key screens |
| 9.12 | **Build config** | Android signing, iOS provisioning, environment configs (dev/staging/prod) |

---

## 6. Key Architectural Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| **Single app** (not 2 separate apps) | Business Suite + Ads Manager combined into QP Suite | Facebook does this — Business Suite includes Ads tools. Simpler UX. |
| **Provider over GetX** | Provider + ChangeNotifier | Cleaner, more testable, aligns with x-QpMessenger patterns, official Flutter team recommendation |
| **GoRouter over Navigator 2.0** | GoRouter | Declarative, deep-link ready, auth guard built-in, proven in x-QpMessenger |
| **Feature-first folder structure** | Each feature is self-contained (screens/models/providers/widgets) | Scales well for 20+ features, easy to find code, supports modular development |
| **Cents-based currency** | All monetary values stored/transmitted as integer cents | Prevents floating-point rounding errors, consistent with API contract |
| **Page context as global provider** | PageContextProvider at root, all API calls use it | Mirrors the web's `useSearchParams` approach, ensures consistency |

---

## 7. UI/UX Design Targets

Based on the Facebook Business Suite reference screenshots, the QP Suite will mirror:

1. **Home** — Page header (cover + avatar + name + followers), Create Post CTA, quick action row (Reel/Story/Advertise/Photo), To-do list, Recent posts
2. **Content** — Tab bar (Posts/Reels/Stories/Mentions), Published/Draft filter, Feed toggle, full-width post cards with media
3. **Inbox** — Messages/Comments tabs with count badges, platform filter pills (Messenger/Instagram/Unread), conversation list with avatars
4. **Insights** — Overview header with period stats, Views/Interactions/Follows card grid with sparkline charts, Top content gallery grid
5. **More** — 4x3 grid (Notifications, Ads, Planner, Appointments, Events, Payouts, Orders, Insights, Leads Centre, Settings, Billing, Help)
6. **Notifications** — Activity feed with avatar + action text + timestamp
7. **Profile Management** — Profile picture/cover photo editor, bio, details
8. **Create New** — Bottom sheet with Post/Reel/Photo/Story/Live options
9. **Messaging Insights** — Audience stats, responsiveness metrics, conversation counts
10. **Comments** — All comments list with filter by (Facebook/Instagram/Unread/Follow up/Done/Spam)

### Design System Color Tokens

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| Primary | `#1b74e4` | `#2d88ff` |
| Card Background | `#ffffff` | `#242526` |
| Text Primary | `#050505` | `#e4e6eb` |
| Text Secondary | `#65676b` | `#b0b3b8` |
| Hover/Tap | `#f0f0f0` | `#3a3b3c` |
| Divider | `#ced0d4` | `#3e4042` |
| Surface BG | `#f0f2f5` | `#18191a` |
| Success | `#31a24c` | `#31a24c` |
| Error | `#ff3b30` | `#ff3b30` |
| Warning | `#f7b928` | `#f7b928` |

### Status Badge Colors

| Status     | Background    | Text Color    |
|-----------|---------------|---------------|
| Active    | emerald-100   | emerald-700   |
| Paused    | amber-100     | amber-700     |
| Draft     | slate-100     | slate-600     |
| Completed | blue-100      | blue-700      |
| Archived  | gray-100      | gray-500      |
| Rejected  | red-100       | red-700       |

---

## 8. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter: { sdk: flutter }
  # State & Navigation
  provider: ^6.1.2
  go_router: ^14.2.1
  # Networking
  dio: ^5.6.0
  socket_io_client: ^3.0.2
  # Storage
  hive: ^2.2.3
  hive_flutter: ^2.2.3
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.5.4
  # Firebase
  firebase_core: ^4.4.0
  firebase_messaging: ^16.1.1
  # UI
  cached_network_image: ^3.4.1
  fl_chart: ^0.69.0
  shimmer: ^3.0.0
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10
  lottie: ^3.1.2
  # Media
  image_picker: ^1.1.2
  file_picker: ^8.1.7
  video_player: ^2.8.1
  chewie: ^1.7.1
  photo_view: ^0.15.0
  # Payments
  flutter_stripe: ^11.0.0
  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0
  url_launcher: ^6.3.0
  package_info_plus: ^8.0.0
  connectivity_plus: ^7.0.0
  permission_handler: ^11.3.1
  share_plus: ^9.0.0
  path_provider: ^2.1.3
  table_calendar: ^3.1.2

dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^4.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
  mockito: ^5.4.0
```

---

## 9. Scalability Considerations (Billion-User Ready)

| Concern | Solution |
|---------|----------|
| **API pagination** | All lists use cursor/page-based pagination, infinite scroll |
| **Image optimization** | cached_network_image with memory/disk LRU cache, thumbnail URLs |
| **Response caching** | Hive-backed HTTP response cache with TTL, stale-while-revalidate |
| **Offline mode** | Critical data (dashboard, content list) cached in Hive, sync on reconnect |
| **Memory management** | Lazy loading, dispose patterns in providers, AutomaticKeepAliveClientMixin |
| **Push notification scaling** | FCM topic subscriptions per page, silent push for data sync |
| **Code splitting** | Feature-first architecture allows lazy route loading |
| **Localization** | ARB-based i18n, RTL support foundation |
| **Accessibility** | Semantic labels, sufficient contrast ratios, screen reader support |
| **Analytics** | Firebase Analytics integration for user behavior tracking |

---

## 10. Summary Counts

| Metric | Count |
|--------|-------|
| **Total screens** | ~45 |
| **Feature modules** | 14 |
| **API endpoints consumed** | ~80+ |
| **Data models** | ~25 |
| **Providers** | ~20 |
| **Shared widgets** | ~15 |
| **Implementation phases** | 9 |

---

## Approval Status

- [x] Plan reviewed and approved — 2026-03-16
- [ ] Phase 1: Foundation & Core — In Progress
- [ ] Phase 2: Dashboard (Home)
- [ ] Phase 3: Content Management
- [ ] Phase 4: Inbox
- [ ] Phase 5: Insights
- [ ] Phase 6: More Menu & Supporting Features
- [ ] Phase 7: Ads Manager
- [ ] Phase 8: Billing & Payments
- [ ] Phase 9: Polish & Production
