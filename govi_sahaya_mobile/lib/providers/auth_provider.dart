import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import '../core/network/api_client.dart';
import 'language_provider.dart';
import 'notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  app_user.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  LanguageProvider? _languageProvider;
  NotificationProvider? _notificationProvider;

  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  AuthProvider() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
        await _languageProvider?.loadLanguageFromBackend();
        // ✅ App reopened — start polling (replaces onLoginSuccess)
        _notificationProvider?.onLoginSuccess();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  // ── Google Sign-In ────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signInWithGoogle();

      if (_user != null) {
        await _languageProvider?.loadLanguageFromBackend();
        _notificationProvider?.onLoginSuccess(); // ✅ starts polling
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Email Sign-In ─────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signIn(email: email, password: password);

      if (_user != null) {
        await _languageProvider?.loadLanguageFromBackend();
        _notificationProvider?.onLoginSuccess(); // ✅ starts polling
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sign-Up ───────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (_user != null) {
        _notificationProvider?.onLoginSuccess(); // ✅ starts polling
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sign-Out ──────────────────────────────────────────────────────
  Future<void> signOut() async {
    _notificationProvider?.onLogout(); // ✅ stops polling + clears state
    await _authService.signOut();
    await ApiClient().clearToken();
    _user = null;
    notifyListeners();
  }

  // ── Update Profile ────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null) {
        await _authService.updateUserData(
          uid: _user!.uid,
          name: name,
          phone: phone,
        );

        _user = app_user.User(
          uid: _user!.uid,
          email: _user!.email,
          name: name,
          phone: phone,
          createdAt: _user!.createdAt,
        );
      }

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
