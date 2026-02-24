import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Agri News'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: newsProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : newsProvider.newsList.isEmpty
                ? const Center(child: Text('No news available'))
                : RefreshIndicator(
                    onRefresh: () => newsProvider.refreshNews(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: newsProvider.newsList.length,
                      itemBuilder: (context, index) {
                        final news = newsProvider.newsList[index];
                        return _buildNewsCard(news);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildNewsCard(dynamic news) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/news-detail',
          arguments: news.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIXED: Proper image handling with URL validation
            _buildNewsImage(news),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge (FIXED - safe access)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(news.category ?? 'general'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      news.category ?? 'News',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title (✅ SAFE)
                  Text(
                    news.title ?? 'No title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description (✅ SAFE)
                  Text(
                    news.description ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer (✅ SAFE null check)
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.getTimeAgo(
                            news.publishedDate ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${news.views ?? 0} views',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build news image with proper validation
  Widget _buildNewsImage(dynamic news) {
    final imageUrl = news.coverImage?.url;

    // Validate URL - must be non-empty and start with http/https
    final bool isValidUrl = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    if (isValidUrl) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) =>
              _buildImagePlaceholder(news.category ?? 'general'),
        ),
      );
    }

    return _buildImagePlaceholder(news.category ?? 'general');
  }

  // Image placeholder for when no valid image URL exists
  Widget _buildImagePlaceholder(String category) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 60,
          color: _getCategoryColor(category).withOpacity(0.5),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch ((category ?? 'general').toLowerCase()) {
      case 'government':
      case 'government_policy':
        return Colors.blue;
      case 'alert':
        return Colors.red;
      case 'market':
      case 'market_prices':
        return Colors.green;
      case 'safety':
        return Colors.orange;
      case 'technology':
        return Colors.purple;
      case 'weather':
        return Colors.orange;
      case 'success_stories':
        return Colors.teal;
      case 'events':
        return Colors.red;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch ((category ?? 'general').toLowerCase()) {
      case 'government':
      case 'government_policy':
        return Icons.account_balance;
      case 'alert':
        return Icons.warning;
      case 'market':
      case 'market_prices':
        return Icons.trending_up;
      case 'safety':
        return Icons.security;
      case 'technology':
        return Icons.computer;
      case 'weather':
        return Icons.cloud;
      case 'success_stories':
        return Icons.emoji_events;
      case 'events':
        return Icons.event;
      default:
        return Icons.article;
    }
  }
}
