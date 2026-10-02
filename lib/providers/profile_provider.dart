// ============================================================================
// 👤 BANTAWAN User Profile & Medical ID State Provider: ProfileProvider
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Profile / Medical Emergency ID)             │
// ├─────────────────────────────────────────────────────────┤
// │                   ProfileProvider                       │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │    ProfileService     │       NearbyService       │  │
// │  │  (Local Persistence)  │    (P2P Profile Sync)     │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// ตัวจัดการสถานะโปรไฟล์ผู้ใช้และข้อมูลทางการแพทย์ฉุกเฉิน (Profile Provider)
// รับผิดชอบการบริหารข้อมูล Medical ID (ชื่อ, กรุ๊ปเลือด, ประวัติการแพ้ยา, โรคประจำตัว)
// พร้อมระบบประเมินความสมบูรณ์ของข้อมูลทางการแพทย์ (Completeness Score)
// และส่งต่อข้อมูลไปยัง NearbyService เพื่อซิงค์อัตลักษณ์ผู้ใช้ใน Mesh Network ออฟไลน์
// ============================================================================

import 'package:flutter/material.dart';
import '../features/home/services/profile_service.dart';
import '../features/chat/services/nearby_service.dart';

/// 🏛️ Provider จัดการ State ข้อมูลส่วนตัวและข้อมูลสุขภาพฉุกเฉินของผู้ใช้ (ProfileProvider)
/// ทำหน้าที่เป็นศูนย์กลางเชื่อมโยงระหว่างหน้าจอ ProfileScreen และฐานข้อมูลในเครื่อง
class ProfileProvider with ChangeNotifier {
  // ----------------------------------------------------------------------------
  // 📦 Internal State Variables
  // ----------------------------------------------------------------------------
  /// 📋 ข้อมูลฟิลด์ต่างๆ ของโปรไฟล์ผู้ใช้ (เช่น 'name', 'bloodType', 'allergies', 'dob')
  Map<String, String> _profile = {};

  /// ⏳ สถานะกำลังโหลดหรือบันทึกข้อมูลจาก Local Storage หรือไม่
  bool _isLoading = false;

  // ----------------------------------------------------------------------------
  // 📢 Public Getters
  // ----------------------------------------------------------------------------
  /// แผนที่ข้อมูลโปรไฟล์ปัจจุบัน
  Map<String, String> get profile => _profile;

  /// ตรวจสอบว่าระบบกำลังดำเนินกระบวนการอ่าน/เขียนข้อมูลอยู่หรือไม่
  bool get isLoading => _isLoading;

  // ============================================================================
  // 🚀 Section 1: Lifecycle & Initialization
  // ============================================================================

  /// 📌 เริ่มต้นการทำงานของ ProfileProvider โดยโหลดข้อมูลเดิมจากเครื่องทันทีที่ถูกสร้าง
  ProfileProvider() {
    loadProfile();
  }

  // ============================================================================
  // 💾 Section 2: Data Persistence & Synchronization
  // ============================================================================

  /// 📌 โหลดข้อมูลโปรไฟล์จาก Local Storage ผ่าน [ProfileService]
  Future<void> loadProfile() async {
    // 1. ตั้งค่าสถานะกำลังโหลด และแจ้งเตือนหน้าจอ
    _isLoading = true;
    notifyListeners();

    // 2. อ่านข้อมูลโปรไฟล์ที่บันทึกไว้ในเครื่อง
    _profile = await ProfileService.getProfile();

    // 3. สิ้นสุดการโหลด และแจ้งเตือนให้อัปเดต UI
    _isLoading = false;
    notifyListeners();
  }

  /// 📌 บันทึกข้อมูลโปรไฟล์ใหม่ลงในเครื่อง พร้อมซิงค์เข้าสู่ระบบสื่อสารออฟไลน์ P2P
  /// - [newProfile]: ข้อมูลชุดใหม่ที่ผู้ใช้กรอกผ่านหน้าแบบฟอร์ม
  Future<void> updateProfile(Map<String, String> newProfile) async {
    // 1. เริ่มแสดงสถานะกำลังประมวลผล
    _isLoading = true;
    notifyListeners();

    // 2. บันทึกลง SharedPreferences ในเครื่องอย่างถาวร
    await ProfileService.saveProfile(newProfile);
    _profile = newProfile;
    
    // 3. ซิงค์ชื่อและอัตลักษณ์ใหม่เข้าไปยัง NearbyService เพื่อให้เพื่อนใน Mesh Network มองเห็น
    await NearbyService().updateProfileInfo();

    // 4. บันทึกเสร็จสมบูรณ์ ปลดสถานะโหลด และอัปเดต UI
    _isLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // 🧮 Section 3: Health Score & Emergency Helpers
  // ============================================================================

  /// 📌 คำนวณคะแนนความสมบูรณ์ของข้อมูลทางการแพทย์ (Medical ID Completeness Score)
  /// คืนค่าเป็นอัตราส่วนทศนิยมระหว่าง 0.0 (ยังไม่กรอก) ถึง 1.0 (ครบถ้วนทุกฟิลด์สำคัญ)
  double get completenessScore {
    if (_profile.isEmpty) return 0.0;

    // รายการฟิลด์สำคัญยิ่งยวดต่อการกู้ชีพยามฉุกเฉิน
    final criticalFields = [
      'name',         // ชื่อ-นามสกุล
      'bloodType',    // หมู่โลหิต
      'allergies',    // ประวัติการแพ้ยา/อาหาร
      'conditions',   // โรคประจำตัว
      'hospitalPref', // โรงพยาบาลตามสิทธิการรักษา
    ];

    int filledCount = 0;
    for (var field in criticalFields) {
      if (_profile[field]?.isNotEmpty == true) {
        filledCount++;
      }
    }

    return filledCount / criticalFields.length;
  }

  /// 📌 สีกำกับระดับความพร้อมของข้อมูลฉุกเฉิน (Status Color Indicator)
  /// - แดง (< 40%): ข้อมูลวิกฤตยังไม่สมบูรณ์ อาจเกิดอันตรายยามปฐมพยาบาล
  /// - ส้ม (40% - 79%): ข้อมูลอยู่ในระดับปานกลาง
  /// - เขียว (>= 80%): ข้อมูลพร้อมสมบูรณ์สำหรับการกู้ชีพฉุกเฉิน
  Color get healthStatusColor {
    double score = completenessScore;
    if (score < 0.4) return Colors.redAccent;
    if (score < 0.8) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  /// 📌 คำนวณอายุของผู้ใช้จากวันเกิด (Date of Birth) หรือดึงจากค่าที่ระบุไว้
  String get calculatedAge {
    // 1. หากผู้ใช้กรอกช่องอายุไว้โดยตรง ให้ส่งคืนค่านั้นได้ทันที
    if (_profile['age']?.isNotEmpty == true) {
      return _profile['age']!;
    }
    // 2. หากระบุเป็นวันเดือนปีเกิด ให้คำนวณผ่าน ProfileService
    return ProfileService.calculateAge(_profile['dob'] ?? '');
  }
}
