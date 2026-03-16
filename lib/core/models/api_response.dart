class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? total;
  final int? page;
  final int? limit;
  final int? unreadCount;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.total,
    this.page,
    this.limit,
    this.unreadCount,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromData,
  }) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      total: json['total'] as int?,
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      unreadCount: json['unread_count'] as int?,
    );
  }
}
