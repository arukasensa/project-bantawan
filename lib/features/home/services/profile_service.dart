// ============================================================================
// 👤 BANTAWAN User Profile Persistence Service: ProfileService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (User Profile & Medical Emergency ID)        │
// ├─────────────────────────────────────────────────────────┤
// │                   ProfileService                        │
// │  ┌───────────────────────────────────────────────────┐  │
// │  │       SharedPreferences ('user_profile' JSON)     │  │
// │  │  (Medical ID / Blood Type / Allergies / BMI / Age) │  │
// │  └───────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการบันทึกและจัดการข้อมูลโปรไฟล์ทางการแพทย์ฉุกเฉิน (User Profile Service)
// จัดเก็บข้อมูลบัตรประจำตัวฉุกเฉิน (Medical ID) ลงใน SharedPreferences
// รองรับข้อมูลกรุ๊ปเลือด, โรคประจำตัว, ประวัติแพ้ยา, ความยินยอมบริจาคอวัยวะ, คำนวณ BMI และอายุ
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🏛️ คลาสบริการบันทึกและดึงข้อมูลบัตรประจำตัวฉุกเฉินส่วนบุคคล (ProfileService)
class ProfileService {
  static const String _storageKey = 'user_profile';

  /// ดึงข้อมูลโปรไฟล์ผู้ใช้ทั้งหมดจาก SharedPreferences
  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      return Map<String, String>.from(json.decode(data));
    }
    // Default profile with privacy options
    return {
      'name': '',
      'dob': '',
      'age': '',
      'bloodType': '',
      'weight': '',
      'height': '',
      'allergies': '',
      'conditions': '',
      'insurance': '',
      'hospitalPref': '',
      'organDonor': 'false',
      'anonymousMode': 'false',
      'shareMedicalInfo': 'true',
      'minimalMedicalInfo': 'false',
    };
  }

  // Save Profile Data
  static Future<void> saveProfile(Map<String, String> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(profile));
  }

  // Calculate Age helper
  static String calculateAge(String dob) {
    if (dob.isEmpty) return '-';
    try {
      final birthDate = DateTime.parse(dob); // Format: YYYY-MM-DD
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return '-';
    }
  }

  // Calculate BMI helper
  static String calculateBMI(String weight, String height) {
    try {
      double w = double.parse(weight);
      double h = double.parse(height) / 100; // cm to m
      if (h <= 0) return '-';
      double bmi = w / (h * h);
      return bmi.toStringAsFixed(1);
    } catch (e) {
      return '-';
    }
  }
}
