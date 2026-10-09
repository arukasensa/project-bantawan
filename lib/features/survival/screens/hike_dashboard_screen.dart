// ============================================================================
// 🥾 BANTAWAN Hike Tracker Dashboard: HikeDashboardScreen (Survival Layer)
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical Survival & Field Tracking)         │
// ├─────────────────────────────────────────────────────────┤
// │                HikeDashboardScreen                      │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Breadcrumbs Trail    │    Backtrack Compass      │  │
// │  │  (FlutterMap Offline) │ (Bearing + Target Arrow)  │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Altitude & Distance  │   Summary & SOS Hotkey    │  │
// │  │  (Altimeter + GPS)    │ (HikeSummaryDialog + Call)│  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// หน้าจอแดชบอร์ดติดตามกิจกรรมเดินป่า (Hike Dashboard Screen)
// แสดงแผนที่รอยทางเดินย้อนกลับ (Breadcrumbs), สถิติระยะทาง, เวลา, ความสูงจริง,
// ระบบเข็มทิศนำทางย้อนรอย (Backtrack Compass), และการยืนยันสิ้นสุดการเดินป่า
// ============================================================================

import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:path_provider/path_provider.dart';
import '../services/hike_service.dart';
import '../widgets/hike_summary_dialog.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 🥾 หน้าจอแดชบอร์ดติดตามและบันทึกสถิติการเดินป่า (Hike Dashboard Screen)
class HikeDashboardScreen extends StatefulWidget {
  /// พิกัดเริ่มต้นที่ต้องการเปิดแผนที่โฟกัสไป
  final LatLng? initialPosition;
  const HikeDashboardScreen({super.key, this.initialPosition});

  @override
  State<HikeDashboardScreen> createState() => _HikeDashboardScreenState();
}

