// ignore_for_file: public_member_api_docs

// ------------------------------------------------------------
// NEWS MODEL
// ------------------------------------------------------------
// This is the main model class that represents a single
// news article in the application.
// It contains all information related to the news item
// including title, content, images, author, statistics, etc.
class NewsModel {

  // Unique identifier for the news article (usually MongoDB _id)
  final String id;

  // Title or headline of the news article
  final String title;

  // URL-friendly version of the title used for routing
  final String slug;

  // Short description or summary of the article
  final String description;

  // Full content/body of the news article
  final String content;

  // Category of the news (e.g., technology, weather, market_prices)
  final String category;

  // List of tags used for searching or filtering
  final List<String> tags;

  // Author information of the news article
  final Author? author;

  // Main cover image displayed on news cards
  final CoverImage? coverImage;

  // Additional images related to the article
  final List<NewsImage> images;

  // Optional external website source URL
  final String? sourceUrl;

  // Date and time when the article was published
  final DateTime publishedDate;

  // Location related to the news article
  final Location? location;

  // Language of the article (en, si, ta)
  final String language;

  // Total number of views for this article
  final int views;

  // Number of likes received
  final int likes;

  // Number of shares
  final int shares;

  // Indicates if the article is featured/highlighted
  final bool isFeatured;

  // Indicates whether the article is published or hidden
  final bool isPublished;

  // Information about external API source
  final ExternalSource? externalSource;

  // Date when the record was created
  final DateTime createdAt;

  // Date when the article was last updated
  final DateTime updatedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    required this.category,
    required this.tags,
    this.author,
    this.coverImage,
    required this.images,
    this.sourceUrl,
    required this.publishedDate,
    this.location,
    required this.language,
    required this.views,
    required this.likes,
    required this.shares,
    required this.isFeatured,
    required this.isPublished,
    this.externalSource,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      coverImage: json['coverImage'] != null
          ? CoverImage.fromJson(json['coverImage'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((img) => NewsImage.fromJson(img))
              .toList()
          : [],
      sourceUrl: json['sourceUrl'],
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : DateTime.now(),
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      language: json['language'] ?? 'en',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isPublished: json['isPublished'] ?? true,
      externalSource: json['externalSource'] != null
          ? ExternalSource.fromJson(json['externalSource'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'category': category,
      'tags': tags,
      'author': author?.toJson(),
      'coverImage': coverImage?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'sourceUrl': sourceUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'location': location?.toJson(),
      'language': language,
      'views': views,
      'likes': likes,
      'shares': shares,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'externalSource': externalSource?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getCategoryLabel() {
    switch (category) {
      case 'market_prices':
        return 'Market Prices';
      case 'government_policy':
        return 'Government Policy';
      case 'technology':
        return 'Technology';
      case 'weather':
        return 'Weather & Alerts';
      case 'success_stories':
        return 'Success Stories';
      case 'events':
        return 'Events';
      default:
        return 'General';
    }
  }
}

class Author {
  final String? name;
  final String? source;

  Author({this.name, this.source});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
    };
  }
}

class CoverImage {
  final String url;
  final String? alt;

  CoverImage({required this.url, this.alt});

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      url: json['url'] ?? '',
      alt: json['alt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'alt': alt,
    };
  }
}

class NewsImage {
  final String url;
  final String? caption;

  NewsImage({required this.url, this.caption});

  factory NewsImage.fromJson(Map<String, dynamic> json) {
    return NewsImage(
      url: json['url'] ?? '',
      caption: json['caption'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'caption': caption,
    };
  }
}

class Location {
  final String? district;
  final String country;

  Location({this.district, required this.country});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      district: json['district'],
      country: json['country'] ?? 'Sri Lanka',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'country': country,
    };
  }
}

class ExternalSource {
  final String name;
  final String? apiId;
  final DateTime? fetchedAt;

  ExternalSource({required this.name, this.apiId, this.fetchedAt});

  factory ExternalSource.fromJson(Map<String, dynamic> json) {
    return ExternalSource(
      name: json['name'] ?? '',
      apiId: json['apiId'],
      fetchedAt:
          json['fetchedAt'] != null ? DateTime.parse(json['fetchedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'apiId': apiId,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }
}
