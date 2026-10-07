// ============================================================================
// 📊 BANTAWAN Hike Summary Model: HikeSummary
// 
// โมเดลสรุปผลรายงานกิจกรรมการเดินป่าและสถิติเส้นทาง (Hike Summary Report)
// บันทึกเวลาเริ่มต้น-สิ้นสุด, ระยะทางสะสม, จำนวนจุดไข่ปลา (Breadcrumbs),
// ระดับความสูง และชุดพิกัดเส้นทางเพื่อใช้นำทางย้อนรอย (Backtrack)
// ============================================================================

import 'package:latlong2/latlong.dart';

/// 📊 โมเดลสรุปผลรายงานกิจกรรมการเดินป่า (Hike Summary Report)
class HikeSummary {
  /// ⏱️ วันและเวลาที่เริ่มต้นกิจกรรมเดินป่า
  final DateTime startTime;

  /// 🏁 วันและเวลาที่สิ้นสุดกิจกรรมเดินป่า
  final DateTime endTime;

  /// ⏳ ระยะเวลาที่ใช้ในการเดินป่าทั้งหมด
  final Duration duration;

  /// 📏 ระยะทางสะสมทั้งหมดที่เดินได้ (กิโลเมตร)
  final double distanceKm;

  /// 📍 จำนวนจุดไข่ปลา (Breadcrumbs) ที่ระบบบันทึกไว้ตลอดเส้นทาง
  final int breadcrumbCount;

  /// ⛰️ ระดับความสูงจากระดับน้ำทะเล ณ จุดเริ่มต้น (เมตร)
  final double? startAltitude;

  /// 🏔️ ระดับความสูงสูงสุดที่วัดได้ตลอดเส้นทาง (เมตร)
  final double? maxAltitude;

  /// 🗺️ รายการพิกัดตำแหน่งทางเดินทั้งหมด (Trail Coordinates)
  final List<LatLng> trail;

  const HikeSummary({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceKm,
    required this.breadcrumbCount,
    this.startAltitude,
    this.maxAltitude,
    required this.trail,
  });

  /// ⏱️ คืนค่าเวลาในรูปแบบข้อความ HH:MM:SS
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  /// 📏 คืนค่าระยะทางพร้อมหน่วยเป็นกิโลเมตร (เช่น "3.45 กม.")
  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} กม.';
}

