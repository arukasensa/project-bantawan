import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'package:flutter1/features/weather/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Bilingual Localization Coverage Tests (Thai & English Parity)', () {
    final l10nTh = lookupAppLocalizations(const Locale('th'));
    final l10nEn = lookupAppLocalizations(const Locale('en'));

    test('Core Navigation & App Keys Parity', () {
      expect(l10nTh.appTitle, isNotEmpty);
      expect(l10nEn.appTitle, isNotEmpty);

      expect(l10nTh.navHome, 'หน้าหลัก');
      expect(l10nEn.navHome, 'Home');

      expect(l10nTh.navFirstAid, 'ปฐมพยาบาล');
      expect(l10nEn.navFirstAid, 'First Aid');

      expect(l10nTh.navSOS, 'ฉุกเฉิน');
      expect(l10nEn.navSOS, 'SOS');

      expect(l10nTh.navMap, 'แผนที่');
      expect(l10nEn.navMap, 'Map');

      expect(l10nTh.navProfile, 'โปรไฟล์');
      expect(l10nEn.navProfile, 'Profile');
    });

    test('Home Screen & HUD Status Keys Parity', () {
      expect(l10nTh.greetingAfternoon, isNotEmpty);
      expect(l10nEn.greetingAfternoon, isNotEmpty);

      expect(l10nTh.safetyStatusNormal, isNotEmpty);
      expect(l10nEn.safetyStatusNormal, isNotEmpty);

      expect(l10nTh.forecast24h7d, isNotEmpty);
      expect(l10nEn.forecast24h7d, isNotEmpty);

      expect(l10nTh.deviceHealthTitle, isNotEmpty);
      expect(l10nEn.deviceHealthTitle, isNotEmpty);

      expect(l10nTh.batteryLabel, isNotEmpty);
      expect(l10nEn.batteryLabel, isNotEmpty);

      expect(l10nTh.gpsSignalLabel, isNotEmpty);
      expect(l10nEn.gpsSignalLabel, isNotEmpty);

      expect(l10nTh.meshNodesLabel, isNotEmpty);
      expect(l10nEn.meshNodesLabel, isNotEmpty);

      expect(l10nTh.bloodTypePrefix, isNotEmpty);
      expect(l10nEn.bloodTypePrefix, isNotEmpty);
    });

    test('Survival Tools & Scenarios Keys Parity', () {
      expect(l10nTh.floodTitle, isNotEmpty);
      expect(l10nEn.floodTitle, isNotEmpty);

      expect(l10nTh.fireTitle, isNotEmpty);
      expect(l10nEn.fireTitle, isNotEmpty);

      expect(l10nTh.earthquakeTitle, isNotEmpty);
      expect(l10nEn.earthquakeTitle, isNotEmpty);

      expect(l10nTh.lostTitle, isNotEmpty);
      expect(l10nEn.lostTitle, isNotEmpty);

      expect(l10nTh.survivalTitle, isNotEmpty);
      expect(l10nEn.survivalTitle, isNotEmpty);

      expect(l10nTh.urgentSosTitle, isNotEmpty);
      expect(l10nEn.urgentSosTitle, isNotEmpty);
    });

    test('Hike Mode & Backtrack Keys Parity', () {
      expect(l10nTh.backtrackArrived, isNotEmpty);
      expect(l10nEn.backtrackArrived, isNotEmpty);

      expect(l10nTh.backtrackBasecamp, isNotEmpty);
      expect(l10nEn.backtrackBasecamp, isNotEmpty);

      expect(l10nTh.hikeExitDialogTitle, isNotEmpty);
      expect(l10nEn.hikeExitDialogTitle, isNotEmpty);

      expect(l10nTh.endHikeBtn, isNotEmpty);
      expect(l10nEn.endHikeBtn, isNotEmpty);

      expect(l10nTh.hikeResumeBtn, isNotEmpty);
      expect(l10nEn.hikeResumeBtn, isNotEmpty);
    });

    test('Peer Verification & Security Keys Parity', () {
      expect(l10nTh.myFingerprintTitle, isNotEmpty);
      expect(l10nEn.myFingerprintTitle, isNotEmpty);

      expect(l10nTh.fingerprintCopied, isNotEmpty);
      expect(l10nEn.fingerprintCopied, isNotEmpty);

      expect(l10nTh.verifiedSuccess, isNotEmpty);
      expect(l10nEn.verifiedSuccess, isNotEmpty);

      expect(l10nTh.resetTrust, isNotEmpty);
      expect(l10nEn.resetTrust, isNotEmpty);
    });

    test('WeatherService Bilingual Support', () {
      // Code 0 = Clear Sky
      expect(WeatherService.getConditionTh(0), 'แจ่มใส ท้องฟ้าโปร่ง');
      expect(WeatherService.getConditionEn(0), 'Clear Sky');
      expect(WeatherService.getCondition(0, true), 'แจ่มใส ท้องฟ้าโปร่ง');
      expect(WeatherService.getCondition(0, false), 'Clear Sky');

      // Code 95 = Thunderstorm
      expect(WeatherService.getConditionTh(95), 'พายุฝนฟ้าคะนอง');
      expect(WeatherService.getConditionEn(95), 'Thunderstorm');
      expect(WeatherService.getCondition(95, true), 'พายุฝนฟ้าคะนอง');
      expect(WeatherService.getCondition(95, false), 'Thunderstorm');
    });

    test('DailyForecastItem Bilingual Support', () {
      final now = DateTime.now();
      final daily = DailyForecastItem(
        date: now,
        weatherCode: 0,
        minTemp: 24.0,
        maxTemp: 32.0,
        precipitationProbability: 10,
        uvIndex: 8.0,
      );

      expect(daily.getDayName(true), 'วันนี้');
      expect(daily.getDayName(false), 'Today');
      expect(daily.getCondition(true), 'แจ่มใส ท้องฟ้าโปร่ง');
      expect(daily.getCondition(false), 'Clear Sky');
    });
  });
}
