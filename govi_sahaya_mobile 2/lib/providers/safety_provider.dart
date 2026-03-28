// lib/providers/safety_provider.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/safety_models.dart';
import '../services/backend_auth_service.dart';
import '../core/network/api_endpoints.dart';
import 'settings_provider.dart';

class SafetyProvider extends ChangeNotifier {
  final BackendAuthService _backendAuth = BackendAuthService();

  // ── SettingsProvider reference ───────────────────────────────────
  SettingsProvider? _settingsProvider;

  void setSettingsProvider(SettingsProvider provider) {
    _settingsProvider = provider;
  }

  List<EmergencyContact> _contacts = [];
  List<FirstAidGuide> _firstAidGuides = [];
  List<SafetyTip> _safetyTips = [];
  List<NearbyHospital> _hospitals = [];

  bool _isLoadingContacts = false;
  bool _isLoadingGuides = false;
  bool _isLoadingTips = false;
  bool _isLoadingHospitals = false;

  String? _hospitalsError;
  String? _locationError;
  bool _locationDisabledInSettings = false;
  Position? _currentPosition;

  List<EmergencyContact> get contacts => _contacts;
  List<FirstAidGuide> get firstAidGuides => _firstAidGuides;
  List<SafetyTip> get safetyTips => _safetyTips;
  List<NearbyHospital> get hospitals => _hospitals;

  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingGuides => _isLoadingGuides;
  bool get isLoadingTips => _isLoadingTips;
  bool get isLoadingHospitals => _isLoadingHospitals;

  String? get hospitalsError => _hospitalsError;
  String? get locationError => _locationError;
  bool get locationDisabledInSettings => _locationDisabledInSettings;
  Position? get currentPosition => _currentPosition;

  // ── Fetch all at once ────────────────────────────────────────────
  Future<void> fetchAll() async {
    await Future.wait([
      fetchEmergencyContacts(),
      fetchFirstAidGuides(),
      fetchSafetyTips(),
    ]);
  }

  // ── Emergency Contacts ───────────────────────────────────────────
  Future<void> fetchEmergencyContacts() async {
    _isLoadingContacts = true;
    notifyListeners();
    try {
      final data = await _backendAuth.get(ApiEndpoints.emergencyContacts);
      if (data != null && data['success'] == true) {
        _contacts = (data['data'] as List)
            .map((e) => EmergencyContact.fromJson(e))
            .toList();
      }
    } catch (_) {
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  // ── First Aid Guides ─────────────────────────────────────────────
  Future<void> fetchFirstAidGuides() async {
    _isLoadingGuides = true;
    notifyListeners();
    try {
      final data = await _backendAuth.get(ApiEndpoints.firstAidGuides);
      if (data != null && data['success'] == true) {
        _firstAidGuides = (data['data'] as List)
            .map((e) => FirstAidGuide.fromJson(e))
            .toList();
      }
    } catch (_) {
    } finally {
      _isLoadingGuides = false;
      notifyListeners();
    }
  }

  // ── Safety Tips ──────────────────────────────────────────────────
  Future<void> fetchSafetyTips() async {
    _isLoadingTips = true;
    notifyListeners();
    try {
      final data = await _backendAuth.get(ApiEndpoints.safetyTips);
      if (data != null && data['success'] == true) {
        _safetyTips =
            (data['data'] as List).map((e) => SafetyTip.fromJson(e)).toList();
      }
    } catch (_) {
    } finally {
      _isLoadingTips = false;
      notifyListeners();
    }
  }

  // ✅ NEW — Called instantly when Settings location toggle changes ──
  void onLocationAccessChanged(bool allowed) {
    if (!allowed) {
      _locationDisabledInSettings = true;
      _hospitals = []; // ✅ clear cached hospital list
      _currentPosition = null; // ✅ clear cached position
      _hospitalsError = null;
      _locationError = null;
    } else {
      // ✅ Re-enabled — clear the blocked state so tab is ready to fetch
      _locationDisabledInSettings = false;
    }
    notifyListeners();
  }

  // ── Nearby Hospitals ─────────────────────────────────────────────
  Future<void> fetchNearbyHospitals() async {
    _isLoadingHospitals = true;
    _hospitalsError = null;
    _locationError = null;
    _locationDisabledInSettings = false;
    notifyListeners();

    // ✅ CHECK SETTINGS TOGGLE FIRST — before touching Geolocator at all
    final locationAllowed = _settingsProvider?.locationAccess ?? true;
    if (!locationAllowed) {
      _locationDisabledInSettings = true;
      _hospitals = []; // ✅ clear on fetch too
      _currentPosition = null;
      _isLoadingHospitals = false;
      notifyListeners();
      return;
    }

    try {
      // ── Location permission check ────────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied';
          _isLoadingHospitals = false;
          notifyListeners();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _locationError =
            'Location permission permanently denied. Enable in device settings.';
        _isLoadingHospitals = false;
        notifyListeners();
        return;
      }

      // ── Get device position ──────────────────────────────────
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;

      // ── Fetch hospitals from backend ─────────────────────────
      final data = await _backendAuth.get(
        ApiEndpoints.nearbyHospitalsWithLocation(lat: lat, lng: lng),
      );

      if (data != null && data['success'] == true) {
        _hospitals = (data['data'] as List)
            .map((e) => NearbyHospital.fromJson(e))
            .toList();
        _hospitalsError = null;
      } else {
        _hospitalsError = 'Failed to fetch nearby hospitals';
      }
    } on LocationServiceDisabledException {
      _locationError = 'Location services are disabled. Please enable GPS.';
    } catch (e) {
      _hospitalsError = 'Could not get location. Please try again.';
    } finally {
      _isLoadingHospitals = false;
      notifyListeners();
    }
  }
}
