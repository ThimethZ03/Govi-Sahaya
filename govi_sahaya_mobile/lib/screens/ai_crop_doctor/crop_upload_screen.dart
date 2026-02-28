import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/ml_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/crop_doctor_service.dart';

class CropUploadScreen extends StatefulWidget {
  const CropUploadScreen({super.key});

  @override
  State<CropUploadScreen> createState() => _CropUploadScreenState();
}

class _CropUploadScreenState extends State<CropUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final CropDoctorService _cropDoctorService = CropDoctorService();

  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    final mlProvider = context.read<MLProvider>();
    await mlProvider.predictDisease(_selectedImage!);
    if (!mounted) return;

    final result = mlProvider.lastPrediction;
    final error = mlProvider.errorMessage;

    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No result received. Please try again.')));
      return;
    }
    try {
      await _cropDoctorService.detect(_selectedImage!);
    } catch (_) {}

    _showResultDialog(result);
  }

  // ---------- helpers ----------
  String _safeStr(dynamic v, [String fallback = 'N/A']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  double _safeDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  List<String> _safeList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) {
      return v
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  dynamic _read(dynamic obj, String key) {
    try {
      if (obj is Map) return obj[key];
      return obj?.toJson != null ? obj.toJson()[key] : null;
    } catch (_) {
      return null;
    }
  }

  Color _confidenceColor(double conf) {
    if (conf >= 0.8) return Colors.green;
    if (conf >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _showResultDialog(dynamic result) {
    final lang = context.read<LanguageProvider>().languageCode;

    final diseaseName =
        _safeStr(_read(result, 'name') ?? result.name, 'Unknown');
    final sinhalaName = _safeStr(
        _read(result, 'name_sinhala') ??
            _read(result, 'nameSinhala') ??
            result.nameSinhala,
        '');
    final cropName = _safeStr(
        _read(result, 'crop_name') ??
            _read(result, 'cropName') ??
            result.cropName,
        'Unknown');
    final confidence =
        _safeDouble(_read(result, 'confidence') ?? result.confidence, 0.0);
    final description =
        _safeStr(_read(result, 'description') ?? result.description, 'N/A');
    final cause = _safeStr(_read(result, 'cause') ?? result.cause, 'N/A');
    final solution =
        _safeStr(_read(result, 'solution') ?? result.solution, 'N/A');
    final prevention =
        _safeStr(_read(result, 'prevention') ?? result.prevention, '');
    final recommendations =
        _safeList(_read(result, 'recommendations') ?? result.recommendations);

    final confColor = _confidenceColor(confidence);

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
                    ? 'රෝග විනිශ්චය ප්‍රතිඵලය'
                    : lang == 'ta'
                        ? 'நோயறிதல் முடிவு'
                        : 'Diagnosis Result',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 20),

              // Confidence bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidence,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(confColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: confColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _dialogRow(
                  Icons.coronavirus_rounded,
                  Colors.red,
                  lang == 'si'
                      ? 'රෝගය'
                      : lang == 'ta'
                          ? 'நோய்'
                          : 'Disease',
                  diseaseName),
              if (sinhalaName.isNotEmpty)
                _dialogRow(
                    Icons.language_rounded,
                    Colors.indigo,
                    lang == 'si'
                        ? 'සිංහල නම'
                        : lang == 'ta'
                            ? 'சிங்கள பெயர்'
                            : 'Sinhala',
                    sinhalaName),
              _dialogRow(
                  Icons.grass_rounded,
                  AppTheme.primaryGreen,
                  lang == 'si'
                      ? 'බෝගය'
                      : lang == 'ta'
                          ? 'பயிர்'
                          : 'Crop',
                  cropName),

              const Divider(height: 16),

              _dialogSection(
                Icons.description_rounded,
                Colors.blue,
                lang == 'si'
                    ? 'විස්තරය'
                    : lang == 'ta'
                        ? 'விளக்கம்'
                        : 'Description',
                description,
              ),
              _dialogSection(
                Icons.science_rounded,
                Colors.purple,
                lang == 'si'
                    ? 'හේතුව'
                    : lang == 'ta'
                        ? 'காரணம்'
                        : 'Cause',
                cause,
              ),
              _dialogSection(
                Icons.healing_rounded,
                Colors.teal,
                lang == 'si'
                    ? 'විසඳුම'
                    : lang == 'ta'
                        ? 'தீர்வு'
                        : 'Solution',
                solution,
              ),
              if (prevention.isNotEmpty && prevention != 'N/A')
                _dialogSection(
                  Icons.shield_rounded,
                  Colors.orange,
                  lang == 'si'
                      ? 'වැළැක්වීම'
                      : lang == 'ta'
                          ? 'தடுப்பு'
                          : 'Prevention',
                  prevention,
                ),

              if (recommendations.isNotEmpty) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      lang == 'si'
                          ? 'නිර්දේශ'
                          : lang == 'ta'
                              ? 'பரிந்துரைகள்'
                              : 'Recommendations',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...recommendations.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(line,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textLight)),
                        ),
                      ],
                    ),
                  ),
                ),
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
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
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

  Widget _dialogSection(
      IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textLight, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final mlProvider = context.watch<MLProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

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
                  // Back button
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
                          ? 'බෝග රූපය උඩුගත කරන්න'
                          : lang == 'ta'
                              ? 'பயிர் படத்தை பதிவேற்றவும்'
                              : 'Upload Crop Image',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Notification icon
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

            // ── White Body ────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Section Label ─────────────────────────────
                      _buildSectionLabel(
                        lang == 'si'
                            ? 'රූපය අප්ලෝඩ් කරන්න'
                            : lang == 'ta'
                                ? 'படத்தை பதிவேற்றவும்'
                                : 'UPLOAD IMAGE',
                      ),
                      const SizedBox(height: 10),

                      // ── Image Preview ─────────────────────────────
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: _selectedImage != null
                              ? Colors.transparent
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedImage != null
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedImage!,
                                    fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.image_outlined,
                                        size: 28, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lang == 'si'
                                        ? 'රූපයක් තෝරා නැත'
                                        : lang == 'ta'
                                            ? 'படம் எதுவும் தேர்ந்தெடுக்கப்படவில்லை'
                                            : 'No image selected',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lang == 'si'
                                        ? 'කැමරාව හෝ ගැලරිය භාවිතා කරන්න'
                                        : lang == 'ta'
                                            ? 'கேமரா அல்லது கேலரி பயன்படுத்தவும்'
                                            : 'Use camera or gallery below',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ── Pick Buttons Row ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickButton(
                              icon: Icons.camera_alt_rounded,
                              iconColor: const Color(0xFF1565C0),
                              bgColor: const Color(0xFFE3F2FD),
                              label: lang == 'si'
                                  ? 'කැමරාව'
                                  : lang == 'ta'
                                      ? 'கேமரா'
                                      : 'Camera',
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPickButton(
                              icon: Icons.photo_library_rounded,
                              iconColor: const Color(0xFF6A1B9A),
                              bgColor: const Color(0xFFF3E5F5),
                              label: lang == 'si'
                                  ? 'ගැලරිය'
                                  : lang == 'ta'
                                      ? 'கேலரி'
                                      : 'Gallery',
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Analyze Button ────────────────────────────
                      GestureDetector(
                        onTap: (_selectedImage != null && !mlProvider.isLoading)
                            ? _analyzeImage
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedImage != null
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _selectedImage != null
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (mlProvider.isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              else
                                Icon(
                                  Icons.analytics_rounded,
                                  size: 18,
                                  color: _selectedImage != null
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                mlProvider.isLoading
                                    ? (lang == 'si'
                                        ? 'විශ්ලේෂණය කරමින්...'
                                        : lang == 'ta'
                                            ? 'பகுப்பாய்வு செய்கிறது...'
                                            : 'Analyzing...')
                                    : (lang == 'si'
                                        ? 'රූපය විශ්ලේෂණය කරන්න'
                                        : lang == 'ta'
                                            ? 'படத்தை பகுப்பாய்வு செய்யவும்'
                                            : 'Analyze Image'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedImage != null
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Tips ──────────────────────────────────────
                      _buildSectionLabel(
                        lang == 'si'
                            ? 'ඉඟි'
                            : lang == 'ta'
                                ? 'குறிப்புகள்'
                                : 'TIPS',
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_rounded,
                                    size: 15, color: Color(0xFF1565C0)),
                                const SizedBox(width: 6),
                                Text(
                                  lang == 'si'
                                      ? 'හොඳම ප්‍රතිඵල සඳහා:'
                                      : lang == 'ta'
                                          ? 'சிறந்த முடிவுகளுக்கு:'
                                          : 'For best results:',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildTip(
                              lang == 'si'
                                  ? 'පැහැදිලි, හොඳ ආලෝකයකින් ඡායාරූප ගන්න'
                                  : lang == 'ta'
                                      ? 'தெளிவான, நன்கு வெளிச்சமான புகைப்படங்கள் எடுக்கவும்'
                                      : 'Take clear, well-lit photos',
                            ),
                            _buildTip(
                              lang == 'si'
                                  ? 'බලපෑමට ලක් වූ ප්‍රදේශය කෙරෙහි අවධානය යොමු කරන්න'
                                  : lang == 'ta'
                                      ? 'பாதிக்கப்பட்ட பகுதியில் கவனம் செலுத்துங்கள்'
                                      : 'Focus on the affected area',
                            ),
                            _buildTip(
                              lang == 'si'
                                  ? 'අඳුරු හෝ කැළඹිලි සහිත රූප වළකින්න'
                                  : lang == 'ta'
                                      ? 'மங்கலான அல்லது இருண்ட படங்களை தவிர்க்கவும்'
                                      : 'Avoid blurry or dark images',
                            ),
                            _buildTip(
                              lang == 'si'
                                  ? 'සම්පූර්ණ කොළය හෝ ගෙඩිය ඇතුළත් කරන්න'
                                  : lang == 'ta'
                                      ? 'முழு இலை அல்லது பழத்தை சேர்க்கவும்'
                                      : 'Include the entire leaf or fruit',
                            ),
                          ],
                        ),
                      ),
                    ],
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
  Widget _buildSectionLabel(String label) {
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
            color: AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Pick Button ────────────────────────────────────────────────────
  Widget _buildPickButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tip Row ────────────────────────────────────────────────────────
  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 14, color: Color(0xFF1565C0)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
