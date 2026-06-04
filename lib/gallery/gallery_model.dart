class GalleryImage {
  final String id;
  final String uploadedBy;
  final String createdAt;
  final String url;

  GalleryImage({
    required this.id,
    required this.uploadedBy,
    required this.createdAt,
    required this.url,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class GalleryResponse {
  final List<GalleryImage> images;
  final bool hasMore;

  GalleryResponse({
    required this.images,
    required this.hasMore,
  });

  factory GalleryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['images'] as List? ?? [];
    return GalleryResponse(
      images: list.map((e) => GalleryImage.fromJson(e)).toList(),
      hasMore: json['hasMore'] ?? false,
    );
  }
}
