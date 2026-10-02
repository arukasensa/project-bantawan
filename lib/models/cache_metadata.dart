// โมเดลเก็บข้อมูล Metadata ของการบันทึกแคช (Cache Metadata)
// ใช้สำหรับตรวจสอบความสดใหม่ของข้อมูลออฟไลน์ (พิกัดล่าสุด, รัศมีการค้นหา, เวลาที่อัปเดต)

/// คลาสเก็บข้อมูลเมทาดาทาของแคชสถานที่/แผนที่
class CacheMetadata {
  /// เวลาที่ทำการอัปเดตข้อมูลแคชล่าสุด
  final DateTime lastUpdated;

  /// ละติจูดศูนย์กลางของจุดที่แคชข้อมูล
  final double latitude;

  /// ลองจิจูดศูนย์กลางของจุดที่แคชข้อมูล
  final double longitude;

  /// รัศมีการค้นหาและบันทึกข้อมูล (กิโลเมตร)
  final double radiusKm;

  CacheMetadata({
    required this.lastUpdated,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  /// แปลงข้อมูลจาก JSON Map เป็นอ็อบเจกต์ CacheMetadata
  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// แปลงอ็อบเจกต์ CacheMetadata เป็น JSON Map เพื่อบันทึกลงฐานข้อมูลหรือ Storage
  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
    };
  }
}
