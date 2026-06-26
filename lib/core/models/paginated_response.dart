class PaginationMeta {
  final int page;
  final int limit;
  final bool hasMore;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({
    required this.data,
    required this.meta,
  });
}
