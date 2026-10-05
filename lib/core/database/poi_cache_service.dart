// ============================================================================
// 💾 BANTAWAN Offline Cache Service: PoiCacheService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Offline Survival & Navigation)              │
// ├─────────────────────────────────────────────────────────┤
// │                  PoiRepositoryImpl                      │
// ├─────────────────────────────────────────────────────────┤
// │                  PoiCacheService                        │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │   SharedPreferences   │   Haversine Distance Calc │  │
// │  │ (JSON Serialization)  │    (Geographic Filtering) │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการจัดการแคชข้อมูลสถานที่ออฟไลน์ (POI Cache Service)
// รับผิดชอบการบันทึก อ่าน และตรวจสอบความสดใหม่ของข้อมูลสถานพยาบาลลงในเครื่อง
// พร้อมระบบ Cache Invalidation (หมดอายุ 24 ชม. และ Eviction เกิน 7 วัน)
// รองรับการคำนวณระยะห่างด้วย Haversine Formula เมื่อไม่มีอินเทอร์เน็ต
// ============================================================================

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/facility_type.dart';
import '../../models/medical_facility.dart';
import '../../models/cache_metadata.dart';
import '../utils/medical_facility_classifier.dart';

/// 🏛️ คลาสบริการบันทึกและจัดการแคชข้อมูลสถานพยาบาลแบบออฟไลน์ (PoiCacheService)
/// ทำงานร่วมกับ SharedPreferences ในการจัดเก็บข้อมูล JSON และตรวจสอบสถานะแคช
class PoiCacheService {
  /// 🔑 คีย์สำหรับจัดเก็บรายการสถานพยาบาลทั้งหมดใน SharedPreferences (v5 ป้องกันการดึงร้านค้า/เซเว่นข้าง รพ.)
  static const String _storageKey = 'cached_poi_facilities_v5';

  /// 🔑 คีย์สำหรับจัดเก็บประวัติและ Metadata ของการค้นหา (พิกัด, รัศมี, เวลาบันทึก)
  static const String _metadataKey = 'cached_poi_metadata_v5';

  // ============================================================================
  // 📥 Section 1: การบันทึกและจัดการข้อมูลแคช (Cache Storage & Eviction)
  // ============================================================================

