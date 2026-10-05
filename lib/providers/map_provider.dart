// ============================================================================
// 🗺️ BANTAWAN Map & Navigation Engine: MapProvider
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │      (MapScreen / Tactical HUD / Navigation Sheet)      │
// ├─────────────────────────────────────────────────────────┤
// │                   Map State Provider                    │
// │    (MapProvider: GPS, FollowMode, Filters, Polyline)   │
// ├─────────────────────────────────────────────────────────┤
// │                   Repositories Layer                    │
// │  (PoiRepositoryImpl, RoutingRepositoryImpl, Cache)      │
// ├─────────────────────────────────────────────────────────┤
// │                   External Services                     │
// │    (Longdo API, Overpass OSM, OSRM, Photon Geocoder)    │
// └─────────────────────────────────────────────────────────┘
// 
// ผู้รับผิดชอบควบคุม State การแสดงผลแผนที่, การระบุพิกัด GPS, การคำนวณเส้นทาง,
// การตรวจจับการออกนอกเส้นทาง (Off-route Detection), และการดึงข้อมูลสถานพยาบาล
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/medical_facility.dart';
import '../features/map/services/longdo_service.dart';
import '../models/facility_type.dart';
import '../repositories/i_poi_repository.dart';
import '../repositories/poi_repository_impl.dart';
import '../repositories/i_routing_repository.dart';
import '../repositories/routing_repository_impl.dart';
import '../core/utils/medical_facility_classifier.dart';

/// 🏛️ คลาสผู้จัดการ State แผนที่และการนำทางหลัก (MapProvider)
class MapProvider with ChangeNotifier {
  // ===========================================================================
  // 🌐 1. State Variables & References (ตัวแปรสถานะและเซอร์วิสอ้างอิง)
  // ===========================================================================

  /// พิกัดตำแหน่งปัจจุบันของผู้ใช้ที่ได้รับจาก GPS (ค่าเริ่มต้น: หาดใหญ่ จ.สงขลา)
  LatLng _currentPosition = const LatLng(7.0086, 100.4747);
  LatLng get currentPosition => _currentPosition;

  /// จุดศูนย์กลางที่ใช้ค้นหาสถานพยาบาล (หากเป็น null จะใช้ _currentPosition)
  LatLng? _searchCenter;
  LatLng get searchCenter => _searchCenter ?? _currentPosition;

  /// พิกัดที่ได้รับแชร์จากอุปกรณ์อื่นผ่าน Mesh Network ไร้เน็ต
  LatLng? _sharedPosition;
  LatLng? get sharedPosition => _sharedPosition;

  /// 📌 อัปเดตพิกัดตำแหน่งที่ได้รับแชร์มาจากเพื่อนใน Mesh Network
  void setSharedPosition(LatLng? pos) {
    _sharedPosition = pos;
    notifyListeners();
  }

  /// รีโพซิทอรีสำหรับสืบค้นข้อมูลสถานพยาบาล (ผสาน Longdo, Overpass, Local Cache)
  final IPoiRepository _poiRepository = PoiRepositoryImpl();

  /// รีโพซิทอรีสำหรับคำนวณเส้นทางการเดินทาง (OSRM Online + Straight-line Fallback)
  final IRoutingRepository _routingRepository = RoutingRepositoryImpl();

  /// HTTP Client สำหรับดึงข้อมูลรายละเอียดเชิงลึกของสถานที่
  http.Client? _detailsClient;

  /// รายการสถานพยาบาลทั้งหมดที่ค้นพบในรัศมีปัจจุบัน
  List<MedicalFacility> _facilities = [];
  List<MedicalFacility> get facilities => _facilities;

  /// ตัวกรองประเภทสถานที่ที่เลือกอยู่ ('all', 'hospital', 'clinic', 'pharmacy')
  String _selectedFilter = 'all';
  String get selectedFilter => _selectedFilter;

  /// ธงสถานะกำลังประมวลผลหรือโหลดข้อมูลเบื้องหลัง
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// สถานพยาบาลเป้าหมายที่ผู้ใช้กดเลือกบนแผนที่
  MedicalFacility? _selectedFacility;
  MedicalFacility? get selectedFacility => _selectedFacility;

