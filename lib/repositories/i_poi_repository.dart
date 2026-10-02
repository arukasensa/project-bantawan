// สัญญาส่วนต่อประสานระบบข้อมูลสถานที่ (POI Repository Interface)
// กำหนดมาตรฐานสำหรับดึงข้อมูลสถานพยาบาลและจุดช่วยเหลือ ทั้งแบบออนไลน์และออฟไลน์

import 'package:latlong2/latlong.dart';
import '../models/facility_type.dart';
import '../models/medical_facility.dart';

/// อินเทอร์เฟซสำหรับเข้าถึงข้อมูลสถานพยาบาล (Point of Interest - POI)
abstract class IPoiRepository {
  /// ค้นหาสถานพยาบาลใกล้เคียงพิกัดที่กำหนด
  /// - [location]: พิกัดตำแหน่งปัจจุบันของผู้ใช้
  /// - [radiusKm]: รัศมีการค้นหา (กิโลเมตร)
  /// - [type]: ประเภทสถานที่ที่ต้องการกรอง (hospital, clinic, pharmacy) หากเป็น null จะดึงทุกประเภท
  /// - [forceRefresh]: บังคับดึงข้อมูลใหม่จาก Server แม้ว่าแคชในเครื่องจะยังไม่หมดอายุ
  Future<List<MedicalFacility>> getNearbyFacilities({
    required LatLng location,
    required double radiusKm,
    FacilityType? type,
    bool forceRefresh = false,
  });
}
