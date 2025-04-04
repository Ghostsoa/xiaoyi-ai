class OnlineRoleCard {
  final int id;
  final String code;
  final int userId;
  final String authorName;
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final String rawDataUrl;
  final String coverUrl;
  final int status;
  final int downloads;
  final DateTime createdAt;
  final DateTime updatedAt;

  OnlineRoleCard({
    required this.id,
    required this.code,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    required this.rawDataUrl,
    required this.coverUrl,
    required this.status,
    required this.downloads,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnlineRoleCard.fromJson(Map<String, dynamic> json) {
    return OnlineRoleCard(
      id: json['id'] as int,
      code: json['code'] as String,
      userId: json['user_id'] as int,
      authorName: json['author_name'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tags: (json['tags'] as String).split(','),
      category: json['category'] as String,
      rawDataUrl: json['raw_data_url'] as String,
      coverUrl: json['cover_url'] as String,
      status: json['status'] as int,
      downloads: json['downloads'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
