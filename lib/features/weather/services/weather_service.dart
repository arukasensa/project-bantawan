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
// │  │ (Temp / Weather Code) │  (PM2.5 / CO / NO2 / O3) │  │
// │  └───────────────────────┴───────────────────────────┘  │
// │               FlutterLocalNotifications                 │
// │         (แจ้งเตือนฝุ่นเกินเกณฑ์ / พายุล่วงหน้า)         │
// └─────────────────────────────────────────────────────────┘
// 
// บริการพยากรณ์สภาพอากาศและดัชนีคุณภาพอากาศ (Weather & Air Quality Service)
// ดึงข้อมูลจาก Open-Meteo API แบบ Parallel สองคำขอพร้อมกัน:
//   1. Weather Forecast: อุณหภูมิ, WMO Weather Code, และรหัสพยากรณ์รายชั่วโมง
//   2. Air Quality: PM2.5, CO, NO2, O3 ทั้งค่าปัจจุบันและรายชั่วโมง
// คำนวณค่า AQI และออก Local Notification เตือนภัยเมื่อมลพิษหรือสภาพอากาศเกินเกณฑ์
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 📦 โมเดลเก็บข้อมูลสภาพอากาศและคุณภาพอากาศปัจจุบัน (WeatherData)
class WeatherData {
  /// 🌡️ อุณหภูมิปัจจุบัน (องศาเซลเซียส)
  final double temperature;

  /// 🌦️ รหัสสภาพอากาศตามมาตรฐาน WMO (0=แจ่มใส, 95+=พายุฝนฟ้าคะนอง)
  final int weatherCode;

  /// 💨 ระดับฝุ่นละเอียด PM2.5 ปัจจุบัน (µg/m³) — เกณฑ์ WHO คือ 15 µg/m³
  final double pm25;

  /// 🏭 ระดับก๊าซคาร์บอนมอนอกไซด์ CO (µg/m³) — เป็นพิษต่อระบบเลือด
  final double co;

  /// 🚗 ระดับก๊าซไนโตรเจนไดออกไซด์ NO2 (µg/m³) — มาจากไอเสียรถยนต์
  final double no2;

  /// ☀️ ระดับโอโซนพื้นดิน O3 (µg/m³) — ระคายเคืองระบบหายใจ
  final double o3;

  /// 📊 ข้อมูล PM2.5 รายชั่วโมง (24 ชั่วโมง) สำหรับกราฟแนวโน้ม
  final List<double> hourlyPm25;

  /// 📊 รหัสสภาพอากาศรายชั่วโมง (24 ชั่วโมง) สำหรับพยากรณ์ล่วงหน้า
  final List<int> hourlyWeatherCode;

  /// 🏷️ ระดับคุณภาพอากาศโดยรวม: 'ปกติ', 'ปานกลาง', 'อันตราย'
  String status;

  /// 📝 ข้อความอธิบายสภาพอากาศและคุณภาพอากาศสำหรับแสดงใน UI
  String description;

  /// 📌 คำนวณค่าดัชนีคุณภาพอากาศ AQI (Air Quality Index) จาก PM2.5
  /// ใช้สูตร EPA Linear Interpolation แบบ Simplified สำหรับแสดงบน UI
  double get aqiValue {
    if (pm25 <= 12) return (pm25 * 50 / 12);              // ดี (0-50)
    if (pm25 <= 35.4) return (pm25 - 12.1) * (100 - 51) / (35.4 - 12.1) + 51; // ปานกลาง (51-100)
    if (pm25 <= 55.4) return (pm25 - 35.5) * (150 - 101) / (55.4 - 35.5) + 101; // ไม่ดีต่อกลุ่มเสี่ยง (101-150)
    return 200; // อันตราย (> 150)
  }

