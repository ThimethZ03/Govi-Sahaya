import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Container(
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
          // Image placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: _getCategoryColor(news.category).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(news.category),
                size: 60,
                color: _getCategoryColor(news.category).withOpacity(0.5),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(news.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    news.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  news.title,
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

                // Sinhala title
                Text(
                  news.titleSinhala,
                  style: AppTheme.sinhalaText(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  news.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.getTimeAgo(news.publishedDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                    if (news.source != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.source,
                          size: 14, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.source!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'government':
        return Colors.blue;
      case 'alert':
        return Colors.red;
      case 'market':
        return Colors.green;
      case 'safety':
        return Colors.orange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'government':
        return Icons.account_balance;
      case 'alert':
        return Icons.warning;
      case 'market':
        return Icons.trending_up;
      case 'safety':
        return Icons.security;
      default:
        return Icons.article;
    }
  }
}
