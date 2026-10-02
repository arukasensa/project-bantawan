import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter1/features/home/services/connectivity_service.dart';

/// ============================================================================
/// 🗺️ Offline Map Service: MapOfflineService
/// ระบบจัดการและดาวน์โหลดแคชแผ่นแผนที่ออฟไลน์ (Tile Caching Engine)
/// ช่วยให้ผู้ใช้ดูแผนที่และนำทางไปยังสถานพยาบาลได้แม้อยู่ในพื้นที่ไร้สัญญาณอินเทอร์เน็ต
/// ============================================================================
class MapOfflineService extends ChangeNotifier {
  final Dio _dio = Dio();               // HTTP Client สำหรับยิงดาวน์โหลดแผ่นแผนที่ Tile PNG
  bool _isDownloading = false;         // สถานะกำลังดาวน์โหลด
  double _progress = 0;                 // ความคืบหน้าดาวน์โหลด (0.0 ถึง 1.0)
  String _status = '';                  // ข้อความแสดงสถานะบน UI
  bool _showDownloadPrompt = false;    // ธงแสดง Pop-up ชวนดาวน์โหลดแผนที่เมื่อเน็ตเริ่มไม่เสถียร

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  String get status => _status;
  bool get showDownloadPrompt => _showDownloadPrompt;

  void setShowDownloadPrompt(bool value) {
    _showDownloadPrompt = value;
    notifyListeners();
  }

  /// 📡 ตรวจจับสถานะอินเทอร์เน็ต: หากอินเทอร์เน็ตเริ่มไม่เสถียร จะแจ้งเตือนให้ผู้ใช้กดดาวน์โหลดแผนที่เก็บไว้ในเครื่อง
  void listenToConnectivity(ConnectivityService connectivity) {
    connectivity.addListener(() {
      if (connectivity.stability == NetworkStability.unstable && !_isDownloading) {
        _showDownloadPrompt = true;
        notifyListeners();
      }
    });
  }

  /// 📁 ดึงพาธไดเรกทอรีจัดเก็บไฟล์แคชแผนที่ในเครื่องอุปกรณ์
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/map_tiles';
  }

  /// 📥 ดาวน์โหลดแผ่นแผนที่ (Tile PNG) รอบพิกัดตำแหน่งของผู้ใช้ในรัศมีประมาณ 2 กม. (ครอบคลุมพื้นที่ 10 ตร.กม.)
  /// รองรับระดับการซูมตั้งแต่ minZoom (12) ถึง maxZoom (16)
  Future<void> downloadAreaTiles(
    LatLng center, {
    int minZoom = 12,
    int maxZoom = 16,
    bool clearExisting = false,
  }) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0;
    _status = clearExisting ? 'กำลังล้างแคชเก่า...' : 'กำลังตรวจสอบข้อมูลเดิม...';
    notifyListeners();

    try {
      final path = await _localPath;
      final dir = Directory(path);
      
      // ล้างแคชเก่าออกหากผู้ใช้สั่ง Clear
      if (clearExisting && await dir.exists()) {
        await dir.delete(recursive: true);
      }
      
      if (!await dir.exists()) await dir.create(recursive: true);

      // 1. คำนวณหาพิกัดแผ่นแผนที่ (Tile X, Y, Z) ทั้งหมดที่ต้องดาวน์โหลด
      List<MapTile> tilesToDownload = [];
      for (int z = minZoom; z <= maxZoom; z++) {
        final radiusInTiles = _calculateTileRadius(2000, center.latitude, z);
        final centerTileX = _lonToTile(center.longitude, z);
        final centerTileY = _latToTile(center.latitude, z);

        for (int x = centerTileX - radiusInTiles; x <= centerTileX + radiusInTiles; x++) {
          for (int y = centerTileY - radiusInTiles; y <= centerTileY + radiusInTiles; y++) {
            tilesToDownload.add(MapTile(x, y, z));
          }
        }
      }

      int totalTiles = tilesToDownload.length;
      int downloaded = 0;

      // 2. ทยอยดาวน์โหลดและเซฟไฟล์ PNG ลงในเครื่อง
      for (var tile in tilesToDownload) {
        if (!_isDownloading) break;

        final tilePath = '$path/${tile.z}/${tile.x}/${tile.y}.png';
        final file = File(tilePath);

        // หากยังไม่มีไฟล์รูปภาพนี้ในเครื่อง ให้ทำการดาวน์โหลดจาก OpenStreetMap Server
        if (!await file.exists()) {
          await file.create(recursive: true);
          final url = 'https://tile.openstreetmap.org/${tile.z}/${tile.x}/${tile.y}.png';

          bool success = false;
          int retries = 0;
          while (!success && retries < 3 && _isDownloading) {
            try {
              await _dio.download(
                url,
                tilePath,
                options: Options(
                  headers: {'User-Agent': 'Bantawan Survival App'},
                  sendTimeout: const Duration(seconds: 5),
                  receiveTimeout: const Duration(seconds: 5),
                ),
              );
              success = true;
            } catch (e) {
              retries++;
              await Future.delayed(Duration(milliseconds: 500 * retries));
            }
          }
        }

        downloaded++;
        _progress = downloaded / totalTiles;
        _status = 'กำลังโหลดแผ่นแผนที่ ($downloaded/$totalTiles)...';
        notifyListeners();
      }

      _status = 'ดาวน์โหลดแผนที่ออฟไลน์สำเร็จ!';
    } catch (e) {
      _status = 'เกิดข้อผิดพลาดในการดาวน์โหลด: $e';
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// 🛑 ยกเลิกการดาวน์โหลดแผนที่
  void cancelDownload() {
    _isDownloading = false;
    _status = 'ยกเลิกการดาวน์โหลดแล้ว';
    notifyListeners();
  }

  /// 📐 คำนวณรัศมีจำนวนแผ่นแผนที่ตามระยะทางเมตร (Meters to Tile Radius)
  int _calculateTileRadius(double meters, double lat, int zoom) {
    final metersPerPixel = 156543.03392 * cos(lat * pi / 180) / pow(2, zoom);
    final metersPerTile = metersPerPixel * 256;
    return (meters / metersPerTile).ceil();
  }

  /// 🌐 แปลงค่า Longitude เป็นพิกัดแผ่นแผนที่ Tile X (Slippy Map Tiling Scheme)
  int _lonToTile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * pow(2, zoom)).floor();
  }

  /// 🌐 แปลงค่า Latitude เป็นพิกัดแผ่นแผนที่ Tile Y (Mercator Projection)
  int _latToTile(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - _asinh(tan(latRad)) / pi) / 2.0 * pow(2, zoom)).floor();
  }

  /// 📐 คำนวณค่า Inverse Hyperbolic Sine (asinh) ทางคณิตศาสตร์
  double _asinh(double x) {
    return log(x + sqrt(x * x + 1.0));
  }
}

/// 🧱 Data Structure Class สำหรับเก็บพิกัดแผ่นแผนที่ (Tile Coordinates)
class MapTile {
  final int x;
  final int y;
  final int z;
  MapTile(this.x, this.y, this.z);
}
