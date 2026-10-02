// ============================================================================
// 🗺️ BANTAWAN Main Tactical GIS Map Screen: MapScreen (Offline Map Layer)
// 
// หน้าจอแผนที่นำทางหลัก (Main Tactical Map Screen)
// รวมเลเยอร์แผนที่ OpenStreetMap (พร้อมไทล์ออฟไลน์), การตรวจจับ GPS และเข็มทิศดิจิทัล,
// การเรนเดอร์หมุดสถานพยาบาล/ผู้รอดชีวิต, การลากเส้น Polyline นำทาง, และแผงควบคุมระบบ
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:flutter1/providers/map_provider.dart';
import '../services/map_offline_service.dart';
import '../widgets/google_map_header.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_markers.dart';
import '../widgets/routing_instructions_panel.dart';
import '../widgets/facility_list_panel.dart';
import '../widgets/floating_facility_card.dart';
import 'package:flutter1/features/survival/screens/hike_dashboard_screen.dart';

/// 🗺️ หน้าจอแผนที่หลักของแอปพลิเคชัน BANTAWAN (Tactical Map Screen)
class MapScreen extends StatefulWidget {
  /// พิกัดเริ่มต้นที่ต้องการให้แผนที่เปิดโฟกัสไป (ถ้ามี)
  final LatLng? initialPosition;
  const MapScreen({super.key, this.initialPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// State ควบคุมการเคลื่อนที่ของแผนที่ หมุด และสตรีม GPS
class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    mapController: _mapController,
  );

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _showStepByStepPanel = false;

  void _openMobileFacilityList(BuildContext context, MapProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (c, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: FacilityListPanel(
            searchController: _searchController,
            onSearch: (q) async {
              Navigator.pop(ctx);
              final searchedPos = await provider.handleSearch(q);
              if (mounted && searchedPos != null) {
                _animatedMapController.animateTo(dest: searchedPos, zoom: 15);
              }
            },
            onSelectFacility: (facility) {
              Navigator.pop(ctx);
              provider.selectFacility(facility);
              _animatedMapController.animateTo(
                dest: LatLng(facility.latitude, facility.longitude),
                zoom: 16,
              );
            },
            onBack: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initStreams();
    _initialFocus();

    if (widget.initialPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MapProvider>().setSharedPosition(widget.initialPosition);
        }
      });
    }
  }

