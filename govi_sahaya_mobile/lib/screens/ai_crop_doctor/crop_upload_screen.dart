import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/ml_provider.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
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
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    final mlProvider = context.read<MLProvider>();

    // 1) ML prediction (for dialog)
    await mlProvider.predictDisease(_selectedImage!);

    if (!mounted) return;

    final result = mlProvider.lastPrediction;
    final error = mlProvider.errorMessage;

    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No result received. Please try again.')),
      );
      return;
    }

    // 2) Save detection to Crop Doctor history (Recent Diagnoses)
    //    If this fails, still show the dialog (don’t block UI)
    try {
      await _cropDoctorService.detect(_selectedImage!);
    } catch (e) {
      // optional: show a small warning, but not required
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Saved history failed: $e')),
      // );
    }

    // 3) Show pretty output dialog
    _showResultDialog(result);
  }

  // ✅ Defensive helpers (prevents crashes)
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

  // ✅ Try to read properties from DiseaseModel OR Map JSON
  dynamic _read(dynamic obj, String key) {
    try {
      if (obj is Map) return obj[key];
      // ignore: avoid_dynamic_calls
      return obj?.toJson != null ? obj.toJson()[key] : null;
    } catch (_) {
      return null;
    }
  }

  void _showResultDialog(dynamic result) {
    // These keys depend on your DiseaseModel + backend response
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnosis Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🦠 Disease: $diseaseName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (sinhalaName.isNotEmpty) Text('🇱🇰 Sinhala: $sinhalaName'),
              const SizedBox(height: 8),
              Text('🌱 Crop: $cropName'),
              Text('📊 Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 14),
              const Text(
                '📝 Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),
              const SizedBox(height: 12),
              const Text(
                '🧬 Cause:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(cause),
              const SizedBox(height: 12),
              const Text(
                '💡 Solution:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(solution),
              const SizedBox(height: 12),
              if (prevention.isNotEmpty && prevention != 'N/A') ...[
                const Text(
                  '🛡️ Prevention:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(prevention),
                const SizedBox(height: 12),
              ],
              const Text(
                '✅ Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (recommendations.isNotEmpty)
                ...recommendations.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ),
                )
              else
                const Text('No recommendations available'),
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

  @override
  Widget build(BuildContext context) {
    final mlProvider = context.watch<MLProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Upload Crop Image'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 80,
                              color: AppTheme.textLight,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No image selected',
                              style: TextStyle(color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Camera Button
              CustomButton(
                text: 'Take Photo',
                icon: Icons.camera_alt,
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),

              // Gallery Button
              CustomButton(
                text: 'Choose from Gallery',
                icon: Icons.photo_library,
                isOutlined: true,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 24),

              // Analyze Button
              CustomButton(
                text: 'Analyze Image',
                icon: Icons.analytics,
                onPressed: _selectedImage != null ? _analyzeImage : null,
                isLoading: mlProvider.isLoading,
              ),
              const SizedBox(height: 16),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for best results:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Take clear, well-lit photos'),
                    _buildTip('Focus on the affected area'),
                    _buildTip('Avoid blurry or dark images'),
                    _buildTip('Include the entire leaf or fruit'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
