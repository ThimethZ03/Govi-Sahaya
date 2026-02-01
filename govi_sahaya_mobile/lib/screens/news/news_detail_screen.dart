import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNewsById(widget.newsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final news = newsProvider.selectedNews;

    if (newsProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (news == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.primaryGreen),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                newsProvider.errorMessage ?? 'News not found',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // FIXED: Safe null check for image with URL validation
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(news),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED: Safe category label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(news.category ?? 'general'),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryDisplayName(news),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      news.title ?? 'No title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildMetaInfo(news),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.description ?? 'No description available',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      news.content ?? 'No content available',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildActionButtons(context, news),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Proper URL validation to prevent "No host specified" error
  Widget _buildHeroImage(dynamic news) {
    final imageUrl = news.coverImage?.url;

    // Validate URL properly - must be non-empty and start with http/https
    final bool isValidUrl = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    if (isValidUrl) {
      return ClipRRect(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
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

  Widget _buildImagePlaceholder(String category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getCategoryColor(category),
            _getCategoryColor(category).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 100,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  // FIXED: Safe category label
  String _getCategoryDisplayName(dynamic news) {
    try {
      return news.getCategoryLabel?.call() ?? news.category ?? 'News';
    } catch (e) {
      return news.category ?? 'News';
    }
  }

  Widget _buildMetaInfo(dynamic news) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          Helpers.getTimeAgo(news.publishedDate ?? DateTime.now()),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '${news.views ?? 0} views',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic news) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLiked
                ? null
                : () async {
                    setState(() => _isLiked = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('News liked!')),
                    );
                  },
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            label: Text('${news.likes ?? 0} Likes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isLiked ? Colors.red : AppTheme.textDark,
              side: BorderSide(
                color: _isLiked ? Colors.red : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Share.share(
                '${news.title ?? ''}\n\n${news.description ?? ''}\n\nRead more on Govi Sahaya App',
              );
            },
            icon: const Icon(Icons.share),
            label: Text('${news.shares ?? 0} Shares'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'market_prices':
      case 'market':
        return Colors.green;
      case 'government_policy':
      case 'government':
        return Colors.blue;
      case 'technology':
        return Colors.purple;
      case 'weather':
        return Colors.orange;
      case 'success_stories':
        return Colors.teal;
      case 'events':
        return Colors.red;
      case 'alert':
        return Colors.red;
      case 'safety':
        return Colors.orange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'market_prices':
      case 'market':
        return Icons.trending_up;
      case 'government_policy':
      case 'government':
        return Icons.account_balance;
      case 'technology':
        return Icons.computer;
      case 'weather':
        return Icons.cloud;
      case 'success_stories':
        return Icons.emoji_events;
      case 'events':
        return Icons.event;
      case 'alert':
        return Icons.warning;
      case 'safety':
        return Icons.security;
      default:
        return Icons.article;
    }
  }
}