/// State ควบคุมการคำนวณระยะทาง เวลา เข็มทิศย้อนรอย และการเรนเดอร์เส้นทาง
class _HikeDashboardScreenState extends State<HikeDashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0);
  String? _localTilesPath;
  late AnimationController _heartbeatController;
  late AnimationController _stopHoldController;

  double _distanceKm = 0.0;
  String _durationStr = "00:00:00";
  Timer? _statTimer;
  DateTime? _hikeStartTime;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition!;
    }
    _initLocalPath();
    _getCurrentLocation();
    _startStatTimer();

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _stopHoldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // ดักฟังเซนเซอร์เข็มทิศสำหรับ Backtrack Navigation
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          _currentHeading = (event.heading! + 360) % 360;
        });
      }
    });
  }

  void _startStatTimer() {
    _statTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final service = Provider.of<HikeService>(context, listen: false);
        _hikeStartTime ??= service.hikeStartTime ?? DateTime.now();

        final now = DateTime.now();
        final diff = now.difference(_hikeStartTime!);
        setState(() {
          _durationStr = _formatDuration(diff);
          if (service.breadcrumbs.length > 1) {
            _distanceKm = service.totalDistanceKm > 0
                ? service.totalDistanceKm
                : _calculateTotalDistance(service.breadcrumbs);
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
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentPosition, 16);
      });
      final service = Provider.of<HikeService>(context, listen: false);
      service.updateCurrentPosition(_currentPosition, altitude: position.altitude);
    } catch (_) {}
  }

  @override
  void dispose() {
    _statTimer?.cancel();
    _compassSubscription?.cancel();
    _heartbeatController.dispose();
    _stopHoldController.dispose();
    super.dispose();
  }

  /// ดักจับการกดย้อนกลับ (Back Button) เพื่อแสดงตัวเลือกระหว่างย่อหน้าต่างกับสิ้นสุดการเดิน
  void _handleBackPress() {
    HapticFeedback.lightImpact();
    final service = Provider.of<HikeService>(context, listen: false);
    if (!service.isHikeActive) {
      Navigator.pop(context);
      return;
    }
    _showExitOptionsDialog();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildMap(),
            _buildCockpitHeader(),
            _buildBacktrackOverlay(),
            _buildBottomControlBar(),
          ],
        ),
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

            // Polyline เส้นทางรอยเท้าเรืองแสง
            PolylineLayer(
              polylines: [
                Polyline(
                  points: hikeService.breadcrumbs,
                  strokeWidth: 5,
                  color: hikeService.isBacktrackActive
                      ? Colors.orangeAccent.withValues(alpha: 0.9)
                      : Colors.blueAccent.withValues(alpha: 0.8),
                  borderColor: hikeService.isBacktrackActive
                      ? Colors.orangeAccent.withValues(alpha: 0.4)
                      : Colors.blueAccent.withValues(alpha: 0.3),
                  borderStrokeWidth: 8,
                ),
              ],
            ),

            MarkerLayer(
              markers: [
                // จุดเริ่มต้น (Basecamp ธงเขียว)
                if (hikeService.breadcrumbs.isNotEmpty)
                  Marker(
                    point: hikeService.breadcrumbs.first,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag_circle_rounded,
                        color: Colors.greenAccent,
                        size: 26,
                      ),
                    ),
                  ),

                // ตำแหน่งปัจจุบันพร้อมเรดาร์กระพริบ
                Marker(
                  point: _currentPosition,
                  width: 80,
                  height: 80,
                  child: _buildPulsingMarker(hikeService.isBacktrackActive),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPulsingMarker(bool isBacktrack) {
    final color = isBacktrack ? Colors.orangeAccent : Colors.blueAccent;

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
                color: color.withValues(
                  alpha: 1 - _heartbeatController.value,
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 10),
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
                  _handleBackPress,
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
    return Consumer<HikeService>(
      builder: (context, hikeService, _) {
        final isBacktrack = hikeService.isBacktrackActive;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBacktrack
                      ? Colors.orangeAccent.withValues(alpha: 0.6)
                      : Colors.greenAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _buildSimplePulseIndicator(isBacktrack),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBacktrack ? 'BACKTRACK ACTIVE' : context.l10n.hikeRecording,
                          style: TextStyle(
                            color: isBacktrack ? Colors.orangeAccent : Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          isBacktrack ? context.l10n.backtrackNavActive : context.l10n.hikeRecordingTrail,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // ปุ่มกดสลับโหมด Backtrack Compass
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      hikeService.toggleBacktrack();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isBacktrack
                            ? Colors.orangeAccent
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBacktrack
                              ? Colors.orangeAccent
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            size: 13,
                            color: isBacktrack ? Colors.black : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBacktrack
                                ? (context.isThai ? 'ย้อนรอยอยู่' : 'Active')
                                : (context.isThai ? 'ย้อนรอย' : 'Backtrack'),
                            style: TextStyle(
                              color: isBacktrack ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimplePulseIndicator(bool isBacktrack) {
    final color = isBacktrack ? Colors.orangeAccent : Colors.greenAccent;

    return AnimatedBuilder(
      animation: _heartbeatController,
      builder: (_, _) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 10 * _heartbeatController.value,
              spreadRadius: 5 * _heartbeatController.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Consumer<HikeService>(
      builder: (context, hikeService, _) {
        final alt = hikeService.currentAltitude;
        final altStr = alt != null ? '${alt.toStringAsFixed(0)} ${context.l10n.meterUnit}' : '-- ${context.l10n.meterUnit}';

        return Row(
          children: [
            _buildStatItem(
              context.l10n.hikeDistance,
              '${_distanceKm.toStringAsFixed(2)} ${context.l10n.kmUnit.toUpperCase()}',
              Icons.route_rounded,
              Colors.cyanAccent,
            ),
            const SizedBox(width: 10),
            _buildStatItem(
              context.l10n.hikeDuration,
              _durationStr,
              Icons.timer_outlined,
              Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            _buildStatItem(
              context.l10n.hikeElevation,
              altStr,
              Icons.landscape_rounded,
              const Color(0xFF10B981),
            ),
          ],
        );
      },
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

  /// 🧭 แผงเข็มทิศนำทางย้อนรอย (Backtrack Compass HUD)
  Widget _buildBacktrackOverlay() {
    return Consumer<HikeService>(
      builder: (context, hikeService, _) {
        if (!hikeService.isBacktrackActive) return const SizedBox.shrink();

        final distMeters = hikeService.getDistanceToStartMeters() ?? 0.0;
        final bearing = hikeService.getBearingToStartDegrees() ?? 0.0;

        // คำนวณมุมหมุนของลูกศรเข็มทิศ: ทิศเป้าหมาย - ทิศที่เครื่องหัน
        final relativeAngle = (bearing - _currentHeading) * (math.pi / 180.0);
        final isNearStart = distMeters < 30 && distMeters > 0;

        String distStr = distMeters >= 1000
            ? '${(distMeters / 1000).toStringAsFixed(2)} ${context.l10n.kmUnit}'
            : '${distMeters.toStringAsFixed(0)} ${context.l10n.meterUnit}';

        return Positioned(
          bottom: 110,
          left: 20,
          right: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.92),
                      const Color(0xFF0F172A).withValues(alpha: 0.96),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isNearStart
                        ? Colors.greenAccent
                        : Colors.orangeAccent.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isNearStart ? Colors.greenAccent : Colors.orangeAccent)
                          .withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ลูกศรเข็มทิศหมุนตามมุมจริง
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border.all(
                          color: isNearStart
                              ? Colors.greenAccent
                              : Colors.orangeAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: isNearStart
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.greenAccent,
                                size: 30,
                              )
                            : Transform.rotate(
                                angle: relativeAngle,
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.orangeAccent,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ข้อมูลระยะทางและคำแนะนำ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isNearStart
                                      ? context.l10n.backtrackArrived
                                      : context.l10n.backtrackBasecamp,
                                  style: TextStyle(
                                    color: isNearStart
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${bearing.toStringAsFixed(0)}° ${_getCardinalDirection(bearing)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isNearStart
                                ? (context.isThai ? 'คุณอยู่ในรัศมีจุดเริ่มต้นเรียบร้อย' : 'You are within starting area')
                                : context.l10n.backtrackDistanceRemaining(distStr),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.backtrackFollowArrow,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // ปุ่มปิดโหมด Backtrack
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => hikeService.toggleBacktrack(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCardinalDirection(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'N (${context.isThai ? 'เหนือ' : 'North'})';
    if (angle >= 22.5 && angle < 67.5) return 'NE';
    if (angle >= 67.5 && angle < 112.5) return 'E';
    if (angle >= 112.5 && angle < 157.5) return 'SE';
    if (angle >= 157.5 && angle < 202.5) return 'S';
    if (angle >= 202.5 && angle < 247.5) return 'SW';
    if (angle >= 247.5 && angle < 292.5) return 'W';
    return 'NW';
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
        child: const Row(
          children: [
            Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
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
              child: Text(
                context.l10n.hikeHoldToEnd,
                style: const TextStyle(
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

  /// เปิดหน้าต่างสรุปผลเมื่อสิ้นสุดการเดินป่า
  void _confirmEndHike() {
    _stopHoldController.reset();
    final service = Provider.of<HikeService>(context, listen: false);
    final summary = service.endHike();

    if (summary != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => HikeSummaryDialog(
          summary: summary,
          onDismiss: () => Navigator.pop(context),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  /// แสดงตัวเลือกเมื่อกดย้อนกลับ: ย่อหน้าต่าง หรือ สิ้นสุดการเดินป่า
  void _showExitOptionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.hiking_rounded, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 10),
            Text(context.l10n.hikeExitDialogTitle, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          context.l10n.hikeExitDialogDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // 1. ปุ่มย่อหน้าต่าง (บันทึกต่อในพื้นหลัง)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.greenAccent, width: 1.2),
                ),
              ),
              icon: const Icon(Icons.picture_in_picture_alt_rounded),
              label: Text(
                context.l10n.hikeMinimizedBox,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(ctx); // ปิด Dialog
                Navigator.pop(context); // ออกไปหน้าหลัก (Hike ยังรันอยู่)
              },
            ),
          ),
          const SizedBox(height: 8),

          // 2. ปุ่มสิ้นสุดการเดินป่า
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                ),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(
                context.l10n.endHikeBtn,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(ctx); // ปิด Dialog
                _confirmEndHike(); // สรุปผลและจบกิจกรรม
              },
            ),
          ),
          const SizedBox(height: 4),

          // 3. ปุ่มยกเลิก/เดินต่อ
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.hikeResumeBtn, style: const TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }
}
