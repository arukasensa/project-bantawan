// ============================================================================
// 🏥 BANTAWAN POI Repository Implementation: PoiRepositoryImpl
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (MapProvider / Tactical Search)              │
// ├─────────────────────────────────────────────────────────┤
// │                   IPoiRepository                        │
// ├─────────────────────────────────────────────────────────┤
// │                 PoiRepositoryImpl                       │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │   Online REST APIs    │    Offline Persistence    │  │
// │  │ (Longdo Map API, OSM) │ (PoiCacheService SQLite)  │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// รับผิดชอบการสืบค้นและรวบรวมข้อมูลสถานพยาบาล (โรงพยาบาล, คลินิก, ร้านขายยา)
// ดำเนินการยิงคำขอแบบขนาน (Parallel Requests) ระหว่าง Longdo Map และ Overpass API
// พร้อมระบบ Fallback ดึงข้อมูลจาก Local SQLite Cache เมื่อเกิดปัญหาเครือข่าย
// ============================================================================

import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/facility_type.dart';
import '../models/medical_facility.dart';
import '../features/map/services/longdo_service.dart';
import '../features/map/services/overpass_service.dart';
import '../features/home/services/connectivity_service.dart';
import '../core/database/poi_cache_service.dart';
import 'i_poi_repository.dart';

