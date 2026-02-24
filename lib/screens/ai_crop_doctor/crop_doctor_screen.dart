import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

class CropDoctorScreen extends StatelessWidget {
  const CropDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('AI Crop Doctor'),
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
                onTap: () => Navigator.pushNamed(context, AppRoutes.cropUpload),
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
                        Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: AppTheme.primaryGreen,
                        ),
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
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
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
              _buildHowItWorksStep(
                '1',
                'Capture Photo',
                'Take a clear photo of the affected plant part',
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                '2',
                'AI Analysis',
                'Our AI analyzes the image to identify diseases',
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                '3',
                'Get Treatment',
                'Receive organic and chemical treatment options',
              ),
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
              _buildRecentDiagnosisCard(
                'Leaf Blight',
                'Rice',
                '87% Confidence',
                'Yesterday',
              ),
              const SizedBox(height: 12),
              _buildRecentDiagnosisCard(
                'Powdery Mildew',
                'Tomato',
                '92% Confidence',
                '2 days ago',
              ),
            ],
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
    String disease,
    String crop,
    String confidence,
    String time,
  ) {
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
                  disease,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$crop • $confidence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
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
