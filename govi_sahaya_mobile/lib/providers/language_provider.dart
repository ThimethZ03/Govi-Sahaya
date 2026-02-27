import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend_support_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';
  bool _isLoading = false;

  final BackendSupportService _supportService = BackendSupportService();

  String get languageCode => _languageCode;
  bool get isLoading => _isLoading;
  bool get isSinhala => _languageCode == 'si';
  bool get isTamil => _languageCode == 'ta';
  bool get isEnglish => _languageCode == 'en';

  // ── Load saved language from SharedPreferences on app start ───────
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  // ── Load language from backend after login (multi-device sync) ────
  Future<void> loadLanguageFromBackend() async {
    try {
      final language = await _supportService
          .getLanguage(); // ✅ getLanguage() not getSettings()
      if (language != null && language.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', language);
        _languageCode = language;
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Could not load language from backend: $e');
    }
  }

  // ── Change language + sync to backend ─────────────────────────────
  Future<bool> changeLanguage(String code) async {
    if (_languageCode == code) return true;

    _isLoading = true;
    notifyListeners();

    // ✅ Save locally immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    _languageCode = code;
    notifyListeners();

    // ✅ Sync to backend in background
    final success = await _supportService.updateLanguage(code);

    _isLoading = false;
    notifyListeners();

    return success;
  }
}
