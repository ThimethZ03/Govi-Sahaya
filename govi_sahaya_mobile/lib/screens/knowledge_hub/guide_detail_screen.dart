import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/guide_model.dart';
import '../../providers/language_provider.dart';
import '../../services/knowledge_hub_service.dart';

class GuideDetailScreen extends StatefulWidget {
  final GuideModel guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  late GuideModel _guide;
  bool _isLiking = false;
  final KnowledgeHubService _service = KnowledgeHubService();

  @override
  void initState() {
    super.initState();
    _guide = widget.guide;
    _loadFreshGuide();
  }

  Future<void> _loadFreshGuide() async {
    try {
      final updated = await _service.getGuideById(_guide.id);
      if (!mounted) return;
      setState(() => _guide = updated);
    } catch (_) {}
  }

  Future<void> _like() async {
    if (_isLiking) return;
    setState(() {
      _isLiking = true;
      _guide = GuideModel(
        id: _guide.id,
        title: _guide.title,
        titleSinhala: _guide.titleSinhala,
        titleTamil: _guide.titleTamil,
        description: _guide.description,
        descriptionSinhala: _guide.descriptionSinhala,
        descriptionTamil: _guide.descriptionTamil,
        content: _guide.content,
        contentSinhala: _guide.contentSinhala,
        contentTamil: _guide.contentTamil,
        category: _guide.category,
        subcategory: _guide.subcategory,
        language: _guide.language,
        difficulty: _guide.difficulty,
        estimatedTimeValue: _guide.estimatedTimeValue,
        estimatedTimeUnit: _guide.estimatedTimeUnit,
        coverImage: _guide.coverImage,
        images: _guide.images,
        crops: _guide.crops,
        tags: _guide.tags,
        benefits: _guide.benefits,
        warnings: _guide.warnings,
        steps: _guide.steps,
        materials: _guide.materials,
        views: _guide.views,
        likes: _guide.likes + 1,
        isFeatured: _guide.isFeatured,
        createdAt: _guide.createdAt,
      );
    });
    try {
      await _service.likeGuide(_guide.id);
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().languageCode;

    // ── Localised strings ─────────────────────────────────────────
    String _loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final title = _loc(
      _guide.title,
      _guide.titleSinhala ?? _guide.title,
      _guide.titleTamil ?? _guide.title,
    );
    final description = _loc(
      _guide.description,
      _guide.descriptionSinhala ?? _guide.description,
      _guide.descriptionTamil ?? _guide.description,
    );
    final content = _loc(
      _guide.content,
      _guide.contentSinhala ?? _guide.content,
      _guide.contentTamil ?? _guide.content,
    );

    final overviewLabel = _loc('Overview', 'සමාලෝචනය', 'மேலோட்டம்');
    final contentLabel =
        _loc('Guide Content', 'මඟපෙන්වීමේ අන්තර්ගතය', 'விரிவான வழிகாட்டி');
    final materialsLabel =
        _loc('Materials Needed', 'අවශ්‍ය ද්‍රව්‍ය', 'தேவையான பொருட்கள்');
    final stepsLabel =
        _loc('Step-by-step', 'පියවරෙන් පියවර', 'படிப்படியான செய்முறை');
    final benefitsLabel = _loc('Benefits', 'ප්‍රයෝජන', 'நன்மைகள்');
    final warningsLabel = _loc('Warnings', 'අවවාද', 'எச்சரிக்கைகள்');
    final optionalLabel = _loc('[Optional]', '[විකල්ප]', '[விருப்பத்தேர்வு]');
    final shareLabel = _loc('Share coming soon', 'හවුල් කිරීම ඉක්මනින් එයි',
        'பகிர்வு விரைவில் வரும்');

    // ── Surface / text tokens for dark mode ──────────────────────
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final surfaceBg = isDark ? AppTheme.darkSurface : AppTheme.backgroundColor;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;

    return Scaffold(
      backgroundColor: surfaceBg,
      body: CustomScrollView(
        slivers: [
          // ══════════════════════════════════════════════════════
          // Hero header
          // ══════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor:
                isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Like button
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: Icon(
                      _guide.likes > widget.guide.likes
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _guide.likes > widget.guide.likes
                          ? Colors.redAccent
                          : Colors.white,
                      size: 20,
                    ),
                    onPressed: _like,
                  ),
                ),
              ),
              // Share button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon:
                        const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(shareLabel)),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image / gradient
                  _guide.coverImage.isNotEmpty
                      ? Image.network(
                          _guide.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBox(),
                        )
                      : _gradientBox(),

                  // Bottom-to-top dark scrim
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),

                  // ── Bottom overlay: title + chips ────────────
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Guide title
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Chips row — completely below the title
                        Row(
                          children: [
                            _overlayChip(
                              icon: Icons.category_outlined,
                              label: _guide.category.replaceAll('_', ' '),
                            ),
                            const SizedBox(width: 6),
                            if (_guide.difficulty != null &&
                                _guide.difficulty!.isNotEmpty)
                              _overlayChip(
                                icon: Icons.speed_outlined,
                                label: _guide.difficulty!,
                                iconColor: _difficultyColor(_guide.difficulty!),
                              ),
                            const Spacer(),
                            _statsPill(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════════════════
          // Body
          // ══════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meta card ──────────────────────────────────
                _metaCard(theme, lang, cardBg, textPri, textSec),

                // ── Optional Sinhala subtitle ──────────────────
                if (lang == 'en' &&
                    _guide.titleSinhala != null &&
                    _guide.titleSinhala!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      _guide.titleSinhala!,
                      style: AppTheme.sinhalaText(fontSize: 15, color: textSec),
                    ),
                  ),

                // ── Tags ───────────────────────────────────────
                if (_guide.tags.isNotEmpty) _tagsSection(theme, textSec),

                // ── Image gallery ─────────────────────────────
                if (_guide.images.isNotEmpty) _imageGallery(),

                const SizedBox(height: 8),

                // ── Overview ──────────────────────────────────
                _contentCard(
                  theme,
                  cardBg: cardBg,
                  label: overviewLabel,
                  icon: Icons.info_outline,
                  iconColor: AppTheme.mediumGreen,
                  child: Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: textSec,
                    ),
                  ),
                ),

