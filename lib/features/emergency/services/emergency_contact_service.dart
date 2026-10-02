// ============================================================================
// 📞 BANTAWAN Emergency Contact Manager: EmergencyContactService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │           (Emergency Contact Book Management)           │
// ├─────────────────────────────────────────────────────────┤
// │              EmergencyContactService                    │
// │  ┌───────────────────────────────────────────────────┐  │
// │  │            SharedPreferences (JSON)               │  │
// │  │  (CRUD: Get / Add / Delete Emergency Contacts)    │  │
// │  └───────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการจัดการสมุดรายชื่อผู้ติดต่อฉุกเฉิน (Emergency Contact Service)
// รับผิดชอบการ CRUD (อ่าน, เพิ่ม, ลบ) รายชื่อบุคคลใกล้ชิด/ญาติ
// ที่ระบบจะติดต่อเมื่อเกิดเหตุฉุกเฉินหรือเมื่อ Safety Check-in ล้มเหลว
// จัดเก็บข้อมูลเป็น JSON ลงใน SharedPreferences ในรูปแบบ List ของ Map
// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🏛️ คลาสบริการบันทึกและจัดการรายชื่อผู้ติดต่อฉุกเฉินส่วนตัว (EmergencyContactService)
/// ทุกเมธอดเป็น static เพื่อให้เรียกใช้ได้ตรงโดยไม่ต้องสร้างอินสแตนซ์
class EmergencyContactService {
  /// 🔑 คีย์ SharedPreferences สำหรับจัดเก็บรายชื่อผู้ติดต่อฉุกเฉินทั้งหมด
  static const String _storageKey = 'emergency_contacts';

  // ============================================================================
  // 📖 Section 1: Reading Contacts
  // ============================================================================

  /// 📌 ดึงรายชื่อผู้ติดต่อฉุกเฉินทั้งหมดจาก Local Storage
  /// ส่งคืน List ของ Map ที่แต่ละ Map มีคีย์ 'name', 'phone', 'relationship'
  /// หากยังไม่มีข้อมูล คืนค่า List ว่าง
  static Future<List<Map<String, String>>> getContacts() async {
    // 1. เข้าถึง SharedPreferences ของเครื่อง
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    
    if (data != null) {
      // 2. ถอดรหัส JSON String เป็นรายการข้อมูลผู้ติดต่อ
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    }
    return []; // ยังไม่มีรายชื่อที่บันทึกไว้
  }

  // ============================================================================
  // 💾 Section 2: Writing & Persistence (Private)
  // ============================================================================

  /// 📌 บันทึกรายชื่อผู้ติดต่อทั้งหมดกลับสู่ SharedPreferences (Private Helper)
  /// - [contacts]: รายชื่อทั้งหมดที่ต้องการจัดเก็บ (หลังเพิ่มหรือลบแล้ว)
  static Future<void> _saveToStorage(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    // แปลง List ของ Map เป็น JSON String แล้วบันทึกลงเครื่อง
    await prefs.setString(_storageKey, json.encode(contacts));
  }

  // ============================================================================
  // ➕ Section 3: Adding Contacts
  // ============================================================================

  /// 📌 เพิ่มรายชื่อผู้ติดต่อฉุกเฉินใหม่เข้าสู่สมุดรายชื่อ
  /// - [name]: ชื่อ-นามสกุลของบุคคล
  /// - [phone]: เบอร์โทรศัพท์ที่ใช้ติดต่อยามฉุกเฉิน
  /// - [relationship]: ความสัมพันธ์กับผู้ใช้ (default: 'คนสนิท')
  static Future<void> addContact(
    String name,
    String phone, {
    String relationship = 'คนสนิท',
  }) async {
    // 1. ดึงรายชื่อปัจจุบันออกมาก่อน
    List<Map<String, String>> contacts = await getContacts();
    
    // 2. เพิ่มรายชื่อใหม่เข้าไปใน List
    contacts.add({'name': name, 'phone': phone, 'relationship': relationship});
    
    // 3. บันทึกรายชื่อที่อัปเดตแล้วกลับสู่ Local Storage
    await _saveToStorage(contacts);
  }

  // ============================================================================
  // 🗑️ Section 4: Deleting Contacts
  // ============================================================================

  /// 📌 ลบรายชื่อผู้ติดต่อฉุกเฉินออกจากสมุดรายชื่อตาม Index
  /// - [index]: ตำแหน่ง (0-based) ของรายชื่อที่ต้องการลบออก
  static Future<void> deleteContact(int index) async {
    // 1. ดึงรายชื่อปัจจุบันออกมา
    List<Map<String, String>> contacts = await getContacts();
    
    // 2. ตรวจสอบว่า Index ที่ส่งมาอยู่ในช่วงที่ถูกต้อง
    if (index >= 0 && index < contacts.length) {
      contacts.removeAt(index); // ลบรายชื่อออกจาก List
      await _saveToStorage(contacts); // บันทึกการเปลี่ยนแปลง
    }
  }
}
