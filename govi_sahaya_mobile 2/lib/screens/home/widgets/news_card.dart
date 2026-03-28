import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/news_model.dart';
import '../../../config/theme.dart';
import '../../../core/utils/helpers.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback? onTap;

  const NewsCard({
    super.key,
    required this.news,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.getCategoryLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (news.isFeatured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    news.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (news.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTags(),
                  ],

                  const SizedBox(height: 14),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (news.coverImage?.url != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: CachedNetworkImage(
          imageUrl: news.coverImage!.url,
          height: 185,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 185,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 60,
          color: _getCategoryColor().withOpacity(0.35),
        ),
      ),
    );
  }

  Widget _buildTags() {
    return SizedBox(
      height: 26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: news.tags.length > 3 ? 3 : news.tags.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.25), width: 1),
            ),
            child: Text(
              '#${news.tags[index]}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          Helpers.getTimeAgo(news.publishedDate),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const Spacer(),
        Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text('${news.views}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(width: 10),
        Icon(Icons.favorite_border_rounded,
            size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text('${news.likes}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (news.category) {
      case 'market_prices':
        return Colors.green.shade600;
      case 'government_policy':
        return Colors.blue.shade600;
      case 'technology':
        return Colors.purple.shade600;
      case 'weather':
        return Colors.orange.shade600;
      case 'success_stories':
        return Colors.teal.shade600;
      case 'events':
        return Colors.red.shade600;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon() {
    switch (news.category) {
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
