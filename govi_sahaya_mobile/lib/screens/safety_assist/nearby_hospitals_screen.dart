// lib/screens/safety_assist/nearby_hospitals_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/safety_provider.dart';
import '../../models/safety_models.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  final bool isDark;
  final String lang;
  const NearbyHospitalsScreen(
      {super.key, required this.isDark, required this.lang});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SafetyProvider>();
      if (p.hospitals.isEmpty && !p.isLoadingHospitals) {
        p.fetchNearbyHospitals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SafetyProvider>();
    final isDark = widget.isDark;
    final lang = widget.lang;

    return RefreshIndicator(
      onRefresh: () => provider.fetchNearbyHospitals(),
      color: AppTheme.primaryGreen,
      child: _buildBody(provider, isDark, lang),
    );
  }

  // ── Main body switcher ───────────────────────────────────────────
  Widget _buildBody(SafetyProvider provider, bool isDark, String lang) {
    // Loading skeleton
    if (provider.isLoadingHospitals && provider.hospitals.isEmpty) {
      return _buildSkeleton(isDark, lang);
    }

    // ✅ Settings location toggle is OFF — show instantly, reactively
    if (provider.locationDisabledInSettings) {
      return _buildLocationDisabledInSettings(isDark, lang);
    }

    // OS-level location permission error
    if (provider.locationError != null) {
      return _buildLocationError(provider, isDark, lang);
    }

    // General API error
    if (provider.hospitalsError != null && provider.hospitals.isEmpty) {
      return _buildGeneralError(provider, isDark, lang);
    }

    // Hospital list
    return _buildHospitalList(provider, isDark, lang);
  }

  // ── Loading skeleton ─────────────────────────────────────────────
  Widget _buildSkeleton(bool isDark, String lang) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSectionLabel(
            lang == 'si'
                ? 'ළඟම රෝහල්'
                : lang == 'ta'
                    ? 'அருகில் உள்ள மருத்துவமனைகள்'
                    : 'NEARBY HOSPITALS',
            isDark,
          ),
        ),
        Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        ...List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Settings location disabled state ─────────────────────────────
  Widget _buildLocationDisabledInSettings(bool isDark, String lang) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded,
                        size: 40, color: Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    lang == 'si'
                        ? 'ස්ථාන ප්‍රවේශය අක්‍රීයයි'
                        : lang == 'ta'
                            ? 'இட அணுகல் முடக்கப்பட்டுள்ளது'
                            : 'Location Access Disabled',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lang == 'si'
                        ? 'ළඟම රෝහල් සොයා ගැනීමට සැකසුම් තුළ ස්ථාන ප්‍රවේශය සක්‍රීය කරන්න.'
                        : lang == 'ta'
                            ? 'அருகிலுள்ள மருத்துவமனைகளை கண்டறிய அமைப்புகளில் இட அணுகலை இயக்கவும்.'
                            : 'Enable Location Access in Settings to find nearby hospitals.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: Text(
                        lang == 'si'
                            ? 'සැකසුම් වෙත යන්න'
                            : lang == 'ta'
                                ? 'அமைப்புகளுக்கு செல்'
                                : 'Go to Settings',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── OS-level location permission error ───────────────────────────
  Widget _buildLocationError(
      SafetyProvider provider, bool isDark, String lang) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded,
                        size: 40, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang == 'si'
                        ? 'ස්ථාන අවසරය අවශ්‍යයි'
                        : lang == 'ta'
                            ? 'இடம் அனுமதி தேவை'
                            : 'Location Permission Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.locationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => provider.fetchNearbyHospitals(),
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(lang == 'si'
                          ? 'නැවත උත්සාහ කරන්න'
                          : lang == 'ta'
                              ? 'மீண்டும் முயற்சி'
                              : 'Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => openAppSettings(),
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: Text(lang == 'si'
                          ? 'සැකසීම් විවෘත කරන්න'
                          : lang == 'ta'
                              ? 'அமைப்புகளை திறக்கவும்'
                              : 'Open App Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── General API error state ──────────────────────────────────────
  Widget _buildGeneralError(SafetyProvider provider, bool isDark, String lang) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_hospital_outlined,
                        size: 40,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang == 'si'
                        ? 'රෝහල් සොයා ගත නොහැකි විය'
                        : lang == 'ta'
                            ? 'மருத்துவமனைகள் கிடைக்கவில்லை'
                            : 'Could Not Find Hospitals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.hospitalsError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchNearbyHospitals(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(lang == 'si'
                        ? 'නැවත උත්සාහ'
                        : lang == 'ta'
                            ? 'மீண்டும்'
                            : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hospital list ────────────────────────────────────────────────
  Widget _buildHospitalList(SafetyProvider provider, bool isDark, String lang) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      itemCount: provider.hospitals.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSectionLabel(
              lang == 'si'
                  ? 'ළඟම රෝහල්'
                  : lang == 'ta'
                      ? 'அருகில் உள்ள மருத்துவமனைகள்'
                      : 'NEARBY HOSPITALS',
              isDark,
            ),
          );
        }

        if (index == 1) {
          if (provider.currentPosition == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color:
                  AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'ඔබේ ස්ථානය: ${provider.currentPosition!.latitude.toStringAsFixed(4)}, ${provider.currentPosition!.longitude.toStringAsFixed(4)}'
                        : lang == 'ta'
                            ? 'உங்கள் இடம்: ${provider.currentPosition!.latitude.toStringAsFixed(4)}, ${provider.currentPosition!.longitude.toStringAsFixed(4)}'
                            : 'Your location: ${provider.currentPosition!.latitude.toStringAsFixed(4)}, ${provider.currentPosition!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final hIndex = index - 2;
        if (hIndex >= provider.hospitals.length) return const SizedBox.shrink();

        return _buildHospitalCard(
            provider.hospitals[hIndex], isDark, lang, hIndex);
      },
    );
  }

  // ── Hospital card ────────────────────────────────────────────────
  Widget _buildHospitalCard(
      NearbyHospital h, bool isDark, String lang, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rank badge + icon ──────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Colors.red, size: 26),
              ),
              if (index < 3)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.amber
                          : index == 1
                              ? Colors.grey.shade400
                              : Colors.brown.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Info ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                    )),
                const SizedBox(height: 3),
                Text(h.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textLight,
                    )),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (h.distance != null)
                      _chip(Icons.directions_car_rounded, h.distance!,
                          Colors.blue, isDark),
                    if (h.duration != null)
                      _chip(Icons.access_time_rounded, h.duration!,
                          AppTheme.primaryGreen, isDark),
                    if (h.isOpen != null)
                      _chip(
                        h.isOpen!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        h.isOpen!
                            ? (lang == 'si'
                                ? 'විවෘතයි'
                                : lang == 'ta'
                                    ? 'திறந்திருக்கும்'
                                    : 'Open')
                            : (lang == 'si'
                                ? 'වසා ඇත'
                                : lang == 'ta'
                                    ? 'மூடப்பட்டுள்ளது'
                                    : 'Closed'),
                        h.isOpen! ? Colors.green : Colors.red,
                        isDark,
                      ),
                    if (h.rating != null)
                      _chip(Icons.star_rounded, h.rating!.toStringAsFixed(1),
                          Colors.amber, isDark),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (h.phone != null) ...[
                GestureDetector(
                  onTap: () => _call(h.phone!),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              GestureDetector(
                onTap: () => _openMaps(h.lat, h.lng, h.name),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info chip ────────────────────────────────────────────────────
  Widget _chip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps(double lat, double lng, String name) async {
    final encoded = Uri.encodeComponent(name);
    final googleMaps = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encoded');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');

    if (await canLaunchUrl(googleMaps)) {
      await launchUrl(googleMaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    }
  }
}

// ── Shared helpers (file-level) ──────────────────────────────────────
Widget _buildSectionLabel(String label, bool isDark) => Row(
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
        Text(label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textLight.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            )),
      ],
    );
