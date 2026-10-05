// ============================================================================
// 🌤️ BANTAWAN Weather & Air Quality Service: WeatherService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │         (Survival Environment & Hazard Awareness)       │
// ├─────────────────────────────────────────────────────────┤
// │                   WeatherService                        │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Open-Meteo Forecast  │ Open-Meteo Air Quality    │  │
// │  │ (Temp / Humidity/Wind │  (PM2.5 / PM10 / CO / O3) │  │
// │  │  Hourly & 7-Day Daily)│  Hourly Trends & AQI)     │  │
// │  └───────────────────────┴───────────────────────────┘  │
// │               FlutterLocalNotifications                 │
// │         (แจ้งเตือนฝุ่นเกินเกณฑ์ / พายุล่วงหน้า)         │
// └─────────────────────────────────────────────────────────┘
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ⏱️ โมเดลพยากรณ์สภาพอากาศรายชั่วโมง (Hourly Forecast Item)
class HourlyForecastItem {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;

  HourlyForecastItem({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  String get weatherIcon => WeatherData.getIconFromCode(weatherCode);
  String get conditionTh => WeatherData.getConditionTh(weatherCode);
}

/// 📅 โมเดลคาดการณ์สภาพอากาศรายวัน (Daily Forecast Item)
class DailyForecastItem {
  final DateTime date;
  final int weatherCode;
  final double minTemp;
  final double maxTemp;
  final int precipitationProbability;
  final double uvIndex;

  DailyForecastItem({
    required this.date,
    required this.weatherCode,
    required this.minTemp,
    required this.maxTemp,
    required this.precipitationProbability,
    required this.uvIndex,
  });

  String get weatherIcon => WeatherData.getIconFromCode(weatherCode);
  String get conditionTh => WeatherData.getConditionTh(weatherCode);

  String get dayNameTh {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'วันนี้';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'พรุ่งนี้';
    }
    switch (date.weekday) {
      case 1:
        return 'จันทร์';
      case 2:
        return 'อังคาร';
      case 3:
        return 'พุธ';
      case 4:
        return 'พฤหัส';
      case 5:
        return 'ศุกร์';
      case 6:
        return 'เสาร์';
      case 7:
        return 'อาทิตย์';
      default:
        return '';
    }
  }
}

/// 📦 โมเดลเก็บข้อมูลสภาพอากาศและคุณภาพอากาศแบบครบวงจร (WeatherData)
class WeatherData {
  /// 🌡️ อุณหภูมิปัจจุบัน (องศาเซลเซียส)
  final double temperature;

  /// 🌡️ ความรู้สึกเหมือน (Feels Like)
  final double apparentTemperature;

  /// 💧 ความชื้นสัมพัทธ์ในอากาศ (%)
  final int humidity;

  /// 💨 ความเร็วลม (กิโลเมตร/ชั่วโมง)
  final double windSpeed;

  /// 🧭 ความกดอากาศพื้นผิว (hPa)
  final double surfacePressure;

  /// 🌧️ ปริมาณน้ำฝนปัจจุบัน (mm)
  final double precipitation;

  /// ☀️ ดัชนีรังสี UV สูงสุดวันนี้
  final double uvIndex;

  /// ☀️ ระบุว่าเป็นเวลากลางวันหรือไม่
  final bool isDay;

  /// 🌅 เวลาพระอาทิตย์ขึ้น (เช่น "06:12")
  final String sunrise;

  /// 🌇 เวลาพระอาทิตย์ตก (เช่น "18:24")
  final String sunset;

  /// 🌦️ รหัสสภาพอากาศตามมาตรฐาน WMO (0=แจ่มใส, 95+=พายุฝนฟ้าคะนอง)
  final int weatherCode;

  /// 💨 ระดับฝุ่นละเอียด PM2.5 ปัจจุบัน (µg/m³)
  final double pm25;

  /// 💨 ระดับฝุ่น PM10 ปัจจุบัน (µg/m³)
  final double pm10;

  /// 🏭 ระดับก๊าซคาร์บอนมอนอกไซด์ CO (µg/m³)
  final double co;

