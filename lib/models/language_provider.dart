import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  // Full list of app-supported languages
  static List<Map<String, String>> get supportedLanguages =>
      AppTranslations.supportedLanguages;

  // MaterialApp locale whitelist (only locales backed by GlobalMaterialLocalizations)
  static List<Locale> get materialSupportedLocales {
    final locales = supportedLanguages
        .map((l) => Locale(l['code']!))
        .where((loc) => GlobalMaterialLocalizations.delegate.isSupported(loc))
        .toList();
    if (!locales.any((l) => l.languageCode == 'en')) {
      locales.insert(0, const Locale('en'));
    }
    return locales;
  }

  Locale _currentLocale = const Locale('en');
  bool _isLoaded = false;

  Locale get currentLocale => _currentLocale;
  bool get isLoaded => _isLoaded;

  /// Safe locale passed to MaterialApp so unsupported Material scripts do not crash widgets.
  Locale get materialLocale {
    if (GlobalMaterialLocalizations.delegate.isSupported(_currentLocale)) {
      return _currentLocale;
    }
    return const Locale('en');
  }

  String tr(String key, {Map<String, String>? args}) =>
      AppTranslations.translate(_currentLocale.languageCode, key, args: args);

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