  /// รัศมีการค้นหาสถานพยาบาลรอบตัว (กิโลเมตร) ค่าเริ่มต้นตายตัว: 50 กม.
  double _searchRadius = 50.0;
  double get searchRadius => _searchRadius;

  /// ธีมรูปแบบแผนที่ ('dark' โหมดกลางคืน, 'satellite' ดาวเทียม, 'traffic' สภาพจราจร)
  String _mapStyle = 'dark';
  String get mapStyle => _mapStyle;

  /// รายการจุดพิกัดเส้นทางนำทาง (Polyline coordinates)
  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  /// เวลาโดยประมาณที่จะถึงที่หมาย (Estimated Time of Arrival - ETA) เช่น "15 นาที"
  String? _eta;
  String? get eta => _eta;

  /// ข้อความระบุข้อผิดพลาดที่เกิดขึ้นขณะคำนวณเส้นทาง
  String? _routeError;
  String? get routeError => _routeError;

  /// 📌 ล้างข้อความแจ้งเตือนข้อผิดพลาดของเส้นทาง
  void clearRouteError() {
    _routeError = null;
  }

  /// ข้อความแจ้งเตือนสถานะล่าสุดบนหน้าจอ (Toast/Banner)
  String? _lastMessage;
  String? get lastMessage => _lastMessage;

  /// 📌 ล้างข้อความแจ้งเตือนสถานะล่าสุด
  void clearLastMessage() {
    _lastMessage = null;
  }

  /// ระยะทางรวมตามเส้นทางนำทาง (กิโลเมตร)
  double? _routeDistance;
  double? get routeDistance => _routeDistance;

  /// โหมดการหมุนและติดตามแผนที่ ('none' อิสระ, 'northUp' หันทิศเหนือ, 'headingUp' หันตามทิศเดิน)
  String _followMode = 'none';
  String get followMode => _followMode;

  /// องศาการหมุนของหน้าปัดแผนที่ (Rotation Degrees)
  double _rotation = 0.0;
  double get rotation => _rotation;

  /// ธงแสดงปุ่ม "ค้นหาในบริเวณนี้" เมื่อผู้ใช้เลื่อนแผนที่ออกจากจุดเดิม
  bool _showSearchThisArea = false;
  bool get showSearchThisArea => _showSearchThisArea;

  /// ธงแสดง BottomSheet รายละเอียดของสถานพยาบาลที่เลือก
  bool _showDetails = false;
  bool get showDetails => _showDetails;

  /// ธงแสดงแผงรายการผลลัพธ์การค้นหา
  bool _showSearchResults = false;
  bool get showSearchResults => _showSearchResults;

  /// ดัชนีแท็บย่อยที่เลือกในหน้ารายละเอียดสถานพยาบาล (0: รายละเอียด, 1: รีวิว, 2: เกี่ยวกับ)
  int _selectedDetailTab = 0;
  int get selectedDetailTab => _selectedDetailTab;

  /// รายการขั้นตอนการเลี้ยวแบบ Turn-by-Turn (OSRM Maneuvers)
  List<Map<String, dynamic>> _routeInstructions = [];
  List<Map<String, dynamic>> get routeInstructions => _routeInstructions;

  /// รายงานเหตุการณ์จราจรและอุบัติเหตุจาก Longdo Traffic API
  List<LongdoIncident> _incidents = [];
  List<LongdoIncident> get incidents => _incidents;

  /// ธงระบุว่าผู้ใช้เดินทางถึงจุดหมายปลายทางแล้ว (ระยะห่าง < 20 เมตร)
  bool _hasArrived = false;
  bool get hasArrived => _hasArrived;

  /// 📌 ล้างธงการเดินทางถึงที่หมาย
  void clearArrivedFlag() {
    _hasArrived = false;
    notifyListeners();
  }

  // ===========================================================================
  // 🎯 2. Map Actions & Filter Controls (เมธอดควบคุมตัวกรองและโหมดแผนที่)
  // ===========================================================================

