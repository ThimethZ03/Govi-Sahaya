import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/guide_model.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideModel guide;

  const GuideDetailScreen({super.key, required this.guide});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.local_florist;
      case 'fruits':
        return Icons.apple;
      case 'soil':
        return Icons.eco;
      case 'pest':
        return Icons.bug_report;
      case 'organic':
        return Icons.nature;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                guide.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(guide.category),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.titleSinhala,
                    style: AppTheme.sinhalaText(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          guide.category,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Helpers.formatDate(guide.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

