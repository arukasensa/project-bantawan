// ============================================================================
// 🛣️ BANTAWAN Turn-by-Turn Routing Model: RouteResult & RouteStatus
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Navigation)              │
// ├─────────────────────────────────────────────────────────┤
// │                   Route Model Layer                     │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Polyline LatLng Path │    Distance & ETA         │  │
// │  │  (Map Line Drawing)   │ (Realtime Speed Estimate) │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Turn-by-turn Steps   │    RouteStatus State      │  │
// │  │  (Maneuver Directions)│ (Idle/Loading/Success/Err)│  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// โมเดลข้อมูลเส้นทางการนำทาง (Route Model)
// ใช้สำหรับจัดเก็บจุดพิกัดเส้นทาง (Polyline), ระยะทางรวม, เวลาประมาณการ (ETA), และขั้นตอนการเลี้ยว
// ============================================================================

import 'package:latlong2/latlong.dart';

/// 🚦 สถานะการคำนวณเส้นทาง (Route Calculation Status)
enum RouteStatus {
  /// สถานะว่าง ยังไม่มีการคำนวณเส้นทาง
  idle,

  /// กำลังร้องขอและคำนวณเส้นทางจาก Routing Service
  loading,

  /// คำนวณเส้นทางสำเร็จและพร้อมแสดงผล
  success,

  /// เกิดข้อผิดพลาดในการคำนวณเส้นทาง
  error
}

/// 🛣️ คลาสเก็บผลลัพธ์การคำนวณเส้นทางนำทาง (Route Result Model)
class RouteResult {
  /// รายการจุดพิกัด LatLng ทั้งหมดตามแนวเส้นทาง (สำหรับวาด Polyline บนแผนที่)
  final List<LatLng> points;

  /// ระยะทางรวมทั้งหมด (กิโลเมตร)
  final double distanceKm;

  /// เวลาโดยประมาณที่จะถึงเป้าหมาย (Estimated Time of Arrival - ETA)
  final String eta;

  /// รายการขั้นตอนแนะนำการเลี้ยว/ทิศทางการเดินทาง (Turn-by-turn instructions)
  final List<Map<String, dynamic>> instructions;

  /// ข้อความระบุข้อผิดพลาด (กรณี status เป็น error)
  final String? error;

  /// สถานะปัจจุบันของผลลัพธ์เส้นทาง
  final RouteStatus status;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.eta,
    required this.instructions,
    this.error,
    this.status = RouteStatus.success,
  });

  /// Factory constructor สำหรับสร้าง RouteResult เมื่อเกิดข้อผิดพลาด
  factory RouteResult.withError(String message) {
    return RouteResult(
      points: [],
      distanceKm: 0.0,
      eta: 'N/A',
      instructions: [],
      error: message,
      status: RouteStatus.error,
    );
  }
}
