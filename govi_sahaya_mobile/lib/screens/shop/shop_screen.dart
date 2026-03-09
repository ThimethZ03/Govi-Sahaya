import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/agri_store_product_model.dart';
import '../../data/agri_store_products_data.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AgriStoreProduct> get _filteredProducts {
    List<AgriStoreProduct> list = _selectedCategory == 'All'
        ? AgriStoreProductsData.products
        : AgriStoreProductsData.getByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.nameSinhala.contains(q) ||
              p.nameTamil.contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.tags.any((t) => t.contains(q)))
          .toList();
    }
    return list;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().languageCode == 'si'
                  ? 'URL විවෘත කළ නොහැකිය'
                  : context.read<LanguageProvider>().languageCode == 'ta'
                      ? 'URL ஐத் திறக்க முடியவில்லை'
                      : 'Could not open the link',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final title = loc('Agri Shop', 'කෘෂි වෙළඳ', 'வேளாண் கடை');
    final subtitle = loc(
      'Buy agri products from trusted Sri Lankan stores',
      'විශ්වාසදායක ශ්‍රී ලංකා නාමාවලි සොයා ගන්න',
      'நம்பகமான இலங்கை கடைகளில் இருந்து வாங்கவும்',
    );
    final searchHint = loc(
      'Search products...',
      'භාණ්ඩ සොයන්න...',
      'பொருட்களைத் தேடவும்...',
    );
    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ═══════════════════════════════════════
            // Header
            // ═══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            )),
                        Text(subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  // Notification bell
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 20),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 15, minHeight: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.primaryGreen, width: 1.5),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════
            // Search + category chips
            // ═══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Search field
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim()),
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(
                              fontSize: 12, color: AppTheme.textLight),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: AppTheme.textLight),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppTheme.textLight),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Category chips
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: AgriStoreProductsData.categories.length,
                        itemBuilder: (context, i) {
                          final cat = AgriStoreProductsData.categories[i];
                          final isSelected = cat == _selectedCategory;
                          // Localize category label
                          String catLabel = cat;
                          if (lang == 'si') {
                            const siMap = {
                              'All': 'සියල්ල',
                              'Fertilizers': 'පොහොර',
                              'Seeds': 'බීජ',
                              'Tools & Equipment': 'මෙවලම්',
                              'Irrigation': 'ජල සම්පාදන',
                              'Pest Control': 'කෘමිනාශක',
                            };
                            catLabel = siMap[cat] ?? cat;
                          } else if (lang == 'ta') {
                            const taMap = {
                              'All': 'அனைத்தும்',
                              'Fertilizers': 'உரங்கள்',
                              'Seeds': 'விதைகள்',
                              'Tools & Equipment': 'கருவிகள்',
                              'Irrigation': 'நீர்ப்பாசனம்',
                              'Pest Control': 'பூச்சிக்கொல்லி',
                            };
                            catLabel = taMap[cat] ?? cat;
                          }
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                  right: i ==
                                          AgriStoreProductsData
                                                  .categories.length -
                                              1
                                      ? 0
                                      : 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white38,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                catLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════
            // Body sheet
            // ═══════════════════════════════════════
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bodyBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: _buildBody(isDark, lang, loc),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      bool isDark, String lang, String Function(String, String, String) loc) {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return _EmptyState(
        isDark: isDark,
        title: loc('No products found', 'භාණ්ඩ නොමැත', 'பொருட்கள் இல்லை'),
        body: loc(
          'Try a different category or search term.',
          'වෙනත් කාණ්ඩයක් හෝ සෙවුම් වචනයක් සොයන්න.',
          'வேறு வகை அல்லது தேடல் சொல் முயற்சிக்கவும்.',
        ),
      );
    }

    final featured = AgriStoreProductsData.featuredProducts;
    final showFeatured = _searchQuery.isEmpty && _selectedCategory == 'All';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Info banner ─────────────────────────────
        SliverToBoxAdapter(
          child: _InfoBanner(isDark: isDark, lang: lang),
        ),

        // ── Featured section ─────────────────────────
        if (showFeatured && featured.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(
                      loc('FEATURED PRODUCTS', 'විශේෂ භාණ්ඩ',
                          'சிறப்பு பொருட்கள்'),
                      isDark),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _FeaturedProductCard(
                        product: featured[i],
                        isDark: isDark,
                        lang: lang,
                        onTap: () => _launchUrl(featured[i].sourceUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── All products label ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, showFeatured ? 8 : 24, 16, 12),
            child: _sectionLabel(
                loc('ALL PRODUCTS', 'සියලු භාණ්ඩ', 'அனைத்து பொருட்கள்'),
                isDark),
          ),
        ),

        // ── Product grid ────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductGridCard(
                product: products[i],
                isDark: isDark,
                lang: lang,
                onTap: () => _launchUrl(products[i].sourceUrl),
              ),
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textLight.withOpacity(0.8),
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════
// Info Banner — explains the redirect-to-store concept
// ══════════════════════════════════════════════════════════
class _InfoBanner extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _InfoBanner({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final bg = isDark
        ? AppTheme.primaryGreen.withOpacity(0.18)
        : AppTheme.primaryGreen.withOpacity(0.07);
    final border = AppTheme.primaryGreen.withOpacity(isDark ? 0.35 : 0.2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc(
                  'Tap any product to buy directly from CS Agro — Sri Lanka\'s trusted agri store.',
                  'ඕනෑම භාණ්ඩයක් ස්පර්ශ කර CS Agro ශ්‍රී ලංකාවේ ගොවිතැන් වෙළඳසැලෙන් සෘජුව මිල දී ගන්න.',
                  'எந்தவொரு பொருளையும் தட்டி CS Agro இலங்கையின் நம்பகமான விவசாய கடையில் இருந்து நேரடியாக வாங்கவும்.',
                ),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Featured horizontal card
// ══════════════════════════════════════════════════════════
class _FeaturedProductCard extends StatelessWidget {
  final AgriStoreProduct product;
  final bool isDark;
  final String lang;
  final VoidCallback onTap;

  const _FeaturedProductCard({
    required this.product,
    required this.isDark,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = lang == 'si'
        ? product.nameSinhala
        : lang == 'ta'
            ? product.nameTamil
            : product.name;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? AppTheme.darkCard : Colors.white,
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / icon area
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(isDark ? 0.18 : 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _categoryIcon(product.category),
                      size: 44,
                      color: AppTheme.primaryGreen
                          .withOpacity(isDark ? 0.6 : 0.45),
                    ),
                  ),
                  // Featured badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 11),
                    ),
                  ),
                  // Organic badge
                  if (product.isOrganic)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Organic',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (product.priceFrom != null)
                          Text(
                            'Rs. ${product.priceFrom!.toStringAsFixed(0)}+',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen
                                .withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Fertilizers':
        return Icons.science_rounded;
      case 'Seeds':
        return Icons.grass_rounded;
      case 'Tools & Equipment':
        return Icons.agriculture_rounded;
      case 'Irrigation':
        return Icons.water_drop_rounded;
      case 'Pest Control':
        return Icons.bug_report_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}

// ══════════════════════════════════════════════════════════
// Product grid card
// ══════════════════════════════════════════════════════════
class _ProductGridCard extends StatelessWidget {
  final AgriStoreProduct product;
  final bool isDark;
  final String lang;
  final VoidCallback onTap;

  const _ProductGridCard({
    required this.product,
    required this.isDark,
    required this.lang,
    required this.onTap,
  });

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Fertilizers':
        return Icons.science_rounded;
      case 'Seeds':
        return Icons.grass_rounded;
      case 'Tools & Equipment':
        return Icons.agriculture_rounded;
      case 'Irrigation':
        return Icons.water_drop_rounded;
      case 'Pest Control':
        return Icons.bug_report_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = lang == 'si'
        ? product.nameSinhala
        : lang == 'ta'
            ? product.nameTamil
            : product.name;
    final displayCat = lang == 'si'
        ? product.categorySinhala
        : lang == 'ta'
            ? product.categoryTamil
            : product.category;

    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderCol),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(isDark ? 0.18 : 0.07),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _categoryIcon(product.category),
                      size: 42,
                      color: AppTheme.primaryGreen
                          .withOpacity(isDark ? 0.6 : 0.45),
                    ),
                  ),
                  if (product.isOrganic)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Organic',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  // CS Agro source chip
                  Positioned(
                    bottom: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white12
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_rounded,
                              size: 9,
                              color: AppTheme.primaryGreen.withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            product.sourceName,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: textPri,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen
                            .withOpacity(isDark ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        displayCat,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.accentGreen
                              : AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (product.priceFrom != null)
                          Text(
                            'Rs. ${product.priceFrom!.toStringAsFixed(0)}+',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        else
                          Text('View price',
                              style: TextStyle(fontSize: 10, color: textSec)),
                        const Spacer(),
                        // Buy button
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;

  const _EmptyState(
      {required this.isDark, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 48, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
