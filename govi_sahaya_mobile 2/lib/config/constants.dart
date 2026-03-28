import '../core/network/api_endpoints.dart';

class AppConstants {
  // App Info
  static const String appName = 'Govi Sahaya';
  static const String appNameSinhala = 'ගොවි සහාය';
  static const String appSlogan = 'නැණවත් ගොවිතැනක් - සරුසාර හෙට දිනක්';
  static const String appVersion = '1.0.0';

  // ✅ Single source of truth — delegates to ApiEndpoints
  static String get baseUrl => ApiEndpoints.baseUrl;
  static String get baseApiUrl => ApiEndpoints.baseApiUrl;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String messagesCollection = 'messages';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserData = 'user_data';
  static const String keyAuthToken = 'auth_token';
  static const String keyLanguage = 'language';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;

  // Pagination
  static const int itemsPerPage = 10;

  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Categories
  static const List<String> cropCategories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Herbs',
    'Flowers',
  ];

  static const List<String> libraryCategories = [
    'Vegetables',
    'Fruits',
    'Soil',
    'Pest',
    'Organic',
  ];

  static const List<String> expenseCategories = [
    'Fertilizer',
    'Water',
    'Rental',
    'Seeds',
    'Labor',
    'Equipment',
    'Other',
  ];
}
