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

  // Constructor used to create a NewsModel object.
// It initializes all the properties of a news article when a new instance is created.
// "required" means those values must be provided when creating the object.





const NewsModel({

  // Unique identifier of the news article (usually comes from database _id)
  required this.id,

  // Title or headline of the news article
  required this.title,

  // URL-friendly version of the title used for routing or SEO
  required this.slug,

  // Short summary or preview of the news article
  required this.description,

  // Full detailed content/body text of the news article
  required this.content,

  // Category the news belongs to (example: technology, weather, market_prices)
  required this.category,

  // List of tags related to the news article for searching/filtering
  required this.tags,

  // Author information (optional because some articles may not include author details)
  this.author,

  // Main cover image displayed for the news article
  this.coverImage,

  // List of additional images related to the news article
  required this.images,

  // Optional external source link if the article comes from another website
  this.sourceUrl,

  // Date and time when the news article was published
  required this.publishedDate,

  // Location information related to the news (district / country)
  this.location,

  // Language code of the article (for example: "en", "si", "ta")
  required this.language,

  // Total number of views the article has received
  required this.views,

  // Number of likes given by users
  required this.likes,

  // Number of times the article has been shared
  required this.shares,

  // Indicates whether the news article is marked as featured
  required this.isFeatured,

  // Indicates whether the article is published or still in draft
  required this.isPublished,

  // Information about the external API source if the article was fetched automatically
  this.externalSource,

  // Date and time when this record was created in the system/database
  required this.createdAt,

  // Date and time when the article was last updated
  required this.updatedAt,
});



/// Factory constructor to create a [NewsModel] object from a JSON map.
/// This is typically used when fetching news data from an API or database.
factory NewsModel.fromJson(Map<String, dynamic> json) {
  return NewsModel(

    // Unique ID of the news article from the database. Defaults to empty string if missing.
    id: json['_id'] as String? ?? '',

    // Headline or title of the news. Defaults to empty string if missing.
    title: json['title'] as String? ?? '',

    // URL-friendly version of the title (slug). Defaults to empty string if missing.
    slug: json['slug'] as String? ?? '',

    // Short summary or description of the news article. Defaults to empty string if missing.
    description: json['description'] as String? ?? '',

    // Full content of the news article. Defaults to empty string if missing.
    content: json['content'] as String? ?? '',

    // Category of the news (e.g., technology, weather). Defaults to 'general' if missing.
    category: json['category'] as String? ?? 'general',

    // List of tags associated with the article. Converts JSON list to List<String>. Defaults to empty list if missing.
    tags: json['tags'] != null
        ? List<String>.from(json['tags'] as List)
        : const <String>[],

    // Nested Author object. Converts JSON map to Author. Null if no author data.
    author: json['author'] != null 
        ? Author.fromJson(json['author'] as Map<String, dynamic>) 
        : null,

    // Main cover image of the news. Converts JSON map to CoverImage. Null if missing.
    coverImage: json['coverImage'] != null
        ? CoverImage.fromJson(json['coverImage'] as Map<String, dynamic>)
        : null,

    // List of additional images for the article. Converts JSON list to List<NewsImage>. Defaults to empty list if missing.
    images: json['images'] != null
        ? (json['images'] as List)
            .map((img) => NewsImage.fromJson(img as Map<String, dynamic>))
            .toList()
        : const <NewsImage>[],

    // Optional external source URL of the news. Null if missing.
    sourceUrl: json['sourceUrl'] as String?,

    // Published date of the article. Converts string to DateTime. Defaults to current time if missing.
    publishedDate: json['publishedDate'] != null
        ? DateTime.parse(json['publishedDate'] as String)
        : DateTime.now(),

    // Location information of the news. Converts JSON map to Location object. Null if missing.
    location: json['location'] != null
        ? Location.fromJson(json['location'] as Map<String, dynamic>)
        : null,

    // Language code of the article (e.g., 'en', 'si'). Defaults to 'en' if missing.
    language: json['language'] as String? ?? 'en',

    // Total number of views. Converts JSON number to int. Defaults to 0 if missing.
    views: (json['views'] as num?)?.toInt() ?? 0,

    // Total number of likes. Converts JSON number to int. Defaults to 0 if missing.
    likes: (json['likes'] as num?)?.toInt() ?? 0,

    // Total number of shares. Converts JSON number to int. Defaults to 0 if missing.
    shares: (json['shares'] as num?)?.toInt() ?? 0,

    // Whether the article is featured. Defaults to false if missing.
    isFeatured: json['isFeatured'] as bool? ?? false,

    // Whether the article is published. Defaults to true if missing.
    isPublished: json['isPublished'] as bool? ?? true,

    // Information about the external API source. Converts JSON map to ExternalSource object. Null if missing.
    externalSource: json['externalSource'] != null
        ? ExternalSource.fromJson(json['externalSource'] as Map<String, dynamic>)
        : null,

    // Record creation date. Converts string to DateTime. Defaults to current time if missing.
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),

    // Last updated date. Converts string to DateTime. Defaults to current time if missing.
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );
}

  

  /// Converts the [NewsModel] object into a JSON-compatible map.