  /// 📌 ปรับเปลี่ยนตัวกรองประเภทสถานที่ (all, hospital, clinic, pharmacy)
  void setFilter(String filter) {
    _selectedFilter = filter;
    loadFacilities();
    notifyListeners();
  }

  /// 📌 สลับรูปแบบการแสดงผลแผนที่ (Dark, Satellite, Traffic)
  /// หากเลือกเป็น 'traffic' จะทำการดึงรายงานอุบัติเหตุจาก Longdo ทันที
  void setMapStyle(String style) {
    _mapStyle = style;
    if (style == 'traffic') {
      // โหมดการจราจร: ดึงข้อมูลรายงานอุบัติเหตุมาปักหมุด
      loadTrafficIncidents();
    } else {
      // โหมดทั่วไป: ล้างหมุดรายงานอุบัติเหตุออกเพื่อประหยัดทรัพยากร
      _incidents = [];
    }
    notifyListeners();
  }

  /// 🚦 โหลดรายงานเหตุการณ์และอุบัติเหตุบนท้องถนนจาก Longdo Traffic API
  Future<void> loadTrafficIncidents() async {
    try {
      final result = await LongdoService.getTrafficIncidents();
      _incidents = result;
      notifyListeners();
    } catch (e) {
      debugPrint('[TRAFFIC] Load incidents error: $e');
    }
  }

  /// 📌 เลือกสถานพยาบาลเป้าหมายบนแผนที่เพื่อเปิดดูรายละเอียดและคำนวณเส้นทาง
  /// - [facility]: อ็อบเจกต์สถานพยาบาลที่เลือก (หากส่ง null จะเป็นการยกเลิกการเลือก)
  void selectFacility(MedicalFacility? facility) {
    _selectedFacility = facility;
    _showDetails = facility != null;
    _hasArrived = false; // รีเซ็ตสถานะการเดินทางถึงที่หมายใหม่
    if (facility == null) {
      clearRoute();
    }
    notifyListeners();
  }

  /// 📌 ล้างข้อมูลเส้นทางการนำทางและคำแนะนำการเลี้ยวทั้งหมด
  void clearRoute() {
    _routePoints = [];
    _eta = null;
    _routeDistance = null;
    _routeInstructions = [];
    _followMode = 'none';
    _routeError = null;
    notifyListeners();
  }

  /// 📌 กำหนดการแสดงผลของ BottomSheet รายละเอียดสถานที่
  void setShowDetails(bool show) {
    _showDetails = show;
    notifyListeners();
  }

  /// 📌 กำหนดการแสดงผลปุ่ม "ค้นหาในบริเวณนี้"
  void setShowSearchThisArea(bool show) {
    _showSearchThisArea = show;
    notifyListeners();
  }

  /// 📌 กำหนดการแสดงผลแผงรายการผลการค้นหา
  void setShowSearchResults(bool show) {
    _showSearchResults = show;
    notifyListeners();
  }

  /// 📌 เลือกแท็บย่อยใน BottomSheet รายละเอียดสถานที่
  void setSelectedDetailTab(int index) {
    _selectedDetailTab = index;
    notifyListeners();
  }

  /// ตำแหน่งพิกัดล่าสุดที่ทำการโหลดข้อมูลสถานที่ไว้
  LatLng? _lastLoadPosition;

  /// 📌 กำหนดขนาดรัศมีการค้นหาสถานที่ (เช่น 10, 20, 50, 100 กม.) และโหลดข้อมูลใหม่ทันที
  void setSearchRadius(double radius) {
    _searchRadius = radius;
    loadFacilities();
    notifyListeners();
  }

  // ตัวแปรควบคุมอัตราการรีเฟรชหน้าจอ (Throttling) เพื่อประหยัด CPU/GPU
  DateTime _lastPositionUpdate = DateTime.now();
  DateTime _lastRotationUpdate = DateTime.now();

  // ===========================================================================
  // 📍 3. Location, Heading & Off-route Detection Engine (พิกัดและการจับการหลุดเส้นทาง)
  // ===========================================================================

