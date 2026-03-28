import '../core/network/api_endpoints.dart';

class GuideImage {
  final String url;
  final String? caption;

  GuideImage({
    required this.url,
    this.caption,
  });

  factory GuideImage.fromJson(Map<String, dynamic> json) {
    return GuideImage(
      url: ApiEndpoints.getImageUrl(json['url'] as String?),
      caption: json['caption'] as String?,
    );
  }
}

class GuideStep {
  final int? stepNumber;
  final String? title;
  final String? description;
  final String? image;
  final List<String> tips;

  GuideStep({
    this.stepNumber,
    this.title,
    this.description,
    this.image,
    this.tips = const [],
  });

  factory GuideStep.fromJson(Map<String, dynamic> json) {
    return GuideStep(
      stepNumber: json['stepNumber'] as int?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class GuideMaterial {
  final String? name;
  final String? quantity;
  final bool optional;

  GuideMaterial({
    this.name,
    this.quantity,
    this.optional = false,
  });

  factory GuideMaterial.fromJson(Map<String, dynamic> json) {
    return GuideMaterial(
      name: json['name'] as String?,
      quantity: json['quantity'] as String?,
      optional: json['optional'] as bool? ?? false,
    );
  }
}

class GuideModel {
  final String id;

  // Titles
  final String title;
  final String? titleSinhala;
  final String? titleTamil;

  // Descriptions
  final String description; // EN
  final String? descriptionSinhala; // SI
  final String? descriptionTamil; // TA

  // Content
  final String content; // EN
  final String? contentSinhala; // SI
  final String? contentTamil; // TA

  final String category;
  final String? subcategory;
  final String? language; // 'en', 'si', 'ta'
  final String? difficulty; // beginner/intermediate/advanced
  final String? estimatedTimeValue;
  final String? estimatedTimeUnit; // minutes/hours/days/weeks

  final String coverImage;
  final List<GuideImage> images;

  final List<String> crops;
  final List<String> tags;
  final List<String> benefits;
  final List<String> warnings;

  final List<GuideStep> steps;
  final List<GuideMaterial> materials;

  final int views;
  final int likes;
  final bool isFeatured;
  final DateTime createdAt;

  GuideModel({
    required this.id,
    required this.title,
    this.titleSinhala,
    this.titleTamil,
    required this.description,
    this.descriptionSinhala,
    this.descriptionTamil,
    required this.content,
    this.contentSinhala,
    this.contentTamil,
    required this.category,
    this.subcategory,
    this.language,
    this.difficulty,
    this.estimatedTimeValue,
    this.estimatedTimeUnit,
    required this.coverImage,
    required this.images,
    required this.crops,
    required this.tags,
    required this.benefits,
    required this.warnings,
    required this.steps,
    required this.materials,
    required this.views,
    required this.likes,
    required this.isFeatured,
    required this.createdAt,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    final created = (json['createdAt'] ?? json['created_at'])?.toString();

    return GuideModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      titleSinhala: json['titleSinhala'] ?? json['title_sinhala'],
      titleTamil: json['titleTamil'],
      description: json['description'] ?? '',
      descriptionSinhala: json['descriptionSinhala'],
      descriptionTamil: json['descriptionTamil'],
      content: json['content'] ?? '',
      contentSinhala: json['contentSinhala'],
      contentTamil: json['contentTamil'],
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      language: json['language'] ?? 'en',
      difficulty: json['difficulty'],
      estimatedTimeValue: json['estimatedTime']?['value']?.toString(),
      estimatedTimeUnit: json['estimatedTime']?['unit']?.toString(),
      coverImage: ApiEndpoints.getImageUrl(
        json['coverImage'] as String?,
      ),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => GuideImage.fromJson(e))
              .toList() ??
          const [],
      crops: (json['crops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => GuideStep.fromJson(e))
              .toList() ??
          const [],
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => GuideMaterial.fromJson(e))
              .toList() ??
          const [],
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: created != null && created.isNotEmpty
          ? DateTime.tryParse(created) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
