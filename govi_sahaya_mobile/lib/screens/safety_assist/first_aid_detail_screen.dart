import 'package:flutter/material.dart';
import '../../config/theme.dart';

class FirstAidDetailScreen extends StatelessWidget {
  final String title;
  final String titleSinhala;
  final String description;

  const FirstAidDetailScreen({
    super.key,
    required this.title,
    required this.titleSinhala,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: Text(title),
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
              Text(
                titleSinhala,
                style: AppTheme.sinhalaText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),

              _buildSection(
                'Symptoms',
                'Watch for these warning signs:\n• Pain or swelling at the affected area\n• Difficulty breathing\n• Nausea or vomiting\n• Dizziness or confusion',
                Icons.warning,
                Colors.orange,
              ),

              _buildSection(
                'Immediate Steps',
                description,
                Icons.medical_services,
                Colors.red,
              ),

              _buildSection(
                'Do NOT',
                '• Panic or move too quickly\n• Apply ice directly to skin\n• Give anything by mouth if unconscious\n• Try to treat serious injuries alone',
                Icons.block,
                Colors.red.shade900,
              ),

              _buildSection(
                'When to Call Emergency',
                '• Severe bleeding\n• Loss of consciousness\n• Difficulty breathing\n• Severe allergic reaction\n• Any serious injury',
                Icons.phone,
                Colors.blue,
              ),

              const SizedBox(height: 24),

              // Emergency Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Emergency: 1990'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
