// ============================================================================
// 🗺️ BANTAWAN Longdo Map API Service: LongdoService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │             (Thai Map, Traffic & POI Search)            │
// ├─────────────────────────────────────────────────────────┤
// │                   LongdoService                         │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Longdo REST API      │   Longdo Search API       │  │
// │  │ (Traffic Incidents)   │ (Nearby POI / Emergency)  │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการเชื่อมต่อ Longdo Map Web Services สำหรับข้อมูลแผนที่ไทย
// - ดึงข้อมูลรายงานอุบัติเหตุ/จราจรบนท้องถนน (Traffic Incidents)
// - ค้นหาสถานพยาบาลใกล้เคียง (Nearby POI Search) ด้วย Tag และ Keyword ภาษาไทย
// - ให้บริการ URL ไทล์สภาพจราจรเรียลไทม์สำหรับแสดงบนแผนที่
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// 📦 โมเดลเก็บข้อมูลอุบัติเหตุหรือเหตุการณ์บนท้องถนนจาก Longdo Traffic API
class LongdoIncident {
  final String title;       // หัวข้อรายงานเหตุการณ์
  final String description; // รายละเอียดเพิ่มเติมของเหตุการณ์
  final LatLng location;    // พิกัดที่เกิดเหตุ
  final int type;           // ประเภทเหตุการณ์: 1=อุบัติเหตุ, 2=ก่อสร้าง, 3=จราจรติดขัด ฯลฯ

  LongdoIncident({
    required this.title,
    required this.description,
    required this.location,
    required this.type,
  });
}

/// 🏛️ คลาสบริการดึงข้อมูลแผนที่และสภาพจราจรจาก Longdo Map API (LongdoService)
class LongdoService {
  /// 🔑 API Key สำหรับยืนยันตัวตนกับ Longdo Map Services
  static const String _apiKey = 'dbdf5b58f8ab78d6646afdfc7bfdc2bc';

  /// 🌐 Base URL ของ Longdo REST API Services
  static const String _baseUrl = 'https://api.longdo.com/map/services';

  /// 🌐 สร้าง Uri สำหรับส่ง HTTP Request (รองรับ CORS Proxy สำหรับ Flutter Web)
  static Uri _buildUri(String path, Map<String, String> queryParams) {
    final directUri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    if (kIsWeb) {
      // โหมด Flutter Web: ใช้ CORS Proxy เพื่อให้เบราว์เซอร์ Chrome เรียกใช้ Longdo API ได้
      return Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(directUri.toString())}');
    }
    return directUri;
  }

  // ============================================================================
  // 🚦 Section 1: Traffic Incident Reports
  // ============================================================================

  /// 📌 ดึงข้อมูลรายงานอุบัติเหตุและเหตุการณ์จราจรทั่วไทยจาก Longdo Traffic API
  static Future<List<LongdoIncident>> getTrafficIncidents() async {
    final url = _buildUri('/rest/traffic', {
      'key': _apiKey,
      'type': 'incident',
    });
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) {
            return LongdoIncident(
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              location: LatLng(
                double.parse(item['lat'].toString()),
                double.parse(item['lon'].toString()),
              ),
              type: int.tryParse(item['type'].toString()) ?? 1,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Longdo Traffic Error: $e');
    }
    return [];
  }

  // ============================================================================
  // 📍 Section 2: POI Detail & Nearby Search
  // ============================================================================

  /// 📌 ดึงรายละเอียดเพิ่มเติมของสถานที่จาก Longdo ด้วย POI ID
  static Future<Map<String, dynamic>?> getPOIDetails(String poiId) async {
    final url = _buildUri('/poi/get', {
      'key': _apiKey,
      'id': poiId,
    });
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Longdo POI Detail Error: $e');
    }
    return null;
  }

  /// 📌 ค้นหาสถานที่ใกล้เคียงตามพิกัด (Nearby POI Search)
  static Future<List<Map<String, dynamic>>> searchNearbyPOI({
    String? tag,
    String? keyword,
    LatLng? location,
    double? lat,
    double? lon,
    int limit = 100,
    String span = '50km',
  }) async {
    try {
      final latitude = location?.latitude ?? lat ?? 7.0086;
      final longitude = location?.longitude ?? lon ?? 100.4747;

      final queryParams = <String, String>{
        'key': _apiKey,
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'span': span,
        'limit': limit.toString(),
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      };

      final directUri = Uri.parse('https://api.longdo.com/POIService/json/search')
          .replace(queryParameters: queryParams);
      final url = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(directUri.toString())}')
          : directUri;

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          final list = data['data'] as List;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Longdo Search POI Error: $e');
    }
    return [];
  }
}
