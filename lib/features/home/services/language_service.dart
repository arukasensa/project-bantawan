// ============================================================================
// 🌐 BANTAWAN Language & Localization Provider: LanguageProvider
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Multi-Language & Localization)              │
// ├─────────────────────────────────────────────────────────┤
// │                  LanguageProvider                       │
// │  ┌───────────────────────────────────────────────────┐  │
// │  │        SharedPreferences ('selected_language')     │  │
// │  │         (สลับภาษาไทย 'th' และ ภาษาอังกฤษ 'en')         │  │
// │  └───────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// ตัวจัดการภาษาหลักของแอปพลิเคชัน (Language Provider & Localization)
// บริหารจัดการการสลับภาษาใช้งานระหว่างภาษาไทย (th) และภาษาอังกฤษ (en)
// พร้อมจัดเก็บการตั้งค่าภาษาลง SharedPreferences เพื่อคงค่าแม้ปิดแอป
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🏛️ Provider จัดการภาษาหลักและระบบหลายภาษาของแอปพลิเคชัน (LanguageProvider)
class LanguageProvider extends ChangeNotifier {
  /// ค่าภาษาปัจจุบัน (ค่าเริ่มต้น: ภาษาไทย 'th')
  Locale _appLocale = const Locale('th');
  static const String _storageKey = 'selected_language';

  Locale get appLocale => _appLocale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_storageKey);
    if (languageCode != null) {
      _appLocale = Locale(languageCode);
    } else {
      _appLocale = const Locale('th'); // Default to Thai
    }
    notifyListeners();
  }

  Future<void> changeLanguage(Locale type) async {
    final prefs = await SharedPreferences.getInstance();
    if (_appLocale == type) return;

    _appLocale = type;
    await prefs.setString(_storageKey, type.languageCode);
    notifyListeners();
  }
}
