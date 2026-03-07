import 'dart:io'; // ✅ needed for File type
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/user.dart' as app_user;

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  app_user.User? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Load profile from backend ──────────────────────────────────
  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _profileService.getProfile(uid);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Update profile ─────────────────────────────────────────────
  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String address = '',
    String birthday = '',
    String gender = '',
    String farmLocation = '',
    String extraNotes = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _profileService.updateProfile(
        uid: uid,
        name: name,
        phone: phone,
        address: address,
        birthday: birthday,
        gender: gender,
        farmLocation: farmLocation,
        extraNotes: extraNotes,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Upload profile picture ─────────────────────────────────────
  Future<String?> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final url = await _profileService.uploadProfilePicture(
        uid: uid,
        imageFile: imageFile,
      );
      // Refresh profile to get updated picture URL
      _userProfile = _userProfile?.copyWith(profileImageUrl: url);
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Delete profile picture ─────────────────────────────────────
  Future<bool> deleteProfilePicture(String uid) async {
    try {
      await _profileService.deleteProfilePicture(uid);
      _userProfile = _userProfile?.copyWith(clearProfileImage: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