  /// 🚗 ระดับก๊าซไนโตรเจนไดออกไซด์ NO2 (µg/m³)
  final double no2;

  /// ☀️ ระดับโอโซนพื้นดิน O3 (µg/m³)
  final double o3;

  /// 📊 ข้อมูล PM2.5 รายชั่วโมง (24 ชั่วโมง) สำหรับกราฟแนวโน้ม
  final List<double> hourlyPm25;

  /// 📊 รหัสสภาพอากาศรายชั่วโมง (24 ชั่วโมง) สำหรับตรวจพายุ
  final List<int> hourlyWeatherCode;

  /// ⏱️ รายการพยากรณ์อากาศรายชั่วโมง 24 ชั่วโมงข้างหน้า
  final List<HourlyForecastItem> hourlyForecast;

  /// 📅 รายการคาดการณ์สภาพอากาศ 7 วันล่วงหน้า
  final List<DailyForecastItem> dailyForecast;

  /// 🏷️ ระดับคุณภาพอากาศโดยรวม: 'ปกติ', 'ปานกลาง', 'เริ่มมีผลต่อสุขภาพ', 'อันตราย'
  String status;

  /// 📝 ข้อความอธิบายสภาพอากาศและคุณภาพอากาศ
  String description;

  /// 📌 คำนวณค่าดัชนีคุณภาพอากาศ AQI (Air Quality Index) จาก PM2.5
  double get aqiValue {
    if (pm25 <= 12) return (pm25 * 50 / 12);
    if (pm25 <= 35.4) return (pm25 - 12.1) * (100 - 51) / (35.4 - 12.1) + 51;
    if (pm25 <= 55.4) return (pm25 - 35.5) * (150 - 101) / (55.4 - 35.5) + 101;
    if (pm25 <= 150.4) return (pm25 - 55.5) * (200 - 151) / (150.4 - 55.5) + 151;
    return 250;
  }

  /// 📌 ประเมินจำนวนอนุภาคฝุ่นโดยประมาณสำหรับ Particle Animation
  int get particleCount {
    if (pm25 > 50) return 80;
    if (pm25 > 25) return 40;
    return 15;
  }

  /// 📌 คำอธิบายสภาพอากาศภาษาไทยตามรหัส WMO
  String get weatherConditionTh => getConditionTh(weatherCode);

  /// 📌 ไอคอน Emoji สภาพอากาศ
  String get weatherIcon => getIconFromCode(weatherCode, isDay: isDay);

  WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.surfacePressure,
    required this.precipitation,
    required this.uvIndex,
    required this.isDay,
    required this.sunrise,
    required this.sunset,
    required this.weatherCode,
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.o3,
    required this.hourlyPm25,
    required this.hourlyWeatherCode,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.status,
    required this.description,
  });

  /// 📌 แปลงรหัสสภาพอากาศ WMO ให้เป็นข้อความภาษาไทย
  static String getConditionTh(int code) {
    switch (code) {
      case 0:
        return 'แจ่มใส ท้องฟ้าโปร่ง';
      case 1:
        return 'โปร่ง มีเมฆเล็กน้อย';
      case 2:
        return 'มีเมฆบางส่วน';
      case 3:
        return 'มีเมฆมาก มืดครึ้ม';
      case 45:
      case 48:
        return 'มีหมอกปกคลุม';
      case 51:
      case 53:
      case 55:
        return 'ฝนละอองปรอยๆ';
      case 56:
      case 57:
        return 'ฝนละอองเย็นจัด';
      case 61:
        return 'ฝนตกเล็กน้อย';
      case 63:
        return 'ฝนตกปานกลาง';
      case 65:
        return 'ฝนตกหนัก';
      case 66:
      case 67:
        return 'ฝนเยือกแข็ง';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'หิมะตก';
      case 80:
      case 81:
        return 'ฝนซู่กระจาย';
      case 82:
        return 'ฝนตกหนักรุนแรง';
      case 85:
      case 86:
        return 'พายุหิมะ';
      case 95:
        return 'พายุฝนฟ้าคะนอง';
      case 96:
      case 99:
        return 'พายุฝนฟ้าคะนองพร้อมลูกเห็บ';
      default:
        return 'สภาพอากาศแปรปรวน';
    }
  }

  /// 📌 แปลงรหัสสภาพอากาศ WMO ให้เป็น Emoji Icon
  static String getIconFromCode(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return isDay ? '☀️' : '🌙';
      case 1:
        return isDay ? '🌤️' : '🌤️';
      case 2:
        return isDay ? '⛅' : '☁️';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
        return '🌦️';
      case 61:
      case 63:
        return '🌧️';
      case 65:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
        return '❄️';
      case 80:
      case 81:
        return '🌦️';
      case 82:
        return '⛈️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }
}

