import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/backend_auth_service.dart';

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

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return 'Just now';
    DateTime? dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return 'Just now';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
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

      // ✅ Your route is: /api/crop-doctor/history
      // If your server uses /api/v1, change this to: '/api/v1/crop-doctor/history'
      final res = await _dio.get(
        '/crop-doctor/history',
        queryParameters: {'page': 1, 'limit': 5},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;

        if (data is Map<String, dynamic>) {
          // Most likely: { success:true, data:[...], pagination:{} }
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

  void _showHistoryItemDialog(Map<String, dynamic> item) {
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
    final time = _timeAgo(_safe(item['createdAt'], fallback: ''));

    final severity = _safe(top['severity'],
        fallback: _safe(_asMap(top['disease'])['severity'], fallback: 'N/A'));
    final status = _safe(item['status'], fallback: 'N/A');
    final notes = _safe(item['notes'], fallback: '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnosis Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🦠 Disease: $diseaseName',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('🌱 Crop: $crop'),
              Text('📊 Confidence: ${(conf * 100).toStringAsFixed(1)}%'),
              Text('⚠️ Severity: $severity'),
              Text('✅ Status: $status'),
              const SizedBox(height: 8),
              Text('⏰ Time: $time'),
              if (notes.isNotEmpty && notes != 'N/A') ...[
                const SizedBox(height: 12),
                const Text('📝 Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(notes),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('AI Crop Doctor'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRecent,
            icon: const Icon(Icons.refresh),
          )
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
                const Text(
                  'Identify Plant Diseases',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a photo of your crop to get instant disease diagnosis and treatment recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 32),

                // Upload Card
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.cropUpload)
                          .then((_) {
                    // ✅ refresh after returning from upload screen
                    _loadRecent();
                  }),
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
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload,
                              size: 64, color: AppTheme.primaryGreen),
                          SizedBox(height: 16),
                          Text(
                            'Upload Crop Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to capture or select from gallery',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // How it works
                const Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHowItWorksStep('1', 'Capture Photo',
                    'Take a clear photo of the affected plant part'),
                const SizedBox(height: 12),
                _buildHowItWorksStep('2', 'AI Analysis',
                    'Our AI analyzes the image to identify diseases'),
                const SizedBox(height: 12),
                _buildHowItWorksStep('3', 'Get Treatment',
                    'Receive organic and chemical treatment options'),
                const SizedBox(height: 32),

                // Recent Diagnoses
                const Text(
                  'Recent Diagnoses',
                  style: TextStyle(
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
                        const Expanded(
                          child: Text(
                              'No recent diagnoses yet. Upload an image to see history here.'),
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
                          onTap: () => _showHistoryItemDialog(item),
                          child: _buildRecentDiagnosisCard(
                            diseaseName,
                            cropType,
                            '${(conf * 100).toStringAsFixed(1)}% Confidence',
                            _timeAgo(createdAt),
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