  /// 📌 อัปเดตตำแหน่งพิกัด GPS ปัจจุบันของผู้ใช้
  /// พร้อมตรวจสอบเงื่อนไขการโหลดสถานที่ใหม่อัตโนมัติ (เมื่อย้ายเกิน 1 กม.)
  /// และประเมินสถานะการนำทาง / ตรวจจับการออกนอกเส้นทาง
  void setPosition(LatLng pos) {
    _currentPosition = pos;

    // 1. ตรวจสอบระยะย้ายตำแหน่ง: หากเคลื่อนที่ห่างจากจุดโหลดเดิมเกิน 1,000 เมตร ให้โหลดสถานพยาบาลรอบตัวใหม่
    if (_lastLoadPosition == null) {
      _lastLoadPosition = pos;
      loadFacilities();
    } else {
      final distance = Geolocator.distanceBetween(
        _lastLoadPosition!.latitude,
        _lastLoadPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (distance > 1000) {
        _lastLoadPosition = pos;
        loadFacilities();
      }
    }

    // 2. ตรวจสอบสถานะการนำทางและการเดินทางถึงจุดหมาย
    _checkRouteStatus(pos);

    // 3. ปรับลดความถี่การ Render (Throttle UI) ไม่เกินทุก 100ms เพื่อความลื่นไหลและถนอมแบตเตอรี่
    final now = DateTime.now();
    if (now.difference(_lastPositionUpdate).inMilliseconds > 100) {
      _lastPositionUpdate = now;
      notifyListeners();
    }
  }

  /// บันทึกเวลาที่ทำการคำนวณเส้นทางใหม่ล่าสุด (ป้องกัน Re-route บ่อยเกินไป)
  DateTime _lastRerouteTime = DateTime.now();

  /// 🧭 ตรวจสอบสถานะการนำทาง: ถึงที่หมายแล้วหรือไม่ หรือออกนอกเส้นทาง (Off-route) หรือไม่
  void _checkRouteStatus(LatLng pos) {
    if (_selectedFacility == null || _routePoints.isEmpty) return;

    // 1. ตรวจสอบเงื่อนไขการถึงจุดหมายปลายทาง (ระยะห่าง < 20 เมตร)
    final distanceToDest = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      _selectedFacility!.latitude,
      _selectedFacility!.longitude,
    );

    if (distanceToDest < 20) {
      // ถึงเป้าหมายแล้ว! เคลียร์เส้นทางและส่งสัญญาณเตือนสำเร็จ
      _routePoints = [];
      _eta = null;
      _routeDistance = null;
      _routeInstructions = [];
      _hasArrived = true;
      notifyListeners();
      return;
    }

    // 2. ตรวจสอบว่าผู้ใช้ออกนอกเส้นทางที่วางไว้หรือไม่ (วัดระยะห่างฉากไปยังจุดที่ใกล้ที่สุดบน Polyline)
    double minDistance = double.infinity;
    for (var point in _routePoints) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        point.latitude,
        point.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
      }
    }

    // 3. หากผู้ใช้ออกนอกแนวเส้นทางเกิน 100 เมตร และผ่านไปอย่างน้อย 15 วินาทีจากการคำนวณครั้งก่อน
    if (minDistance > 100) {
      final now = DateTime.now();
      if (now.difference(_lastRerouteTime).inSeconds > 15) {
        _lastRerouteTime = now;
        debugPrint('Off-route detected (${minDistance.round()}m). Recalculating route...');
        // คำนวณเส้นทางใหม่จากพิกัดปัจจุบันโดยอัตโนมัติ (Auto Re-routing)
        getRouteTo(_selectedFacility!);
      }
    }
  }

  /// 📌 กำหนดองศาการหมุนของแผนที่ตามเข็มทิศ
  void setRotation(double rot) {
    _rotation = rot;

    // Throttle การอัปเดตมุมมองแผนที่ทุก 100ms
    final now = DateTime.now();
    if (now.difference(_lastRotationUpdate).inMilliseconds > 100) {
      _lastRotationUpdate = now;
      notifyListeners();
    }
  }

  /// 📌 กำหนดโหมดการติดตามตำแหน่ง ('none', 'northUp', 'headingUp')
  void setFollowMode(String mode) {
    _followMode = mode;
    notifyListeners();
  }
  // ===========================================================================
  // 🏥 4. Facilities Loading & De-duplication Engine (โหลดหมุดและกรองข้อมูลซ้ำ)
  // ===========================================================================

  /// 📌 ดึงข้อมูลสถานพยาบาลรอบพิกัดค้นหา พร้อมระบบตัดข้อมูลซ้ำซ้อน (De-duplication)
  /// - [forceRefresh]: บังคับดึงข้อมูลใหม่จาก Server แม้ว่าแคชในเครื่องจะยังไม่หมดอายุ
  Future<void> loadFacilities({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. แปลงตัวกรอง String เป็น Enum FacilityType (hospital, clinic, pharmacy)
      FacilityType? type;
      if (_selectedFilter == 'hospital') {
        type = FacilityType.hospital;
      } else if (_selectedFilter == 'clinic') {
        type = FacilityType.clinic;
      } else if (_selectedFilter == 'pharmacy') {
        type = FacilityType.pharmacy;
      }

      // 2. ร้องขอรายการสถานพยาบาลผ่าน PoiRepository (ยิงควบคู่ Longdo + Overpass OSM + แคช)
      final rawFacilities = await _poiRepository.getNearbyFacilities(
        location: searchCenter,
        radiusKm: _searchRadius,
        type: type,
        forceRefresh: forceRefresh,
      );

      // 3. กรองและขจัดข้อมูลซ้ำซ้อน (De-duplication) โดยตรวจพิกัดใกล้กัน (< 100m) และชื่อคล้ายกัน
      final List<MedicalFacility> uniqueFacilities = [];
      for (var facility in rawFacilities) {
        if (uniqueFacilities.length >= 1500) {
          break; // จำกัดจำนวนหมุดสูงสุด 1,500 แห่งเพื่อแสดงผลอย่างครอบคลุม
        }

        bool isDuplicate = false;
        for (var existing in uniqueFacilities) {
          final distance = Geolocator.distanceBetween(
            facility.latitude,
            facility.longitude,
            existing.latitude,
            existing.longitude,
          );

          if (distance < 100) {
            // ถ้าระยะห่างน้อยกว่า 100 เมตร ตรวจสอบความคล้ายของชื่อด้วย Jaccard Similarity
            final nameSimilarity = _calculateNameSimilarity(
              facility.name,
              existing.name,
            );
            if (nameSimilarity > 0.6) {
              isDuplicate = true;
              break;
            }
          }
        }
        if (!isDuplicate) uniqueFacilities.add(facility);
      }

      // 4. คัดกรองชื่อและรัศมีความปลอดภัย (วัดจาก searchCenter ซึ่งอาจเป็นตำแหน่งปัจจุบันหรือจุดที่กำลังดูอยู่)
      final centerPos = searchCenter;
      _facilities = uniqueFacilities.where((f) {
        final dist = f.distanceFrom(
          centerPos.latitude,
          centerPos.longitude,
        );
        if (dist > _searchRadius * 1.1) return false;

        // ตรวจสอบความถูกต้องว่าเป็นสถานพยาบาลของมนุษย์จริง ไม่ใช่สัตว์เลี้ยง ขนส่ง หรืออาหาร
        if (!MedicalFacilityClassifier.isValidFacility(f)) return false;

        // กรองตามหมวดหมู่ที่เลือก (all, hospital, clinic, pharmacy)
        if (_selectedFilter != 'all') {
          return f.type.toLowerCase() == _selectedFilter.toLowerCase();
        }

        return true;
      }).toList();

      // 5. จัดเรียงลำดับสถานพยาบาลจากระยะใกล้ที่สุดไปไกลที่สุด โดยวัดจาก centerPos
      _facilities.sort(
        (a, b) => a
            .distanceFrom(centerPos.latitude, centerPos.longitude)
            .compareTo(
              b.distanceFrom(
                centerPos.latitude,
                centerPos.longitude,
              ),
            ),
      );

      // 6. จำกัดจำนวนสถานที่ใกล้เคียงสูงสุด 100 แห่งตามความต้องการ
      if (_facilities.length > 100) {
        _facilities = _facilities.take(100).toList();
      }

      _lastLoadPosition = centerPos;
      if (forceRefresh) {
        _lastMessage = 'โหลดข้อมูลสถานพยาบาลสำเร็จ (พบ ${_facilities.length} แห่ง)';
      }
    } catch (e) {
      debugPrint('Multi-source load error: $e');
      if (forceRefresh) {
        _lastMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลสถานที่';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📌 รีเซ็ตศูนย์กลางการค้นหากลับมาที่ตำแหน่ง GPS ปัจจุบันของผู้ใช้ พร้อมโหลดข้อมูล 50 กม. รอบตัวใหม่
  Future<void> resetToCurrentPosition() async {
    _searchCenter = null;
    _lastLoadPosition = _currentPosition;
    _showSearchThisArea = false;
    await loadFacilities();
  }

  /// 🧮 คำนวณความคล้ายคลึงของชื่อสถานที่ (Character Set Intersection over Union)
  double _calculateNameSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final setA = a.split('').toSet();
    final setB = b.split('').toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return intersection / union;
  }

  // ===========================================================================
  // 🛣️ 5. Routing & Rich Data Enrichment Engine (การนำทางและเสริมข้อมูลเชิงลึก)
  // ===========================================================================

  /// 📌 คำนวณเส้นทางนำทางจากตำแหน่งปัจจุบันไปยังสถานพยาบาลเป้าหมาย
  /// - [facility]: สถานพยาบาลปลายทาง
  Future<void> getRouteTo(MedicalFacility facility) async {
    _isLoading = true;
    _routeError = null;
    notifyListeners();

    try {
      // 1. เรียกคำนวณเส้นทางผ่าน RoutingRepository (OSRM ถนนจริง หรือ Fallback เส้นตรง)
      final routeResult = await _routingRepository.getRoute(
        start: _currentPosition,
        end: LatLng(facility.latitude, facility.longitude),
      );

      // 2. จัดเก็บผลลัพธ์พิกัดเส้นทาง, ระยะทางรวม, เวลาเดินทาง, และคำแนะนำการเลี้ยว
      if (routeResult.error != null) {
        _routeError = routeResult.error;
      }

      _routePoints = routeResult.points;
      _routeDistance = routeResult.distanceKm;
      _eta = routeResult.eta;
      _routeInstructions = routeResult.instructions;
    } catch (e) {
      _routePoints = [];
      _routeDistance = null;
      _eta = null;
      _routeError = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์นำทางได้ (ตรวจเช็คอินเทอร์เน็ตของคุณ)';
      debugPrint('Error fetching route: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      // 3. ดึงข้อมูลรายละเอียดเพิ่มเติม (เบอร์โทร, เว็บไซต์) แบบอะซิงค์
      fetchRichDetails(facility);
    }
  }
  /// ℹ️ ดึงข้อมูลรายละเอียดเพิ่มเติมของสถานที่จาก Longdo API (เช่น เบอร์โทรศัพท์, เว็บไซต์)
  Future<void> fetchRichDetails(MedicalFacility facility) async {
    _detailsClient?.close();
    _detailsClient = http.Client();

    // 1. ร้องขอข้อมูลรายละเอียดเชิงลึกจาก Longdo POI API
    try {
      final longdoDetails = await LongdoService.getPOIDetails(facility.id);
      if (longdoDetails != null) {
        // อัปเดตเบอร์โทรศัพท์หากของเดิมยังว่างอยู่
        if (longdoDetails['tel'] != null && facility.phone.isEmpty) {
          facility.phone = longdoDetails['tel'].toString();
        }
        // อัปเดตลิงก์เว็บไซต์หากของเดิมยังว่างอยู่
        if (longdoDetails['url'] != null && facility.website == null) {
          facility.website = longdoDetails['url'].toString();
        }
      }
    } catch (e) {
      debugPrint('Longdo enrichment error: $e');
    }

    notifyListeners();
  }

  // ===========================================================================
  // 🔍 6. Geocoding & Search Location Engine (ค้นหาพิกัดและแปลงที่อยู่)
  // ===========================================================================

  /// 📌 ค้นหาสถานพยาบาลรอบจุดศูนย์กลางแผนที่ที่ระบุ [center]
  Future<void> searchFacilitiesInCenter(LatLng center) async {
    _searchCenter = center;
    _lastLoadPosition = center;
    await loadFacilities(forceRefresh: true);
  }

  /// 📌 ค้นหาตำแหน่งพิกัดจากข้อความค้นหา (Geocoding Search)
  /// รองรับทั้ง Native Geocoding, Photon API (Komoot), และ Fallback Nominatim (OSM)
  /// - [query]: ข้อความค้นหา เช่น "โรงพยาบาลสงขลานครินทร์", "หาดใหญ่"
  /// ส่งคืนค่าพิกัด [LatLng] ของผลลัพธ์แรกที่พบ หรือ null หากไม่พบ
  Future<LatLng?> handleSearch(String query) async {
    // 1. หากช่องค้นหาว่าง ให้ยกเลิกจุดโฟกัสและโหลดสถานที่รอบตำแหน่งปัจจุบัน
    if (query.trim().isEmpty) {
      _searchCenter = null;
      await loadFacilities(forceRefresh: true);
      return null;
    }

    try {
      // 2. ลำดับแรก: ทดลองใช้ Native OS Geocoding บนอุปกรณ์พกพา (iOS/Android)
      if (!kIsWeb) {
        try {
          List<Location> locations = await locationFromAddress(query);
          if (locations.isNotEmpty) {
            final loc = locations.first;
            final target = LatLng(loc.latitude, loc.longitude);
            _searchCenter = target;
            await loadFacilities(forceRefresh: true);
            return target;
          }
        } catch (e) {
          debugPrint('Native geocoding failed, falling back to Web API: $e');
        }
      }

      // 3. ลำดับที่สอง: ค้นหาผ่าน Photon Geocoding API (ขับเคลื่อนด้วย OpenStreetMap & Komoot)
      final encodedQuery = Uri.encodeComponent(query);
      final refPos = searchCenter;
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=$encodedQuery'
        '&lat=${refPos.latitude}&lon=${refPos.longitude}'
        '&limit=1',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final first = features.first;
          final geometry = first['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          // Photon ส่งคืนพิกัดในรูปแบบ [Longitude, Latitude]
          final double lon = (coordinates[0] as num).toDouble();
          final double lat = (coordinates[1] as num).toDouble();

          final target = LatLng(lat, lon);
          _searchCenter = target;
          await loadFacilities(forceRefresh: true);
          return target;
        } else {
          // หาก Photon ไม่พบ ให้สลับไปใช้ Nominatim สำรอง
          return await _searchNominatim(query);
        }
      } else {
        return await _searchNominatim(query);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      try {
        // 4. Fallback ฉุกเฉิน: ดึงพิกัดผ่าน Nominatim OSM
        return await _searchNominatim(query);
      } catch (err) {
        debugPrint('Nominatim backup failed: $err');
      }
    }
    return null;
  }

  /// 🌐 ค้นหาพิกัดสำรองผ่าน OpenStreetMap Nominatim Search API
  Future<LatLng?> _searchNominatim(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encodedQuery'
      '&format=json&limit=1&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'Bantawan Survival App'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      if (list.isNotEmpty) {
        final first = list.first;
        final double lat = double.parse(first['lat'].toString());
        final double lon = double.parse(first['lon'].toString());
        final target = LatLng(lat, lon);
        _searchCenter = target;
        await loadFacilities(forceRefresh: true);
        return target;
      }
    }
    return null;
  }

  @override
  void dispose() {
    // ปิดการเชื่อมต่อ HTTP Client เมื่อ Provider ถูกทำลาย
    _detailsClient?.close();
    super.dispose();
  }
}
