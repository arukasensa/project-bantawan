// ============================================================================
// 🗺️ BANTAWAN Overpass / OpenStreetMap Query Service: OverpassService
//
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │             (Offline-Ready Medical POI Data)            │
// ├─────────────────────────────────────────────────────────┤
// │                   OverpassService                       │
// │  ┌───────────────────────────────────────────────────┐  │
// │  │              Overpass API Mirrors                 │  │
// │  │  (True First-Win Racing: เลือก Mirror เร็วที่สุด)  │  │
// │  │  overpass-api.de / lz4 / kumi / private.coffee   │  │
// │  └───────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
//
// บริการสืบค้นข้อมูลพิกัดสถานพยาบาลจาก OpenStreetMap ผ่าน Overpass API
// ใช้เทคนิค True First-Win Racing: ยิงหลาย Endpoint พร้อมกันแบบ Parallel
// และเลือก Mirror แรกที่ตอบกลับสำเร็จ (ไม่ต้องรอทุก Mirror เสร็จ)
// แบ่ง Query เป็น 2 ชุดเบาๆ เพื่อหลีกเลี่ยง Server-Side Timeout
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/medical_facility_classifier.dart';

/// 🏛️ คลาสบริการดึงข้อมูลพิกัดสถานพยาบาลจาก OpenStreetMap (OverpassService)
/// ทุกเมธอดเป็น static เรียกใช้ได้ทันทีโดยไม่ต้องสร้างอินสแตนซ์
class OverpassService {
  // ----------------------------------------------------------------------------
  // 🌐 Mirror Endpoints (ยิงพร้อมกันเพื่อหาตัวที่เร็วที่สุด)
  // ----------------------------------------------------------------------------
  /// รายชื่อ Overpass API Mirror ทั้งหมดสำหรับ Load Racing (มี CORS Header รองรับ Flutter Web)
  static const List<String> _overpassUrls = [
    'https://overpass-api.de/api/interpreter',       // Mirror หลักของเยอรมัน
    'https://lz4.overpass-api.de/api/interpreter',   // Mirror LZ4 compression
    'https://overpass.kumi.systems/api/interpreter',  // Mirror ทั่วโลก (Kumi)
    'https://overpass.private.coffee/api/interpreter',
  ];

  // ============================================================================
  // 🔍 Section 1: Main Query Entry Point
  // ============================================================================

  /// 📌 ดึงข้อมูลสถานพยาบาลรอบพิกัด [center] ในรัศมี [radiusInKm] กิโลเมตร
  /// แบ่งเป็น 2 Query ขนาน (amenity + healthcare) เพื่อลด Complexity และหลีกเลี่ยง Timeout
  static Future<List<Map<String, dynamic>>> fetchMedicalNearby(
    LatLng center,
    double radiusInKm,
  ) async {
    // จำกัดรัศมีของ Overpass สูงสุดที่ 10 กม. เพื่อหลีกเลี่ยง Server Timeout / 429
    // โดย Longdo POI API จะเป็นผู้ให้บริการครอบคลุมระยะ 50 กม. ทั้งหมด
    final double effectiveRadiusKm = radiusInKm.clamp(1.0, 10.0);
    final double radiusInMeters = effectiveRadiusKm * 1000;
    const int serverTimeout = 12;

    // Query ชุดที่ 1: amenity=hospital/clinic/pharmacy/doctors (สถานพยาบาลหลัก)
    final String queryAmenity = '''
[out:json][timeout:$serverTimeout];
(
  node["amenity"~"hospital|clinic|pharmacy|doctors|health_post|nursing_home"](around:$radiusInMeters,${center.latitude},${center.longitude});
  way["amenity"~"hospital|clinic|pharmacy|doctors|health_post|nursing_home"](around:$radiusInMeters,${center.latitude},${center.longitude});
);
out tags center qt 150;
''';

    // Query ชุดที่ 2: healthcare=* (ครอบคลุมสถานพยาบาลที่ tag ด้วย healthcare แทน amenity)
    final String queryHealthcare = '''
[out:json][timeout:$serverTimeout];
(
  node["healthcare"](around:$radiusInMeters,${center.latitude},${center.longitude});
  way["healthcare"](around:$radiusInMeters,${center.latitude},${center.longitude});
);
out tags center qt 150;
''';

    // Query ชุดที่ 3: building=hospital (อาคารโรงพยาบาลที่อาจยังไม่มี amenity tag)
    final String queryBuilding = '''
[out:json][timeout:$serverTimeout];
(
  node["building"="hospital"](around:$radiusInMeters,${center.latitude},${center.longitude});
  way["building"="hospital"](around:$radiusInMeters,${center.latitude},${center.longitude});
);
out tags center qt 100;
''';

    // ยิง 3 query ขนานกัน แต่ละ query ใช้ True First-Win Racing ข้าม mirrors
    final results = await Future.wait([
      _fetchWithFirstWin(queryAmenity, serverTimeout + 5),
      _fetchWithFirstWin(queryHealthcare, serverTimeout + 5),
      _fetchWithFirstWin(queryBuilding, serverTimeout + 5),
    ], eagerError: false);

    // รวมผลลัพธ์ทั้ง 3 query และ de-duplicate ด้วย OSM id
    final Map<String, Map<String, dynamic>> unique = {};
    for (final list in results) {
      for (final item in list) {
        final id = item['id'] as String? ?? '';
        if (id.isNotEmpty) unique[id] = item;
      }
    }
    return unique.values.toList();
  }

  // ============================================================================
  // 🏁 Section 2: True First-Win Mirror Racing Strategy
  // ============================================================================