  /// 📌 บันทึกและผสาน (Merge) ข้อมูล POIs ใหม่ลงในแคชของเครื่อง พร้อมบันทึกประวัติ Metadata
  /// - [newFacilities]: รายการสถานพยาบาลใหม่ที่ได้จากการค้นหาผ่านเครือข่าย
  /// - [centerLat]: ละติจูดของจุดศูนย์กลางการค้นหา
  /// - [centerLng]: ลองจิจูดของจุดศูนย์กลางการค้นหา
  /// - [radiusKm]: รัศมีการค้นหา (กิโลเมตร)
  static Future<void> saveFacilities(
    List<MedicalFacility> newFacilities, {
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    try {
      // 1. เข้าถึง SharedPreferences ของเครื่อง
      final prefs = await SharedPreferences.getInstance();

      // 2. ดึงข้อมูลสถานพยาบาลเดิมที่มีอยู่ในเครื่องออกมาเตรียมผสาน
      final List<MedicalFacility> cached = await getRawCachedFacilities();

      // 3. ผสานรายการเดิมกับรายการใหม่ พร้อมกำจัดข้อมูลที่ซ้ำซ้อนโดยใช้ ID เป็นคีย์
      final Map<String, MedicalFacility> unique = {};
      for (var f in cached) {
        if (MedicalFacilityClassifier.isValidFacility(f)) {
          unique[f.id] = f; // ใส่ข้อมูลเดิมเฉพาะที่ผ่านการตรวจสอบ
        }
      }
      for (var f in newFacilities) {
        if (MedicalFacilityClassifier.isValidFacility(f)) {
          unique[f.id] = f; // ข้อมูลใหม่อัปเดตทับข้อมูลเดิมที่มี ID ตรงกัน
        }
      }

      // 4. แปลงข้อมูลทั้งหมดเป็น JSON List แล้วบันทึกลง SharedPreferences
      final List<Map<String, dynamic>> jsonList =
          unique.values.map((f) => _facilityToJson(f)).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));

      // 5. ดึงรายการ Metadata เดิมที่เคยบันทึกไว้
      final String? metaDataStr = prefs.getString(_metadataKey);
      List<CacheMetadata> metadataList = [];
      if (metaDataStr != null) {
        final List<dynamic> decoded = json.decode(metaDataStr);
        metadataList =
            decoded.map((e) => CacheMetadata.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      final now = DateTime.now(); // เวลาปัจจุบันสำหรับคำนวณอายุแคช

      // 6. กลไก Cache Eviction: ล้างประวัติการแคชที่เก่าเกิน 7 วันออก เพื่อประหยัดเนื้อที่
      metadataList.removeWhere((meta) => now.difference(meta.lastUpdated).inDays >= 7);

      // 7. เพิ่มประวัติ Metadata ของการค้นหาครั้งล่าสุดนี้เข้าไป
      metadataList.add(CacheMetadata(
        lastUpdated: now,
        latitude: centerLat,
        longitude: centerLng,
        radiusKm: radiusKm,
      ));

      // 8. บันทึก Metadata ทั้งหมดกลับสู่ SharedPreferences
      final List<Map<String, dynamic>> metaJson =
          metadataList.map((m) => m.toJson()).toList();
      await prefs.setString(_metadataKey, json.encode(metaJson));
    } catch (_) {
      // ดักจับข้อยกเว้นกรณีการเข้าถึง Storage ขัดข้อง เพื่อไม่ให้แอปพลิเคชันหยุดทำงาน
    }
  }

  /// 📌 ดึงข้อมูลสถานพยาบาลทั้งหมดที่ถูกแคชไว้ในเครื่อง (ยังไม่ผ่านการกรองระยะหรือประเภท)
  /// ส่งคืนรายการ [MedicalFacility] ทั้งหมดใน Local Storage หรือคืนค่า List ว่างหากไม่มีข้อมูล
  static Future<List<MedicalFacility>> getRawCachedFacilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        // ถอดรหัส JSON String เป็น List ของ Map แล้วแปลงเป็น Object
        final List<dynamic> decoded = json.decode(data);
        return decoded.map((e) => _jsonToFacility(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {
      // หากเกิดข้อผิดพลาดในการแปลงไฟล์ JSON ส่งคืนค่าว่าง
    }
    return [];
  }

  // ============================================================================
  // 🔍 Section 2: การตรวจสอบความถูกต้องและการกรองข้อมูล (Validation & Querying)
  // ============================================================================

  /// 📌 ตรวจสอบความถูกต้องและความครอบคลุมของแคชตามพิกัดและเวลา (Cache Invalidation)
  /// - [userLat]: ละติจูดตำแหน่งปัจจุบันของผู้ใช้
  /// - [userLng]: ลองจิจูดตำแหน่งปัจจุบันของผู้ใช้
  /// - [radiusKm]: รัศมีที่ต้องการค้นหา
  /// ส่งคืน true หากมีข้อมูลแคชที่สดใหม่ (ไม่เกิน 24 ชม.) และครอบคลุมรัศมีที่ระบุ
  static Future<bool> isCacheValid({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? metaDataStr = prefs.getString(_metadataKey);
      if (metaDataStr == null) return false; // ไม่มีประวัติแคชมาก่อน

      final List<dynamic> decoded = json.decode(metaDataStr);
      final List<CacheMetadata> metadataList =
          decoded.map((e) => CacheMetadata.fromJson(Map<String, dynamic>.from(e))).toList();

      final now = DateTime.now();
      for (var meta in metadataList) {
        // 1. ตรวจสอบอายุของแคช: ต้องอัปเดตไม่เกิน 24 ชั่วโมง
        final age = now.difference(meta.lastUpdated);
        if (age.inHours >= 24) continue; // หากเก่าเกิน 24 ชม. ข้ามรายการนี้ไป

        // 2. คำนวณความครอบคลุมของพื้นที่พิกัด (Geometric Enclosure Check)
        // ระยะห่างจากจุดปัจจุบันไปยังศูนย์กลางแคชเดิม + รัศมีใหม่ ต้องไม่เกินรัศมีของแคชเดิม (+เผื่อ Margin 10%)
        final double distanceToMeta = _calculateDistance(userLat, userLng, meta.latitude, meta.longitude);
        if (distanceToMeta + radiusKm <= meta.radiusKm * 1.1) {
          // ตรวจสอบว่าแคชที่มีอยู่ไม่ใช่แคชผิดพลาด/ว่างเปล่าจากการยิง API ล้มเหลวก่อนหน้า
          final cached = await getRawCachedFacilities();
          if (cached.length < 15) return false;
          return true; // แคชเดิมครอบคลุมพื้นที่ที่กำลังค้นหา และมีข้อมูลเพียงพอ
        }
      }
    } catch (_) {}
    return false; // ไม่พบแคชที่ครอบคลุมหรือเกิดข้อผิดพลาด
  }

  /// 📌 กรองและดึงข้อมูลสถานพยาบาลตามรัศมีและประเภทสถานที่ (ใช้สำหรับกรณี Offline Mode)
  /// - [userLat]: ละติจูดของผู้ใช้งาน
  /// - [userLng]: ลองจิจูดของผู้ใช้งาน
  /// - [radiusKm]: รัศมีค้นหา (กิโลเมตร)
  /// - [type]: ประเภทสถานพยาบาลที่ต้องการกรอง (hospital, clinic, pharmacy) หรือ null เพื่อดึงทั้งหมด
  /// ส่งคืนรายการ [MedicalFacility] ที่ตรงตามเงื่อนไขและอยู่ในรัศมี
  static Future<List<MedicalFacility>> getCachedFacilities({
    required double userLat,
    required double userLng,
    required double radiusKm,
    FacilityType? type,
  }) async {
    // 1. โหลดข้อมูลสถานที่ทั้งหมดในเครื่อง
    final List<MedicalFacility> all = await getRawCachedFacilities();
    final List<MedicalFacility> filtered = [];

    for (var f in all) {
      // 2. กรองสถานที่ที่ไม่ใช่สถานพยาบาลมนุษย์แท้จริงออก
      if (!MedicalFacilityClassifier.isValidFacility(f)) continue;

      // จำแนกและอัปเดตประเภทให้ถูกต้องแม่นยำ (เช่น รพ.สต. -> hospital)
      final classifiedType = MedicalFacilityClassifier.classify(
        name: f.name,
        amenity: f.source == 'osm' ? f.type : null,
      );
      if (classifiedType == null) continue;

      final facility = MedicalFacility(
        id: f.id,
        name: f.name,
        type: classifiedType, // อัปเดตประเภทให้ถูกต้องแม่นยำ
        address: f.address,
        latitude: f.latitude,
        longitude: f.longitude,
        phone: f.phone,
        isOpen24Hours: f.isOpen24Hours || classifiedType == 'hospital',
        imageUrl: f.imageUrl,
        source: f.source,
        website: f.website,
        operator: f.operator,
        hasEmergency: f.hasEmergency,
        wheelchair: f.wheelchair,
        openingHours: f.openingHours,
        email: f.email,
        description: f.description,
      );

      // 3. ตรวจสอบเงื่อนไขการกรองประเภทสถานพยาบาล
      if (type != null) {
        final fType = facility.type.toLowerCase();
        if (type == FacilityType.hospital && fType != 'hospital') continue;
        if (type == FacilityType.clinic && fType != 'clinic') continue;
        if (type == FacilityType.pharmacy && fType != 'pharmacy') continue;
      }

      // 4. ตรวจสอบพิกัดระยะทางจริงจากผู้ใช้โดยใช้สูตร Haversine
      final distance = facility.distanceFrom(userLat, userLng);
      if (distance <= radiusKm) {
        filtered.add(facility); // บรรจุลงรายการหากอยู่ในรัศมีที่กำหนด
      }
    }

    return filtered;
  }

  // ============================================================================
  // 🧮 Section 3: ฟังก์ชันช่วยเหลือและการคำนวณระยะทาง (Helpers & Mathematical Models)
  // ============================================================================

  /// 📌 คำนวณระยะห่างระหว่างพิกัด 2 จุดบนผิวโลกด้วยสูตร Haversine Formula (กิโลเมตร)
  /// - [lat1], [lng1]: พิกัดจุดที่ 1
  /// - [lat2], [lng2]: พิกัดจุดที่ 2
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // รัศมีเฉลี่ยของโลก (กิโลเมตร)
    double dLat = (lat2 - lat1) * pi / 180; // แปลงผลต่างละติจูดเป็นเรเดียน
    double dLon = (lng2 - lng1) * pi / 180; // แปลงผลต่างลองจิจูดเป็นเรเดียน

    // คำนวณส่วนโค้งทรงกลม (Spherical Trigonometry)
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // ระยะทางจริงบนผิวโลกเป็นกิโลเมตร
  }

  /// 📌 แปลงอ็อบเจกต์ [MedicalFacility] ให้กลายเป็น Map JSON เพื่อจัดเก็บลง Local Storage
  static Map<String, dynamic> _facilityToJson(MedicalFacility f) {
    return {
      'id': f.id,
      'name': f.name,
      'type': f.type,
      'address': f.address,
      'latitude': f.latitude,
      'longitude': f.longitude,
      'phone': f.phone,
      'isOpen24Hours': f.isOpen24Hours,
      'imageUrl': f.imageUrl,
      'source': f.source,
      'website': f.website,
      'operator': f.operator,
      'hasEmergency': f.hasEmergency,
      'wheelchair': f.wheelchair,
      'openingHours': f.openingHours,
      'email': f.email,
      'description': f.description,
    };
  }

  /// 📌 แปลง Map JSON จาก Local Storage กลับเป็นอ็อบเจกต์ [MedicalFacility]
  static MedicalFacility _jsonToFacility(Map<String, dynamic> json) {
    return MedicalFacility(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'hospital',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
      isOpen24Hours: json['isOpen24Hours'] ?? false,
      imageUrl: json['imageUrl'],
      source: json['source'] ?? 'osm',
      website: json['website'],
      operator: json['operator'],
      hasEmergency: json['hasEmergency'] ?? false,
      wheelchair: json['wheelchair'],
      openingHours: json['openingHours'],
      email: json['email'],
      description: json['description'],
    );
  }
}