/// 
/// This is typically used when sending data to an API or saving it in a database.
/// Nested objects and lists are also converted to JSON using their respective `toJson()` methods.
Map<String, dynamic> toJson() {
  return {

    // Unique ID of the news article
    '_id': id,

    // Headline/title of the article
    'title': title,

    // URL-friendly version of the title (slug)
    'slug': slug,

    // Short description of the article
    'description': description,

    // Full content/body of the article
    'content': content,

    // Category of the news (e.g., technology, weather, market_prices)
    'category': category,

    // List of tags associated with the news
    'tags': tags,

    // Nested author object converted to JSON. Null if author is not set
    'author': author?.toJson(),

    // Main cover image object converted to JSON. Null if not set
    'coverImage': coverImage?.toJson(),

    // List of additional images, each converted to JSON
    'images': images.map((img) => img.toJson()).toList(),

    // Optional external URL source of the news
    'sourceUrl': sourceUrl,

    // Published date converted to ISO 8601 string for standardization
    'publishedDate': publishedDate.toIso8601String(),

    // Location object converted to JSON. Null if not set
    'location': location?.toJson(),

    // Language code of the article (e.g., 'en', 'si', 'ta')
    'language': language,

    // Total views count
    'views': views,

    // Total likes count
    'likes': likes,

    // Total shares count
    'shares': shares,

    // Whether the article is marked as featured
    'isFeatured': isFeatured,

    // Whether the article is published
    'isPublished': isPublished,

    // External source information converted to JSON. Null if not set
    'externalSource': externalSource?.toJson(),

    // Record creation date converted to ISO 8601 string
    'createdAt': createdAt.toIso8601String(),

    // Last updated date converted to ISO 8601 string
    'updatedAt': updatedAt.toIso8601String(),
  };
}


  /// Returns a human-readable label for the article's category.
/// 
/// The category field in the database is usually a machine-friendly string
/// like 'market_prices' or 'technology'. This method converts it to a
/// user-friendly label suitable for display in the UI.
String getCategoryLabel() {
  switch (category) {
    case 'market_prices':
      return 'Market Prices'; // Friendly label for market prices news

    case 'government_policy':
      return 'Government Policy'; // Friendly label for government policy news

    case 'technology':
      return 'Technology'; // Friendly label for technology news

    case 'weather':
      return 'Weather & Alerts'; // Friendly label for weather-related news

    case 'success_stories':
      return 'Success Stories'; // Friendly label for success stories

    case 'events':
      return 'Events'; // Friendly label for events news

    default:
      return 'General'; // Default label for any other category
  }
}
@override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NewsModel(id: $id, title: $title, category: $category, published: $publishedDate)';
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
