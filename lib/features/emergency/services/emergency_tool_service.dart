// ============================================================================
// 🔦 BANTAWAN Emergency Hardware Tools Service: EmergencyToolService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │           (Survival Tools & Signal Emission)            │
// ├─────────────────────────────────────────────────────────┤
// │               EmergencyToolService                      │
// │  ┌────────────────────┬──────────────────────────────┐  │
// │  │   TorchLight API   │       AudioPlayer            │  │
// │  │ Strobe / Morse SOS │  Siren (assets/audio/*.mp3)  │  │
// │  └────────────────────┴──────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการควบคุมอุปกรณ์ฮาร์ดแวร์ฉุกเฉิน (Emergency Hardware Tools Service)
// รับผิดชอบการสั่งงาน 3 โหมดสัญญาณเรียกขอความช่วยเหลือ:
//   1. ไฟฉายกะพริบถี่ (Strobe Light) - กะพริบทุก 100ms
//   2. สัญญาณแสงรหัสมอร์ส SOS (... --- ...) - วนซ้ำต่อเนื่อง
//   3. เสียงไซเรนฉุกเฉิน (Siren Audio Loop) - เล่น audio/siren.mp3 วนซ้ำ
// ออกแบบเป็น Singleton เพื่อป้องกันการควบคุมฮาร์ดแวร์ซ้ำซ้อนจากหลาย Provider
// ============================================================================

import 'dart:async';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 🏛️ คลาสบริการควบคุมเครื่องมือฮาร์ดแวร์ฉุกเฉิน (EmergencyToolService)
/// ออกแบบเป็น Singleton + ChangeNotifier เพื่อให้ SOS Screen ติดตามสถานะอุปกรณ์แบบ Realtime
class EmergencyToolService extends ChangeNotifier {
  // ----------------------------------------------------------------------------
  // 🔒 Singleton Pattern Implementation
  // ----------------------------------------------------------------------------
  static final EmergencyToolService _instance =
      EmergencyToolService._internal();
  factory EmergencyToolService() => _instance;
  EmergencyToolService._internal();

  // ----------------------------------------------------------------------------
  // 📦 Internal State & Controllers
  // ----------------------------------------------------------------------------
  /// ⏱️ ตัวจับเวลาสำหรับควบคุมจังหวะการเปิด-ปิดไฟฉาย (ใช้ร่วมกันทั้ง Strobe และ Morse)
  Timer? _flashlightTimer;

  /// 🔊 เครื่องเล่นเสียงไซเรนฉุกเฉิน (รองรับ Loop Mode)
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 💡 สถานะไฟฉายกะพริบเร็ว (Strobe Light Mode)
  bool _isStrobeActive = false;

  /// 📡 สถานะส่งรหัสมอร์ส SOS ด้วยไฟฉาย (Morse Code SOS Mode)
  bool _isMorseActive = false;

  /// 🚨 สถานะเปิดเสียงไซเรนฉุกเฉิน (Emergency Siren Mode)
  bool _isSirenActive = false;

  // ----------------------------------------------------------------------------
  // 📢 Public Getters
  // ----------------------------------------------------------------------------
  /// ตรวจสอบว่าโหมด Strobe Light กำลังทำงานอยู่หรือไม่
  bool get isStrobeActive => _isStrobeActive;

  /// ตรวจสอบว่าโหมด Morse SOS กำลังส่งสัญญาณอยู่หรือไม่
  bool get isMorseActive => _isMorseActive;

  /// ตรวจสอบว่าเสียงไซเรนกำลังดังอยู่หรือไม่
  bool get isSirenActive => _isSirenActive;

  // ----------------------------------------------------------------------------
  // 📐 Morse Code SOS Pattern Definition
  // ----------------------------------------------------------------------------
  // สัญญาณมอร์ส SOS: ... --- ... (S = จุดสั้น, O = ขีดยาว)
  // รูปแบบ: [เวลาเปิดไฟ(ms), เวลาปิดไฟ(ms), ...]
  // Short (จุด) = 200ms, Long (ขีด) = 600ms, ช่วงพัก = 200ms, หยุดระหว่างตัวอักษร = 600ms
  final List<int> _morsePattern = [
    200, 200, 200, 200, 200, 600, // S (dot dot dot gap)
    600, 200, 600, 200, 600, 600, // O (dash dash dash gap)
    200, 200, 200, 200, 200, 1000, // S (dot dot dot long-pause)
  ];

  // ============================================================================
  // 💡 Section 1: Strobe Light Control
  // ============================================================================