/// 🏛️ คลาสบริการดึงข้อมูลพยากรณ์อากาศและตรวจสอบคุณภาพอากาศ (WeatherService)
class WeatherService {
  /// 🔔 Plugin สำหรับแสดง Local Notification เมื่อตรวจพบภัยอากาศ
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================================
  // 🚀 Section 1: Initialization
  // ============================================================================

  /// 📌 เริ่มต้นระบบ Local Notification สำหรับแจ้งเตือนภัยอากาศและฝุ่น
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  // ============================================================================
  // 🌐 Section 2: API Data Fetching (Parallel Requests)
  // ============================================================================

  /// 📌 ดึงข้อมูลพยากรณ์อากาศ คาดการณ์ล่วงหน้า และคุณภาพอากาศ ณ พิกัดที่กำหนด
  static Future<WeatherData?> getRealTimeWeather(double lat, double lon) async {
    try {
      // 1. URL สำหรับ Open-Meteo Forecast API (ปัจจุบัน, รายชั่วโมง 24 ชม., รายวัน 7 วัน)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m'
        '&hourly=temperature_2m,precipitation_probability,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max,sunrise,sunset'
        '&timezone=auto'
        '&forecast_days=7',
      );

      // 2. URL สำหรับ Open-Meteo Air Quality API (PM2.5, PM10, CO, NO2, O3)
      final aqiUrl = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?'
        'latitude=$lat&longitude=$lon'
        '&current=pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,ozone,us_aqi'
        '&hourly=pm2_5'
        '&timezone=auto'
        '&forecast_days=1',
      );

      // 3. ยิงทั้งสองคำขอพร้อมกันด้วย Future.wait เพื่อความรวดเร็ว
      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(aqiUrl),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final weatherJson = jsonDecode(responses[0].body);
        final aqiJson = jsonDecode(responses[1].body);

