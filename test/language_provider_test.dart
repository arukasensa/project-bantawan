import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter1/features/home/services/language_service.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider & Offline Mesh Localization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with default locale (th)', () async {
      final provider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.appLocale.languageCode, 'th');
    });

    test('loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'selected_language': 'en'});

      final provider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.appLocale.languageCode, 'en');
    });

    test('changeLanguage switches locale and notifies listeners', () async {
      final provider = LanguageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      await provider.changeLanguage(const Locale('en'));
      expect(provider.appLocale.languageCode, 'en');
      expect(notificationCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_language'), 'en');

      // Changing to same locale should not notify
      await provider.changeLanguage(const Locale('en'));
      expect(notificationCount, 1);

      // Switching back to th
      await provider.changeLanguage(const Locale('th'));
      expect(provider.appLocale.languageCode, 'th');
      expect(notificationCount, 2);
      expect(prefs.getString('selected_language'), 'th');
    });

    test('AppLocalizations has offline mesh translations for Thai', () {
      final l10nTh = lookupAppLocalizations(const Locale('th'));

      expect(l10nTh.appTitle, 'BANTAWAN');
      expect(l10nTh.carrierBag, 'กระเป๋าคนส่งสาร');
      expect(l10nTh.offlineBagEmpty, 'ยังไม่มีซองจดหมายในกระเป๋า');
      expect(l10nTh.selectCarrier, 'เลือกคนส่งสาร (Data Mule)');
      expect(l10nTh.dispatchAllConnected, 'ฝากทุกคนที่เชื่อมต่อ');
      expect(l10nTh.meshRelayTitle, 'บริดจ์และการส่งต่อทอด (Mesh Relay)');
      expect(l10nTh.meshRelayDesc, 'ส่งต่อแพ็กเก็ตข้อความและ SOS ข้ามโหนดในรัศมีบลูทูธแบบ Multi-hop');
      expect(l10nTh.dataMuleTitle, 'คนส่งสารฉุกเฉิน (Data Mule)');
      expect(l10nTh.dataMuleDesc, 'ฝากส่งข้อความผ่านอุปกรณ์คนอื่นเมื่ออยู่นอกระยะสัญญาณ');
      expect(l10nTh.tacticalCallsign, 'นามเรียกขาน (@callsign)');
      expect(l10nTh.changeCallsign, 'เปลี่ยนชื่อ');
      expect(l10nTh.appLanguage, 'ภาษาของแอป');
      expect(l10nTh.autoPlayVoice, 'เล่นเสียงอัตโนมัติ');
      expect(l10nTh.systemInfo, 'ข้อมูลสถาปัตยกรรมระบบ');
      expect(l10nTh.settingsTab, 'ตั้งค่า');
      expect(l10nTh.infoTab, 'ข้อมูล');
      expect(l10nTh.tabPublic, 'สาธารณะ');
      expect(l10nTh.tabPrivate, 'ส่วนตัว');
      expect(l10nTh.onlinePeers, 'โหนดในรัศมี');
    });

    test('AppLocalizations has offline mesh translations for English', () {
      final l10nEn = lookupAppLocalizations(const Locale('en'));

      expect(l10nEn.appTitle, 'BANTAWAN');
      expect(l10nEn.carrierBag, 'Courier Tactical Bag');
      expect(l10nEn.offlineBagEmpty, 'Your tactical bag is currently empty');
      expect(l10nEn.selectCarrier, 'Select Carrier (Data Mule)');
      expect(l10nEn.dispatchAllConnected, 'Dispatch to All Connected');
      expect(l10nEn.meshRelayTitle, 'Mesh Relay & Bridging');
      expect(l10nEn.meshRelayDesc, 'Multi-hop message and SOS forwarding across Bluetooth nodes');
      expect(l10nEn.dataMuleTitle, 'Emergency Data Mule');
      expect(l10nEn.dataMuleDesc, 'Store-carry-and-forward messages via passing peers when out of range');
      expect(l10nEn.tacticalCallsign, 'Tactical Callsign');
      expect(l10nEn.changeCallsign, 'Change Callsign');
      expect(l10nEn.appLanguage, 'App Language');
      expect(l10nEn.autoPlayVoice, 'Auto-play Voice Messages');
      expect(l10nEn.systemInfo, 'System Architecture & Info');
      expect(l10nEn.settingsTab, 'Settings');
      expect(l10nEn.infoTab, 'Info');
      expect(l10nEn.tabPublic, 'Public');
      expect(l10nEn.tabPrivate, 'Private');
      expect(l10nEn.onlinePeers, 'Nearby Nodes');
    });
  });
}