  /// 📌 ประเมินจำนวนอนุภาคฝุ่นโดยประมาณสำหรับ Particle Animation ใน UI
  int get particleCount {
    if (pm25 > 50) return 80;  // ฝุ่นหนักมาก: แสดงอนุภาคเยอะ
    if (pm25 > 25) return 40;  // ฝุ่นปานกลาง
    return 15;                  // อากาศดี: อนุภาคน้อย
  }

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.pm25,
    required this.co,
    required this.no2,
    required this.o3,
    required this.hourlyPm25,
    required this.hourlyWeatherCode,
    required this.status,
    required this.description,
  });

  /// 📌 แปลงรหัสสภาพอากาศ WMO ให้เป็น Emoji Icon สำหรับแสดงใน UI
  String get weatherIcon {
    if (weatherCode <= 3) return '☀️';   // 0-3: แจ่มใสถึงมีเมฆบ้าง
    if (weatherCode <= 48) return '☁️';  // 4-48: มีเมฆมากถึงหมอก
    if (weatherCode <= 67) return '🌧️'; // 49-67: ฝนปรอย-ฝนหนัก
    if (weatherCode <= 77) return '❄️';  // 68-77: หิมะ/ลูกเห็บ
    if (weatherCode <= 82) return '⛈️'; // 78-82: ฝนหนักมาก
    return '⛈️';                          // 83+: พายุฝนฟ้าคะนอง
  }
}

