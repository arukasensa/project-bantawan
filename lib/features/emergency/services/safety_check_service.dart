// ============================================================================
// ⏱️ BANTAWAN Dead Man's Switch / Safety Check-in Service: SafetyCheckService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │           (Emergency & Survival Monitoring)             │
// ├─────────────────────────────────────────────────────────┤
// │               SafetyCheckService                        │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Timer (Countdown)    │    Auto SOS Dispatch      │  │
// │  │  (Dead Man's Switch)  │ (NearbyService + SMS URL) │  │
// │  │  Local Notifications  │ Emergency Contact Link    │  │
// │  │  SharedPreferences    │ Haptic/Sound Warnings     │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการระบบตรวจสอบความปลอดภัยอัตโนมัติ (Dead Man's Switch)
// ผู้ใช้ตั้งนาฬิกาถอยหลัง หากไม่กดยืนยัน "ปลอดภัย" ก่อนเวลาหมด ระบบจะ:
//   1. ปลุกระบบ Mesh Network เพื่อเตรียมพร้อมส่งสัญญาณล่วงหน้า
//   2. ดึงพิกัด GPS ณ ขณะนั้น และอ่านระดับแบตเตอรี่
//   3. ส่งสัญญาณ SOS ผ่าน Mesh Network ด้วย NearbyService
//   4. ดึงรายชื่อจาก EmergencyContactService เพื่อส่ง SMS หาผู้ติดต่อฉุกเฉินตัวจริง
//   5. แสดงการแจ้งเตือนต่อเนื่อง และส่งสัญญาณเตือนด่วนใน Warning Phase
//   6. บันทึกเป้าหมายเวลาลง SharedPreferences เพื่อฟื้นฟูได้แม้แอปถูกปิด
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';
import 'package:flutter1/features/emergency/services/emergency_contact_service.dart';

/// 🏛️ คลาสบริการนับถอยหลังตรวจสอบความปลอดภัยอัตโนมัติ (SafetyCheckService)
/// ใช้สถาปัตยกรรม ChangeNotifier เพื่อกระจายสถานะ Countdown และ Warning ไปยัง UI แบบ Realtime
class SafetyCheckService extends ChangeNotifier {
  static const int _activeNotifId = 8801;
  static const int _warningNotifId = 8802;

  static const String _prefActiveKey = 'safety_check_is_active';
  static const String _prefTargetTimeKey = 'safety_check_target_time';
  static const String _prefRecurringKey = 'safety_check_recurring';
  static const String _prefDurationKey = 'safety_check_initial_duration';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Battery _battery = Battery();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  bool _isRecurring = false;
  bool _isWarning = false;
  int _initialDurationSeconds = 0;
  bool _isInitialized = false;

  SafetyCheckService() {
    init();
  }

  // ----------------------------------------------------------------------------
  // 📢 Public Getters
  // ----------------------------------------------------------------------------
  int get remainingSeconds => _remainingSeconds;
  bool get isActive => _isActive;
  bool get isRecurring => _isRecurring;
  bool get isWarning => _isWarning;
  double get progress => _initialDurationSeconds > 0
      ? _remainingSeconds / _initialDurationSeconds
      : 0;

  // ============================================================================
  // 🚀 Section 0: Initialization & State Restoration
  // ============================================================================

