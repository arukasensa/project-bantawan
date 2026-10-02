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
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการระบบตรวจสอบความปลอดภัยอัตโนมัติ (Dead Man's Switch)
// ผู้ใช้ตั้งนาฬิกาถอยหลัง หากไม่กดยืนยัน "ปลอดภัย" ก่อนเวลาหมด ระบบจะ:
//   1. ดึงพิกัด GPS ณ ขณะนั้น
//   2. ส่งสัญญาณ SOS ผ่าน Mesh Network ด้วย NearbyService
//   3. เปิดแอปส่ง SMS พร้อมข้อความและลิงก์พิกัด Google Maps
//   4. รายงานระดับแบตเตอรี่ที่เหลืออยู่ในข้อความฉุกเฉิน
// รองรับโหมดนับซ้ำ (Recurring) และโหมดเตือนล่วงหน้า (Warning Phase)
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';

/// 🏛️ คลาสบริการนับถอยหลังตรวจสอบความปลอดภัยอัตโนมัติ (SafetyCheckService)
/// ใช้สถาปัตยกรรม ChangeNotifier เพื่อกระจายสถานะ Countdown และ Warning ไปยัง UI แบบ Realtime
class SafetyCheckService extends ChangeNotifier {
  // ----------------------------------------------------------------------------
  // 📦 Internal State Variables
  // ----------------------------------------------------------------------------
  /// ⏱️ ตัวจับเวลา Periodic Timer สำหรับนับถอยหลังทุก 1 วินาที
  Timer? _timer;

  /// 🔢 จำนวนวินาทีที่เหลืออยู่ก่อนเวลาหมดและระบบยิง SOS อัตโนมัติ
  int _remainingSeconds = 0;

  /// 🟢 สถานะว่าระบบเช็กความปลอดภัยกำลังทำงานอยู่หรือไม่
  bool _isActive = false;

  /// 🔁 โหมดนับซ้ำ: รีเซ็ตนาฬิกาอัตโนมัติเมื่อครบกำหนด แทนที่จะหยุดทำงาน
  bool _isRecurring = false;

  /// 🟡 สถานะเฟสเตือนล่วงหน้า (Warning Phase) ก่อนเวลาหมด (เช่น เหลือ 1-2 นาทีสุดท้าย)
  bool _isWarning = false;

  /// 📏 ระยะเวลาทั้งหมดที่ผู้ใช้ตั้งไว้ครั้งล่าสุด (หน่วย: วินาที) ใช้สำหรับคำนวณ Progress Bar
  int _initialDurationSeconds = 0;

  /// 🔋 ตัวอ่านสถานะระดับแบตเตอรี่ของอุปกรณ์ เพื่อรายงานในข้อความ SOS
  final Battery _battery = Battery();

  // ----------------------------------------------------------------------------
  // 📢 Public Getters
  // ----------------------------------------------------------------------------
  /// วินาทีที่เหลือก่อนจะยิง SOS อัตโนมัติ
  int get remainingSeconds => _remainingSeconds;

  /// ตรวจสอบว่าระบบเช็กกำลังทำงานอยู่หรือไม่
  bool get isActive => _isActive;

  /// ตรวจสอบว่าเปิดโหมดนับซ้ำอัตโนมัติอยู่หรือไม่
  bool get isRecurring => _isRecurring;

  /// ตรวจสอบว่าอยู่ในช่วงเตือนก่อนเวลาหมดหรือไม่ (ใช้ทำให้ UI กะพริบ/เปลี่ยนสี)
  bool get isWarning => _isWarning;

  /// ความคืบหน้าของนาฬิกา (0.0 = หมดเวลา → 1.0 = เพิ่งเริ่ม) สำหรับ Progress Indicator
  double get progress => _initialDurationSeconds > 0
      ? _remainingSeconds / _initialDurationSeconds
      : 0;

  // ============================================================================
  // ▶️ Section 1: Timer Control (Start / Stop / Reset)
  // ============================================================================

  /// 📌 เริ่มนับถอยหลังการตรวจสอบความปลอดภัย
  /// - [minutes]: ระยะเวลานับถอยหลัง (นาที)
  /// - [recurring]: เปิดโหมดนับซ้ำอัตโนมัติหลังเวลาหมด (default: false)
  void startCheck(int minutes, {bool recurring = false}) {
    // 1. หยุด Timer เดิมที่อาจกำลังทำงานอยู่ก่อน เพื่อป้องกัน Timer ซ้อน
    stopCheck();

    // 2. ตั้งค่าพารามิเตอร์การนับถอยหลัง
    _isRecurring = recurring;
    _initialDurationSeconds = minutes * 60; // แปลงนาทีเป็นวินาที
    _remainingSeconds = _initialDurationSeconds;
    _isActive = true;
    _isWarning = false;

    // 3. เริ่ม Periodic Timer ที่จะทำงานทุก 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--; // ลดเวลาถอยหลัง 1 วินาที

        // 4. ตรวจสอบเกณฑ์การเข้าสู่ Warning Phase
        // หากตั้งเกิน 5 นาที ให้เตือนตอนเหลือ 2 นาที ถ้าน้อยกว่าให้เตือนตอนเหลือ 1 นาที
        final warningThreshold = _initialDurationSeconds > 300 ? 120 : 60;
        if (_remainingSeconds <= warningThreshold && !_isWarning) {
          _isWarning = true;
          _triggerWarning(); // เรียกใช้ฟังก์ชันเตือนล่วงหน้า
        }

        notifyListeners(); // แจ้ง UI ให้อัปเดตตัวเลขถอยหลัง
      } else {
        // 5. เวลาหมดแล้ว: ยิง SOS ฉุกเฉินทันที
        _triggerSOS();
        if (_isRecurring) {
          resetCheck(); // โหมดนับซ้ำ: รีเซ็ตและเริ่มรอบใหม่
        } else {
          stopCheck(); // โหมดปกติ: หยุดระบบ
        }
      }
    });
    notifyListeners();
  }

  /// 📌 หยุดการทำงานของระบบนับถอยหลังและรีเซ็ตค่าทั้งหมด
  void stopCheck() {
    _timer?.cancel(); // ยกเลิก Timer ที่กำลังทำงาน
    _timer = null;
    _isActive = false;
    _isWarning = false;
    _remainingSeconds = 0;
    notifyListeners();
  }

  /// 📌 ผู้ใช้กดปุ่ม "ฉันปลอดภัย" เพื่อรีเซ็ตนาฬิกากลับสู่ระยะเวลาเดิม
  void resetCheck() {
    if (_isActive) {
      _remainingSeconds = _initialDurationSeconds; // ตั้งเวลาใหม่จากค่าเดิม
      _isWarning = false;
      notifyListeners();
    }
  }

  /// 📌 สลับ/ปิด โหมดนับซ้ำอัตโนมัติ (Recurring Mode Toggle)
  void toggleRecurring() {
    _isRecurring = !_isRecurring;
    notifyListeners();
  }

  // ============================================================================
  // 🚨 Section 2: Warning & SOS Dispatch
  // ============================================================================

  /// 📌 ทริกเกอร์เฟสเตือนล่วงหน้า (Warning Phase) เพื่อแจ้ง UI ปรับสีหรือกะพริบ
  void _triggerWarning() {
    // ขณะนี้อัปเดต State เพื่อให้ UI ตอบสนอง (แสดงสีแดง/การเต้น/สั่น)
    // ในอนาคตสามารถเพิ่มเสียงเตือนหรือ Local Notification ตรงนี้ได้
    debugPrint("Safety Check: เข้าสู่เฟสเตือนล่วงหน้า (Warning Phase)!");
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

      // 3. สร้างข้อความฉุกเฉินรวม พิกัด + ลิงก์ Google Maps + สถานะแบต
      final message =
          "EMERGENCY! Auto Check-in Failed.\n"
          "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
          "Battery: $batteryLevel%";

      // 4. ส่ง SOS ผ่านระบบ P2P Mesh ของ NearbyService (ทำงานแม้ไม่มีอินเทอร์เน็ต)
      NearbyService().sendLocalSOS(message);

      // 5. เปิดแอป SMS พร้อมข้อความสำเร็จรูป ให้ผู้ใช้หรือระบบส่งต่อได้ทันที
      final Uri smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint("Safety Check SOS Error: $e");
    }
  }
}
