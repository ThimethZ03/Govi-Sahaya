import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Knowledge Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Category Tabs
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All'),
                  ...AppConstants.libraryCategories.map(
                    (category) => _buildCategoryChip(category),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGuideCard(
                    'How to prepare compost at home',
                    'ගෙදර කොම්පෝස්ට් සකස් කරන්නේ කෙසේද',
                    'Soil',
                    Icons.eco,
                  ),
                  _buildGuideCard(
                    'Best practices for tomato cultivation',
                    'තක්කාලි වගාව සඳහා හොඳම පිළිවෙත්',
                    'Vegetables',
                    Icons.local_florist,
                  ),
                  _buildGuideCard(
                    'Organic pest control methods',
                    'කාබනික පළිබෝධ පාලන ක්‍රම',
                    'Pest',
                    Icons.bug_report,
                  ),
                  _buildGuideCard(
                    'Water management in paddy fields',
                    'වී කෙත්වල ජල කළමනාකරණය',
                    'Soil',
                    Icons.water_drop,
                  ),
                  _buildGuideCard(
                    'Understanding soil pH levels',
                    'පස් pH මට්ටම් අවබෝධ කර ගැනීම',
                    'Soil',
                    Icons.science,
                  ),
                  _buildGuideCard(
                    'Fruit tree pruning techniques',
                    'පළතුරු ගස් කප්පාදු කිරීමේ ක්‍රම',
                    'Fruits',
                    Icons.park,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildGuideCard(
    String title,
    String titleSinhala,
    String category,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              titleSinhala,
              style: AppTheme.sinhalaText(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
        onTap: () {
          _showGuideDetail(context, title, titleSinhala);
        },
      ),
    );
  }

  void _showGuideDetail(
      BuildContext context, String title, String titleSinhala) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titleSinhala,
                style: AppTheme.sinhalaText(
                  fontSize: 16,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'This is a detailed guide content. Replace with actual content from your backend API.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
