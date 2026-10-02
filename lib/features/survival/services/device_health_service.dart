// บริการตรวจวัดสุขภาพและสถานะอุปกรณ์ (Device Health & Diagnostics Service)
// ติดตามระดับแบตเตอรี่, ตรวจสอบสถานะการเปิดใช้งาน GPS,
// และแจ้งเตือนผู้ใช้เมื่อแบตเตอรี่เหลือน้อยเพื่อประหยัดพลังงานในสถานการณ์ฉุกเฉิน

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// คลาสบริการตรวจสอบสถานะฮาร์ดแวร์ของเครื่อง (แบตเตอรี่และ GPS)
class DeviceHealthService extends ChangeNotifier {
  static final DeviceHealthService _instance = DeviceHealthService._internal();
  factory DeviceHealthService() => _instance;
  DeviceHealthService._internal();

  final Battery _battery = Battery();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<BatteryState>? _batterySubscription;
  StreamSubscription<ServiceStatus>? _gpsSubscription;

  /// ธงป้องกันการแจ้งเตือนแบตเตอรี่ต่ำซ้ำซ้อน
  bool _hasNotifiedLowBattery = false;

  /// ธงป้องกันการแจ้งเตือน GPS ปิดซ้ำซ้อน
  bool _hasNotifiedGpsDisabled = false;

  /// ระดับเปอร์เซ็นต์แบตเตอรี่ปัจจุบัน (0 - 100)
  int _batteryLevel = 100;

  /// ระบุว่าเปิดใช้งานระบบระบุพิกัด GPS อยู่หรือไม่
  bool _isGpsEnabled = true;

  int get batteryLevel => _batteryLevel;
  bool get isGpsEnabled => _isGpsEnabled;

  Future<void> init() async {
    // 1. Initialize Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);

    // 2. Start Monitoring
    _startBatteryMonitoring();
    _startGpsMonitoring();

    // 3. Initial Check
    await checkHealth();
  }

  void _startBatteryMonitoring() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((
      BatteryState state,
    ) async {
      final level = await _battery.batteryLevel;
      _batteryLevel = level;
      notifyListeners();
      _checkBattery(level);
    });
  }

  void _startGpsMonitoring() {
    if (kIsWeb) return; // getServiceStatusStream is not supported on web
    _gpsSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      final isEnabled = status == ServiceStatus.enabled;
      _isGpsEnabled = isEnabled;
      notifyListeners();
      _checkGps(isEnabled);
    });
  }

  Future<void> checkHealth() async {
    final level = await _battery.batteryLevel;
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();

    _batteryLevel = level;
    _isGpsEnabled = isGpsEnabled;
    notifyListeners();

    _checkBattery(level);
    _checkGps(isGpsEnabled);
  }

  void _checkBattery(int level) {
    if (level < 15 && !_hasNotifiedLowBattery) {
      _showNotification(
        id: 1,
        title: '⚠️ แบตเตอรี่ต่ำ',
        body:
            'แบตเตอรี่เหลือน้อยกว่า 15% กรุณาชาร์จเพื่อความปลอดภัยในการใช้งาน SOS',
      );
      _hasNotifiedLowBattery = true;
    } else if (level >= 15) {
      _hasNotifiedLowBattery = false;
    }
  }

  void _checkGps(bool isEnabled) {
    if (!isEnabled && !_hasNotifiedGpsDisabled) {
      _showNotification(
        id: 2,
        title: '📍 GPS ปิดอยู่',
        body:
            'กรุณาเปิด GPS เพื่อให้ระบบสามารถระบุตำแหน่งของท่านเมื่อเกิดเหตุฉุกเฉิน',
      );
      _hasNotifiedGpsDisabled = true;
    } else if (isEnabled) {
      _hasNotifiedGpsDisabled = false;
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'device_health_channel',
          'Device Health Check',
          channelDescription: 'Notifications for battery and GPS status',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notifications.show(id, title, body, platformChannelSpecifics);
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