  /// 📌 เปิด/ปิดโหมดไฟฉายกะพริบถี่ (Strobe Light) สำหรับส่งสัญญาณดึงดูดความสนใจ
  /// - [active]: true = เปิดไฟกะพริบ, false = ปิดและดับไฟ
  Future<void> toggleStrobe(bool active) async {
    // 1. หยุดและล้าง Timer ไฟฉายที่อาจทำงานอยู่ก่อน (ป้องกัน Conflict)
    _cleanupFlashlight();
    _isMorseActive = false; // ปิดโหมด Morse หากเปิดอยู่
    _isStrobeActive = active;

    if (active) {
      // 2. เริ่ม Strobe: สลับเปิด-ปิดไฟทุก 100ms (10 ครั้ง/วินาที)
      bool isOn = false;
      _flashlightTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) async {
        try {
          if (isOn) {
            await TorchLight.disableTorch(); // ปิดไฟ
          } else {
            await TorchLight.enableTorch(); // เปิดไฟ
          }
          isOn = !isOn; // สลับสถานะ
        } catch (e) {
          debugPrint("Torch Error: $e");
          timer.cancel(); // หยุด Timer หากฮาร์ดแวร์ผิดพลาด
        }
      });
    } else {
      // 3. ดับไฟทันทีเมื่อปิดโหมด
      await TorchLight.disableTorch();
    }
    notifyListeners();
  }

  // ============================================================================
  // 📡 Section 2: Morse Code SOS Signal
  // ============================================================================

  /// 📌 เปิด/ปิดโหมดส่งสัญญาณรหัสมอร์ส SOS (... --- ...) ด้วยไฟฉาย
  /// - [active]: true = เริ่มส่งสัญญาณ, false = หยุดและดับไฟ
  Future<void> toggleMorseSOS(bool active) async {
    // 1. หยุด Timer เดิมและปิดโหมด Strobe ก่อน
    _cleanupFlashlight();
    _isStrobeActive = false;
    _isMorseActive = active;

    if (active) {
      int index = 0; // ตัวชี้ตำแหน่งปัจจุบันใน Pattern Array

      // 2. ฟังก์ชันวนรูปแบบมอร์สแบบ Recursive ด้วย Timer (ไม่ Blocking)
      void runPattern() async {
        if (!_isMorseActive) return; // หยุดทันทีหากผู้ใช้ปิดโหมดแล้ว

        bool isOn = index % 2 == 0; // Index คู่ = เปิดไฟ, คี่ = ปิดไฟ
        int duration = _morsePattern[index]; // ระยะเวลาของช่วงนี้ (ms)

        try {
          if (isOn) {
            await TorchLight.enableTorch(); // เปิดไฟตามจังหวะมอร์ส
          } else {
            await TorchLight.disableTorch(); // ปิดไฟตามจังหวะมอร์ส
          }
        } catch (e) {
          debugPrint("Morse Torch Error: $e");
          return;
        }

        // 3. ตั้ง Timer เพื่อเปลี่ยนไปสัญญาณถัดไปหลังจากครบเวลา
        _flashlightTimer = Timer(Duration(milliseconds: duration), () {
          index = (index + 1) % _morsePattern.length; // วนกลับสู่จุดเริ่มเมื่อครบ Pattern
          runPattern();
        });
      }

      runPattern(); // เริ่มวนสัญญาณ SOS
    } else {
      await TorchLight.disableTorch(); // ดับไฟเมื่อปิดโหมด
    }
    notifyListeners();
  }

  // ============================================================================
  // 🔊 Section 3: Emergency Siren
  // ============================================================================

  /// 📌 เปิด/ปิดเสียงไซเรนฉุกเฉินแบบวนซ้ำต่อเนื่อง (Looping Siren Audio)
  /// - [active]: true = เปิดเสียงไซเรน, false = หยุดเสียง
  Future<void> toggleSiren(bool active) async {
    _isSirenActive = active;
    if (active) {
      // 1. ตั้งโหมดเล่นซ้ำอัตโนมัติเมื่อเพลงจบ (Loop Mode)
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // 2. เล่นไฟล์เสียงไซเรนที่จัดเก็บไว้ใน assets/audio/
      try {
        await _audioPlayer.play(AssetSource('audio/siren.mp3'));
      } catch (e) {
        debugPrint("Audio Error: $e");
      }
    } else {
      // 3. หยุดเสียงทันทีเมื่อผู้ใช้ปิดโหมด
      await _audioPlayer.stop();
    }
    notifyListeners();
  }

  // ============================================================================
  // 🧹 Section 4: Resource Cleanup
  // ============================================================================

  /// 📌 ยกเลิก Timer ไฟฉายที่ทำงานอยู่และดับไฟฉาย (ใช้ก่อนสลับโหมด)
  void _cleanupFlashlight() {
    _flashlightTimer?.cancel(); // หยุด Timer
    _flashlightTimer = null;
    TorchLight.disableTorch(); // ดับไฟฉายอย่างปลอดภัย
  }

  /// 📌 คืนทรัพยากรทั้งหมดเมื่อ Widget ถูกทำลาย (Lifecycle Disposal)
  @override
  void dispose() {
    _cleanupFlashlight(); // ยกเลิก Timer และดับไฟ
    _audioPlayer.dispose(); // ปิดเครื่องเล่นเสียงและปลดหน่วยความจำ
    super.dispose();
  }
}
