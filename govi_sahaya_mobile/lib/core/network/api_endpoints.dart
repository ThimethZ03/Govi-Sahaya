class ApiEndpoints {
  // Base URL - CHANGE THIS TO YOUR COMPUTER'S IP
  static const String _baseUrl = 'http://192.168.8.127:5000';

  // Alternative URLs (commented out)
  // static const String _baseUrl = 'http://10.0.2.2:5000'; // Android Emulator only
  // static const String _baseUrl = 'http://localhost:5000'; // iOS Simulator only

  static const String apiVersion = '/api/v1';
  static const String baseApiUrl = '$_baseUrl$apiVersion';

  // ✅ Use this for all profile picture / image URLs
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$path';
  }

  // Health
  static const String health = '$_baseUrl/health';

  // Auth endpoints
  static const String login = '$baseApiUrl/auth/login';
  static const String register = '$baseApiUrl/auth/register';
  static const String logout = '$baseApiUrl/auth/logout';
  static const String forgotPassword = '$baseApiUrl/auth/forgot-password';
  static const String resetPassword = '$baseApiUrl/auth/reset-password';
  static const String refreshToken = '$baseApiUrl/auth/refresh-token';
  static const String firebaseSync = '$baseApiUrl/auth/firebase-sync';

  // User endpoints
  static const String userProfile = '$baseApiUrl/users/profile';
  static const String updateProfile = '$baseApiUrl/users/profile';
  static const String uploadProfilePicture =
      '$baseApiUrl/users/profile-picture';

  // Crop Doctor / Disease Detection
  static const String detectDisease = '$baseApiUrl/ml/detect-disease';
  static const String detectionHistory = '$baseApiUrl/crop-doctor/history';

  // Crops & Diseases
  static const String crops = '$baseApiUrl/crops';
  static const String diseases = '$baseApiUrl/ml/diseases';

  // Weather
  static const String weatherCurrent = '$baseApiUrl/weather/current';
  static const String weatherForecast = '$baseApiUrl/weather/forecast';

  // News
  static const String news = '$baseApiUrl/news/latest';
  static const String newsSearch = '$baseApiUrl/news/search';

  // Forum
  static const String forumPosts = '$baseApiUrl/forum/posts';
  static const String createPost = '$baseApiUrl/forum/posts';
  static String postDetail(String id) => '$baseApiUrl/forum/posts/$id';
  static String postComments(String id) =>
      '$baseApiUrl/forum/posts/$id/comments';
  static String likePost(String id) => '$baseApiUrl/forum/posts/$id/like';

  // Knowledge Hub
  static const String knowledgeArticles = '$baseApiUrl/knowledge-hub/articles';
  static String articleDetail(String id) =>
      '$baseApiUrl/knowledge-hub/articles/$id';

  // Profit Planner
  static const String profitExpenses = '$baseApiUrl/profit-planner/expenses';
  static const String profitFields = '$baseApiUrl/profit-planner/fields';
  static const String profitReports = '$baseApiUrl/profit-planner/reports';

  // Shop
  static const String shopItems = '$baseApiUrl/shop/items';
  static String shopItemDetail(String id) => '$baseApiUrl/shop/items/$id';
  static const String cart = '$baseApiUrl/shop/cart';
  static const String orders = '$baseApiUrl/shop/orders';

  // Safety
  static const String safetyGuidelines = '$baseApiUrl/safety/guidelines';
  static const String firstAid = '$baseApiUrl/safety/first-aid';

  // Notifications
  static const String notifications = '$baseApiUrl/notifications';

  // ML Service
  static const String mlHealth = '$baseApiUrl/ml/health';
  static const String mlModelInfo = '$baseApiUrl/ml/model-info';
  static const String mlTest = '$baseApiUrl/ml/test';
}

class AppConstants {
  // App Info
  static const String appName = 'Govi Sahaya';
  static const String appNameSinhala = 'ගොවි සහාය';
  static const String appSlogan = 'නැණවත් ගොවිතැනක් - සරුසාර හෙට දිනක්';
  static const String appVersion = '1.0.0';

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
