import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/backend_auth_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW

class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({super.key});

  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends State<CropDoctorScreen> {
  late final Dio _dio;
  final BackendAuthService _auth = BackendAuthService();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (s) => s != null && s < 500,
    ));
    _loadRecent();
  }

  // ---------- helpers ----------
  String _safe(dynamic v, {String fallback = 'N/A'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  double _safeDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  String? _extractError(dynamic data) {
    try {
      if (data == null) return null;
      if (data is String) return data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? data['details'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _timeAgo(String? iso, String lang) {
    if (iso == null || iso.isEmpty) {
      return lang == 'si'
          ? 'දැන් ම'
          : lang == 'ta'
              ? 'இப்போது'
              : 'Just now';
    }
    DateTime? dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return lang == 'si'
          ? 'දැන් ම'
          : lang == 'ta'
              ? 'இப்போது'
              : 'Just now';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return lang == 'si'
          ? 'දැන් ම'
          : lang == 'ta'
              ? 'இப்போது'
              : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return lang == 'si'
          ? 'මිනිත්තු ${diff.inMinutes}කට පෙර'
          : lang == 'ta'
              ? '${diff.inMinutes} நிமிடங்களுக்கு முன்'
              : '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return lang == 'si'
          ? 'පැය ${diff.inHours}කට පෙර'
          : lang == 'ta'
              ? '${diff.inHours} மணி நேரத்திற்கு முன்'
              : '${diff.inHours} hours ago';
    }
    return lang == 'si'
        ? 'දින ${diff.inDays}කට පෙර'
        : lang == 'ta'
            ? '${diff.inDays} நாட்களுக்கு முன்'
            : '${diff.inDays} days ago';
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    return <String, dynamic>{};
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return Colors.red;
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'mild':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ---------- API ----------
  Future<void> _loadRecent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getBackendToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not authenticated. Please login again.';
          _loading = false;
        });
        return;
      }
      final res = await _dio.get(
        '/crop-doctor/history',
        queryParameters: {'page': 1, 'limit': 5},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final list = data['data'] ?? data['results'] ?? data['detections'];
          if (list is List) {
            setState(() {
              _recent = list
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              _loading = false;
            });
            return;
          }
        }
      }
      setState(() {
        _error = _extractError(res.data) ?? 'Failed to fetch recent diagnoses';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _showHistoryItemDialog(Map<String, dynamic> item, String lang) {
    final top = _asMap(item['topPrediction']);
    final diseaseFromTop = _safe(top['diseaseName'], fallback: '');
    final diseaseFromPopulate =
        _safe(_asMap(top['disease'])['name'], fallback: '');
    final diseaseName = diseaseFromTop.isNotEmpty
        ? diseaseFromTop
        : diseaseFromPopulate.isNotEmpty
            ? diseaseFromPopulate
            : 'Unknown';

    final crop = _safe(item['cropType'],
        fallback: _safe(item['crop_name'], fallback: 'Unknown'));
    final conf = _safeDouble(top['confidence'], fallback: 0.0);
    final time = _timeAgo(_safe(item['createdAt'], fallback: ''), lang);
    final severity = _safe(top['severity'],
        fallback: _safe(_asMap(top['disease'])['severity'], fallback: 'N/A'));
    final status = _safe(item['status'], fallback: 'N/A');
    final notes = _safe(item['notes'], fallback: '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.biotech_rounded,
                  color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lang == 'si'
                    ? 'රෝග විනිශ්චය විස්තර'
                    : lang == 'ta'
                        ? 'நோயறிதல் விவரங்கள்'
                        : 'Diagnosis Details',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              _dialogRow(
                  Icons.coronavirus_rounded,
                  Colors.red,
                  lang == 'si'
                      ? 'රෝගය'
                      : lang == 'ta'
                          ? 'நோய்'
                          : 'Disease',
                  diseaseName),
              _dialogRow(
                  Icons.grass_rounded,
                  AppTheme.primaryGreen,
                  lang == 'si'
                      ? 'බෝගය'
                      : lang == 'ta'
                          ? 'பயிர்'
                          : 'Crop',
                  crop),
              _dialogRow(
                  Icons.percent_rounded,
                  Colors.blue,
                  lang == 'si'
                      ? 'විශ්වාසය'
                      : lang == 'ta'
                          ? 'நம்பகத்தன்மை'
                          : 'Confidence',
                  '${(conf * 100).toStringAsFixed(1)}%'),
              _dialogRow(
                  Icons.warning_amber_rounded,
                  _severityColor(severity),
                  lang == 'si'
                      ? 'බරපතලකම'
                      : lang == 'ta'
                          ? 'தீவிரம்'
                          : 'Severity',
                  severity),
              _dialogRow(
                  Icons.check_circle_outline_rounded,
                  Colors.green,
                  lang == 'si'
                      ? 'තත්ත්වය'
                      : lang == 'ta'
                          ? 'நிலை'
                          : 'Status',
                  status),
              _dialogRow(
                  Icons.access_time_rounded,
                  Colors.grey,
                  lang == 'si'
                      ? 'වේලාව'
                      : lang == 'ta'
                          ? 'நேரம்'
                          : 'Time',
                  time),
              if (notes.isNotEmpty && notes != 'N/A') ...[
                const Divider(height: 16),
                Text(
                  lang == 'si'
                      ? 'සටහන්'
                      : lang == 'ta'
                          ? 'குறிப்புகள்'
                          : 'Notes',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight),
                ),
                const SizedBox(height: 4),
                Text(notes,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textDark)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang == 'si'
                  ? 'වසන්න'
                  : lang == 'ta'
                      ? 'மூடு'
                      : 'Close',
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'AI බෝග වෛද්‍යය'
                          : lang == 'ta'
                              ? 'AI பயிர் மருத்துவர்'
                              : 'AI Crop Doctor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loading ? null : _loadRecent,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 18),
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
                                    height: 1.1),
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

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // ✅ dark mode aware background
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _loadRecent,
                  color: AppTheme.primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ────────────────────────────────────
                        Text(
                          lang == 'si'
                              ? 'ශාක රෝග හඳුනා ගන්න'
                              : lang == 'ta'
                                  ? 'தாவர நோய்களை அடையாளம் காணுங்கள்'
                                  : 'Identify Plant Diseases',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            // ✅ dark mode text
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lang == 'si'
                              ? 'ක්ෂණික රෝග විනිශ්චයක් ලබා ගැනීමට බෝගයේ ඡායාරූපයක් උඩුගත කරන්න'
                              : lang == 'ta'
                                  ? 'உடனடி நோயறிதலுக்கு பயிரின் புகைப்படம் பதிவேற்றவும்'
                                  : 'Upload a photo of your crop for instant disease diagnosis',
                          style: TextStyle(
                            fontSize: 12,
                            // ✅ dark mode subtitle
                            color: isDark ? Colors.white54 : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Upload Card ───────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.cropUpload)
                                  .then((_) => _loadRecent()),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen
                                      .withOpacity(isDark ? 0.2 : 0.12),
                                  AppTheme.primaryGreen
                                      .withOpacity(isDark ? 0.08 : 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 30,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  lang == 'si'
                                      ? 'බෝග රූපය උඩුගත කරන්න'
                                      : lang == 'ta'
                                          ? 'பயிர் படத்தை பதிவேற்றவும்'
                                          : 'Upload Crop Image',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lang == 'si'
                                      ? 'ග්‍රහණය කිරීමට හෝ ගැලරියෙන් තේරීමට තට්ටු කරන්න'
                                      : lang == 'ta'
                                          ? 'புகைப்படம் எடுக்க அல்லது கேலரியிலிருந்து தட்டவும்'
                                          : 'Tap to capture or select from gallery',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : AppTheme.textLight.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    lang == 'si'
                                        ? 'දැන් ආරම්භ කරන්න'
                                        : lang == 'ta'
                                            ? 'இப்போது தொடங்கு'
                                            : 'Start Now',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Stats Row ────────────────────────────────
                        Row(
                          children: [
                            _buildStatChip(
                                Icons.speed_rounded,
                                const Color(0xFF1565C0),
                                isDark
                                    ? const Color(0xFF1A2744)
                                    : const Color(0xFFE3F2FD),
                                lang == 'si'
                                    ? 'ක්ෂණික'
                                    : lang == 'ta'
                                        ? 'உடனடி'
                                        : 'Instant',
                                isDark),
                            const SizedBox(width: 8),
                            _buildStatChip(
                                Icons.verified_rounded,
                                const Color(0xFF2E7D32),
                                isDark
                                    ? const Color(0xFF1A2E1A)
                                    : const Color(0xFFE8F5E9),
                                lang == 'si'
                                    ? 'නිවැරදි'
                                    : lang == 'ta'
                                        ? 'துல்லியமான'
                                        : 'Accurate',
                                isDark),
                            const SizedBox(width: 8),
                            _buildStatChip(
                                Icons.eco_rounded,
                                const Color(0xFF6A1B9A),
                                isDark
                                    ? const Color(0xFF2A1A3A)
                                    : const Color(0xFFF3E5F5),
                                lang == 'si'
                                    ? 'ජෛව'
                                    : lang == 'ta'
                                        ? 'இயற்கை'
                                        : 'Organic',
                                isDark),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // ── How it Works ──────────────────────────────
                        _buildSectionLabel(
                          lang == 'si'
                              ? 'ක්‍රියා කරන ආකාරය'
                              : lang == 'ta'
                                  ? 'இது எப்படி செயல்படுகிறது'
                                  : 'HOW IT WORKS',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildHowItWorksStep(
                          '1',
                          Icons.photo_camera_rounded,
                          const Color(0xFF1565C0),
                          isDark
                              ? const Color(0xFF1A2744)
                              : const Color(0xFFE3F2FD),
                          lang == 'si'
                              ? 'ඡායාරූපය ගන්න'
                              : lang == 'ta'
                                  ? 'புகைப்படம் எடுக்கவும்'
                                  : 'Capture Photo',
                          lang == 'si'
                              ? 'බලපෑමට ලක් වූ ශාක කොටසේ පැහැදිලි ඡායාරූපයක් ගන්න'
                              : lang == 'ta'
                                  ? 'பாதிக்கப்பட்ட தாவர பகுதியின் தெளிவான புகைப்படம் எடுக்கவும்'
                                  : 'Take a clear photo of the affected plant part',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildHowItWorksStep(
                          '2',
                          Icons.psychology_rounded,
                          const Color(0xFF6A1B9A),
                          isDark
                              ? const Color(0xFF2A1A3A)
                              : const Color(0xFFF3E5F5),
                          lang == 'si'
                              ? 'AI විශ්ලේෂණය'
                              : lang == 'ta'
                                  ? 'AI பகுப்பாய்வு'
                                  : 'AI Analysis',
                          lang == 'si'
                              ? 'රෝග හඳුනා ගැනීමට අපගේ AI රූපය විශ්ලේෂණය කරයි'
                              : lang == 'ta'
                                  ? 'நோய்களை அடையாளம் காண AI படத்தை பகுப்பாய்வு செய்கிறது'
                                  : 'Our AI analyzes the image to identify diseases',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildHowItWorksStep(
                          '3',
                          Icons.healing_rounded,
                          const Color(0xFF00695C),
                          isDark
                              ? const Color(0xFF0A2420)
                              : const Color(0xFFE0F2F1),
                          lang == 'si'
                              ? 'ප්‍රතිකාරය ලබා ගන්න'
                              : lang == 'ta'
                                  ? 'சிகிச்சை பெறுங்கள்'
                                  : 'Get Treatment',
                          lang == 'si'
                              ? 'කාබනික සහ රසායනික ප්‍රතිකාර විකල්ප ලබා ගන්න'
                              : lang == 'ta'
                                  ? 'இயற்கை மற்றும் இரசாயன சிகிச்சை விருப்பங்களைப் பெறுங்கள்'
                                  : 'Receive organic and chemical treatment options',
                          isDark,
                        ),
                        const SizedBox(height: 22),

                        // ── Recent Diagnoses ──────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionLabel(
                                lang == 'si'
                                    ? 'මෑත රෝග විනිශ්චය'
                                    : lang == 'ta'
                                        ? 'சமீபத்திய நோயறிதல்கள்'
                                        : 'RECENT DIAGNOSES',
                                isDark,
                              ),
                            ),
                            if (_recent.isNotEmpty)
                              GestureDetector(
                                onTap: _loadRecent,
                                child: Text(
                                  lang == 'si'
                                      ? 'නැවුම් කරන්න'
                                      : lang == 'ta'
                                          ? 'புதுப்பி'
                                          : 'Refresh',
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen),
                            ),
                          )
                        else if (_error != null)
                          _buildInfoBanner(
                            icon: Icons.error_outline_rounded,
                            iconColor: Colors.red.shade700,
                            bgColor: isDark
                                ? Colors.red.shade900.withOpacity(0.3)
                                : Colors.red.shade50,
                            borderColor: isDark
                                ? Colors.red.shade800
                                : Colors.red.shade200,
                            message: _error!,
                            isDark: isDark,
                          )
                        else if (_recent.isEmpty)
                          _buildInfoBanner(
                            icon: Icons.info_outline_rounded,
                            iconColor: Colors.blue.shade700,
                            bgColor: isDark
                                ? Colors.blue.shade900.withOpacity(0.3)
                                : Colors.blue.shade50,
                            borderColor: isDark
                                ? Colors.blue.shade800
                                : Colors.blue.shade200,
                            message: lang == 'si'
                                ? 'තවම මෑත රෝග විනිශ්චයක් නැත. ඉතිහාසය බැලීමට රූපයක් උඩුගත කරන්න.'
                                : lang == 'ta'
                                    ? 'இன்னும் சமீபத்திய நோயறிதல்கள் இல்லை. வரலாற்றைக் காண படம் பதிவேற்றவும்.'
                                    : 'No recent diagnoses yet. Upload an image to see history here.',
                            isDark: isDark,
                          )
                        else
                          Column(
                            children: _recent.map((item) {
                              final top = _asMap(item['topPrediction']);
                              final diseaseFromTop =
                                  _safe(top['diseaseName'], fallback: '');
                              final diseaseFromPopulate = _safe(
                                  _asMap(top['disease'])['name'],
                                  fallback: '');
                              final diseaseName = diseaseFromTop.isNotEmpty
                                  ? diseaseFromTop
                                  : diseaseFromPopulate.isNotEmpty
                                      ? diseaseFromPopulate
                                      : 'Unknown';
                              final cropType = _safe(item['cropType'],
                                  fallback: _safe(item['crop_name'],
                                      fallback: 'Unknown Crop'));
                              final conf =
                                  _safeDouble(top['confidence'], fallback: 0.0);
                              final severity = _safe(top['severity'],
                                  fallback: _safe(
                                      _asMap(top['disease'])['severity'],
                                      fallback: ''));
                              final createdAt =
                                  _safe(item['createdAt'], fallback: '');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildRecentDiagnosisCard(
                                  diseaseName: diseaseName,
                                  cropType: cropType,
                                  confidence: conf,
                                  severity: severity,
                                  timeAgo: _timeAgo(createdAt, lang),
                                  lang: lang,
                                  isDark: isDark,
                                  onTap: () =>
                                      _showHistoryItemDialog(item, lang),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            // ✅ dark mode label
            color:
                isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Stat Chip ──────────────────────────────────────────────────────
  Widget _buildStatChip(IconData icon, Color iconColor, Color bgColor,
      String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── How It Works Step ──────────────────────────────────────────────
  Widget _buildHowItWorksStep(
    String number,
    IconData icon,
    Color iconColor,
    Color bgColor,
    String title,
    String description,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ✅ dark mode tile
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        // ✅ dark mode title
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    // ✅ dark mode description
                    color: isDark ? Colors.white54 : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Banner ────────────────────────────────────────────────────
  Widget _buildInfoBanner({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String message,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: iconColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Diagnosis Card ──────────────────────────────────────────
  Widget _buildRecentDiagnosisCard({
    required String diseaseName,
    required String cropType,
    required double confidence,
    required String severity,
    required String timeAgo,
    required String lang,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final confPercent = (confidence * 100).toStringAsFixed(1);
    final sevColor = _severityColor(severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // ✅ dark mode card
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.biotech_rounded,
                    color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        // ✅ dark mode text
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.grass_rounded,
                            size: 11, color: AppTheme.primaryGreen),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            cropType,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.white54 : AppTheme.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.percent_rounded,
                            size: 11, color: Colors.blue.shade400),
                        const SizedBox(width: 2),
                        Text(
                          '$confPercent%',
                          style: TextStyle(
                              fontSize: 11, color: Colors.blue.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 10,
                            color: isDark
                                ? Colors.white38
                                : AppTheme.textLight.withOpacity(0.6)),
                        const SizedBox(width: 3),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white38
                                : AppTheme.textLight.withOpacity(0.7),
                          ),
                        ),
                        if (severity.isNotEmpty && severity != 'N/A') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              severity,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: sevColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  // ✅ dark mode chevron bg
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.grey, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
