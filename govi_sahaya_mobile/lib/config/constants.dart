class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://10.31.2.1:5000/api/v1';
  static const String apiVersion = 'v1';

  // API Endpoints
  static const String predictEndpoint = '/ml/detect-disease';
  static const String guidesEndpoint = '/guides';
  static const String shopItemsEndpoint = '/shop-items';
  static const String profitPlannerEndpoint = '/profit-planner';
  static const String newsEndpoint = '/news';
  static const String weatherEndpoint = '/weather';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String messagesCollection = 'messages';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';

  // App Text (Sinhala)
  static const String appNameSinhala = 'ගොවි සහාය';
  static const String appSlogan = 'නැණවත් ගොවිතැනක් - සරුසාර හෙට දිනක්';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserData = 'user_data';
  static const String keyLanguage = 'language';

  // Categories
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
