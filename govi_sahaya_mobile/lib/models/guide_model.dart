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
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      titleSinhala: json['titleSinhala'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['coverImage'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'titleSinhala': titleSinhala,
      'content': content,
      'category': category,
      'coverImage': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }
}
