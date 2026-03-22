import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

class ProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  app_user.User? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _authService.getUserData(uid);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserData(uid: uid, name: name, phone: phone);

      // refresh profile from firestore/cache
      _userProfile = await _authService.getUserData(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
