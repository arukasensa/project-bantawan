// ============================================================================
// 🏥 BANTAWAN Medical Facility POI Model: MedicalFacility
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │                  MedicalFacility Model                  │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  POI Details & Contact│    Haversine Distance     │  │
// │  │  (Hospital/Clinic/Phar)│  (Accurate Offline Math)  │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  ER / 24-Hour Flags   │    JSON Serialization     │  │
// │  │  (Emergency Triage)   │  (Cache Storage & API)    │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// โมเดลข้อมูลสถานพยาบาล (Medical Facility Model)
// จัดเก็บข้อมูลของโรงพยาบาล คลินิก หรือร้านขายยา พร้อมฟังก์ชันคำนวณระยะห่างด้วย Haversine Formula
// ============================================================================

import 'dart:math';

/// 🏥 คลาสเก็บข้อมูลสถานพยาบาลหรือจุดปฐมพยาบาล (Medical Facility Model)
class MedicalFacility {
  /// ไอดีอ้างอิงของสถานที่ (จาก OSM หรือ Longdo)
  final String id;

  /// ชื่อของสถานพยาบาล (ภาษาไทยหรืออังกฤษ)
  final String name;

  /// ประเภทของสถานที่: 'hospital', 'clinic', 'pharmacy'
  final String type;

  /// ที่อยู่หรือรายละเอียดที่ตั้ง
  final String address;

  /// พิกัดละติจูด (Latitude)
  final double latitude;

  /// พิกัดลองจิจูด (Longitude)
  final double longitude;

  /// เบอร์โทรศัพท์สำหรับติดต่อฉุกเฉิน
  String phone;

  /// ระบุว่าเปิดให้บริการตลอด 24 ชั่วโมงหรือไม่
  final bool isOpen24Hours;

  /// URL ภาพถ่ายของสถานพยาบาล (ถ้ามี)
  final String? imageUrl;

  /// แหล่งที่มาของข้อมูล ('longdo' หรือ 'osm')
  final String source;

  // ข้อมูลรายละเอียดเชิงลึก (Rich Details)
  /// ลิงก์เว็บไซต์ทางการ
  String? website;

  /// หน่วยงานหรือผู้บริหารจัดการ (เช่น กรมการแพทย์, เอกชน)
  String? operator;

  /// รองรับแผนกฉุกเฉินหรือไม่ (Emergency Room / ER)
  bool hasEmergency;

  /// ความสะดวกในการเข้าถึงด้วยเก้าอี้เข็น (Wheelchair Accessibility)
  String? wheelchair;

  /// รายละเอียดเวลาทำการ (เช่น จันทร์-ศุกร์ 08:00-20:00)
  String? openingHours;

  /// อีเมลติดต่อ
  String? email;

  /// คำอธิบายหรือหมายเหตุเพิ่มเติมเกี่ยวกับสถานที่
  String? description;

  MedicalFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.isOpen24Hours = false,
    this.imageUrl,
    this.source = 'longdo',
    this.website,
    this.operator,
    this.hasEmergency = false,
    this.wheelchair,
    this.openingHours,
    this.email,
    this.description,
  });

  /// คำนวณระยะห่างจากพิกัดเป้าหมาย (lat, lng) มายังสถานพยาบาลนี้
  /// โดยใช้สูตรคำนวณระยะทางบนผิวทรงกลม (Haversine Formula) ส่งคืนเป็นกิโลเมตร (km)
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371; // รัศมีเฉลี่ยของโลก (กิโลเมตร)
    double dLat = _toRadians(latitude - lat);
    double dLon = _toRadians(longitude - lng);

    // คำนวณตามสูตร Haversine
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat)) *
            cos(_toRadians(latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// แปลงค่าองศา (Degree) ให้เป็นเรเดียน (Radian)
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
