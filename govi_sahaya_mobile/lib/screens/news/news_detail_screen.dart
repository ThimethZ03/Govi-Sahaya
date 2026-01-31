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
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGreen,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (news == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGreen,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                newsProvider.errorMessage ?? 'News not found',
                style: const TextStyle(color: Colors.grey),
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
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: news.coverImage != null
                  ? CachedNetworkImage(
                      imageUrl: news.coverImage!.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getCategoryColor(news.category),
                              _getCategoryColor(news.category).withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(news.category),
                            size: 100,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getCategoryColor(news.category),
                            _getCategoryColor(news.category).withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(news.category),
                          size: 100,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(news.category),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            news.getCategoryLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Meta Info
                        _buildMetaInfo(news),
                        const SizedBox(height: 24),

                        // Tags
                        if (news.tags.isNotEmpty) _buildTags(news.tags),

                        // Description
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            news.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Content
                        Text(
                          news.content,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.8,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Location
                        if (news.location?.district != null)
                          _buildLocationInfo(news),

                        // Source
                        if (news.externalSource != null) _buildSourceInfo(news),

                        const SizedBox(height: 32),

                        // Action Buttons
                        _buildActionButtons(context, news),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(news) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          Helpers.getTimeAgo(news.publishedDate),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '${news.views} views',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        if (news.author?.source != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              news.author!.source!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTags(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationInfo(news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            '${news.location!.district}, ${news.location!.country}',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfo(news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.source, color: Colors.amber[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Source: ${news.externalSource!.name}',
              style: TextStyle(
                color: Colors.amber[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, news) {
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
            label: Text('${news.likes} Likes'),
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
                '${news.title}\n\n${news.description}\n\nRead more on Govi Sahaya App',
              );
            },
            icon: const Icon(Icons.share),
            label: Text('${news.shares} Shares'),
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
    switch (category) {
      case 'market_prices':
        return Colors.green;
      case 'government_policy':
        return Colors.blue;
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'market_prices':
        return Icons.trending_up;
      case 'government_policy':
        return Icons.account_balance;
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
