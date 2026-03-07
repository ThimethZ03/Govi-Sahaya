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
          ? ExternalSource.fromJson(
              json['externalSource'] as Map<String, dynamic>)
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
        return 'Market Prices'; // Display label for market prices
      case 'government_policy':
        return 'Government Policy'; // Display label for government policy
      case 'technology':
        return 'Technology'; // Display label for technology news
      case 'weather':
        return 'Weather & Alerts'; // Display label for weather updates
      case 'success_stories':
        return 'Success Stories'; // Display label for success stories
      case 'events':
        return 'Events'; // Display label for events
      default:
        return 'General'; // Default label for unknown categories
    }
  }

  /// Overrides the equality operator to compare two NewsModel objects.
  ///
  /// Two articles are considered equal if their `id` fields are identical.
  /// `identical(this, other)` quickly returns true if both references point to the same object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsModel && other.id == id;
  }

  /// Overrides hashCode to be consistent with the equality operator.
  ///
  /// Since equality is based on `id`, the hash code is derived from `id` as well.
  /// Ensures correct behavior when using NewsModel objects in Sets or Maps.
  @override
  int get hashCode => id.hashCode;

  /// Provides a readable string representation of the NewsModel object.
  ///
  /// Useful for debugging or logging, showing key details of the article:
  /// id, title, category, and published date.
  @override
  String toString() =>
      'NewsModel(id: $id, title: $title, category: $category, published: $publishedDate)';
}

// ------------------------------------------------------------
// AUTHOR MODEL
// ------------------------------------------------------------
// This class represents the author information of a news article.
// It stores details such as the author's name and the source
// from which the news article originated.

class Author {
  // Name of the author who wrote or published the article
  final String? name;

  // Source or organization the author belongs to (e.g., BBC, Reuters)
  final String? source;

  // Constant constructor used to create an Author object.
  // Both fields are optional because some articles may not include author details.
  const Author({this.name, this.source});

  /// Factory constructor used to create an Author object from JSON data.
  /// This is commonly used when receiving author data from an API.
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      // Extracts the author name from JSON
      name: json['name'] as String?,

      // Extracts the source or organization from JSON
      source: json['source'] as String?,
    );
  }

  /// Converts the Author object into a JSON map.
  /// This is useful when sending data to APIs or storing in a database.
  Map<String, dynamic> toJson() => {
        'name': name, // Author name
        'source': source, // Author source/organization
      };

  /// Provides a readable string representation of the Author object.
  /// Useful for debugging or logging.
  @override
  String toString() => 'Author(name: $name, source: $source)';
}

// Model class representing a cover image
class CoverImage {
  // Image URL
  final String url;

  // Optional alternative text for the image
  final String? alt;

  // Constructor to create a CoverImage object
  const CoverImage({required this.url, this.alt});

  // Create CoverImage object from JSON data
  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      url: json['url'] as String? ?? '',
      alt: json['alt'] as String?,
    );
  }

  // Convert CoverImage object to JSON format
  Map<String, dynamic> toJson() => {'url': url, 'alt': alt};

  // Check if the URL is a valid http/https link
  bool get isValidUrl =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));

  // Return a readable string for debugging
  @override
  String toString() => 'CoverImage(url: $url)';
}



// Model class representing an image used in a news article
class NewsImage {

  // URL of the image
  final String url;

  // Optional caption describing the image
  final String? caption;

  // Constructor to create a NewsImage object
  const NewsImage({required this.url, this.caption});

  // Create a NewsImage object from JSON data
  factory NewsImage.fromJson(Map<String, dynamic> json) {
    return NewsImage(
      url: json['url'] as String? ?? '',
      caption: json['caption'] as String?,
    );
  }

  // Convert NewsImage object to JSON format
  Map<String, dynamic> toJson() => {'url': url, 'caption': caption};

  // Return readable string for debugging
  @override
  String toString() => 'NewsImage(url: $url, caption: $caption)';
}


// Model class representing a location
class Location {

  // District name (optional)
  final String? district;

  // Country name
  final String country;

  // Constructor to create a Location object
  const Location({this.district, required this.country});

  // Create a Location object from JSON data
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      district: json['district'] as String?,
      country: json['country'] as String? ?? 'Sri Lanka',
    );
  }

  // Convert Location object to JSON format
  Map<String, dynamic> toJson() => {'district': district, 'country': country};

  // Return readable string for debugging
  @override
  String toString() => 'Location(district: $district, country: $country)';
}




class ExternalSource {
  final String name;
  final String? apiId;
  final DateTime? fetchedAt;

  const ExternalSource({required this.name, this.apiId, this.fetchedAt});

  factory ExternalSource.fromJson(Map<String, dynamic> json) {
    return ExternalSource(
      name: json['name'] as String? ?? '',
      apiId: json['apiId'] as String?,
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'apiId': apiId,
        'fetchedAt': fetchedAt?.toIso8601String(),
      };

  @override
  String toString() =>
      'ExternalSource(name: $name, apiId: $apiId, fetchedAt: $fetchedAt)';
}

