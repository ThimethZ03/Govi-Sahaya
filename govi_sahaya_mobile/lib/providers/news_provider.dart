// Import Flutter foundation library for ChangeNotifier
import 'package:flutter/foundation.dart';

// Import the service that handles API requests
import '../services/news_service.dart';

// Import the model representing a news article
import '../models/news_model.dart';

/// This class manages all news state in the application.
/// It uses ChangeNotifier so UI widgets update when data changes.
class NewsProvider with ChangeNotifier {

  // Default constructor that creates a NewsService object
  NewsProvider() : _newsService = NewsService();

  // Constructor used mainly for testing (dependency injection)
  NewsProvider.withService(this._newsService);

  // Instance of the service used to call API methods
  final NewsService _newsService;

  // ---------------------------------------------------------------------------
  // Private state variables
  // ---------------------------------------------------------------------------

  // List that stores all fetched news
  List<NewsModel> _newsList = [];

  // List for featured news (if used on homepage)
  List<NewsModel> _featuredNews = [];

  // List for latest news (home screen)
  List<NewsModel> _latestNews = [];

  // Stores a single selected news article
  NewsModel? _selectedNews;

  // Loading state for general news requests
  bool _isLoading = false;

  // Loading state for featured news
  bool _isFeaturedLoading = false;

  // Loading state for latest news
  bool _isLatestLoading = false;

  // Stores error message if API fails
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Pagination variables
  // ---------------------------------------------------------------------------

  // Current page number
  int _currentPage = 1;

  // Total pages returned from API
  int _totalPages = 1;

  // Number of news items per page
  static const int _limit = 10;

  // ---------------------------------------------------------------------------
  // Filter variables
  // ---------------------------------------------------------------------------

  // Selected category filter
  String? _selectedCategory;

  // Search text filter
  String? _searchQuery;

  // Selected language filter
  String? _selectedLanguage;

  // ---------------------------------------------------------------------------
  // Public getters (read-only access for UI)
  // ---------------------------------------------------------------------------

  // Returns an unmodifiable list of news
  List<NewsModel> get newsList => List.unmodifiable(_newsList);

  // Returns featured news list
  List<NewsModel> get featuredNews => List.unmodifiable(_featuredNews);

  // Returns latest news list
  List<NewsModel> get latestNews => List.unmodifiable(_latestNews);

  // Returns selected news article
  NewsModel? get selectedNews => _selectedNews;

  // Returns loading state
  bool get isLoading => _isLoading;

  // Returns featured loading state
  bool get isFeaturedLoading => _isFeaturedLoading;

  // Returns latest loading state
  bool get isLatestLoading => _isLatestLoading;

  // Returns error message if exists
  String? get errorMessage => _errorMessage;

  // Returns current page number
  int get currentPage => _currentPage;

  // Returns total pages
  int get totalPages => _totalPages;

  // Returns true if more pages exist
  bool get hasMorePages => _currentPage < _totalPages;

  // Returns selected category
  String? get selectedCategory => _selectedCategory;

  // Returns search query
  String? get searchQuery => _searchQuery;

  // Returns selected language
  String? get selectedLanguage => _selectedLanguage;

  // ---------------------------------------------------------------------------
  // Fetch news with filters and pagination
  // ---------------------------------------------------------------------------

