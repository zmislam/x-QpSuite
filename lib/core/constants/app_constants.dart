class AppConstants {
  static const String appName = 'QP Suite';
  static const String appTagline = 'Manage your business, all in one place';
  static const String deepLinkScheme = 'qpsuite';
  static const String deepLinkHost = 'suite.qp.com';

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int defaultInsightsDays = 30;

  // Dashboard period options
  static const List<int> dashboardPeriods = [7, 14, 30, 0]; // 0 = all-time

  // Content types
  static const List<String> contentTypes = ['Post', 'Reel', 'Story'];

  // File upload limits
  static const int maxUploadSizeMB = 100;
  static const int maxMediaFiles = 10;
  static const List<String> allowedImageTypes = [
    'jpeg', 'jpg', 'png', 'gif', 'webp',
  ];
  static const List<String> allowedVideoTypes = [
    'mp4', 'mov', 'avi', 'webm',
  ];
}
