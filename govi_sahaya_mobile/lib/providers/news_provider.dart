import 'package:flutter/foundation.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';

/// Manages the state of all news-related data.
///
/// Uses [ChangeNotifier] so that registered widgets rebuild whenever
/// [notifyListeners] is called.
class NewsProvider with ChangeNotifier {
  NewsProvider() : _newsService = NewsService();

  /// Injectable for testing.
  NewsProvider.withService(this._newsService);

  final NewsService _newsService;

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  List<NewsModel> _newsList = [];
  List<NewsModel> _featuredNews = [];
  List<NewsModel> _latestNews = [];
  NewsModel? _selectedNews;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isLatestLoading = false;

  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _limit = 10;

  // Filters
  String? _selectedCategory;
  String? _searchQuery;
  String? _selectedLanguage;


  // ---------------------------------------------------------------------------
    // Public getters
    // ---------------------------------------------------------------------------

    List<NewsModel> get newsList => List.unmodifiable(_newsList);
    List<NewsModel> get featuredNews => List.unmodifiable(_featuredNews);
    List<NewsModel> get latestNews => List.unmodifiable(_latestNews);
    NewsModel? get selectedNews => _selectedNews;

    bool get isLoading => _isLoading;
    bool get isFeaturedLoading => _isFeaturedLoading;
    bool get isLatestLoading => _isLatestLoading;

    String? get errorMessage => _errorMessage;

    int get currentPage => _currentPage;
    int get totalPages => _totalPages;
    bool get hasMorePages => _currentPage < _totalPages;

    String? get selectedCategory => _selectedCategory;
    String? get searchQuery => _searchQuery;
    String? get selectedLanguage => _selectedLanguage;


  // Fetch news with filters
  Future<void> fetchNews({bool loadMore = false}) async {
    if (loadMore) {
      if (_currentPage >= _totalPages) return;
      _currentPage++;
    } else {
      _currentPage = 1;
      _newsList.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _newsService.getNews(
        page: _currentPage,
        limit: _limit,
        category: _selectedCategory,
        search: _searchQuery,
        language: _selectedLanguage,
      );

      if (loadMore) {
        _newsList.addAll(response['data'] as List<NewsModel>);
      } else {
        _newsList = response['data'] as List<NewsModel>;
      }

      final pagination = response['pagination'];
      _totalPages = pagination['pages'] ?? 1;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

 // ---------------------------------------------------------------------------
    // Latest news (home screen)
    // ---------------------------------------------------------------------------

    /// Silently fetches the latest news without showing a global loading state.
    Future<void> fetchLatestNews({int limit = 10}) async {
        _isLatestLoading = true;
        notifyListeners();

        try {
            _latestNews = await _newsService.getLatestNews(limit: limit);
        } catch (_) {
            _latestNews = [];
        } finally {
            _isLatestLoading = false;
            notifyListeners();
        }
    }
  // ✅ ADD THIS METHOD - Fetch latest news (for home screen)
  Future<void> fetchLatestNews({int limit = 10}) async {
    try {
      _latestNews = await _newsService.getLatestNews(limit: limit);
      notifyListeners();
    } catch (e) {
      // Silent fail for home screen - just return empty list
      _latestNews = [];
      notifyListeners();
    }
  }

  // Fetch news by ID
  Future<void> fetchNewsById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedNews = await _newsService.getNewsById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Like news
  Future<bool> likeNews(String id, String token) async {
    try {
      final result = await _newsService.likeNews(id, token);

      // Update local state
      if (_selectedNews?.id == id) {
        _selectedNews = NewsModel.fromJson({
          ..._selectedNews!.toJson(),
          'likes': result['likes'],
        });
      }

      // Update in list
      final index = _newsList.indexWhere((news) => news.id == id);
      if (index != -1) {
        _newsList[index] = NewsModel.fromJson({
          ..._newsList[index].toJson(),
          'likes': result['likes'],
        });
      }

      // Update in latest news
      final latestIndex = _latestNews.indexWhere((news) => news.id == id);
      if (latestIndex != -1) {
        _latestNews[latestIndex] = NewsModel.fromJson({
          ..._latestNews[latestIndex].toJson(),
          'likes': result['likes'],
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Share news
  Future<bool> shareNews(String id, String token) async {
    try {
      final result = await _newsService.shareNews(id, token);

      // Update local state
      if (_selectedNews?.id == id) {
        _selectedNews = NewsModel.fromJson({
          ..._selectedNews!.toJson(),
          'shares': result['shares'],
        });
      }

      // Update in list
      final index = _newsList.indexWhere((news) => news.id == id);
      if (index != -1) {
        _newsList[index] = NewsModel.fromJson({
          ..._newsList[index].toJson(),
          'shares': result['shares'],
        });
      }

      // Update in latest news
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

  // Set filters
  void setCategory(String? category) {
    _selectedCategory = category;
    fetchNews();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchNews();
  }

  void setLanguage(String? language) {
    _selectedLanguage = language;
    fetchNews();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = null;
    _selectedLanguage = null;
    fetchNews();
  }

  // Refresh news
  Future<void> refreshNews() async {
    await fetchNews();
  }

  // Get news by category
  List<NewsModel> getNewsByCategory(String category) {
    return _newsList.where((news) => news.category == category).toList();
  }
}