  Future<void> fetchNews({bool loadMore = false}) async {

    // If loading more pages
    if (loadMore) {

      // Stop if already on the last page
      if (_currentPage >= _totalPages) return;

      // Move to next page
      _currentPage++;

    } else {

      // Reset page to 1 for fresh search
      _currentPage = 1;

      // Clear existing news list
      _newsList.clear();
    }

    // Set loading state
    _isLoading = true;

    // Clear previous error
    _errorMessage = null;

    // Notify UI to update loading indicator
    notifyListeners();

    try {

      // Call API to fetch news
      final response = await _newsService.getNews(
        page: _currentPage,
        limit: _limit,
        category: _selectedCategory,
        search: _searchQuery,
        language: _selectedLanguage,
      );

      // If loading more data, append to list
      if (loadMore) {

        _newsList.addAll(response['data'] as List<NewsModel>);

      } else {

        // Otherwise replace list
        _newsList = response['data'] as List<NewsModel>;
      }

      // Get pagination info from API response
      final pagination = response['pagination'];

      // Update total pages
      _totalPages = pagination['pages'] ?? 1;

      // Turn off loading
      _isLoading = false;

      // Notify UI to rebuild
      notifyListeners();

    } catch (e) {

      // Store error message
      _errorMessage = e.toString();

      // Turn off loading
      _isLoading = false;

      // Notify UI about error
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch latest news (used for homepage)
  // ---------------------------------------------------------------------------

  Future<void> fetchLatestNews({int limit = 10}) async {

    // Enable latest loading state
    _isLatestLoading = true;

    notifyListeners();
    

    try {

      // Fetch latest news from API
      _latestNews = await _newsService.getLatestNews(limit: limit);

    } catch (_) {

      // If API fails, return empty list
      _latestNews = [];
    }

    // Disable loading
    _isLatestLoading = false;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Fetch single news by ID
  // ---------------------------------------------------------------------------

  Future<void> fetchNewsById(String id) async {

    // Enable loading
    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {

      // Fetch single news article
      _selectedNews = await _newsService.getNewsById(id);

      _isLoading = false;

      notifyListeners();

    } catch (e) {

      // Store error
      _errorMessage = e.toString();

      _isLoading = false;

      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Like news article
  // ---------------------------------------------------------------------------

  Future<bool> likeNews(String id, String token) async {

    try {

      // Call API to like article
      final result = await _newsService.likeNews(id, token);

      // Update selected news if it matches
      if (_selectedNews?.id == id) {

        _selectedNews = NewsModel.fromJson({
          ..._selectedNews!.toJson(),
          'likes': result['likes'],
        });
      }

      // Find news in main list
      final index = _newsList.indexWhere((news) => news.id == id);

      if (index != -1) {

        // Update likes locally
        _newsList[index] = NewsModel.fromJson({
          ..._newsList[index].toJson(),
          'likes': result['likes'],
        });
      }

      // Update latest news list
      final latestIndex = _latestNews.indexWhere((news) => news.id == id);

      if (latestIndex != -1) {

        _latestNews[latestIndex] = NewsModel.fromJson({
          ..._latestNews[latestIndex].toJson(),
          'likes': result['likes'],
        });
      }

      // Notify UI
      notifyListeners();

      return true;

    } catch (e) {

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Share news article
  // ---------------------------------------------------------------------------

  Future<bool> shareNews(String id, String token) async {

    try {

      // Call API share endpoint
      final result = await _newsService.shareNews(id, token);

      // Update selected news
      if (_selectedNews?.id == id) {

        _selectedNews = NewsModel.fromJson({
          ..._selectedNews!.toJson(),
          'shares': result['shares'],
        });
      }

      // Update main news list
      final index = _newsList.indexWhere((news) => news.id == id);

      if (index != -1) {

        _newsList[index] = NewsModel.fromJson({
          ..._newsList[index].toJson(),
          'shares': result['shares'],
        });
      }

      // Update latest news list
      final latestIndex = _latestNews.indexWhere((news) => news.id == id);

      if (latestIndex != -1) {

        _latestNews[latestIndex] = NewsModel.fromJson({
          ..._latestNews[latestIndex].toJson(),
          'shares': result['shares'],
        });
      }

      notifyListeners();

      return true;

    } catch (e) {

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Set category filter
  // ---------------------------------------------------------------------------

  void setCategory(String? category) {

    // Save selected category
    _selectedCategory = category;

    // Fetch filtered news
    fetchNews();
  }

  // ---------------------------------------------------------------------------
  // Set search query
  // ---------------------------------------------------------------------------

  void setSearchQuery(String? query) {

    _searchQuery = query;

    fetchNews();
  }

  // ---------------------------------------------------------------------------
  // Set language filter
  // ---------------------------------------------------------------------------

  void setLanguage(String? language) {

    _selectedLanguage = language;

    fetchNews();
  }

  // ---------------------------------------------------------------------------
  // Clear all filters
  // ---------------------------------------------------------------------------

  void clearFilters() {

    _selectedCategory = null;
    _searchQuery = null;
    _selectedLanguage = null;

    fetchNews();
  }

  // ---------------------------------------------------------------------------
  // Refresh news list
  // ---------------------------------------------------------------------------

  Future<void> refreshNews() async {

    await fetchNews();
  }

  // ---------------------------------------------------------------------------
  // Get news by category locally
  // ---------------------------------------------------------------------------

  List<NewsModel> getNewsByCategory(String category) {

    // Return filtered news list
    return _newsList.where((news) => news.category == category).toList();
  }
}