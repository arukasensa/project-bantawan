// สัญญาส่วนต่อประสานระบบค้นหาเส้นทางนำทาง (Routing Repository Interface)
// กำหนดมาตรฐานสำหรับการคำนวณเส้นทางและขั้นตอนการเดินทางระหว่างสองพิกัด

import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

/// อินเทอร์เฟซสำหรับค้นหาและคำนวณเส้นทางการเดินทาง
abstract class IRoutingRepository {
  /// คำนวณเส้นทางระหว่างจุดเริ่มต้นและจุดสิ้นสุด
  /// - [start]: พิกัดตำแหน่งเริ่มต้น (จุดปล่อยตัว/ตำแหน่งผู้ใช้)
  /// - [end]: พิกัดตำแหน่งปลายทาง (สถานพยาบาล/จุดหมาย)
  /// ส่งคืนผลลัพธ์ [RouteResult] ซึ่งประกอบด้วยพิกัด Polyline, ระยะทาง และเวลาเดินทาง
  Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
  });
}
