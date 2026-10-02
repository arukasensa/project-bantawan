// บริการบันทึกเส้นทางเดินป่า (Hike Tracker Service)
// ติดตามพิกัดและหยอดจุดไข่ปลา (Breadcrumbs Trail) ทุกระยะ 50 เมตร
// เพื่อให้ผู้ใช้สามารถเดินย้อนรอยกลับจุดเริ่มต้นได้แม้ไม่มีอินเทอร์เน็ต

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// คลาสบริการติดตามและบันทึกรอยทางเดินป่า (Breadcrumb Trail Tracker)
class HikeService extends ChangeNotifier {
  /// สถานะการเริ่มบันทึกกิจกรรมเดินป่า
  bool _isHikeActive = false;

  /// รายการจุดพิกัดรอยทางเดิน (Breadcrumbs)
  List<LatLng> _breadcrumbs = [];

  StreamSubscription<Position>? _positionSubscription;

  bool get isHikeActive => _isHikeActive;
  List<LatLng> get breadcrumbs => _breadcrumbs;

  void startHike(LatLng startPos) {
    _isHikeActive = true;
    _breadcrumbs = [startPos];

    // Start tracking position for breadcrumbs
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50, // Save check-point every 50 meters
          ),
        ).listen((Position position) {
          if (_isHikeActive) {
            _breadcrumbs.add(LatLng(position.latitude, position.longitude));
            notifyListeners();
          }
        });

    notifyListeners();
  }

  void stopHike() {
    _isHikeActive = false;
    _positionSubscription?.cancel();
    notifyListeners();
  }

  void clearBreadcrumbs() {
    _breadcrumbs.clear();
    notifyListeners();
  }
}
