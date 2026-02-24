class GuideModel {
  final String id;
  final String title;
  final String titleSinhala;
  final String content;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final List<String> tags;

  GuideModel({
    required this.id,
    required this.title,
    required this.titleSinhala,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
    required this.tags,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    return GuideModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleSinhala: json['title_sinhala'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_sinhala': titleSinhala,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
    };
  }
}
