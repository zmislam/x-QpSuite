class ApiConstants {
  /// Override at build time: --dart-define=API_BASE_URL=https://api.example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://217.73.238.134:9006/api',
  );

  /// Server origin (e.g. http://192.168.0.102:9000)
  static String get serverOrigin => baseUrl.replaceAll('/api', '');

  /// Normalize backend URLs to use the current server origin.
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;
    final origin = serverOrigin;
    return url
        .replaceFirst(RegExp(r'https?://localhost:\d+'), origin)
        .replaceFirst(RegExp(r'https?://127\.0\.0\.1:\d+'), origin);
  }

  /// Build a full media URL from a relative path.
  /// If the path already starts with http, normalize it.
  /// Otherwise, prepend the server origin + /uploads/.
  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return normalizeUrl(path);
    // If already includes /uploads/, just prepend origin
    if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$serverOrigin$cleanPath';
    }
    // Default: treat as user profile upload
    return '$serverOrigin/uploads/$path';
  }

  /// Page profile picture URL (uploads/pages/)
  static String pageProfileUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/pages/$filename';
  }

  /// Page cover picture URL (uploads/pages/)
  static String pageCoverUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/pages/$filename';
  }

  /// Post media URL (uploads/posts/)
  static String postMediaUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/posts/$filename';
  }

  /// Video thumbnail URL (uploads/posts/thumbnails/)
  static String videoThumbnailUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/posts/thumbnails/$filename';
  }

  /// User profile picture URL (uploads/)
  static String userProfileUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/$filename';
  }

  /// Reel media URL (uploads/reels/)
  static String reelMediaUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/reels/$filename';
  }

  /// Reel thumbnail URL (uploads/reels/thumbnails/)
  static String reelThumbnailUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/reels/thumbnails/$filename';
  }

  /// Story media URL (uploads/story/)
  static String storyMediaUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/story/$filename';
  }

  /// Page post media URL (uploads/pages/posts/)
  static String pagePostMediaUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/pages/posts/$filename';
  }

  /// Returns the best displayable URL for a content media item.
  /// For videos, prefers thumbnail. Uses mediaBaseDir to determine path.
  static String contentMediaDisplayUrl({
    required String url,
    String? thumbnailUrl,
    String type = 'image',
    String? mediaBaseDir,
  }) {
    final isVideo = type == 'video' ||
        const ['mp4', 'mov', 'avi', 'mkv', 'webm']
            .any((ext) => url.toLowerCase().endsWith('.$ext'));
    // For videos, prefer thumbnail if available
    if (isVideo && thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      if (mediaBaseDir == 'reels') return reelThumbnailUrl(thumbnailUrl);
      return videoThumbnailUrl(thumbnailUrl);
    }
    // For images or video without thumbnail, use media URL
    if (mediaBaseDir == 'reels') return reelMediaUrl(url);
    if (mediaBaseDir == 'story') return storyMediaUrl(url);
    return postMediaUrl(url);
  }

  /// Group profile URL (uploads/group/)
  static String groupProfileUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return normalizeUrl(filename);
    return '$serverOrigin/uploads/group/$filename';
  }

  // ── Auth ──────────────────────────────────────────
  static const String login = '/login';
  static const String signup = '/signup';
  static const String userProfile = '/user-profile';

  // ── Business Suite ────────────────────────────────
  static const String managedPages = '/business-suite/managed-pages';
  static String dashboard(String pageId) => '/business-suite/$pageId/dashboard';
  static String content(String pageId) => '/business-suite/$pageId/content';
  static String contentUploadMedia(String pageId) =>
      '/business-suite/$pageId/content/upload-media';
  static String contentSchedule(String pageId) =>
      '/business-suite/$pageId/content/schedule';
  static String contentScheduleById(String pageId, String scheduleId) =>
      '/business-suite/$pageId/content/schedule/$scheduleId';
  static String contentCalendar(String pageId) =>
      '/business-suite/$pageId/content/calendar';
  static String scheduledPosts(String pageId) =>
      '/business-suite/$pageId/scheduled-posts';
  static String scheduledPostById(String pageId, String id) =>
      '/business-suite/$pageId/scheduled-posts/$id';
  static String scheduledPostPublishNow(String pageId, String id) =>
      '/business-suite/$pageId/scheduled-posts/$id/publish-now';
  static String publishedPostUploadMedia(String pageId) =>
      '/business-suite/$pageId/published-posts/upload-media';
  static String publishedPostById(String pageId, String postId) =>
      '/business-suite/$pageId/published-posts/$postId';
  static String boostedPosts(String pageId) =>
      '/business-suite/$pageId/boosted-posts';
  static String boostedPostById(String pageId, String campaignId) =>
      '/business-suite/$pageId/boosted-posts/$campaignId';
  static String notifications(String pageId) =>
      '/business-suite/$pageId/notifications';
  static String notificationsReadAll(String pageId) =>
      '/business-suite/$pageId/notifications/read-all';
  static String todos(String pageId) => '/business-suite/$pageId/todos';
  static String todoById(String pageId, String todoId) =>
      '/business-suite/$pageId/todos/$todoId';
  static String insights(String pageId) =>
      '/business-suite/$pageId/insights';
  static String insightsAudience(String pageId) =>
      '/business-suite/$pageId/insights/audience';
  static String insightsContent(String pageId) =>
      '/business-suite/$pageId/insights/content';
  static String postInsights(String pageId, String postId) =>
      '/business-suite/$pageId/content/$postId/insights';
  static String inbox(String pageId) => '/business-suite/$pageId/inbox';
  static String inboxThread(String pageId, String threadId) =>
      '/business-suite/$pageId/inbox/$threadId';
  static String inboxThreadReply(String pageId, String threadId) =>
      '/business-suite/$pageId/inbox/$threadId/reply';
  static String inboxThreadRead(String pageId, String threadId) =>
      '/business-suite/$pageId/inbox/$threadId/read';
  static String publishStoryNow(String pageId) =>
      '/business-suite/$pageId/story/publish-now';
  static String onboarding(String pageId) =>
      '/business-suite/$pageId/onboarding';

  // ── Ads Manager (Campaigns V2) ───────────────────
  static const String canAdvertise = '/campaigns-v2/billing/can-advertise';
  static const String campaigns = '/campaigns-v2/campaigns';
  static String campaignById(String id) => '/campaigns-v2/campaigns/$id';
  static String campaignFull(String id) => '/campaigns-v2/campaigns/$id/full';
  static const String adSets = '/campaigns-v2/ad-sets';
  static String adSetById(String id) => '/campaigns-v2/ad-sets/$id';
  static const String ads = '/campaigns-v2/ads';
  static String adById(String id) => '/campaigns-v2/ads/$id';
  static const String adsUploadMedia = '/campaigns-v2/ads/upload-media';
  static const String boost = '/campaigns-v2/boost';
  static const String promotePage = '/campaigns-v2/promote-page';
  static String pageCampaigns(String pageId) =>
      '/campaigns-v2/page-campaigns/$pageId';
  static const String tableData = '/campaigns-v2/table-data';
  static const String deliveryStatus = '/campaigns-v2/delivery-status';
  static String analytics(String campaignId) =>
      '/campaigns-v2/analytics/$campaignId';
  static String adAnalytics(String adId) =>
      '/campaigns-v2/analytics/ad/$adId';
  static String campaignDemographics(String campaignId) =>
      '/campaigns-v2/analytics/$campaignId/demographics';
  static const String beacon = '/campaigns-v2/beacon';
  static const String beaconBatch = '/campaigns-v2/beacon/batch';

  // ── Billing ───────────────────────────────────────
  static const String billingAccount = '/campaigns-v2/billing/account';
  static const String billingStatus = '/campaigns-v2/billing/status';
  static const String costBreakdown = '/campaigns-v2/billing/cost-breakdown';
  static const String billingHistory = '/campaigns-v2/billing/history';
  static const String billingCycles = '/campaigns-v2/billing/my-cycles';
  static String billingCycleById(String id) =>
      '/campaigns-v2/billing/my-cycles/$id';
  static const String setupIntent = '/campaigns-v2/billing/setup-intent';
  static const String confirmCard = '/campaigns-v2/billing/confirm-card';
  static const String paymentMethod = '/campaigns-v2/billing/payment-method';

  // ── Audiences ─────────────────────────────────────
  static const String savedAudiences = '/campaigns-v2/audiences/saved';
  static const String customAudiences = '/campaigns-v2/audiences/custom';
  static const String allAudiences = '/campaigns-v2/audiences/all';

  // ── Leads ─────────────────────────────────────────
  static const String leadForms = '/campaigns-v2/leads/forms';
  static String leadSubmissions(String formId) =>
      '/campaigns-v2/leads/submissions/$formId';
  static String leadExport(String formId) =>
      '/campaigns-v2/leads/export/$formId';

  // ── Reports ───────────────────────────────────────
  static const String reportsSummary = '/campaigns-v2/reports/summary';
  static const String reportsExport = '/campaigns-v2/reports/export';

  // ── Onboarding (Advertiser) ───────────────────────
  static const String onboardingProfile = '/campaigns-v2/onboarding/profile';
  static const String onboardingComplete = '/campaigns-v2/onboarding/complete';
  static const String onboardingVerify = '/campaigns-v2/onboarding/verify';
  static const String onboardingBusinessTypes =
      '/campaigns-v2/onboarding/business-types';
  static const String onboardingVerificationStatus =
      '/campaigns-v2/onboarding/verification-status';

  // ── Bulk Actions ──────────────────────────────────
  static const String bulkAction = '/campaigns-v2/bulk-action';
  static String duplicate(String id) => '/campaigns-v2/duplicate/$id';

  // ── Posts (Social API) ────────────────────────────
  static String allPosts({int pageNo = 1, int pageSize = 10}) =>
      '/get-all-users-posts-v2?pageNo=$pageNo&pageSize=$pageSize';
  static const String individualPosts =
      '/get-all-users-posts-individual-for-app';
  static const String pagePosts = '/get-pages-posts';
  static const String savePagePost = '/save-page-post';
  static const String reactOnPost = '/save-reaction-main-post';
  static String getComments(String postId) =>
      '/get-all-comments-direct-post/$postId';
  static const String sendComment = '/save-user-comment-by-post';
  static const String replyComment = '/reply-comment-by-direct-post';
  static const String reactOnComment =
      '/save-comment-reaction-of-direct-post';
  static String reactionUserList(String postId) =>
      '/reaction-user-lists-of-direct-post/$postId';
  static const String deleteComment = '/delete-single-comment';
  static const String savePost = '/save-post';
  static const String hidePost = '/hide-unhide-post';
  static const String bookmarkPost = '/save-post-bookmark';
  static String removeBookmark(String bookmarkId) =>
      '/remove-post-bookmark/$bookmarkId';
}
