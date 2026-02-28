import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Safety Assist'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emergency Contacts
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildEmergencyCard(
              'Police Emergency',
              '119',
              Icons.local_police,
              Colors.blue,
            ),
            _buildEmergencyCard(
              'Ambulance',
              '1990',
              Icons.local_hospital,
              Colors.red,
            ),
            _buildEmergencyCard(
              'Fire & Rescue',
              '110',
              Icons.fire_truck,
              Colors.orange,
            ),
            _buildEmergencyCard(
              'Agriculture Hotline',
              '1920',
              Icons.agriculture,
              Colors.green,
            ),
            const SizedBox(height: 24),

            // First Aid
            const Text(
              'First Aid Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildFirstAidCard(
              'Snake Bite',
              'කටුස්සා කෑම',
              'Keep calm, immobilize affected area, seek medical help immediately',
              Icons.warning,
            ),
            _buildFirstAidCard(
              'Pesticide Poisoning',
              'පළිබෝධනාශක වස වීම',
              'Remove contaminated clothing, wash skin, call poison control',
              Icons.science,
            ),
            _buildFirstAidCard(
              'Heat Stroke',
              'තාප ආඝාතය',
              'Move to shade, cool body with water, seek medical help',
              Icons.wb_sunny,
            ),
            _buildFirstAidCard(
              'Cuts & Wounds',
              'කැපුම් සහ තුවාල',
              'Clean wound, apply pressure to stop bleeding, bandage properly',
              Icons.healing,
            ),
            const SizedBox(height: 24),

            // Nearby Hospitals
            const Text(
              'Nearby Hospitals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildHospitalCard(
              'National Hospital Colombo',
              '011 2691111',
              '5.2 km away',
              Icons.local_hospital,
            ),
            _buildHospitalCard(
              'Colombo South Hospital',
              '011 2626222',
              '8.5 km away',
              Icons.local_hospital,
            ),
            _buildHospitalCard(
              'Asiri Hospital Colombo',
              '011 4526000',
              '3.8 km away',
              Icons.local_hospital,
            ),
            const SizedBox(height: 24),

            // Safety Tips
            const Text(
              'Safety Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildSafetyTipCard(
              'Pesticide Safety',
              'Always wear protective equipment when handling pesticides',
              Icons.safety_divider,
            ),
            _buildSafetyTipCard(
              'Sun Protection',
              'Wear hat and apply sunscreen during peak sun hours',
              Icons.wb_sunny,
            ),
            _buildSafetyTipCard(
              'Tool Safety',
              'Keep farming tools sharp and in good condition',
              Icons.build,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    String title,
    String number,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: color),
          onPressed: () => _makePhoneCall(number),
        ),
      ),
    );
  }

  Widget _buildFirstAidCard(
    String title,
    String titleSinhala,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red, size: 28),
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
                  titleSinhala,
                  style: AppTheme.sinhalaText(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(
    String name,
    String phone,
    String distance,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.red),
            onPressed: () => _makePhoneCall(phone),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
