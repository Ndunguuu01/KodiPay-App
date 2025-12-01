class MarketplaceAd {
  final int? id;
  final String title;
  final String? description;
  final String? contactInfo;
  final String? imageUrl;
  final String type; // 'image' or 'video'
  final int userId;
  final DateTime? createdAt;

  MarketplaceAd({
    this.id,
    required this.title,
    this.description,
    this.contactInfo,
    this.imageUrl,
    this.type = 'image',
    required this.userId,
    this.createdAt,
  });

  factory MarketplaceAd.fromJson(Map<String, dynamic> json) {
    return MarketplaceAd(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      contactInfo: json['contact_info'],
      imageUrl: json['image_url'],
      type: json['type'] ?? 'image',
      userId: json['user_id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'contact_info': contactInfo,
      'image_url': imageUrl,
      'type': type,
      'user_id': userId,
    };
  }
}