  Future<void> _initialFocus() async {
    final provider = context.read<MapProvider>();
    if (widget.initialPosition != null) {
      provider.setPosition(widget.initialPosition!);
      _animatedMapController.animateTo(dest: widget.initialPosition!, zoom: 15);
      return;
    }
    // หาก MapProvider มีพิกัดจริงที่ได้จาก HomeScreen แล้ว ให้เลื่อนแผนที่ไปจุดนั้นทันที
    if (provider.currentPosition.latitude != 7.0086 ||
        provider.currentPosition.longitude != 100.4747) {
      _animatedMapController.animateTo(
        dest: provider.currentPosition,
        zoom: 15,
      );
    }

    try {
      // 0. ตรวจสอบว่าบริการ GPS บนเครื่องถูกเปิดไว้หรือไม่
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'กรุณาเปิดบริการตำแหน่งพิกัด (GPS Location) บนอุปกรณ์ของคุณ',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 1. ดึงตำแหน่งล่าสุดทันที (Last Known Position)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        final LatLng initialPos = LatLng(lastPos.latitude, lastPos.longitude);
        provider.setPosition(initialPos);
        _animatedMapController.animateTo(dest: initialPos, zoom: 15);
      }

      // 2. ตรวจสอบและร้องขอสิทธิ์ GPS Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // 3. ดึงพิกัดปัจจุบันผ่าน Fused Location Provider ก่อน
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 8),
              forceLocationManager: true,
            ),
          );
        }

        if (mounted) {
          final LatLng currentPos = LatLng(
            position.latitude,
            position.longitude,
          );
          provider.setPosition(currentPos);
          _animatedMapController.animateTo(dest: currentPos, zoom: 15);
        }
      }
    } catch (e) {
      debugPrint('Initial location focus failed: $e');
    }
  }

  void _initStreams() {
    final provider = context.read<MapProvider>();

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen(
          (position) {
            final newPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              provider.setPosition(newPos);
              if (provider.followMode != 'none') {
                _animatedMapController.animateTo(dest: newPos);
              }
            }
          },
          onError: (err) {
            debugPrint('[MAP] Position stream error: $err');
          },
        );

    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        final double raw = event.heading ?? 0.0;
        final double heading = (raw % 360 + 360) % 360;
        provider.setRotation(heading);
        if (provider.followMode == 'headingUp') {
          _animatedMapController.animateTo(rotation: -heading);
        }
      },
      onError: (err) {
        debugPrint('[MAP] Compass stream error: $err');
      },
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _searchController.dispose();

    // Clear shared position when leaving the map screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().setSharedPosition(null);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    final offlineService = Provider.of<MapOfflineService>(context);

    if (provider.lastMessage != null) {
      final msg = provider.lastMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.lastMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearLastMessage();
        }
      });
    }

    if (provider.routeError != null) {
      final errorMsg = provider.routeError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.routeError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          provider.clearRouteError();
        }
      });
    }

    if (provider.hasArrived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.hasArrived) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('คุณเดินทางถึงที่หมายเรียบร้อยแล้ว!'),
                ],
              ),
              backgroundColor: Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          provider.clearArrivedFlag();
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 760;
          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: 380,
                  child: FacilityListPanel(
                    searchController: _searchController,
                    onSearch: (q) async {
                      final searchedPos = await provider.handleSearch(q);
                      if (mounted && searchedPos != null) {
                        _animatedMapController.animateTo(
                          dest: searchedPos,
                          zoom: 15,
                        );
                      }
                    },
                    onSelectFacility: (facility) {
                      provider.selectFacility(facility);
                      _animatedMapController.animateTo(
                        dest: LatLng(facility.latitude, facility.longitude),
                        zoom: 16,
                      );
                    },
                    onBack: () => Navigator.maybePop(context),
                  ),
                ),
                Expanded(
                  child: _buildMapArea(
                    context,
                    provider,
                    offlineService,
                    isWide: true,
                  ),
                ),
              ],
            );
          }
          return _buildMapArea(
            context,
            provider,
            offlineService,
            isWide: false,
          );
        },
      ),
    );
  }

  Widget _buildMapArea(
    BuildContext context,
    MapProvider provider,
    MapOfflineService offlineService, {
    required bool isWide,
  }) {
    return Stack(
      children: [
        // 1. The Map Engine (OSM)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: provider.currentPosition,
            initialZoom: 15,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                if (provider.followMode != 'none') {
                  provider.setFollowMode('none');
                }
                provider.setShowSearchThisArea(true);
              }
            },
          ),
          children: [
            // Base Map Tile
            TileLayer(
              urlTemplate: provider.mapStyle == 'satellite'
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : provider.mapStyle == 'traffic'
                  // OSM Standard: แผนที่สว่างชัดเจน เหมาะสำหรับโหมดจราจร (ฟรี ไม่ต้อง API Key)
                  ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                  // OSM via Waymarked: Dark-styled map (ฟรี ไม่ต้อง API Key)
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bantawan.app',
              retinaMode: RetinaMode.isHighDensity(context),
            ),

            // Traffic Overlay — Longdo Traffic XYZ Tile (แสดงเส้นจราจร เขียว/เหลือง/แดง เรียลไทม์)
            if (provider.mapStyle == 'traffic')
              Opacity(
                opacity: 0.85,
                child: TileLayer(
                  urlTemplate:
                      'https://ms.longdo.com/mmmap/tile.php?zoom={z}&x={x}&y={y}&key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&proj=epsg3857&HD=1&layer=traffic',
                ),
              ),

            // Route Polyline (Mockup Mint/Cyan Glow effect)
            if (provider.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Outer Glow Shadow
                  Polyline(
                    points: provider.routePoints,
                    strokeWidth: 9,
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                  // Inner bright core
                  Polyline(
                    points: provider.routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFF34D399),
                  ),
                ],
              ),

            // Markers
            MarkerLayer(
              markers: [
                // User Location
                Marker(
                  point: provider.currentPosition,
                  width: 30,
                  height: 30,
                  child: _buildLocationMarker(),
                ),
                // Shared Location from Chat
                if (provider.sharedPosition != null)
                  Marker(
                    point: provider.sharedPosition!,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            "แชร์พิกัด",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Facilities
                ...provider.facilities.map(
                  (f) => TacticalFacilityMarker.build(
                    facility: f,
                    isSelected: provider.selectedFacility?.id == f.id,
                    onTap: () {
                      provider.selectFacility(f);
                      _animatedMapController.animateTo(
                        dest: LatLng(f.latitude, f.longitude),
                        zoom: 16,
                      );
                    },
                    context: context,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Navigation HUD or Header
        if (provider.routePoints.isNotEmpty)
          SafeArea(child: _buildNavigationHUD(provider))
        else if (!isWide)
          SafeArea(
            child: GoogleMapHeader(
              searchController: _searchController,
              onSearch: (q) async {
                final searchedPos = await provider.handleSearch(q);
                if (mounted && searchedPos != null) {
                  _animatedMapController.animateTo(
                    dest: searchedPos,
                    zoom: 15,
                  );
                }
              },
              onBack: () => Navigator.maybePop(context),
            ),
          ),

        // 3. Floating "Search This Area" Button
        if (provider.showSearchThisArea && provider.routePoints.isEmpty)
          _buildSearchThisAreaButton(provider),

        // 4. Mobile Quick Facility List FAB (Hidden when a card is selected to prevent overlap)
        if (!isWide && provider.routePoints.isEmpty && provider.selectedFacility == null)
          Positioned(
            left: 16,
            bottom: 32,
            child: FloatingActionButton.extended(
              heroTag: 'mobile_facility_list_fab',
              onPressed: () => _openMobileFacilityList(context, provider),
              icon: const Icon(
                Icons.format_list_bulleted_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'สถานพยาบาล (${provider.facilities.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: const Color(0xFF131D31),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
            ),
          ),

        // 5. Step-by-Step Instructions Overlay Panel
        if (_showStepByStepPanel && provider.routePoints.isNotEmpty)
          const RoutingInstructionsPanel(),

        // 6. Side Controls
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          right: 16,
          bottom: (provider.selectedFacility != null) ? 260 : 32,
          child: MapControls(
            onToggleLayer: _showLayerMenu,
            onToggleFollow: _cycleFollowMode,
            onToggleHike: () =>
                _showHikeConfirmation(context, provider, offlineService),
          ),
        ),

        // 7. Mockup-Style Floating Facility Card (with Google Maps button)
        if (provider.selectedFacility != null)
          Positioned(
            left: isWide ? 32 : 16,
            right: isWide ? null : 16,
            bottom: 24,
            child: FloatingFacilityCard(
              facility: provider.selectedFacility!,
              onClose: () {
                provider.selectFacility(null);
              },
            ),
          ),

        // 8. Offline Status Toast
        if (offlineService.isDownloading)
          _buildOfflineProgress(offlineService),

        // 10. Loading Indicator Overlay
        if (provider.isLoading)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'กำลังประมวลผลข้อมูล...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineProgress(MapOfflineService service) {
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              service.status,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: service.progress,
              backgroundColor: Colors.white24,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _showLayerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'สไตล์แผนที่',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLayerOption('Normal', 'normal', Icons.dark_mode_rounded),
                _buildLayerOption(
                  'Satellite',
                  'satellite',
                  Icons.satellite_alt_rounded,
                ),
                _buildLayerOption('Traffic', 'traffic', Icons.traffic_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerOption(String label, String value, IconData icon) {
    final provider = context.read<MapProvider>();
    final isSelected = provider.mapStyle == value;
    return GestureDetector(
      onTap: () {
        provider.setMapStyle(value);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _cycleFollowMode() {
    final provider = context.read<MapProvider>();
    provider.resetToCurrentPosition();
    _animatedMapController.animateTo(
      dest: provider.currentPosition,
      zoom: 15,
      rotation: 0,
    );
    if (provider.followMode == 'none') {
      provider.setFollowMode('northUp');
    } else if (provider.followMode == 'northUp') {
      provider.setFollowMode('headingUp');
    } else {
      provider.setFollowMode('none');
    }
  }

  void _showHikeConfirmation(
    BuildContext context,
    MapProvider provider,
    MapOfflineService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hiking_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text(
              'ยืนยันเข้าโหมดเดินป่า',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'ระบบจะดาวน์โหลดแผนที่ออฟไลน์ในบริเวณรอบตัวคุณ เพื่อให้ใช้งานได้แม้ไม่มีอินเทอร์เน็ต ต้องการดำเนินการต่อหรือไม่?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              service.downloadAreaTiles(provider.currentPosition);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HikeDashboardScreen(
                    initialPosition: provider.currentPosition,
                  ),
                ),
              );
            },
            child: const Text('ยืนยันและโหลดแผนที่'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHUD(MapProvider provider) {
    final destinationName = provider.selectedFacility?.name ?? 'ที่หมาย';
    final distanceStr = provider.routeDistance != null
        ? '${provider.routeDistance!.toStringAsFixed(1)} กม.'
        : '-- กม.';
    final etaStr = provider.eta ?? '-- นาที';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Direction icon with background glow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Distance, Destination Name and ETA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destinationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            distanceStr,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            etaStr,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Toggle Step-by-Step Instructions List
                IconButton(
                  icon: Icon(
                    _showStepByStepPanel
                        ? Icons.toc_rounded
                        : Icons.format_list_bulleted_rounded,
                    color: _showStepByStepPanel
                        ? Colors.blueAccent
                        : Colors.white70,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showStepByStepPanel = !_showStepByStepPanel;
                    });
                  },
                ),

                // Close/Stop Navigation Button
                IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.white60,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showStepByStepPanel = false;
                    });
                    provider.clearRoute();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchThisAreaButton(MapProvider provider) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            final center = _mapController.camera.center;
            provider.searchFacilitiesInCenter(center);
            provider.setShowSearchThisArea(false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_rounded, color: Colors.blueAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'ค้นหาในบริเวณนี้',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