/// 🏛️ คลาสบริการดึงข้อมูลพยากรณ์อากาศและตรวจสอบคุณภาพอากาศ (WeatherService)
/// ทุกเมธอดเป็น static เรียกใช้ได้ทันทีโดยไม่ต้องสร้างอินสแตนซ์
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

  /// 📌 ดึงข้อมูลพยากรณ์อากาศและคุณภาพอากาศ ณ พิกัดที่กำหนดแบบ Parallel
  /// - [lat]: ละติจูดของตำแหน่งที่ต้องการตรวจสอบ
  /// - [lon]: ลองจิจูดของตำแหน่งที่ต้องการตรวจสอบ
  /// ส่งคืนอ็อบเจกต์ [WeatherData] หรือ null หาก API ไม่ตอบสนอง
  static Future<WeatherData?> getRealTimeWeather(double lat, double lon) async {
    try {
      // 1. สร้าง URL สำหรับ Open-Meteo Forecast API (อุณหภูมิ + รหัสอากาศรายชั่วโมง)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&hourly=weather_code&forecast_days=1',
      );

      // 2. สร้าง URL สำหรับ Open-Meteo Air Quality API (PM2.5, CO, NO2, O3)
      final aqiUrl = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=pm2_5,carbon_monoxide,nitrogen_dioxide,ozone&hourly=pm2_5&forecast_days=1',
      );

      // 3. ยิงทั้งสองคำขอพร้อมกันด้วย Future.wait เพื่อลดเวลาโหลดรวม
      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(aqiUrl),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final weatherJson = jsonDecode(responses[0].body);
        final aqiJson = jsonDecode(responses[1].body);

        // 4. แยกข้อมูลสภาพอากาศปัจจุบัน
        final double temp = weatherJson['current']['temperature_2m'].toDouble();
        final int code = weatherJson['current']['weather_code'];

        // 5. แยกข้อมูลคุณภาพอากาศปัจจุบัน
        final currentAqi = aqiJson['current'];
        final double pm2 = currentAqi['pm2_5'].toDouble();
        final double co = currentAqi['carbon_monoxide'].toDouble();
        final double no2 = currentAqi['nitrogen_dioxide'].toDouble();
        final double o3 = currentAqi['ozone'].toDouble();

        // 6. แยกข้อมูล PM2.5 รายชั่วโมง สำหรับกราฟแนวโน้ม
        List<double> hourlyPm25 = [];
        if (aqiJson['hourly'] != null && aqiJson['hourly']['pm2_5'] != null) {
          hourlyPm25 = (aqiJson['hourly']['pm2_5'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
        }

        // 7. แยกรหัสสภาพอากาศรายชั่วโมง สำหรับตรวจพายุล่วงหน้า
        List<int> hourlyCode = [];
        if (weatherJson['hourly'] != null &&
            weatherJson['hourly']['weather_code'] != null) {
          hourlyCode = (weatherJson['hourly']['weather_code'] as List)
              .map((e) => (e as num).toInt())
              .toList();
        }

        // 8. ประเมินระดับอันตรายของฝุ่น PM2.5 และสร้างข้อความสถานะ
        String status = "ปกติ";
        String desc = "อากาศแจ่มใส";

        if (pm2 > 50) {
          status = "อันตราย";
          desc = "ค่าฝุ่น PM 2.5 สูง ($pm2 µg/m³)";
        } else if (pm2 > 25) {
          status = "ปานกลาง";
          desc = "เริ่มมีผลต่อสุขภาพ ($pm2 µg/m³)";
        } else {
          desc = "คุณภาพอากาศดี ($pm2 µg/m³)";
        }

        return WeatherData(
          temperature: temp,
          weatherCode: code,
          pm25: pm2,
          co: co,
          no2: no2,
          o3: o3,
          hourlyPm25: hourlyPm25,
          hourlyWeatherCode: hourlyCode,
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
  /// - ตรวจสอบ PM2.5 > 50 µg/m³ (อันตรายต่อสุขภาพ)
  /// - ตรวจสอบรหัสพายุในอีก 1-2 ชั่วโมงข้างหน้า
  static Future<void> checkAndNotify(WeatherData data) async {
    // 1. แจ้งเตือนหากค่า PM2.5 เกินเกณฑ์อันตราย (> 50 µg/m³)
    if (data.pm25 > 50) {
      await _showNotification(
        id: 101,
        title: '⚠️ เตือนภัยฝุ่น PM 2.5',
        body:
            'ค่าฝุ่นสูง ${data.pm25} µg/m³ ควรใส่หน้ากาก N95 และงดกิจกรรมกลางแจ้ง',
      );
    }

    // 2. ตรวจสอบสภาพอากาศรุนแรงในอีก 1-2 ชั่วโมง โดยดูจาก hourlyWeatherCode
    // Open-Meteo ส่งข้อมูลรายชั่วโมงเรียงจาก 00:00 → ใช้ DateTime.now().hour เป็น Index ปัจจุบัน
    final nowHour = DateTime.now().hour;
    if (data.hourlyWeatherCode.length > nowHour + 2) {
      final nextCode1 = data.hourlyWeatherCode[nowHour + 1]; // อีก 1 ชั่วโมง
      final nextCode2 = data.hourlyWeatherCode[nowHour + 2]; // อีก 2 ชั่วโมง

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
  /// - รหัสที่ถือว่าอันตราย: 65=ฝนหนัก, 82=ฝนเทกระหน่ำ, 95=พายุ, 96/99=พายุลูกเห็บ
  static bool _isSevere(int code) {
    return [65, 82, 95, 96, 99].contains(code);
  }

  // ============================================================================
  // 🔔 Section 4: Local Notification Helper
  // ============================================================================

  /// 📌 แสดง Local Push Notification ฉุกเฉินด้วยความสำคัญสูงสุด (High Priority)
  /// - [id]: ID ของ Notification (ป้องกันการแสดงซ้ำ)
  /// - [title]: หัวข้อการแจ้งเตือน
  /// - [body]: เนื้อหาการแจ้งเตือน
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'weather_alert_channel',         // Channel ID
          'Weather Alerts',                // ชื่อช่องการแจ้งเตือน
          channelDescription:
              'Notifications for severe weather and air quality',
          importance: Importance.max,      // แสดงบนสุดของหน้าจอ
          priority: Priority.high,         // ความสำคัญสูงสุด
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(id, title, body, details);
  }
}
