import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/backend_auth_service.dart';
import '../../providers/language_provider.dart'; // ✅ ADD

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
    // ✅ lang added
    final top = _asMap(item['topPrediction']);
    final diseaseFromTop = _safe(top['diseaseName'], fallback: '');
    final diseaseFromPopulate =
        _safe(_asMap(top['disease'])['name'], fallback: '');
    final diseaseName = (diseaseFromTop.isNotEmpty)
        ? diseaseFromTop
        : (diseaseFromPopulate.isNotEmpty ? diseaseFromPopulate : 'Unknown');

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
        title: Text(
          lang == 'si'
              ? 'රෝග විනිශ්චය විස්තර'
              : lang == 'ta'
                  ? 'நோயறிதல் விவரங்கள்'
                  : 'Diagnosis Details',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🦠 ${lang == 'si' ? 'රෝගය' : lang == 'ta' ? 'நோய்' : 'Disease'}: $diseaseName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                  '🌱 ${lang == 'si' ? 'බෝගය' : lang == 'ta' ? 'பயிர்' : 'Crop'}: $crop'),
              Text(
                  '📊 ${lang == 'si' ? 'විශ්වාසය' : lang == 'ta' ? 'நம்பகத்தன்மை' : 'Confidence'}: ${(conf * 100).toStringAsFixed(1)}%'),
              Text(
                  '⚠️ ${lang == 'si' ? 'බරපතලකම' : lang == 'ta' ? 'தீவிரம்' : 'Severity'}: $severity'),
              Text(
                  '✅ ${lang == 'si' ? 'තත්ත්වය' : lang == 'ta' ? 'நிலை' : 'Status'}: $status'),
              const SizedBox(height: 8),
              Text(
                  '⏰ ${lang == 'si' ? 'වේලාව' : lang == 'ta' ? 'நேரம்' : 'Time'}: $time'),
              if (notes.isNotEmpty && notes != 'N/A') ...[
                const SizedBox(height: 12),
                Text(
                  '📝 ${lang == 'si' ? 'සටහන්' : lang == 'ta' ? 'குறிப்புகள்' : 'Notes'}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notes),
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
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode; // ✅ ADD

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: Text(
          lang == 'si'
              ? 'AI බෝග වෛද්‍යය'
              : lang == 'ta'
                  ? 'AI பயிர் மருத்துவர்'
                  : 'AI Crop Doctor', // ✅
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRecent,
            icon: const Icon(Icons.refresh),
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
        child: RefreshIndicator(
          onRefresh: _loadRecent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  lang == 'si'
                      ? 'ශාක රෝග හඳුනා ගන්න'
                      : lang == 'ta'
                          ? 'தாவர நோய்களை அடையாளம் காணுங்கள்'
                          : 'Identify Plant Diseases', // ✅
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang == 'si'
                      ? 'ක්ෂණික රෝග විනිශ්චයක් සහ ප්‍රතිකාර නිර්දේශ ලබා ගැනීමට ඔබේ බෝගයේ ඡායාරූපයක් උඩුගත කරන්න'
                      : lang == 'ta'
                          ? 'உடனடி நோயறிதல் மற்றும் சிகிச்சை பரிந்துரைகளுக்கு உங்கள் பயிரின் புகைப்படத்தை பதிவேற்றவும்'
                          : 'Upload a photo of your crop to get instant disease diagnosis and treatment recommendations',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 32),

                // Upload Card
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.cropUpload)
                          .then((_) => _loadRecent()),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload,
                              size: 64, color: AppTheme.primaryGreen),
                          const SizedBox(height: 16),
                          Text(
                            lang == 'si'
                                ? 'බෝග රූපය උඩුගත කරන්න'
                                : lang == 'ta'
                                    ? 'பயிர் படத்தை பதிவேற்றவும்'
                                    : 'Upload Crop Image', // ✅
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang == 'si'
                                ? 'ග්‍රහණය කිරීමට හෝ ගැලරියෙන් තේරීමට තට්ටු කරන්න'
                                : lang == 'ta'
                                    ? 'புகைப்படம் எடுக்க அல்லது கேலரியிலிருந்து தேர்ந்தெடுக்க தட்டவும்'
                                    : 'Tap to capture or select from gallery',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // How it works
                Text(
                  lang == 'si'
                      ? 'එය ක්‍රියා කරන ආකාරය'
                      : lang == 'ta'
                          ? 'இது எப்படி செயல்படுகிறது'
                          : 'How it works', // ✅
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHowItWorksStep(
                  '1',
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
                ),
                const SizedBox(height: 12),
                _buildHowItWorksStep(
                  '2',
                  lang == 'si'
                      ? 'AI විශ්ලේෂණය'
                      : lang == 'ta'
                          ? 'AI பகுப்பாய்வு'
                          : 'AI Analysis',
                  lang == 'si'
                      ? 'රෝග හඳුනා ගැනීමට අපගේ AI රූපය විශ්ලේෂණය කරයි'
                      : lang == 'ta'
                          ? 'நோய்களை அடையாளம் காண எங்கள் AI படத்தை பகுப்பாய்வு செய்கிறது'
                          : 'Our AI analyzes the image to identify diseases',
                ),
                const SizedBox(height: 12),
                _buildHowItWorksStep(
                  '3',
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
                ),
                const SizedBox(height: 32),

                // Recent Diagnoses
                Text(
                  lang == 'si'
                      ? 'මෑත රෝග විනිශ්චය'
                      : lang == 'ta'
                          ? 'சமீபத்திய நோயறிதல்கள்'
                          : 'Recent Diagnoses', // ✅
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_recent.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang == 'si'
                                ? 'තවම මෑත රෝග විනිශ්චයක් නැත. ඉතිහාසය බැලීමට රූපයක් උඩුගත කරන්න.'
                                : lang == 'ta'
                                    ? 'இன்னும் சமீபத்திய நோயறிதல்கள் இல்லை. வரலாற்றைக் காண படம் பதிவேற்றவும்.'
                                    : 'No recent diagnoses yet. Upload an image to see history here.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _recent.map((item) {
                      final top = _asMap(item['topPrediction']);
                      final diseaseFromTop =
                          _safe(top['diseaseName'], fallback: '');
                      final diseaseFromPopulate =
                          _safe(_asMap(top['disease'])['name'], fallback: '');
                      final diseaseName = (diseaseFromTop.isNotEmpty)
                          ? diseaseFromTop
                          : (diseaseFromPopulate.isNotEmpty
                              ? diseaseFromPopulate
                              : 'Unknown');
                      final cropType = _safe(
                        item['cropType'],
                        fallback:
                            _safe(item['crop_name'], fallback: 'Unknown Crop'),
                      );
                      final conf =
                          _safeDouble(top['confidence'], fallback: 0.0);
                      final createdAt = _safe(item['createdAt'], fallback: '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showHistoryItemDialog(item, lang), // ✅
                          child: _buildRecentDiagnosisCard(
                            diseaseName,
                            cropType,
                            '${(conf * 100).toStringAsFixed(1)}% ${lang == 'si' ? 'විශ්වාසය' : lang == 'ta' ? 'நம்பகத்தன்மை' : 'Confidence'}',
                            _timeAgo(createdAt, lang), // ✅
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiagnosisCard(
      String disease, String crop, String confidence, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_hospital,
              color: AppTheme.primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🦠 $disease',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🌱 $crop • 📊 $confidence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⏰ $time',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textLight),
        ],
      ),
    );
  }
}
