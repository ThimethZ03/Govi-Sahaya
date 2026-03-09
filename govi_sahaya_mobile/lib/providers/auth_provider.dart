import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../core/network/api_client.dart';
import 'language_provider.dart';
import 'notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  app_user.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  LanguageProvider? _languageProvider;
  NotificationProvider? _notificationProvider;

  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  void setLanguageProvider(LanguageProvider lp) => _languageProvider = lp;
  void setNotificationProvider(NotificationProvider np) =>
      _notificationProvider = np;

  AuthProvider() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Step 1: reload saved JWT from SharedPreferences
        await ApiClient().init();

        // Step 2: if no token in storage, refresh via backend
        if (!ApiClient().isAuthenticated) {
          await _refreshBackendToken(firebaseUser);
        }

        // Step 3: load user data from Firestore (works offline)
        _user = await _authService.getUserData(firebaseUser.uid);
        notifyListeners();

        // Step 4: sync latest profile from backend
        await _syncProfileFromBackend();
        await _languageProvider?.loadLanguageFromBackend();
        _notificationProvider?.onLoginSuccess();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  // Exchange Firebase ID token for backend JWT (used on app restart)
  Future<void> _refreshBackendToken(User firebaseUser) async {
    try {
      debugPrint('🔄 Refreshing backend token via Firebase ID token...');

      // We already rely on /auth/firebase-sync everywhere else;
      // here we can just re-sync to ensure JWT is stored.
      await _authService.backendAuth.syncWithBackend(
        firebaseUid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'User',
        phone: firebaseUser.phoneNumber,
      );

      debugPrint('✅ Backend JWT refreshed via firebaseSync');
    } catch (e) {
      debugPrint('⚠️ Could not refresh backend token: $e');
    }
  }

  // Background sync from backend
  Future<void> _syncProfileFromBackend() async {
    if (_user == null) return;
    try {
      final backendUser = await _profileService.getProfile(_user!.uid);
      _user = backendUser;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Backend profile sync skipped: $e');
    }
  }

  // Public: refresh profile from backend
  Future<void> fetchProfile() async {
    if (_user == null) return;
    try {
      final updated = await _profileService.getProfile(_user!.uid);
      _user = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ fetchProfile error: $e');
    }
  }

  // Public: refresh after edit profile
  Future<void> refreshProfile(String uid) async {
    try {
      final updated = await _profileService.getProfile(uid);
      _user = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ refreshProfile error: $e');
    }
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);

      _user = await _authService.signInWithGoogle();

      if (_user != null) {
        await _syncProfileFromBackend();
        await _languageProvider?.loadLanguageFromBackend();
        _notificationProvider?.onLoginSuccess();
      }

      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // Email Sign-In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      _user = await _authService.signIn(email: email, password: password);

      if (_user != null) {
        await _syncProfileFromBackend();
        await _languageProvider?.loadLanguageFromBackend();
        _notificationProvider?.onLoginSuccess();
      }

      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // Sign-Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _setLoading(true);

      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      // After signup we sign out in AuthService and show verify dialog from UI,
      // so no login success callback here.
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  // Optional: resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
    } catch (e) {
      _setError(e);
    }
  }

  // Sign-Out
  Future<void> signOut() async {
    _notificationProvider?.onLogout();
    await _authService.signOut();
    await ApiClient().clearToken();
    _user = null;
    notifyListeners();
  }

  // Update Profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String address = '',
    String birthday = '',
    String gender = '',
    String farmLocation = '',
    String extraNotes = '',
  }) async {
    if (_user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return false;
    }
    try {
      _setLoading(true);

      final updated = await _profileService.updateProfile(
        uid: _user!.uid,
        name: name,
        phone: phone,
        address: address,
        birthday: birthday,
        gender: gender,
        farmLocation: farmLocation,
        extraNotes: extraNotes,
      );

      _user = updated;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  // Upload Profile Picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    if (_user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return null;
    }
    try {
      _setLoading(true);

      final url = await _profileService.uploadProfilePicture(
        uid: _user!.uid,
        imageFile: imageFile,
      );

      _user = _user!.copyWith(
        profileImageUrl: url,
        photoUrl: url,
      );

      _setLoading(false);
      return url;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  // Delete Profile Picture
  Future<void> deleteProfilePicture() async {
    if (_user == null) return;
    try {
      await _profileService.deleteProfilePicture(_user!.uid);
      _user = _user!.copyWith(clearProfileImage: true);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ deleteProfilePicture error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(Object e) {
    _errorMessage = e.toString().replaceAll('Exception: ', '');
    _isLoading = false;
    notifyListeners();
  }
}
