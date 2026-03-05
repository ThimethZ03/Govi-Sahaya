// lib/core/network/api_endpoints.dart

class ApiEndpoints {
  // ── Single source of truth ─────────────────────────────────────
  static const String _activeUrl = _localUrl;

  // 🔴 LOCAL DEVELOPMENT
  static const String _localUrl = 'http://192.168.8.127:5000';

  // ── Other dev options (keep commented) ────────────────────────
  // static const String _activeUrl = 'http://10.0.2.2:5000';  // Android Emulator
  // static const String _activeUrl = 'http://localhost:5000';  // iOS Simulator
  // static const String _productionUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';
  // static const String _productionUrl = 'https://api.govishahaya.lk';

  // ── Exposed base URLs ──────────────────────────────────────────
  static const String baseUrl = _activeUrl;
  static const String apiVersion = '/api/v1';
  static const String baseApiUrl = '$_activeUrl$apiVersion';

  // ✅ Resolves image URLs — Cloudinary URLs returned as-is
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // ── Health ─────────────────────────────────────────────────────
  static const String health = '$baseUrl/health';

  // ── Auth ───────────────────────────────────────────────────────
  static const String login = '$baseApiUrl/auth/login';
  static const String register = '$baseApiUrl/auth/register';
  static const String logout = '$baseApiUrl/auth/logout';
  static const String forgotPassword = '$baseApiUrl/auth/forgot-password';
  static const String resetPassword = '$baseApiUrl/auth/reset-password';
  static const String refreshToken = '$baseApiUrl/auth/refresh-token';
  static const String firebaseSync = '$baseApiUrl/auth/firebase-sync';

  // ── Users ──────────────────────────────────────────────────────
  static const String userProfile = '$baseApiUrl/users/profile';
  static const String updateProfile = '$baseApiUrl/users/profile';
  static const String uploadProfilePicture =
      '$baseApiUrl/users/profile-picture';

  // ── Crop Doctor / ML ───────────────────────────────────────────
  static const String detectDisease = '$baseApiUrl/ml/detect-disease';
  static const String detectionHistory = '$baseApiUrl/ml/history';
  static const String diseases = '$baseApiUrl/ml/diseases';
  static const String mlHealth = '$baseApiUrl/ml/health';
  static const String mlModelInfo = '$baseApiUrl/ml/model-info';
  static const String mlTest = '$baseApiUrl/ml/test';

  // ── Crops ──────────────────────────────────────────────────────
  static const String crops = '$baseApiUrl/crops';

  // ── Weather ────────────────────────────────────────────────────
  static const String weatherCurrent = '$baseApiUrl/weather/current';
  static const String weatherForecast = '$baseApiUrl/weather/forecast';

  // ── News ───────────────────────────────────────────────────────
  static const String news = '$baseApiUrl/news/latest';
  static const String newsSearch = '$baseApiUrl/news/search';

  // ── Forum ──────────────────────────────────────────────────────
  static const String forumPosts = '$baseApiUrl/forum/posts';
  static const String createPost = '$baseApiUrl/forum/posts';
  static const String forumMyPosts = '$baseApiUrl/forum/my-posts';

  static String postDetail(String id) => '$baseApiUrl/forum/posts/$id';
  static String postComments(String id) =>
      '$baseApiUrl/forum/posts/$id/comments';
  static String likePost(String id) => '$baseApiUrl/forum/posts/$id/like';
  static String deleteComment(String id) => '$baseApiUrl/forum/comments/$id';
  static String likeComment(String id) => '$baseApiUrl/forum/comments/$id/like';

  // ── Knowledge Hub ──────────────────────────────────────────────
  // Main guides listing with filters: /knowledge/guides?category=&language=&search=&page=&limit=
  static const String knowledgeGuides = '$baseApiUrl/knowledge/guides';

  static String guideDetail(String id) => '$baseApiUrl/knowledge/guides/$id';

  static String guideBySlug(String slug) =>
      '$baseApiUrl/knowledge/guides/slug/$slug';

  // ✅ FIXED: match backend routes (/guides/featured, /guides/popular)
  static const String featuredGuides = '$baseApiUrl/knowledge/guides/featured';
  static const String popularGuides = '$baseApiUrl/knowledge/guides/popular';

  static const String guideCategories = '$baseApiUrl/knowledge/categories';

  static String likeGuide(String id) => '$baseApiUrl/knowledge/guides/$id/like';

  // ── Profit Planner ─────────────────────────────────────────────
  static const String profitExpenses = '$baseApiUrl/planner/expenses';
  static const String profitFields = '$baseApiUrl/planner/fields';
  static const String profitReports = '$baseApiUrl/planner/reports';

  // ── Shop ───────────────────────────────────────────────────────
  static const String shopItems = '$baseApiUrl/shop/items';
  static const String cart = '$baseApiUrl/shop/cart';
  static const String orders = '$baseApiUrl/shop/orders';
  static String shopItemDetail(String id) => '$baseApiUrl/shop/items/$id';

  // ── Safety (messaging/chat — existing) ────────────────────────
  static const String safetyMessages = '$baseApiUrl/safety/messages';
  static const String safetyConversations = '$baseApiUrl/safety/conversations';

  // ── Safety Assist ──────────────────────────────────────────────
  static const String emergencyContacts =
      '$baseApiUrl/safety-assist/emergency-contacts';
  static const String firstAidGuides = '$baseApiUrl/safety-assist/first-aid';
  static const String safetyTips = '$baseApiUrl/safety-assist/tips';
  static const String nearbyHospitals =
      '$baseApiUrl/safety-assist/nearby-hospitals';

  static String nearbyHospitalsWithLocation({
    required double lat,
    required double lng,
    int radius = 15000,
  }) =>
      '$baseApiUrl/safety-assist/nearby-hospitals?lat=$lat&lng=$lng&radius=$radius';

  // ── Notifications ──────────────────────────────────────────────
  static const String notifications = '$baseApiUrl/notifications';

  // ── Support ────────────────────────────────────────────────────
  static const String support = '$baseApiUrl/support';
}
