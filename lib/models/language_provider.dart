import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  // App-supported languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English (US)'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'hi', 'name': 'हिन्दी'},
    {'code': 'ta', 'name': 'தமிழ்'},
  ];

  Locale _currentLocale = const Locale('en');
  bool _isLoaded = false;

  Locale get currentLocale => _currentLocale;
  bool get isLoaded => _isLoaded;
  
  String get currentLanguageName {
    final lang = supportedLanguages.firstWhere(
      (l) => l['code'] == _currentLocale.languageCode,
      orElse: () => supportedLanguages.first,
    );
    return lang['name']!;
  }

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    if (savedCode != null) {
      _currentLocale = Locale(savedCode);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
}