  /// เริ่มต้นระบบ Notification Channel และฟื้นฟูสถานะจาก SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Initialize notification channel
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      await _notifications.initialize(initSettings);
    } catch (e) {
      debugPrint('[SafetyCheckService] Notification init error: $e');
    }

    // 2. Restore state from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool wasActive = prefs.getBool(_prefActiveKey) ?? false;
      if (wasActive) {
        final int targetEpoch = prefs.getInt(_prefTargetTimeKey) ?? 0;
        final bool recurring = prefs.getBool(_prefRecurringKey) ?? false;
        final int initialDuration = prefs.getInt(_prefDurationKey) ?? 0;
        final int nowEpoch = DateTime.now().millisecondsSinceEpoch;

        _isRecurring = recurring;
        _initialDurationSeconds = initialDuration;

        if (targetEpoch > nowEpoch) {
          // ยังไม่หมดเวลา ฟื้นฟูเวลานับถอยหลังต่อทันที
          final remaining = ((targetEpoch - nowEpoch) / 1000).ceil();
          _remainingSeconds = remaining;
          _isActive = true;
          _startTimer();
          _updateNotification();
          notifyListeners();
        } else if (targetEpoch > 0) {
          // หมดเวลาระหว่างที่แอปถูกปิด/รีสตาร์ต ให้หยุดและยิง SOS แจ้งเตือน
          debugPrint('[SafetyCheckService] Timer expired while app was offline. Triggering emergency SOS...');
          await _triggerSOS();
          await stopCheck();
        }
      }
    } catch (e) {
      debugPrint('[SafetyCheckService] State restoration error: $e');
    }
  }

  // ============================================================================
  // ▶️ Section 1: Timer Control (Start / Stop / Reset)
  // ============================================================================

  /// 📌 เริ่มนับถอยหลังการตรวจสอบความปลอดภัย
  /// - [minutes]: ระยะเวลานับถอยหลัง (นาที)
  /// - [recurring]: เปิดโหมดนับซ้ำอัตโนมัติหลังเวลาหมด (default: false)
  Future<void> startCheck(int minutes, {bool recurring = false}) async {
    await stopCheck();

    _isRecurring = recurring;
    _initialDurationSeconds = minutes * 60;
    _remainingSeconds = _initialDurationSeconds;
    _isActive = true;
    _isWarning = false;

    // 1. บันทึกลง SharedPreferences เพื่อรองรับการทำงานข้าม Process และฟื้นฟูหลังปิดแอป
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetEpoch = DateTime.now().millisecondsSinceEpoch + (_initialDurationSeconds * 1000);
      await prefs.setBool(_prefActiveKey, true);
      await prefs.setInt(_prefTargetTimeKey, targetEpoch);
      await prefs.setBool(_prefRecurringKey, _isRecurring);
      await prefs.setInt(_prefDurationKey, _initialDurationSeconds);
    } catch (e) {
      debugPrint('[SafetyCheckService] Error saving preferences: $e');
    }

    // 2. ตรวจสอบและปลุกเครือข่ายฉุกเฉิน Mesh Network ทันที เพื่อพร้อมส่งสัญญาณ SOS
    final nearby = NearbyService();
    if (!nearby.isAdvertising && !nearby.isDiscovering) {
      debugPrint('[SafetyCheck] 🛡️ Auto-activating Mesh Network for active lifeline monitoring...');
      nearby.startEmergencyNetwork();
    }

    // 3. เริ่ม Timer และแสดง Notification บนแถบสถานะ
    _startTimer();
    await _updateNotification();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;

        final warningThreshold = _initialDurationSeconds > 300 ? 120 : 60;
        if (_remainingSeconds <= warningThreshold && !_isWarning) {
          _isWarning = true;
          await _triggerWarning();
        }

        // อัปเดตการแจ้งเตือนทุกๆ 60 วินาที หรือเมื่อเข้าสู่ Warning Phase
        if (_remainingSeconds % 60 == 0 || _isWarning) {
          _updateNotification();
        }

        notifyListeners();
      } else {
        // เวลาหมด ยิง SOS ฉุกเฉินทันที
        await _triggerSOS();
        if (_isRecurring) {
          await resetCheck();
        } else {
          await stopCheck();
        }
      }
    });
  }

  /// 📌 หยุดการทำงานของระบบนับถอยหลังและรีเซ็ตค่าทั้งหมด
  Future<void> stopCheck() async {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _isWarning = false;
    _remainingSeconds = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefActiveKey);
      await prefs.remove(_prefTargetTimeKey);
      await prefs.remove(_prefRecurringKey);
      await prefs.remove(_prefDurationKey);

      await _notifications.cancel(_activeNotifId);
      await _notifications.cancel(_warningNotifId);
    } catch (e) {
      debugPrint('[SafetyCheckService] Error stopping check: $e');
    }

    notifyListeners();
  }

  /// 📌 ผู้ใช้กดปุ่ม "ฉันปลอดภัย" เพื่อรีเซ็ตนาฬิกากลับสู่ระยะเวลาเดิม
  Future<void> resetCheck() async {
    if (_isActive) {
      _remainingSeconds = _initialDurationSeconds;
      _isWarning = false;

      try {
        final prefs = await SharedPreferences.getInstance();
        final targetEpoch = DateTime.now().millisecondsSinceEpoch + (_initialDurationSeconds * 1000);
        await prefs.setInt(_prefTargetTimeKey, targetEpoch);
        await _notifications.cancel(_warningNotifId);
      } catch (e) {
        debugPrint('[SafetyCheckService] Error resetting check: $e');
      }

      await _updateNotification();
      notifyListeners();
    }
  }

  /// 📌 สลับ/ปิด โหมดนับซ้ำอัตโนมัติ (Recurring Mode Toggle)
  void toggleRecurring() {
    _isRecurring = !_isRecurring;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_prefRecurringKey, _isRecurring);
    }).catchError((_) {});
    notifyListeners();
  }

  // ============================================================================
  // 🚨 Section 2: Warning, Notifications & SOS Dispatch
  // ============================================================================

  /// 📌 ทริกเกอร์เฟสเตือนล่วงหน้า (Warning Phase) แจ้งเตือนผู้ใช้ด้วยสั่นและ Notification
  Future<void> _triggerWarning() async {
    HapticFeedback.heavyImpact();
    debugPrint("[SafetyCheck] ⚠️ เข้าสู่เฟสเตือนล่วงหน้า (Warning Phase)!");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'safety_check_warning_channel',
      'Safety Check Warnings',
      channelDescription: 'High-priority critical alerts for pending check-in',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      enableVibration: true,
      color: Color(0xFFFF1744),
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isEn = prefs.getString('selected_language') == 'en';

      await _notifications.show(
        _warningNotifId,
        isEn
            ? '🚨 Safety Alert: Time is running out!'
            : '🚨 แจ้งเตือนความปลอดภัย: เวลากำลังจะหมด!',
        isEn
            ? '$_remainingSeconds seconds remaining. Tap to confirm you are safe or SOS will trigger automatically.'
            : 'เหลือเวลาอีก $_remainingSeconds วินาที กรุณากดยืนยันว่าคุณปลอดภัย มิฉะนั้นระบบจะยิง SOS และส่ง SMS อัตโนมัติ',
        platformDetails,
      );
    } catch (e) {
      debugPrint('[SafetyCheck] Warning notification error: $e');
    }
  }

  /// 📌 อัปเดต Notification บนแถบแจ้งเตือนสถานะแบบ Real-time
  Future<void> _updateNotification() async {
    if (!_isActive) return;

    final mins = (_remainingSeconds / 60).floor();
    final secs = _remainingSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'safety_check_status_channel',
      'Safety Check Status',
      channelDescription: 'Ongoing status of active safety check-in watch',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      color: _isWarning ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
    );
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isEn = prefs.getString('selected_language') == 'en';

      await _notifications.show(
        _activeNotifId,
        isEn
            ? (_isWarning ? '⚠️ Preparing SOS Dispatch ($timeStr)' : '🛡️ Safety Watch Active')
            : (_isWarning ? '⚠️ เตรียมส่งสัญญาณฉุกเฉิน ($timeStr)' : '🛡️ ระบบเฝ้าระวังอัตโนมัติเปิดอยู่'),
        isEn
            ? 'Remaining time: $timeStr • Tap to confirm safety'
            : 'เวลานับถอยหลังคงเหลือ: $timeStr • แตะเพื่อยืนยันตัวตน',
        platformDetails,
      );
    } catch (e) {
      debugPrint('[SafetyCheck] Status notification error: $e');
    }
  }

  /// 📌 ยิงสัญญาณ SOS ฉุกเฉินอัตโนมัติเมื่อหมดเวลาโดยไม่ได้รับการยืนยัน
  Future<void> _triggerSOS() async {
    try {
      // 1. ขอพิกัด GPS แม่นยำสูง ณ ขณะนั้น
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 2. อ่านระดับแบตเตอรี่เพื่อรายงานในข้อความ SOS
      final batteryLevel = await _battery.batteryLevel;

      // 3. ตรวจสอบภาษาเพื่อส่งข้อความที่เหมาะสม
      final prefs = await SharedPreferences.getInstance();
      final isEn = prefs.getString('selected_language') == 'en';

      // 4. สร้างข้อความฉุกเฉินรวม พิกัด + ลิงก์ Google Maps + สถานะแบต
      final message = isEn
          ? "EMERGENCY! Safety Check-in Expired without response.\n"
            "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
            "Battery: $batteryLevel%"
          : "ฉุกเฉิน! ระบบเฝ้าระวังหมดเวลาโดยไม่มีการตอบสนอง\n"
            "พิกัด: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
            "ระดับแบตเตอรี่: $batteryLevel%";

      // 4. ตรวจสอบให้มั่นใจว่า Mesh Network ทำงานอยู่ และส่ง SOS ทันที
      final nearby = NearbyService();
      if (!nearby.isAdvertising && !nearby.isDiscovering) {
        await nearby.startEmergencyNetwork();
      }
      await nearby.sendLocalSOS(message);

      // 5. ดึงเบอร์ผู้ติดต่อฉุกเฉินจาก EmergencyContactService เพื่อใส่ใน SMS
      final contacts = await EmergencyContactService.getContacts();
      final phoneNumbers = contacts
          .map((c) => c['phone']?.trim() ?? '')
          .where((p) => p.isNotEmpty)
          .toList();

      final recipientString = phoneNumbers.isNotEmpty ? phoneNumbers.join(',') : '';
      final Uri smsUri = Uri.parse(
        recipientString.isNotEmpty
            ? 'sms:$recipientString?body=${Uri.encodeComponent(message)}'
            : 'sms:?body=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint("Safety Check SOS Error: $e");
    }
  }
}
