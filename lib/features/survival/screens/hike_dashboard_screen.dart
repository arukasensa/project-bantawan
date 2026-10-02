// หน้าจอแดชบอร์ดติดตามการเดินป่า (Hike Dashboard Screen)
// แสดงแผนที่รอยทางเดินย้อนกลับ (Breadcrumbs), สถิติระยะทางกิโลเมตร,
// เวลาที่ใช้เดิน, และปุ่มกดค้างเพื่อหยุดการบันทึกอย่างปลอดภัย

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/hike_service.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'package:path_provider/path_provider.dart';

/// หน้าจอแสดงผลและบันทึกสถิติการเดินป่า
class HikeDashboardScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const HikeDashboardScreen({super.key, this.initialPosition});

  @override
  State<HikeDashboardScreen> createState() => _HikeDashboardScreenState();
}

/// State ควบคุมการคำนวณระยะทาง เวลา และการเรนเดอร์เส้นทางเดินป่า
class _HikeDashboardScreenState extends State<HikeDashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0);
  String? _localTilesPath;
  late AnimationController _heartbeatController;
  late AnimationController _stopHoldController;

  // Real stats (placeholders for elevation)
  double _distanceKm = 0.0;
  String _durationStr = "00:00:00";
  Timer? _statTimer;
  DateTime? _hikeStartTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition!;
    }
    _initLocalPath();
    _getCurrentLocation();
    _hikeStartTime = DateTime.now();
    _startStatTimer();

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _stopHoldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  void _startStatTimer() {
    _statTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final diff = now.difference(_hikeStartTime!);
        setState(() {
          _durationStr = _formatDuration(diff);
          // In a real app, distance would be calculated from breadcrumbs
          final service = Provider.of<HikeService>(context, listen: false);
          if (service.breadcrumbs.length > 1) {
            _distanceKm = _calculateTotalDistance(service.breadcrumbs);
          }
        });
      }
    });
  }

  double _calculateTotalDistance(List<LatLng> points) {
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total / 1000.0;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Future<void> _initLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _localTilesPath = '${directory.path}/map_tiles';
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentPosition, 16);
    });
  }

  @override
  void dispose() {
    _statTimer?.cancel();
    _heartbeatController.dispose();
    _stopHoldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMap(),
          _buildCockpitHeader(),
          _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<HikeService>(
      builder: (context, hikeService, _) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentPosition, initialZoom: 16),
          children: [
            if (_localTilesPath != null)
              TileLayer(
                urlTemplate: '$_localTilesPath/{z}/{x}/{y}.png',
                tileProvider: FileTileProvider(),
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              )
            else
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),

            // Polyline with Glow
            PolylineLayer(
              polylines: [
                Polyline(
                  points: hikeService.breadcrumbs,
                  strokeWidth: 5,
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                  borderColor: Colors.blueAccent.withValues(alpha: 0.3),
                  borderStrokeWidth: 8,
                ),
              ],
            ),

            MarkerLayer(
              markers: [
                // Start Point
                if (hikeService.breadcrumbs.isNotEmpty)
                  Marker(
                    point: hikeService.breadcrumbs.first,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.flag_circle_rounded,
                      color: Colors.greenAccent,
                      size: 30,
                    ),
                  ),
                // Current Location with Pulse
                Marker(
                  point: _currentPosition,
                  width: 80,
                  height: 80,
                  child: _buildPulsingMarker(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPulsingMarker() {
    return AnimatedBuilder(
      animation: _heartbeatController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30 * (1 + _heartbeatController.value * 1.5),
              height: 30 * (1 + _heartbeatController.value * 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(
                  alpha: 1 - _heartbeatController.value,
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent, blurRadius: 10),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCockpitHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildCircularButton(
                  Icons.arrow_back_ios_new_rounded,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildHeartbeatBanner()),
                const SizedBox(width: 12),
                _buildCircularButton(
                  Icons.my_location_rounded,
                  _getCurrentLocation,
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildStatsDashboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartbeatBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _buildSimplePulseIndicator(),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HIKE HEARTBEAT',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'เส้นทางถูกบันทึกเรียบร้อย',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.greenAccent,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePulseIndicator() {
    return AnimatedBuilder(
      animation: _heartbeatController,
      builder: (_, _) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent,
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.5),
              blurRadius: 10 * _heartbeatController.value,
              spreadRadius: 5 * _heartbeatController.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Row(
      children: [
        _buildStatItem(
          'DISTANCE',
          '${_distanceKm.toStringAsFixed(2)} KM',
          Icons.route_rounded,
          Colors.cyanAccent,
        ),
        const SizedBox(width: 10),
        _buildStatItem(
          'DURATION',
          _durationStr,
          Icons.timer_outlined,
          Colors.orangeAccent,
        ),
        const SizedBox(width: 10),
        _buildStatItem(
          'ELEVATION',
          '245 m',
          Icons.landscape_rounded,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(height: 6),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Row(
        children: [
          _buildEmergencyQuickButton(),
          const SizedBox(width: 12),
          Expanded(child: _buildEndHikeButton()),
        ],
      ),
    );
  }

  Widget _buildEmergencyQuickButton() {
    return GestureDetector(
      onTap: () => CallService.makeCall('1669'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              '1669',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndHikeButton() {
    return GestureDetector(
      onLongPressStart: (_) => _stopHoldController.forward(),
      onLongPressEnd: (_) {
        if (_stopHoldController.value < 1.0) _stopHoldController.reverse();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: const Text(
                'HOLD TO END',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _stopHoldController,
            builder: (context, child) {
              if (_stopHoldController.value == 1.0) {
                Future.microtask(() => _confirmEndHike());
              }
              return SizedBox(
                height: 60,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width *
                          _stopHoldController.value,
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmEndHike() {
    _stopHoldController.reset();
    final service = Provider.of<HikeService>(context, listen: false);
    service.stopHike();
    Navigator.pop(context);
  }
}