                // ── Guide content ─────────────────────────────
                _contentCard(
                  theme,
                  cardBg: cardBg,
                  label: contentLabel,
                  icon: Icons.menu_book_outlined,
                  iconColor: AppTheme.primaryGreen,
                  child: Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.8,
                      color: textSec,
                    ),
                  ),
                ),

                // ── Materials ────────────────────────────────
                if (_guide.materials.isNotEmpty)
                  _contentCard(
                    theme,
                    cardBg: cardBg,
                    label: materialsLabel,
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppTheme.warningOrange,
                    child:
                        _materialsList(theme, optionalLabel, textPri, textSec),
                  ),

                // ── Steps ────────────────────────────────────
                if (_guide.steps.isNotEmpty)
                  _contentCard(
                    theme,
                    cardBg: cardBg,
                    label: stepsLabel,
                    icon: Icons.format_list_numbered,
                    iconColor: AppTheme.mediumGreen,
                    child: _stepsList(theme, textPri, textSec),
                  ),

                // ── Benefits ─────────────────────────────────
                if (_guide.benefits.isNotEmpty)
                  _contentCard(
                    theme,
                    cardBg: cardBg,
                    label: benefitsLabel,
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.successGreen,
                    child: _bulletList(
                      theme,
                      bullets: _guide.benefits,
                      icon: Icons.check_circle,
                      color: AppTheme.successGreen,
                      textColor: textSec,
                    ),
                  ),

                // ── Warnings ─────────────────────────────────
                if (_guide.warnings.isNotEmpty)
                  _contentCard(
                    theme,
                    cardBg: cardBg,
                    label: warningsLabel,
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.warningOrange,
                    accentColor: AppTheme.warningOrange.withOpacity(0.08),
                    child: _bulletList(
                      theme,
                      bullets: _guide.warnings,
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.warningOrange,
                      textColor: textSec,
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _gradientBox() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
          ),
        ),
      );

  Widget _overlayChip({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined,
              color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text('${_guide.views}',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(width: 10),
          const Icon(Icons.favorite_border, color: Colors.redAccent, size: 13),
          const SizedBox(width: 4),
          Text('${_guide.likes}',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _metaCard(ThemeData theme, String lang, Color cardBg, Color textPri,
      Color textSec) {
    final time =
        _guide.estimatedTimeValue != null && _guide.estimatedTimeUnit != null
            ? '${_guide.estimatedTimeValue} ${_guide.estimatedTimeUnit}'
            : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            Helpers.formatDate(_guide.createdAt),
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 12, color: textSec),
          ),
          if (time != null) ...[
            const SizedBox(width: 16),
            Icon(Icons.timer_outlined, size: 14, color: AppTheme.primaryGreen),
            const SizedBox(width: 6),
            Text(
              time,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontSize: 12, color: textSec),
            ),
          ],
          if (_guide.isFeatured) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Featured',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagsSection(ThemeData theme, Color textSec) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _guide.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag,
                    size: 11, color: AppTheme.primaryGreen.withOpacity(0.8)),
                const SizedBox(width: 3),
                Text(
                  tag,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _imageGallery() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _guide.images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final img = _guide.images[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    img.url,
                    width: 180,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                  if (img.caption != null && img.caption!.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          img.caption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Reusable section card with a left-accent border strip
  Widget _contentCard(
    ThemeData theme, {
    required Color cardBg,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Color? accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: accentColor ?? cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(color: iconColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _materialsList(
      ThemeData theme, String optionalText, Color textPri, Color textSec) {
    return Column(
      children: _guide.materials.map((m) {
        final parts = <String>[];
        if (m.name != null && m.name!.isNotEmpty) parts.add(m.name!);
        if (m.quantity != null && m.quantity!.isNotEmpty)
          parts.add('(${m.quantity})');
        if (m.optional) parts.add(optionalText);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.warningOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parts.join(' '),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(height: 1.5, color: textSec),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _stepsList(ThemeData theme, Color textPri, Color textSec) {
    return Column(
      children: _guide.steps.map((s) {
        final num = s.stepNumber ?? _guide.steps.indexOf(s) + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number circle
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$num',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.title != null && s.title!.isNotEmpty)
                      Text(
                        s.title!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPri,
                        ),
                      ),
                    if (s.description != null && s.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: textSec,
                        ),
                      ),
                    ],
                    if (s.tips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...s.tips.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  size: 14, color: AppTheme.accentGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(height: 1.5, color: textSec),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _bulletList(
    ThemeData theme, {
    required List<String> bullets,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      children: bullets.map((b) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(height: 1.5, color: textColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner':
        return Colors.greenAccent;
      case 'intermediate':
        return Colors.orangeAccent;
      case 'advanced':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }
}