/// 🏛️ คลาสอิมพลีเมนต์ระบบสืบค้นข้อมูลสถานพยาบาล (PoiRepositoryImpl)
class PoiRepositoryImpl implements IPoiRepository {
  /// 📌 ดึงข้อมูลสถานพยาบาลรอบพิกัดที่กำหนด ทั้งโหมดออนไลน์และออฟไลน์
  /// - [location]: พิกัดตำแหน่งศูนย์กลางการค้นหา (LatLng)
  /// - [radiusKm]: รัศมีการค้นหา (กิโลเมตร)
  /// - [type]: ประเภทสถานที่ที่ต้องการกรอง (hospital, clinic, pharmacy) หรือ null เพื่อดึงทั้งหมด
  /// - [forceRefresh]: บังคับดึงข้อมูลใหม่จาก Server ทันทีโดยไม่สนอายุของแคชเดิม
  /// ส่งคืนรายการอ็อบเจกต์ [MedicalFacility] ทั้งหมดที่ค้นพบ
  @override
  Future<List<MedicalFacility>> getNearbyFacilities({
    required LatLng location,
    required double radiusKm,
    FacilityType? type,
    bool forceRefresh = false,
  }) async {
    // 1. ตรวจสอบสถานะการเชื่อมต่ออินเทอร์เน็ตของเครื่อง
    final connectivity = ConnectivityService().currentResult;
    final isOffline = connectivity == ConnectivityResult.none;

    // 2. หากอยู่ในโหมดออฟไลน์: สลับไปดึงข้อมูลจากแคชในเครื่องทันที
    if (isOffline) {
      return await PoiCacheService.getCachedFacilities(
        userLat: location.latitude,
        userLng: location.longitude,
        radiusKm: radiusKm,
        type: type,
      );
    }

    // 3. โหมดออนไลน์: ดึงพิกัดจาก REST APIs แบบคู่ขนาน
    try {
      if (!forceRefresh) {
        // ตรวจสอบความถูกต้องและความครอบคลุมของแคชปัจจุบัน (ยังไม่หมดอายุและรัศมีครอบคลุม)
        final isCacheValid = await PoiCacheService.isCacheValid(
          userLat: location.latitude,
          userLng: location.longitude,
          radiusKm: radiusKm,
        );

        if (isCacheValid) {
          // หากแคชยังสดใหม่ ไม่จำเป็นต้องยิง API ให้เปลืองเน็ตและแบตเตอรี่ คืนค่าแคชได้ทันที
          return await PoiCacheService.getCachedFacilities(
            userLat: location.latitude,
            userLng: location.longitude,
            radiusKm: radiusKm,
            type: type,
          );
        }
      }

      final span = '${radiusKm.toInt()}km';

      // ─── Longdo Multi-Query Parallel Search ───
      // ยิงขนาน 10+ query ด้วย keyword/tag ภาษาไทยครอบคลุมทุกประเภท
      final List<Future<List<Map<String, dynamic>>>> longdoFutures = [];
      final List<Future<List<Map<String, dynamic>>>> osmFutures = [];

      if (type == null || type == FacilityType.hospital) {
        longdoFutures.add(LongdoService.searchNearbyPOI(tag: 'hospital', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'โรงพยาบาล', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'รพ.', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'hospital', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
      }
      if (type == null || type == FacilityType.clinic) {
        // ในฐานข้อมูล Longdo คลินิกส่วนใหญ่ค้นหาด้วยคำว่า คลินิก, หมอ, แพทย์, รพ.สต., ทันตกรรม
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'คลินิก', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'หมอ', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'แพทย์', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'ทันตกรรม', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'รพ.สต.', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'อนามัย', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'clinic', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
      }
      if (type == null || type == FacilityType.pharmacy) {
        longdoFutures.add(LongdoService.searchNearbyPOI(tag: 'pharmacy', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'ร้านขายยา', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'ร้านยา', location: location, limit: 500, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'เภสัช', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
        longdoFutures.add(LongdoService.searchNearbyPOI(keyword: 'pharmacy', location: location, limit: 300, span: span).catchError((_) => <Map<String, dynamic>>[]));
      }

      // ─── Overpass API (OSM) ───
      osmFutures.add(OverpassService.fetchMedicalNearby(location, radiusKm).catchError((e) {
        debugPrint('[POI Rep] Overpass Error: $e');
        return <Map<String, dynamic>>[];
      }));

      // ยิง Longdo และ Overpass พร้อมกัน
      final allFutures = [...longdoFutures, ...osmFutures];
      final resultsList = await Future.wait(allFutures);

      final int osmStart = longdoFutures.length;

      // รวมผลลัพธ์จาก Longdo
      final List<Map<String, dynamic>> longdoResults = [];
      for (int i = 0; i < osmStart; i++) {
        longdoResults.addAll(resultsList[i]);
      }
      // รวมผลลัพธ์จาก OSM
      final List<Map<String, dynamic>> osmResults = [];
      for (int i = osmStart; i < resultsList.length; i++) {
        osmResults.addAll(resultsList[i]);
      }

      final List<MedicalFacility> allConverted = [];

      // 4. แปลงผลลัพธ์ของ Longdo — จำแนกประเภท hospital, clinic, pharmacy อย่างแม่นยำ
      allConverted.addAll(
        longdoResults
            .where((item) => item['id'] != null && item['name'] != null)
            .map((item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final tag = (item['tag'] ?? '').toString().toLowerCase();

          String detectedType = 'clinic'; // default สำหรับสถานพยาบาลย่อย
          if (tag.contains('pharmacy') ||
              name.contains('ยา') ||
              name.contains('เภสัช') ||
              name.contains('pharmacy') ||
              name.contains('drug')) {
            detectedType = 'pharmacy';
          } else if (name.contains('โรงพยาบาล') ||
              name.contains('hospital') ||
              (name.contains('รพ.') && !name.contains('รพ.สต.'))) {
            detectedType = 'hospital';
          } else if (tag.contains('clinic') ||
              name.contains('คลินิก') ||
              name.contains('clinic') ||
              name.contains('หมอ') ||
              name.contains('แพทย์') ||
              name.contains('การแพทย์') ||
              name.contains('อนามัย') ||
              name.contains('รพ.สต.') ||
              name.contains('สุขศาลา') ||
              name.contains('ทันต') ||
              name.contains('dental') ||
              name.contains('eye') ||
              name.contains('พยาบาล')) {
            detectedType = 'clinic';
          } else if (tag.contains('hospital')) {
            detectedType = 'hospital';
          }

          final rawName = (item['name'] ?? '').toString();
          final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;

          return MedicalFacility(
            id: item['id']?.toString() ?? UniqueKey().toString(),
            name: rawName,
            type: detectedType,
            address: item['address'] ?? 'ไม่มีข้อมูลที่อยู่',
            latitude: lat,
            longitude: lon,
            phone: item['tel'] ?? '',
            website: item['url'],
            isOpen24Hours: rawName.contains('24') || rawName.contains('ตลอด 24'),
            source: 'longdo',
          );
        }).where((f) {
          if (f.latitude == 0.0 || f.longitude == 0.0) return false;
          if (type == null) return true;
          final fType = f.type.toLowerCase();
          if (type == FacilityType.hospital && fType != 'hospital') return false;
          if (type == FacilityType.clinic && fType != 'clinic') return false;
          if (type == FacilityType.pharmacy && fType != 'pharmacy') return false;
          return true;
        }),
      );

      // 5. แปลงผลลัพธ์ของ OSM (Overpass)
      // กรองประเภทในฝั่งแอปตามโครงสร้างอินเทอร์เน็ตที่ได้สเปกมา
      allConverted.addAll(
        osmResults
            .map((item) {
              return MedicalFacility(
                id: item['id'] ?? UniqueKey().toString(),
                name: item['name'] ?? 'ไม่ทราบชื่อ (OSM)',
                type: item['type'] ?? 'hospital',
                address: item['address'] ?? 'OpenStreetMap Facility',
                latitude: double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0,
                longitude: double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0,
                phone: item['tel'] ?? '',
                source: 'osm',
                website: item['website'],
                operator: item['operator'],
                hasEmergency: item['emergency'] == 'yes',
                wheelchair: item['wheelchair'],
                openingHours: item['opening_hours'],
              );
            })
            .where((f) {
              // กรองสเตตัสในแอปให้ตรงกับประเภทที่คัดเลือก
              if (type == null) return true;
              final fType = f.type.toLowerCase();
              if (type == FacilityType.hospital && fType != 'hospital') return false;
              if (type == FacilityType.clinic && fType != 'clinic') return false;
              if (type == FacilityType.pharmacy && fType != 'pharmacy') return false;
              return true;
            }),
      );

      // 6. De-duplicate: กำจัดซ้ำด้วย ID และครอบคลุม near-duplicate (OSM + Longdo อาจส่งสถานที่เดียวกัน)
      final Map<String, MedicalFacility> uniqueById = {};
      for (final f in allConverted) {
        uniqueById[f.id] = f;
      }

      // Near-duplicate: รวมสถานที่ที่พิกัดห่างกันไม่เกิน 15 เมตร และชื่อคล้ายกัน
      final List<MedicalFacility> deduped = [];
      for (final f in uniqueById.values) {
        bool isDup = false;
        for (final existing in deduped) {
          final dLat = (f.latitude - existing.latitude).abs();
          final dLon = (f.longitude - existing.longitude).abs();
          if (dLat < 0.00015 && dLon < 0.00015) {
            isDup = true;
            break;
          }
        }
        if (!isDup) deduped.add(f);
      }

      final List<MedicalFacility> result = deduped.take(2000).toList();

      // บันทึกอัปเดตแคชลงเครื่องออฟไลน์แบบอะซิงค์ (เบื้องหลัง)
      PoiCacheService.saveFacilities(
        result,
        centerLat: location.latitude,
        centerLng: location.longitude,
        radiusKm: radiusKm,
      );

      return result;
    } catch (e) {
      // หากยิง API ล้มเหลว ให้ดึงค่าในแคชที่บันทึกไว้ในเครื่องทดแทนทันที
      return await PoiCacheService.getCachedFacilities(
        userLat: location.latitude,
        userLng: location.longitude,
        radiusKm: radiusKm,
        type: type,
      );
    }
  }
}
