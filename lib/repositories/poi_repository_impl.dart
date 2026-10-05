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
import '../core/utils/medical_facility_classifier.dart';
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
      // ยิงค้นหาด้วย keyword/tag ที่เจาะจงเฉพาะสถานพยาบาลจริง
      final List<Future<List<Map<String, dynamic>>>> longdoFutures = [];
      final List<Future<List<Map<String, dynamic>>>> osmFutures = [];

      // Helper function to query Longdo and attach source intent
      Future<List<Map<String, dynamic>>> queryLongdo({
        String? tag,
        String? keyword,
        required String defaultType,
      }) async {
        try {
          final res = await LongdoService.searchNearbyPOI(
            tag: tag,
            keyword: keyword,
            location: location,
            limit: tag != null ? 500 : 300,
            span: span,
          );
          for (final item in res) {
            item['_queryType'] = defaultType;
          }
          return res;
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }

      if (type == null || type == FacilityType.hospital) {
        longdoFutures.add(queryLongdo(tag: 'hospital', defaultType: 'hospital'));
        longdoFutures.add(queryLongdo(keyword: 'โรงพยาบาล', defaultType: 'hospital'));
        longdoFutures.add(queryLongdo(keyword: 'hospital', defaultType: 'hospital'));
        longdoFutures.add(queryLongdo(keyword: 'ศูนย์การแพทย์', defaultType: 'hospital'));
      }
      if (type == null || type == FacilityType.clinic) {
        // ค้นหาคลินิก สถานีอนามัย รพ.สต. และทันตกรรม
        longdoFutures.add(queryLongdo(tag: 'clinic', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'คลินิก', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'clinic', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'ทันตกรรม', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'รพ.สต.', defaultType: 'hospital')); // รพ.สต. เป็นโรงพยาบาล
        longdoFutures.add(queryLongdo(keyword: 'โรงพยาบาลส่งเสริมสุขภาพตำบล', defaultType: 'hospital'));
        longdoFutures.add(queryLongdo(keyword: 'สถานีอนามัย', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'ศูนย์บริการสาธารณสุข', defaultType: 'clinic'));
        longdoFutures.add(queryLongdo(keyword: 'คลินิกเวชกรรม', defaultType: 'clinic'));
      }
      if (type == null || type == FacilityType.pharmacy) {
        // เจาะจงเฉพาะร้านขายยาและเภสัชกรรม ป้องกันคำว่า 'ยา' ปลอม
        longdoFutures.add(queryLongdo(tag: 'pharmacy', defaultType: 'pharmacy'));
        longdoFutures.add(queryLongdo(keyword: 'ร้านขายยา', defaultType: 'pharmacy'));
        longdoFutures.add(queryLongdo(keyword: 'ร้านยา', defaultType: 'pharmacy'));
        longdoFutures.add(queryLongdo(keyword: 'เภสัช', defaultType: 'pharmacy'));
        longdoFutures.add(queryLongdo(keyword: 'pharmacy', defaultType: 'pharmacy'));
        longdoFutures.add(queryLongdo(keyword: 'ฟาร์มาซี', defaultType: 'pharmacy'));
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

      // 4. แปลงผลลัพธ์ของ Longdo — จำแนกประเภท hospital, clinic, pharmacy ด้วย MedicalFacilityClassifier
      allConverted.addAll(
        longdoResults
            .where((item) => item['id'] != null && item['name'] != null)
            .map((item) {
          final rawName = (item['name'] ?? '').toString().trim();
          final rawTag = (item['tag'] ?? '').toString().trim();

          // หากติด Blacklist (สัตว์เลี้ยง, ขนส่ง, ร้านอาหาร, กีฬา, ทหาร, สำนักงาน ฯลฯ) ตัดทิ้งทันที
          if (MedicalFacilityClassifier.isBlacklisted(rawName, tag: rawTag)) {
            return null;
          }

          final detectedType = MedicalFacilityClassifier.classify(
            name: rawName,
            tag: rawTag,
          );

          // ⚠️ หากไม่สามารถจำแนกว่าเป็นสถานพยาบาลมนุษย์แท้จริง ให้ตัดทิ้งทันที
          // ห้ามเดาหรือ fallback เป็น queryType เด็ดขาด เพราะ Longdo ส่งผลลัพธ์ปนเปื้อนจาก keyword ในที่อยู่/ข้อความ
          if (detectedType == null) {
            return null;
          }

          final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
          if (lat == 0.0 || lon == 0.0) return null;

          return MedicalFacility(
            id: item['id']?.toString() ?? UniqueKey().toString(),
            name: rawName,
            type: detectedType,
            address: item['address'] ?? 'ไม่มีข้อมูลที่อยู่',
            latitude: lat,
            longitude: lon,
            phone: item['tel'] ?? '',
            website: item['url'],
            isOpen24Hours: detectedType == 'hospital' || rawName.contains('24') || rawName.contains('ตลอด 24'),
            source: 'longdo',
          );
        })
        .whereType<MedicalFacility>()
        .where((f) {
          if (type == null) return true;
          final fType = f.type.toLowerCase();
          if (type == FacilityType.hospital && fType != 'hospital') return false;
          if (type == FacilityType.clinic && fType != 'clinic') return false;
          if (type == FacilityType.pharmacy && fType != 'pharmacy') return false;
          return true;
        }),
      );

      // 5. แปลงผลลัพธ์ของ OSM (Overpass)
      allConverted.addAll(
        osmResults
            .map((item) {
              final rawName = (item['name'] ?? '').toString().trim();
              final rawType = (item['type'] ?? 'hospital').toString().trim();

              // กรองสถานที่ที่ติด Blacklist ออก
              if (MedicalFacilityClassifier.isBlacklisted(rawName, amenity: rawType)) {
                return null;
              }

              final detectedType = MedicalFacilityClassifier.classify(
                name: rawName,
                amenity: rawType,
              );

              // หากไม่ใช่สถานพยาบาลแท้จริง ตัดทิ้งทันที
              if (detectedType == null) {
                return null;
              }

              final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
              final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
              if (lat == 0.0 || lon == 0.0) return null;

              return MedicalFacility(
                id: item['id'] ?? UniqueKey().toString(),
                name: rawName.isEmpty ? 'ไม่ทราบชื่อ (OSM)' : rawName,
                type: detectedType,
                address: item['address'] ?? 'OpenStreetMap Facility',
                latitude: lat,
                longitude: lon,
                phone: item['tel'] ?? '',
                source: 'osm',
                website: item['website'],
                operator: item['operator'],
                hasEmergency: item['emergency'] == 'yes',
                isOpen24Hours: detectedType == 'hospital' ||
                    item['emergency'] == 'yes' ||
                    (item['opening_hours']?.toString().contains('24') ?? false),
                wheelchair: item['wheelchair'],
                openingHours: item['opening_hours'],
              );
            })
            .whereType<MedicalFacility>()
            .where((f) {
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