        // 4. แยกข้อมูลสภาพอากาศปัจจุบัน
        final current = weatherJson['current'] ?? {};
        final double temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final double apparentTemp = (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
        final int humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 70;
        final double wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
        final double pressure = (current['surface_pressure'] as num?)?.toDouble() ?? 1012.0;
        final double precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
        final int code = (current['weather_code'] as num?)?.toInt() ?? 0;
        final bool isDay = (current['is_day'] as num?)?.toInt() == 1;

        // 5. แยกข้อมูลคุณภาพอากาศปัจจุบัน
        final currentAqi = aqiJson['current'] ?? {};
        final double pm2 = (currentAqi['pm2_5'] as num?)?.toDouble() ?? 15.0;
        final double pm10Val = (currentAqi['pm10'] as num?)?.toDouble() ?? 25.0;
        final double co = (currentAqi['carbon_monoxide'] as num?)?.toDouble() ?? 200.0;
        final double no2 = (currentAqi['nitrogen_dioxide'] as num?)?.toDouble() ?? 10.0;
        final double o3 = (currentAqi['ozone'] as num?)?.toDouble() ?? 40.0;

        // 6. แยกข้อมูล PM2.5 รายชั่วโมง (24 ค่า)
        List<double> hourlyPm25 = [];
        if (aqiJson['hourly'] != null && aqiJson['hourly']['pm2_5'] != null) {
          hourlyPm25 = (aqiJson['hourly']['pm2_5'] as List)
              .take(24)
              .map((e) => (e as num).toDouble())
              .toList();
        }

        // 7. แยกรหัสสภาพอากาศรายชั่วโมง (hourly weather codes)
        List<int> hourlyCode = [];
        if (weatherJson['hourly'] != null &&
            weatherJson['hourly']['weather_code'] != null) {
          hourlyCode = (weatherJson['hourly']['weather_code'] as List)
              .map((e) => (e as num).toInt())
              .toList();
        }

        // 8. สร้างรายการ Hourly Forecast สำหรับ 24 ชม. ถัดจากชั่วโมงปัจจุบัน
        final List<HourlyForecastItem> hourlyForecast = [];
        if (weatherJson['hourly'] != null) {
          final hTimes = weatherJson['hourly']['time'] as List? ?? [];
          final hTemps = weatherJson['hourly']['temperature_2m'] as List? ?? [];
          final hProbs = weatherJson['hourly']['precipitation_probability'] as List? ?? [];
          final hCodes = weatherJson['hourly']['weather_code'] as List? ?? [];

          final currentHour = DateTime.now().hour;
          final int startIndex = currentHour.clamp(0, hTimes.length - 1);
          final int count = (hTimes.length - startIndex).clamp(0, 24);

          for (int i = 0; i < count; i++) {
            final idx = startIndex + i;
            final timeStr = hTimes[idx].toString();
            final parsedTime = DateTime.tryParse(timeStr) ?? DateTime.now().add(Duration(hours: i));
            final tVal = (hTemps.length > idx ? (hTemps[idx] as num).toDouble() : temp);
            final pVal = (hProbs.length > idx ? (hProbs[idx] as num).toInt() : 0);
            final cVal = (hCodes.length > idx ? (hCodes[idx] as num).toInt() : code);

            hourlyForecast.add(HourlyForecastItem(
              time: parsedTime,
              temperature: tVal,
              precipitationProbability: pVal,
              weatherCode: cVal,
            ));
          }
        }

        // 9. สร้างรายการ Daily Forecast 7 วัน
        final List<DailyForecastItem> dailyForecast = [];
        String sunriseStr = '--:--';
        String sunsetStr = '--:--';
        double uvIndexToday = 5.0;

        if (weatherJson['daily'] != null) {
          final d = weatherJson['daily'];
          final dTimes = d['time'] as List? ?? [];
          final dCodes = d['weather_code'] as List? ?? [];
          final dMaxTemps = d['temperature_2m_max'] as List? ?? [];
          final dMinTemps = d['temperature_2m_min'] as List? ?? [];
          final dRainProbs = d['precipitation_probability_max'] as List? ?? [];
          final dUvs = d['uv_index_max'] as List? ?? [];
          final dSunrises = d['sunrise'] as List? ?? [];
          final dSunsets = d['sunset'] as List? ?? [];

          if (dSunrises.isNotEmpty && dSunrises[0] != null) {
            final sTime = DateTime.tryParse(dSunrises[0].toString());
            if (sTime != null) {
              sunriseStr = '${sTime.hour.toString().padLeft(2, '0')}:${sTime.minute.toString().padLeft(2, '0')}';
            }
          }
          if (dSunsets.isNotEmpty && dSunsets[0] != null) {
            final sTime = DateTime.tryParse(dSunsets[0].toString());
            if (sTime != null) {
              sunsetStr = '${sTime.hour.toString().padLeft(2, '0')}:${sTime.minute.toString().padLeft(2, '0')}';
            }
          }
          if (dUvs.isNotEmpty && dUvs[0] != null) {
            uvIndexToday = (dUvs[0] as num).toDouble();
          }

          for (int i = 0; i < dTimes.length; i++) {
            final date = DateTime.tryParse(dTimes[i].toString()) ?? DateTime.now().add(Duration(days: i));
            final wCode = (dCodes.length > i ? (dCodes[i] as num).toInt() : code);
            final minT = (dMinTemps.length > i ? (dMinTemps[i] as num).toDouble() : temp - 3);
            final maxT = (dMaxTemps.length > i ? (dMaxTemps[i] as num).toDouble() : temp + 4);
            final rProb = (dRainProbs.length > i ? (dRainProbs[i] as num).toInt() : 0);
            final uv = (dUvs.length > i ? (dUvs[i] as num).toDouble() : 5.0);

            dailyForecast.add(DailyForecastItem(
              date: date,
              weatherCode: wCode,
              minTemp: minT,
              maxTemp: maxT,
              precipitationProbability: rProb,
              uvIndex: uv,
            ));
          }
        }

        // 10. ประเมินระดับอันตรายของฝุ่น PM2.5 และสร้างข้อความสถานะ
        String status = "ปกติ";
        String desc = "อากาศแจ่มใส";

        if (pm2 > 50) {
          status = "อันตราย";
          desc = "ค่าฝุ่น PM 2.5 สูง ($pm2 µg/m³)";
        } else if (pm2 > 35) {
          status = "เริ่มมีผลต่อสุขภาพ";
          desc = "เริ่มมีผลต่อสุขภาพ ($pm2 µg/m³)";
        } else if (pm2 > 25) {
          status = "ปานกลาง";
          desc = "คุณภาพอากาศปานกลาง ($pm2 µg/m³)";
        } else {
          status = "ปกติ";
          desc = "คุณภาพอากาศดี ($pm2 µg/m³)";
        }

        return WeatherData(
          temperature: temp,
          apparentTemperature: apparentTemp,
          humidity: humidity,
          windSpeed: wind,
          surfacePressure: pressure,
          precipitation: precip,
          uvIndex: uvIndexToday,
          isDay: isDay,
          sunrise: sunriseStr,
          sunset: sunsetStr,
          weatherCode: code,
          pm25: pm2,
          pm10: pm10Val,
          co: co,
          no2: no2,
          o3: o3,
          hourlyPm25: hourlyPm25,
          hourlyWeatherCode: hourlyCode,
          hourlyForecast: hourlyForecast,
          dailyForecast: dailyForecast,
          status: status,
          description: desc,
        );
      }
    } catch (e) {
      debugPrint('Weather API Error: $e');
    }
    return null;
  }

  // ============================================================================
  // 🔔 Section 3: Hazard Alert & Notification
  // ============================================================================

  /// 📌 ตรวจสอบข้อมูลสภาพอากาศและออก Local Notification เมื่อตรวจพบภัยอากาศ
  static Future<void> checkAndNotify(WeatherData data) async {
    if (data.pm25 > 50) {
      await _showNotification(
        id: 101,
        title: '⚠️ เตือนภัยฝุ่น PM 2.5',
        body: 'ค่าฝุ่นสูง ${data.pm25} µg/m³ ควรใส่หน้ากาก N95 และงดกิจกรรมกลางแจ้ง',
      );
    }

    final nowHour = DateTime.now().hour;
    if (data.hourlyWeatherCode.length > nowHour + 2) {
      final nextCode1 = data.hourlyWeatherCode[nowHour + 1];
      final nextCode2 = data.hourlyWeatherCode[nowHour + 2];

      if (_isSevere(nextCode1) || _isSevere(nextCode2)) {
        await _showNotification(
          id: 102,
          title: '🌧️ เตือนภัยสภาพอากาศ',
          body: 'คาดว่าจะมีพายุหรือฝนตกหนักในอีก 1-2 ชั่วโมงข้างหน้า',
        );
      }
    }
  }

  /// 📌 ตรวจสอบว่ารหัส WMO Weather Code หมายถึงสภาพอากาศรุนแรงหรือไม่
  static bool _isSevere(int code) {
    return [65, 82, 95, 96, 99].contains(code);
  }

  // ============================================================================
  // 🔔 Section 4: Local Notification Helper
  // ============================================================================

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_alert_channel',
      'Weather Alerts',
      channelDescription: 'Notifications for severe weather and air quality',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }
}
