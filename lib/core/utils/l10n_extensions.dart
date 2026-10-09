// ============================================================================
// 🌐 BANTAWAN Localization Extension: l10n_extensions.dart
// 
// ส่วนขยาย BuildContext สำหรับเข้าถึง AppLocalizations และสถานะภาษาปัจจุบัน
// ช่วยลด boilerplate code จาก `AppLocalizations.of(context)!` เป็น `context.l10n`
// และ `Localizations.localeOf(context).languageCode == 'th'` เป็น `context.isThai`
// ============================================================================

import 'package:flutter/widgets.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// เข้าถึง AppLocalizations ประจำ Context ปัจจุบัน
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw StateError(
        'AppLocalizations not found in current context. '
        'Ensure MaterialApp has proper localizationsDelegates configured.',
      );
    }
    return localizations;
  }

  /// ตรวจสอบว่าแอปกำลังแสดงผลเป็นภาษาไทยหรือไม่
  bool get isThai => Localizations.localeOf(this).languageCode == 'th';
}