  /// 📌 ยิงคำขอไปยังทุก Mirror พร้อมกัน และคืนผลจาก Mirror แรกที่ตอบกลับสำเร็จ (มีข้อมูล)
  /// ใช้ Completer เพื่อให้ได้ผลทันที ไม่ต้องรอ Mirror ช้าๆ เสร็จทั้งหมด
  static Future<List<Map<String, dynamic>>> _fetchWithFirstWin(
    String query,
    int timeoutSec,
  ) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    int remaining = _overpassUrls.length;

    for (final url in _overpassUrls) {
      _fetchFromUrl(url, query, timeoutSec).then((result) {
        // Mirror แรกที่มีข้อมูลจริง → คืนผลทันที
        if (result.isNotEmpty && !completer.isCompleted) {
          completer.complete(result);
        }
        remaining--;
        // Mirror ทั้งหมดล้มเหลว → คืน list ว่าง
        if (remaining <= 0 && !completer.isCompleted) {
          completer.complete([]);
        }
      }).catchError((_) {
        remaining--;
        if (remaining <= 0 && !completer.isCompleted) {
          completer.complete([]);
        }
      });
    }

    // Fallback timeout กรณีไม่มี Mirror ใดตอบกลับเลย
    return completer.future.timeout(
      Duration(seconds: timeoutSec + 10),
      onTimeout: () {
        debugPrint('[Overpass] All mirrors timed out.');
        return [];
      },
    );
  }

  // ============================================================================
  // 📡 Section 3: Single URL Request & Data Normalization
  // ============================================================================

  /// 📌 ยิง HTTP POST ไปยัง Overpass Mirror URL เดียวและแปลงผลลัพธ์เป็น List ของ Map
  static Future<List<Map<String, dynamic>>> _fetchFromUrl(
    String url,
    String query,
    int timeoutSec,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            body: {'data': query},
          )
          .timeout(Duration(seconds: timeoutSec));

      if (response.statusCode == 200) {
        // ถอดรหัส UTF-8 อย่างชัดเจน เพื่อรองรับชื่อภาษาไทย
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List? ?? [];

        return elements
            .where((e) {
              // กรองเอาเฉพาะ Element ที่มีพิกัดที่ถูกต้อง
              final lat = e['lat'] ?? e['center']?['lat'];
              final lon = e['lon'] ?? e['center']?['lon'];
              if (lat == null || lon == null) return false;

              // กรองสัตวแพทย์และคลินิกสัตว์ออกทันที
              final tags = e['tags'] as Map<String, dynamic>? ?? {};
              final amenity = tags['amenity'] as String? ?? '';
              final healthcare = tags['healthcare'] as String? ?? '';
              if (amenity == 'veterinary' || healthcare == 'veterinary') return false;

              return true;
            })
            .map((e) => _normalizeElement(e))
            .where((m) => m != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      debugPrint('[Overpass] Error ($url): $e');
    }
    return [];
  }

  // ============================================================================
  // 🔄 Section 4: Element Normalization
  // ============================================================================

  /// 📌 แปลง OSM Element ดิบให้เป็น Map มาตรฐานของแอป
  static Map<String, dynamic>? _normalizeElement(dynamic e) {
    final tags = e['tags'] as Map<String, dynamic>? ?? {};
    final amenity = tags['amenity'] as String? ?? '';
    final healthcare = tags['healthcare'] as String? ?? '';
    final building = tags['building'] as String? ?? '';

    // ชื่อภาษาไทยก่อน ถ้าไม่มีใช้ชื่อภาษาอังกฤษ
    final name = tags['name:th'] ??
        tags['name'] ??
        tags['name:en'] ??
        'ไม่ทราบชื่อ (OSM)';

    // กรองสถานที่ที่ติด Blacklist (สัตว์เลี้ยง, ขนส่ง, อาหาร, กีฬา, ทหาร ฯลฯ) ออก
    if (MedicalFacilityClassifier.isBlacklisted(name, amenity: amenity, healthcare: healthcare)) {
      return null;
    }

    // ใช้ MedicalFacilityClassifier จำแนกและคัดกรอง
    final classified = MedicalFacilityClassifier.classify(
      name: name,
      amenity: amenity,
      healthcare: healthcare,
      building: building,
    );

    // หากไม่ผ่านการจำแนกว่าเป็นสถานพยาบาลมนุษย์แท้จริง ให้ตัดทิ้งทันที
    if (classified == null) {
      return null;
    }

    final String normalizedType = classified;

    return {
      'id': 'osm_${e['id']}',
      'name': name,
      'type': normalizedType,
      'lat': e['lat'] ?? e['center']?['lat'],
      'lon': e['lon'] ?? e['center']?['lon'],
      'address': tags['addr:full'] ?? _buildAddress(tags),
      'tel': tags['phone'] ?? tags['contact:phone'] ?? tags['contact:mobile'] ?? '',
      'source': 'osm',
      'website': tags['website'] ?? tags['contact:website'] ?? '',
      'opening_hours': tags['opening_hours'] ?? '',
      'operator': tags['operator'] ?? tags['operator:th'] ?? '',
      'wheelchair': tags['wheelchair'] ?? '',
      'description': tags['description'] ?? tags['description:th'] ?? '',
      'email': tags['email'] ?? tags['contact:email'] ?? '',
      'emergency': tags['emergency'] ?? '',
    };
  }

  // ============================================================================
  // 🧮 Section 5: Address Builder Helper
  // ============================================================================

  /// 📌 สร้างที่อยู่แบบ Human-readable จาก Tags ของ OSM Element
  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:subdistrict'] ?? tags['addr:suburb'],
      tags['addr:district'],
      tags['addr:city'] ?? tags['addr:province'],
    ].where((p) => p != null).toList();

    return parts.isEmpty ? 'ข้อมูลใน OpenStreetMap' : parts.join(' ');
  }
}
