// บริการบันทึกเส้นทางเดินป่า (Hike Tracker Service)
// ติดตามพิกัดและหยอดจุดไข่ปลา (Breadcrumbs Trail) ทุกระยะ 50 เมตร
// รองรับระบบนำทางย้อนรอย (Backtrack Navigation) และสรุปสถิติการเดินป่า

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/hike_summary.dart';

/// คลาสบริการติดตามและบันทึกรอยทางเดินป่า (Breadcrumb Trail Tracker)
class HikeService extends ChangeNotifier {
  /// สถานะการเริ่มบันทึกกิจกรรมเดินป่า
  bool _isHikeActive = false;

  /// รายการจุดพิกัดรอยทางเดิน (Breadcrumbs)
  List<LatLng> _breadcrumbs = [];

  /// เวลาเริ่มต้นเดินป่า
  DateTime? _hikeStartTime;

  /// ระยะทางสะสมทั้งหมด (กิโลเมตร)
  double _totalDistanceKm = 0.0;

  /// พิกัดตำแหน่งปัจจุบันล่าสุด
  LatLng? _currentPosition;

  /// ระดับความสูงจากระดับน้ำทะเลปัจจุบัน (เมตร)
  double? _currentAltitude;

  /// ระดับความสูงเริ่มต้น
  double? _startAltitude;

  /// ระดับความสูงสูงสุดที่วัดได้
  double? _maxAltitude;

  /// สถานะเปิดโหมดนำทางย้อนรอย (Backtrack Mode)
  bool _isBacktrackActive = false;

  StreamSubscription<Position>? _positionSubscription;

  bool get isHikeActive => _isHikeActive;
  List<LatLng> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  DateTime? get hikeStartTime => _hikeStartTime;
  double get totalDistanceKm => _totalDistanceKm;
  LatLng? get currentPosition => _currentPosition;
  double? get currentAltitude => _currentAltitude;
  double? get startAltitude => _startAltitude;
  double? get maxAltitude => _maxAltitude;
  bool get isBacktrackActive => _isBacktrackActive;

  /// เริ่มต้นกิจกรรมเดินป่าและบันทึกเส้นทาง
  void startHike(LatLng startPos) async {
    _isHikeActive = true;
    _breadcrumbs = [startPos];
    _currentPosition = startPos;
    _hikeStartTime = DateTime.now();
    _totalDistanceKm = 0.0;
    _isBacktrackActive = false;

    // ดึงค่าความสูงเริ่มต้นจาก GPS ล่าสุด
    try {
      final currentPos = await Geolocator.getCurrentPosition();
      _currentAltitude = currentPos.altitude;
      _startAltitude = currentPos.altitude;
      _maxAltitude = currentPos.altitude;
      _currentPosition = LatLng(currentPos.latitude, currentPos.longitude);
    } catch (_) {}

    // เริ่มต้นดักจับตำแหน่งแบบต่อเนื่องทุก 50 เมตร
    try {
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // หยอดจุดไข่ปลาทุก 50 เมตร
        ),
      ).listen((Position position) {
        if (_isHikeActive) {
          final newPoint = LatLng(position.latitude, position.longitude);

          // คำนวณระยะทางสะสม
          if (_breadcrumbs.isNotEmpty) {
            final lastPoint = _breadcrumbs.last;
            final distMeters = Geolocator.distanceBetween(
              lastPoint.latitude,
              lastPoint.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
            _totalDistanceKm += distMeters / 1000.0;
          }

          _breadcrumbs.add(newPoint);
          _currentPosition = newPoint;
          _currentAltitude = position.altitude;

          if (_maxAltitude == null || position.altitude > _maxAltitude!) {
            _maxAltitude = position.altitude;
          }

          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('[HikeService] Stream subscription warning: $e');
    }

    notifyListeners();
  }

  /// อัปเดตตำแหน่งปัจจุบันแบบแมนนวล (เมื่อดึงตำแหน่งเฉพาะหน้า)
  void updateCurrentPosition(LatLng pos, {double? altitude}) {
    _currentPosition = pos;
    if (altitude != null) {
      _currentAltitude = altitude;
      if (_maxAltitude == null || altitude > _maxAltitude!) {
        _maxAltitude = altitude;
      }
    }
    notifyListeners();
  }

  /// สลับเปิด/ปิดโหมดนำทางย้อนรอย (Backtrack Navigation)
  void toggleBacktrack([bool? forceState]) {
    _isBacktrackActive = forceState ?? !_isBacktrackActive;
    notifyListeners();
  }

  /// คำนวณระยะทางที่เหลือตรงไปยังจุดเริ่มต้น (เมตร)
  double? getDistanceToStartMeters() {
    if (_breadcrumbs.isEmpty || _currentPosition == null) return null;
    final start = _breadcrumbs.first;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      start.latitude,
      start.longitude,
    );
  }

  /// คำนวณมุมทิศองศา (Bearing) ชี้ตรงไปยังจุดเริ่มต้น (0° - 359°)
  double? getBearingToStartDegrees() {
    if (_breadcrumbs.isEmpty || _currentPosition == null) return null;
    final start = _breadcrumbs.first;
    final bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      start.latitude,
      start.longitude,
    );
    // ปรับให้เป็นช่วงบวก 0 ถึง 360 องศา
    return (bearing + 360) % 360;
  }

  /// หยุดการเดินป่าและสร้างรายงานสรุปผล
  HikeSummary? endHike() {
    if (!_isHikeActive && _breadcrumbs.isEmpty) return null;

    final now = DateTime.now();
    final start = _hikeStartTime ?? now;
    final summary = HikeSummary(
      startTime: start,
      endTime: now,
      duration: now.difference(start),
      distanceKm: _totalDistanceKm,
      breadcrumbCount: _breadcrumbs.length,
      startAltitude: _startAltitude,
      maxAltitude: _maxAltitude,
      trail: List.from(_breadcrumbs),
    );

    stopHike();
    return summary;
  }

  /// หยุดการบันทึกชั่วคราว
  void stopHike() {
    _isHikeActive = false;
    _positionSubscription?.cancel();
    _isBacktrackActive = false;
    notifyListeners();
  }

  /// ล้างข้อมูลจุดรอยทาง
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
    _totalDistanceKm = 0.0;
    _hikeStartTime = null;
    _currentPosition = null;
    _currentAltitude = null;
    _startAltitude = null;
    _maxAltitude = null;
    _isBacktrackActive = false;
    notifyListeners();
  }
}
