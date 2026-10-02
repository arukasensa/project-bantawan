// ============================================================================
// 🧭 BANTAWAN Routing Repository Implementation: RoutingRepositoryImpl
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (MapProvider / Tactical Navigation)          │
// ├─────────────────────────────────────────────────────────┤
// │                  IRoutingRepository                     │
// ├─────────────────────────────────────────────────────────┤
// │                 RoutingRepositoryImpl                   │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │    Online Road OSRM   │     Offline Compass       │  │
// │  │  (Turn-by-turn steps) │ (Direct Vector Fallback)  │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// ตัวจัดการคำนวณเส้นทางนำทางจริง (Routing Repository Implementation)
// - โหมดออนไลน์: ร้องขอเส้นทางถนนจริง (Driving Turn-by-Turn) จาก Project OSRM API
// - โหมดออฟไลน์ / กรณี API ขัดข้อง: สลับไปคำนวณเส้นทางตรง (Great-Circle Distance)
//   พร้อมคำนวณเวลาเดินทางเท้า (Walking ETA: 5 km/h) อัตโนมัติ
// ============================================================================

import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/home/services/connectivity_service.dart';
import '../models/route_model.dart';
import 'i_routing_repository.dart';

/// 🏛️ คลาสอิมพลีเมนต์ระบบคำนวณเส้นทางนำทาง (RoutingRepositoryImpl)
/// ทำหน้าที่เป็นสะพานเชื่อมระหว่าง UI/Provider กับ API การเดินรถภายนอกและการคำนวณสำรองยามฉุกเฉิน
class RoutingRepositoryImpl implements IRoutingRepository {
  /// 📌 คำนวณเส้นทางระหว่างจุดเริ่มต้นและจุดหมายปลายทาง
  /// - [start]: พิกัดตำแหน่งเริ่มต้น (LatLng)
  /// - [end]: พิกัดตำแหน่งปลายทาง (LatLng)
  /// ส่งคืนอ็อบเจกต์ [RouteResult] ที่ประกอบด้วย พิกัด Polyline, ระยะทาง (กม.), เวลาประเมิน (ETA), และคำแนะนำการเลี้ยว
  @override
  Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    // 1. ตรวจสอบสถานะการเชื่อมต่อเครือข่ายอินเทอร์เน็ต
    final connectivity = ConnectivityService().currentResult;
    final isOffline = connectivity == ConnectivityResult.none;

    // 2. หากออฟไลน์ สลับไปคำนวณเวกเตอร์เส้นตรงนำร่องทันทีโดยไม่ต้องเสียเวลายิง Network
    if (isOffline) {
      return _buildOfflineFallback(start, end);
    }

    // 3. เตรียม URL สำหรับเรียก OSRM Driving Service
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}?overview=full&geometries=polyline&steps=true',
    );

    try {
      // 4. ส่ง HTTP GET ไปยัง OSRM พร้อมตั้งเวลา Timeout 8 วินาที เพื่อป้องกันหน้าค้าง
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      
      // 5. หากได้รับสถานะตอบกลับสำเร็จ (HTTP 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;
        
        if (routes.isNotEmpty) {
          final route = routes[0]; // เลือกเส้นทางที่ดีที่สุด (Index 0)
          final polyline = route['geometry'] as String; // รหัสเส้นทางบีบอัด (Encoded Polyline)
          final duration = (route['duration'] as num).toDouble(); // วินาที
          final distance = (route['distance'] as num).toDouble(); // เมตร
          final legs = route['legs'] as List;
          
          // ดึงคำแนะนำการเลี้ยวแต่ละช่วง (Turn-by-turn Navigation Steps)
          List<Map<String, dynamic>> instructions = [];
          if (legs.isNotEmpty) {
            final steps = legs[0]['steps'] as List;
            instructions = steps.map((s) => s as Map<String, dynamic>).toList();
          }

          // ถอดรหัส Polyline String ให้เป็นรายการพิกัด LatLng
          List<PointLatLng> result = PolylinePoints.decodePolyline(polyline);
          final points = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

          return RouteResult(
            points: points,
            distanceKm: distance / 1000, // แปลงเมตรเป็นกิโลเมตร
            eta: '${(duration / 60).round()} นาที', // แปลงวินาทีเป็นนาที
            instructions: instructions,
          );
        }
      }
      // หากเซิร์ฟเวอร์ตอบกลับแต่ไม่มีเส้นทาง ให้เข้าสู่โหมด Fallback
      return _buildOfflineFallback(start, end);
    } catch (_) {
      // 6. สลับไปใช้ Fallback ทันทีเมื่อเกิด Network Timeout หรือ API ล่ม
      return _buildOfflineFallback(start, end);
    }
  }

  /// 📌 คำนวณเส้นทางนำร่องแบบเวกเตอร์แนวตรง (Offline Direct Vector) ยามฉุกเฉินที่ไม่มีสัญญาณอินเทอร์เน็ต
  /// - [start]: พิกัดจุดเริ่มต้น
  /// - [end]: พิกัดจุดหมาย
  /// ประเมินระยะห่างตามแนวเส้นโค้งโลก (Geodesic) และประเมินเวลาเดินเท้าด้วยความเร็ว 5 กม./ชม.
  RouteResult _buildOfflineFallback(LatLng start, LatLng end) {
    // คำนวณระยะห่างระหว่างจุด 2 จุดด้วยสูตรทางภูมิศาสตร์ (ผลลัพธ์เป็นเมตร)
    final distanceMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    final distanceKm = distanceMeters / 1000.0;
    
    // ประเมินเวลาเดินเท้า: กำหนดอัตราความเร็วเฉลี่ยเดินเท้า 5 กม./ชั่วโมง
    final minutes = (distanceKm / 5.0 * 60).round();
    
    return RouteResult(
      points: [start, end], // ลากเส้นตรงเชื่อมพิกัดเริ่มต้นไปยังเป้าหมาย
      distanceKm: distanceKm,
      eta: '~$minutes นาที (เดินเท้า)',
      instructions: [
        {
          'maneuver': {'instruction': 'มุ่งหน้าไปในทิศทางพิกัดเป้าหมาย (โหมดนำทางออฟไลน์แนวตรง)'}
        }
      ],
      error: 'ทำงานในโหมดออฟไลน์: แสดงเส้นทางนำร่องแนวตรง',
    );
  }
}
