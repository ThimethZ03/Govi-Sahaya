import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/ml_provider.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';

class CropUploadScreen extends StatefulWidget {
  const CropUploadScreen({super.key});

  @override
  State<CropUploadScreen> createState() => _CropUploadScreenState();
}

class _CropUploadScreenState extends State<CropUploadScreen> {
  final ImagePicker _picker = ImagePicker();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage != null) {
      final mlProvider = context.read<MLProvider>();
      await mlProvider.predictDisease(_selectedImage!);

      if (mounted && mlProvider.lastPrediction != null) {
        _showResultDialog(mlProvider.lastPrediction!);
      } else if (mounted && mlProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mlProvider.errorMessage!)),
        );
      }
    }
  }

  void _showResultDialog(dynamic result) {
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
                'Disease: ${result.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Sinhala: ${result.nameSinhala}'),
              const SizedBox(height: 8),
              Text('Crop: ${result.cropName}'),
              Text(
                  'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(result.description),
              const SizedBox(height: 12),
              const Text(
                'Organic Treatment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(result.organicTreatment),
              const SizedBox(height: 12),
              const Text(
                'Chemical Treatment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(result.chemicalTreatment),
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
