import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/guide_model.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideModel guide;

  const GuideDetailScreen({super.key, required this.guide});

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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
