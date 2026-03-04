// lib/core/network/api_endpoints.dart

class ApiEndpoints {
  // ── Single source of truth ─────────────────────────────────────
  // ✅ Change ONLY this one line to switch dev ↔ production
  static const String _activeUrl = _localUrl;

  // 🔴 LOCAL DEVELOPMENT
  static const String _localUrl = 'http://192.168.8.127:5000';

  // ✅ PRODUCTION — replace with your actual AWS EC2 IP
  // static const String _productionUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';
  // Once you add SSL + domain:
  // static const String _productionUrl = 'https://api.govishahaya.lk';

  // ── Other dev options (keep commented) ────────────────────────
  // static const String _activeUrl = 'http://10.0.2.2:5000';  // Android Emulator
  // static const String _activeUrl = 'http://localhost:5000';  // iOS Simulator

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

  // Health
  static const String health = '$baseUrl/health';

  // Auth
  static const String login = '$baseApiUrl/auth/login';
  static const String register = '$baseApiUrl/auth/register';
  static const String logout = '$baseApiUrl/auth/logout';
  static const String forgotPassword = '$baseApiUrl/auth/forgot-password';
  static const String resetPassword = '$baseApiUrl/auth/reset-password';
  static const String refreshToken = '$baseApiUrl/auth/refresh-token';
  static const String firebaseSync = '$baseApiUrl/auth/firebase-sync';

  // Users
  static const String userProfile = '$baseApiUrl/users/profile';
  static const String updateProfile = '$baseApiUrl/users/profile';
  static const String uploadProfilePicture =
      '$baseApiUrl/users/profile-picture';

  // Crop Doctor / ML
  static const String detectDisease = '$baseApiUrl/ml/detect-disease';
  static const String detectionHistory = '$baseApiUrl/ml/history';
  static const String diseases = '$baseApiUrl/ml/diseases';
  static const String mlHealth = '$baseApiUrl/ml/health';
  static const String mlModelInfo = '$baseApiUrl/ml/model-info';
  static const String mlTest = '$baseApiUrl/ml/test';

  // Crops
  static const String crops = '$baseApiUrl/crops';

  // Weather
  static const String weatherCurrent = '$baseApiUrl/weather/current';
  static const String weatherForecast = '$baseApiUrl/weather/forecast';

  // News
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
  // ✅ FIXED: /knowledge-hub → /knowledge (matches routes/index.js)
  static const String knowledgeArticles = '$baseApiUrl/knowledge/articles';
  static String articleDetail(String id) =>
      '$baseApiUrl/knowledge/articles/$id';

  // ── Profit Planner ─────────────────────────────────────────────
  // ✅ FIXED: /profit-planner → /planner (matches routes/index.js)
  static const String profitExpenses = '$baseApiUrl/planner/expenses';
  static const String profitFields = '$baseApiUrl/planner/fields';
  static const String profitReports = '$baseApiUrl/planner/reports';

  // Shop
  static const String shopItems = '$baseApiUrl/shop/items';
  static const String cart = '$baseApiUrl/shop/cart';
  static const String orders = '$baseApiUrl/shop/orders';
  static String shopItemDetail(String id) => '$baseApiUrl/shop/items/$id';

  // Safety
  static const String safetyGuidelines = '$baseApiUrl/safety/guidelines';
  static const String firstAid = '$baseApiUrl/safety/first-aid';

  // Notifications
  static const String notifications = '$baseApiUrl/notifications';

  // Support
  static const String support = '$baseApiUrl/support'; // ✅ NEW
}
