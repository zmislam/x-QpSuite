class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
  }) : totalPages = (total / limit).ceil();

  bool get hasMore => page < totalPages;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  Pagination copyWith({int? page}) {
    return Pagination(
      page: page ?? this.page,
      limit: limit,
      total: total,
    );
  }
}
