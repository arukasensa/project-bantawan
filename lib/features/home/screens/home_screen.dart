// ============================================================================
// 🏠 BANTAWAN Home Tactical Command Center: HomeScreen (Main Dashboard Layer)
// 
// หน้าจอหลักของแอปพลิเคชัน (Home Tactical Hub Screen)
// รวมภาพรวมสถานะผู้ใช้: พิกัด GPS และที่อยู่ออฟไลน์, การ์ดสถานพยาบาลที่ใกล้ที่สุด,
// สภาพอากาศและค่าฝุ่น PM2.5, เมนูลัดบริการฉุกเฉิน 1669, สถานะ Safety Check,
// และสถานะเครือข่ายออฟไลน์ Mesh Network
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'dart:ui';
import 'package:flutter1/core/navigation/main_navigation.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'package:flutter1/features/survival/screens/survival_tools_screen.dart';
import 'package:flutter1/features/emergency/screens/emergency_contact_screen.dart';
import 'package:flutter1/features/emergency/screens/all_emergency_numbers_screen.dart';
import 'package:flutter1/features/weather/services/weather_service.dart';
import 'package:flutter1/models/medical_facility.dart';
import 'package:flutter1/core/utils/medical_facility_classifier.dart';
import 'package:flutter1/features/map/services/longdo_service.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter1/features/weather/screens/weather_detail_screen.dart';
import 'package:flutter1/providers/profile_provider.dart';
import 'package:flutter1/providers/map_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter1/core/widgets/shimmer_loading.dart';
import 'package:flutter1/features/emergency/services/safety_check_service.dart';
import 'package:flutter1/features/map/services/map_offline_service.dart';
import 'package:flutter1/features/emergency/screens/safety_check_screen.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';
import 'package:flutter1/features/chat/screens/nearby_chat_screen.dart';
import 'package:flutter1/features/survival/services/device_health_service.dart';
import 'package:flutter1/core/widgets/tactical_decorations_painter.dart';
import 'package:flutter1/features/notifications/services/notification_service.dart';
import 'package:flutter1/features/notifications/widgets/notification_bottom_sheet.dart';
import 'package:flutter1/features/survival/services/hike_service.dart';
import 'package:flutter1/features/survival/screens/hike_dashboard_screen.dart';

/// 🏠 หน้าจอหลักของแอปพลิเคชัน BANTAWAN (Home Dashboard)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 🎛️ State ควบคุมการโหลดพิกัดปัจจุบัน ข้อมูลสถานพยาบาลใกล้ฉัน และพยากรณ์อากาศ
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _currentAddress;
  String? _currentCity;
  bool _isLoadingHospital = false;
  MedicalFacility? _nearestHospital;
  WeatherData? _weatherData;
  double? _nearestDistance;

  late AnimationController _sosAnimationController;
  late AnimationController _radarAnimationController;

  // --- 🧲 Draggable & Magnetic Floating Pill Coordinates ---
  Offset? _floatingPillPosition;
  bool _isDraggingPill = false;
  static const double _pillWidth = 198.0;
  static const double _pillHeight = 46.0;

  final List<Map<String, dynamic>> _emergencyNumbers = [
    {
      'key': 'medicalEmergency',
      'name': 'แพทย์ฉุกเฉิน',
      'number': '1669',
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFFE53935),
    },
    {
      'key': 'police',
      'name': 'ตำรวจ',
      'number': '191',
      'icon': Icons.local_police_rounded,
      'color': const Color(0xFF1E88E5),
    },
    {
      'key': 'fire',
      'name': 'ดับเพลิง',
      'number': '199',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFFF6F00),
    },
    {
      'key': 'tourist',
      'name': 'ท่องเที่ยว',
      'number': '1155',
      'icon': Icons.tour_rounded,
      'color': const Color(0xFF43A047),
    },
    {
      'key': 'rescue',
      'name': 'กู้ภัย',
      'number': '1784',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF8E24AA),
    },
    {
      'key': 'mentalHealth',
      'name': 'สุขภาพจิต',
      'number': '1323',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF00ACC1),
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'key': 'hospitals',
      'name': 'โรงพยาบาล',
      'icon': Icons.local_hospital_outlined,
      'color': const Color(0xFF43A047),
    },
    {
      'key': 'firstAidGuide',
      'name': 'คู่มือปฐมพยาบาล',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFFF6F00),
    },
    {
      'key': 'emergencyContacts',
      'name': 'ผู้ติดต่อฉุกเฉิน',
      'icon': Icons.contact_phone_outlined,
      'color': const Color(0xFF8E24AA),
    },
    {
      'key': 'medicalHistory',
      'name': 'ประวัติสุขภาพ',
      'icon': Icons.history,
      'color': const Color(0xFF00ACC1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _sosAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _radarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Add a slight delay to allow the app to fully initialize before requesting GPS
    Future.delayed(
      const Duration(milliseconds: 800),
      () => _determinePosition(),
    );
  }

  @override
  void dispose() {
    _sosAnimationController.dispose();
    _radarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() {
      _currentAddress = "กำลังดึงตำแหน่ง...";
      _currentCity = "กำลังระบุ...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = AppLocalizations.of(context)!.retryHint;
            _currentCity = AppLocalizations.of(context)!.locationNotFound;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentAddress = "Permission Required"; // TODO: Add to ARB
              _currentCity = "No Permission";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentAddress = "เปิดสิทธิ์ในตั้งค่า";
            _currentCity = "ถูกปิดกั้น";
          });
        }
        return;
      }

      // Optimize: Get last known location first for instant UI update
      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high, // Optimized from best
          timeLimit: const Duration(seconds: 20),
          forceLocationManager: true, // Better compatibility for APKs
        ),
      );

      if (mounted) {
        context.read<MapProvider>().setPosition(
          latlong.LatLng(position.latitude, position.longitude),
        );
        HapticFeedback.selectionClick();
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );


      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          final street = place.street?.isNotEmpty == true
              ? place.street
              : place.subLocality;
          final locality = place.subLocality?.isNotEmpty == true
              ? place.subLocality
              : place.locality;

          _currentAddress = [street, locality]
              .where((e) => e != null && e.isNotEmpty && !e.contains('+'))
              .join(', ');
          if (_currentAddress != null && _currentAddress!.isEmpty) {
            _currentAddress = "ไม่ทราบชื่อถนน";
          }

          _currentCity = [
            place.subAdministrativeArea,
            place.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(' ');

          if (_currentCity!.isEmpty) _currentCity = "Thailand";
        });

        final currentPos = position;
        setState(() => _isLoadingHospital = true);

        try {
          final results = await LongdoService.searchNearbyPOI(
            tag: 'hospital',
            keyword: 'โรงพยาบาล',
            location: latlong.LatLng(currentPos.latitude, currentPos.longitude),
            limit: 10,
          );

          if (mounted && results.isNotEmpty) {
            Map<String, dynamic>? validItem;
            String? detectedType;

            for (final item in results) {
              final name = (item['name'] ?? '').toString();
              final type = MedicalFacilityClassifier.classify(
                name: name,
                tag: item['tag']?.toString(),
              );
              // ต้องเป็นโรงพยาบาลหรือสถานพยาบาลที่ผ่านการคัดกรอง
              if (type != null) {
                validItem = item;
                detectedType = type;
                break;
              }
            }

            if (validItem != null && detectedType != null) {
              final firstName = (validItem['name'] ?? '').toString();
              setState(() {
                _nearestHospital = MedicalFacility(
                  id: validItem!['id']?.toString() ?? 'near-1',
                  name: firstName,
                  type: detectedType!,
                  address: validItem['address'] ?? '',
                  latitude: double.tryParse(validItem['lat']?.toString() ?? '0') ?? 0,
                  longitude: double.tryParse(validItem['lon']?.toString() ?? '0') ?? 0,
                  phone: validItem['tel'] ?? '',
                );
                _nearestDistance = _nearestHospital!.distanceFrom(
                  currentPos.latitude,
                  currentPos.longitude,
                );
              });
            }
          }
        } catch (e) {
          debugPrint('Hospital fetch error: $e');
        } finally {
          if (mounted) setState(() => _isLoadingHospital = false);
        }

        final weather = await WeatherService.getRealTimeWeather(
          currentPos.latitude,
          currentPos.longitude,
        );
        if (weather != null && mounted) {
          // Check for Smart Warnings
          WeatherService.checkAndNotify(weather);

          setState(() {
            _weatherData = weather;
          });
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() {
          _currentAddress = AppLocalizations.of(context)!.tapToRetry;
          _currentCity = AppLocalizations.of(context)!.locationNotFound;
        });
      }
    } finally {
      // Data loading complete
    }
  }

  Future<void> _makeCall(String number) async {
    await CallService.makeCall(number);
  }

  void _navigateToSOS() {
    HapticFeedback.lightImpact();
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    if (mainNavState != null) mainNavState.changeTab(2); // SOS is index 2
  }

  void _handleServiceTap(int index) {
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    switch (index) {
      case 0: // Hospitals
        if (mainNavState != null) mainNavState.changeTab(3); // Tab 3 is Map
        break;
      case 1: // First Aid
        if (mainNavState != null) {
          mainNavState.changeTab(1); // Tab 1 is First Aid
        }
        break;
      case 2: // Emergency Contacts
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencyContactScreen(),
          ),
        );
        break;
      case 3: // Medical History
        if (mainNavState != null) mainNavState.changeTab(4); // Tab 4 is Profile
        break;
    }
  }

  String _getEmergencyName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'medicalEmergency':
        return l10n.medicalEmergency;
      case 'police':
        return l10n.police;
      case 'fire':
        return l10n.fire;
      case 'tourist':
        return l10n.tourist;
      case 'rescue':
        return l10n.rescue;
      case 'mentalHealth':
        return l10n.mentalHealth;
      default:
        return '';
    }
  }

  String _getServiceName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'hospitals':
        return l10n.hospitals;
      case 'firstAidGuide':
        return l10n.firstAidGuide;
      case 'emergencyContacts':
        return l10n.emergencyContacts;
      case 'medicalHistory':
        return l10n.medicalHistory;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;

    // ขอบเขตความปลอดภัยสำหรับการลากปุ่มลอย (Safe Drag Bounds)
    final double minX = 16.0;
    final double maxX = (screenSize.width - _pillWidth - 16.0).clamp(16.0, double.infinity);
    final double minY = screenPadding.top + 60.0;
    final double maxY = (screenSize.height - 100.0 - _pillHeight).clamp(minY, double.infinity);

    // กำหนดพิกัดเริ่มต้นถ้ายังไม่ได้ลาก (มุมล่างขวาเหนือ Bottom Bar)
    final currentPos = _floatingPillPosition ??
        Offset(maxX, screenSize.height - 96 - _pillHeight - screenPadding.bottom);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Premium Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F23),
                    Color(0xFF16213E),
                    Color(0xFF050510),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: TacticalGridPainter(color: Colors.blueAccent),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(child: _buildTopBar()),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () {
                      final mainNavState = context
                          .findAncestorStateOfType<MainNavigationState>();
                      if (mainNavState != null) mainNavState.changeTab(4);
                    },
                    child: _buildGreeting(),
                  ),
                  const SizedBox(height: 25),

                  // Weather Alert Priority
                  _buildDisasterAlert(),
                  const SizedBox(height: 12),

                  // Connectivity Stability Alert
                  _buildConnectivityAlert(),
                  const SizedBox(height: 12),

                  // New: Safety Check Status
                  _buildSafetyCheckStatus(),
                  const SizedBox(height: 16),

                  // Device Health Dashboard
                  _buildDeviceHealthDashboard(),
                  const SizedBox(height: 16),

                  // Main Action Buttons (SOS & Disaster)
                  _buildMainLargeButtons(),
                  const SizedBox(height: 25),

                  // Main Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<ProfileProvider>(
                          builder: (context, provider, _) => GestureDetector(
                            onTap: () => _handleServiceTap(3),
                            child: _buildMedicalIDMini(provider),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleServiceTap(0),
                          child: _buildHospitalMini(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.emergencyHotlines,
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllEmergencyNumbersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEmergencyGrid(),

                  const SizedBox(height: 30),
                  _buildSectionHeader(AppLocalizations.of(context)!.medicalId),
                  const SizedBox(height: 15),
                  _buildServicesGrid(),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // 🌲 Hike Floating Action Pill (When Hiking Mode is active!)
          Consumer<HikeService>(
            builder: (context, hikeService, _) {
              if (!hikeService.isHikeActive) return const SizedBox.shrink();

              final hikeY = (currentPos.dy - _pillHeight - 12).clamp(minY, maxY);

              return AnimatedPositioned(
                duration: _isDraggingPill ? Duration.zero : const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                left: currentPos.dx.clamp(minX, maxX),
                top: hikeY,
                child: _buildHikeFloatingPill(hikeService, minX, maxX, minY, maxY, screenSize),
              );
            },
          ),

          // 🚀 Cyberpunk Floating Action Pill (Draggable + Magnetic Snap to Left/Right)
          AnimatedPositioned(
            duration: _isDraggingPill ? Duration.zero : const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            left: currentPos.dx.clamp(minX, maxX),
            top: currentPos.dy.clamp(minY, maxY),
            child: _buildCyberpunkMeshFloatingPill(minX, maxX, minY, maxY, screenSize),
          ),
        ],
      ),
    );
  }

  /// 🚀 ปุ่มลอยสไตล์ Cyberpunk (Floating Action Pill) เข้าถึงแชทออฟไลน์ (#mesh) แบบรวดเร็ว
  /// รองรับการกดลากขึ้นลง ย้ายข้าง และดูดชิดขอบซ้าย-ขวาอัตโนมัติ (Magnetic Snap)
  Widget _buildCyberpunkMeshFloatingPill(
    double minX,
    double maxX,
    double minY,
    double maxY,
    Size screenSize,
  ) {
    return Consumer<NearbyService>(
      builder: (context, nearbyService, _) {
        final connectedCount = nearbyService.connectedDevices.length;
        final hasUrgentNotice = nearbyService.notices.any((n) => n.isUrgent);
        final noticeCount = nearbyService.notices.length;
        final isScanning = nearbyService.isAdvertising || nearbyService.isDiscovering;
        final isConnected = connectedCount > 0;

        // โทนสีนีออนตามสถานะ: แดงฉุกเฉิน / เขียวอมฟ้าออนไลน์ / น้ำเงินสแกน
        final Color primaryGlow = hasUrgentNotice
            ? Colors.redAccent
            : (isConnected ? const Color(0xFF00ADB5) : const Color(0xFF2196F3));

        return AnimatedBuilder(
          animation: _radarAnimationController,
          builder: (context, child) {
            final pulseValue = (1.0 + 0.08 * (0.5 - (0.5 - _radarAnimationController.value).abs()));

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearbyChatScreen(),
                  ),
                );
              },
              onPanStart: (details) {
                HapticFeedback.selectionClick();
                setState(() => _isDraggingPill = true);
              },
              onPanUpdate: (details) {
                final cur = _floatingPillPosition ??
                    Offset(maxX, screenSize.height - 96 - _pillHeight - MediaQuery.of(context).padding.bottom);
                setState(() {
                  _floatingPillPosition = Offset(
                    (cur.dx + details.delta.dx).clamp(minX - 6, maxX + 6),
                    (cur.dy + details.delta.dy).clamp(minY, maxY),
                  );
                });
              },
              onPanEnd: (details) {
                final cur = _floatingPillPosition ??
                    Offset(maxX, screenSize.height - 96 - _pillHeight - MediaQuery.of(context).padding.bottom);
                // 🧲 ดูดชิดซ้ายหรือชิดขวาอัตโนมัติ (Magnetic Snap to Edge)
                final snapToLeft = (cur.dx + _pillWidth / 2) < (screenSize.width / 2);
                final targetX = snapToLeft ? minX : maxX;
                HapticFeedback.mediumImpact();
                setState(() {
                  _isDraggingPill = false;
                  _floatingPillPosition = Offset(targetX, cur.dy.clamp(minY, maxY));
                });
              },
              child: AnimatedScale(
                scale: _isDraggingPill ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: _pillWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: hasUrgentNotice
                            ? [
                                const Color(0xFF330B12).withValues(alpha: 0.94),
                                const Color(0xFF1A060A).withValues(alpha: 0.96),
                              ]
                            : [
                                const Color(0xFF0A1424).withValues(alpha: 0.92),
                                const Color(0xFF050B14).withValues(alpha: 0.96),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primaryGlow.withValues(alpha: isConnected || hasUrgentNotice ? 0.75 : 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGlow.withValues(
                            alpha: hasUrgentNotice
                                ? 0.45
                                : (isConnected ? 0.35 : 0.18),
                          ),
                          blurRadius: isConnected ? 16 : 8,
                          spreadRadius: isConnected ? 1 : 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // จุดเรดาร์สถานะเชื่อมต่อกระพริบตามจังหวะ
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasUrgentNotice
                                ? Colors.redAccent
                                : (isConnected
                                    ? Colors.greenAccent
                                    : (isScanning ? Colors.amberAccent : Colors.white38)),
                            boxShadow: [
                              BoxShadow(
                                color: (hasUrgentNotice
                                        ? Colors.redAccent
                                        : (isConnected ? Colors.greenAccent : Colors.amberAccent))
                                    .withValues(alpha: 0.8),
                                blurRadius: 6 * pulseValue,
                                spreadRadius: 1 * pulseValue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ไอคอน Cyberpunk Mesh / Alert
                        Icon(
                          hasUrgentNotice
                              ? Icons.warning_amber_rounded
                              : (isConnected ? Icons.hub_rounded : Icons.cell_tower_rounded),
                          color: primaryGlow,
                          size: 18,
                        ),
                        const SizedBox(width: 8),

                        // คอลัมน์ข้อความและสถานะ
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "#mesh ออฟไลน์",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (noticeCount > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: hasUrgentNotice ? Colors.redAccent : const Color(0xFF00ADB5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$noticeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              hasUrgentNotice
                                  ? "🚨 มีประกาศด่วน"
                                  : (isConnected
                                      ? "$connectedCount โหนดออนไลน์"
                                      : (isScanning ? "กำลังสแกนหาเพื่อน..." : "แตะเพื่อเปิดเรดาร์")),
                              style: TextStyle(
                                color: hasUrgentNotice
                                    ? Colors.redAccent
                                    : (isConnected ? Colors.greenAccent : Colors.white60),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),

                        // ไอคอนลูกศรนำทาง
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryGlow.withValues(alpha: 0.7),
                          size: 11,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  }

  /// 🌲 ปุ่มลอยเข้าถึงโหมดเดินป่า (Hike Floating Pill) เมื่อมีการบันทึกเส้นทางค้างอยู่
  Widget _buildHikeFloatingPill(
    HikeService hikeService,
    double minX,
    double maxX,
    double minY,
    double maxY,
    Size screenSize,
  ) {
    const primaryGlow = Colors.greenAccent;

    return AnimatedBuilder(
      animation: _radarAnimationController,
      builder: (context, child) {
        final pulseValue = (1.0 + 0.08 * (0.5 - (0.5 - _radarAnimationController.value).abs()));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HikeDashboardScreen(
                  initialPosition: hikeService.currentPosition,
                ),
              ),
            );
          },
          child: AnimatedScale(
            scale: _isDraggingPill ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: _pillWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D2818),
                        Color(0xFF05150D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: primaryGlow.withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlow.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // จุดเรดาร์สีเขียวนีออนกระพริบ
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.8),
                              blurRadius: 6 * pulseValue,
                              spreadRadius: 1 * pulseValue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ไอคอนภูเขา/เดินป่า
                      const Icon(
                        Icons.landscape_rounded,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),

                      // คอลัมน์ข้อความและสถานะ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "🌲 เดินป่าอยู่",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              hikeService.isBacktrackActive
                                  ? "🧭 กำลังย้อนรอย..."
                                  : "${hikeService.totalDistanceKm.toStringAsFixed(2)} กม. • ${hikeService.breadcrumbs.length} จุด",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // ไอคอนลูกศรนำทาง
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: primaryGlow.withValues(alpha: 0.7),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainLargeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _tacticalCircularButton(
            title: "SOS",
            subtitle: "กดเพื่อขอความช่วยเหลือทันที",
            color: Colors.redAccent,
            onTap: _navigateToSOS,
            animation: _radarAnimationController,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _tacticalCircularButton(
            title: "SURVIVAL PROTOCOL",
            icon: Icons.explore_rounded,
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SurvivalToolsScreen(),
                ),
              );
            },
            animation: _radarAnimationController,
          ),
        ),
      ],
    );
  }

  Widget _tacticalCircularButton({
    required String title,
    String? subtitle,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
    required Animation<double>
    animation, // Kept parameter to avoid breaking calls, but not used internally now
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: color == Colors.redAccent
                    ? const [Color(0xFFFF4D4D), Color(0xFFE53935)]
                    : color == Colors.blueAccent
                    ? const [Color(0xFF2196F3), Color(0xFF1565C0)]
                    : [color, color.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 80,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 34),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ] else ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                // Outer Tactical Ring (Static)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  isLoading:
                      _currentCity == "กำลังระบุ..." || _currentCity == null,
                  child: Text(
                    _currentCity ?? "ไม่ทราบตำแหน่ง",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ShimmerLoading(
                  isLoading:
                      _currentAddress == "กำลังดึงตำแหน่ง..." ||
                      _currentAddress == null,
                  child: Text(
                    _currentAddress ?? "ไม่ทราบที่อยู่ขณะนี้",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Consumer<NotificationService>(
            builder: (context, notifService, _) {
              final unread = notifService.unreadCount;
              final hasSos = notifService.hasCriticalSos;

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => NotificationBottomSheet(
                      currentWeather: _weatherData,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        unread > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: hasSos
                            ? Colors.redAccent
                            : (unread > 0 ? Colors.amberAccent : Colors.white),
                        size: 28,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasSos ? Colors.redAccent : const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0F172A),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (hasSos ? Colors.redAccent : Colors.red)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    String greeting = "สวัสดีตอนกลางวัน ,";
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "สวัสดีตอนเช้า ,";
    } else if (hour < 17) {
      greeting = "สวัสดีตอนกลางวัน ,";
    } else {
      greeting = "สวัสดีตอนเย็น ,";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: Colors.blueAccent.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "SECURE LINK",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "ระบบดูแลความปลอดภัยทำงานปกติ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisasterAlert() {
    if (_weatherData == null) {
      return ShimmerLoading(isLoading: true, child: const WeatherSkeleton());
    }

    final data = _weatherData!;

    // กำหนดโทนสีตามความรุนแรงของสภาพอากาศหรือฝุ่น
    Color themeColor = const Color(0xFF10B981); // Emerald
    Color glowColor = const Color(0xFF10B981).withValues(alpha: 0.15);

    if (data.pm25 > 50 || data.weatherCode >= 95) {
      themeColor = const Color(0xFFEF4444); // Red
      glowColor = const Color(0xFFEF4444).withValues(alpha: 0.25);
    } else if (data.pm25 > 35) {
      themeColor = const Color(0xFFF97316); // Orange
      glowColor = const Color(0xFFF97316).withValues(alpha: 0.2);
    } else if (data.weatherCode >= 51 && data.weatherCode <= 82) {
      themeColor = const Color(0xFF06B6D4); // Cyan
      glowColor = const Color(0xFF06B6D4).withValues(alpha: 0.2);
    } else if (data.pm25 > 25) {
      themeColor = const Color(0xFFF59E0B); // Amber
      glowColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailScreen(weatherData: data),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF131D31).withValues(alpha: 0.9),
              const Color(0xFF0D1424).withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Radar Title & AQI Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        color: themeColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'สภาพอากาศและสิ่งแวดล้อม',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'AQI: ${data.aqiValue.toInt()} • ${data.status}',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Middle Row: Weather Icon + Big Temp + Thai Weather Text + Feels like
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    data.weatherIcon,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            data.temperature.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            '°C',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.weatherConditionTh,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'รู้สึกเหมือน ${data.apparentTemperature.toStringAsFixed(1)}°C • PM 2.5: ${data.pm25.toStringAsFixed(1)} µg/m³',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Chips Row: Humidity, Wind, UV, Rain probability
            Row(
              children: [
                _buildWeatherMiniChip(
                  icon: Icons.water_drop_rounded,
                  label: 'ชื้น ${data.humidity}%',
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 8),
                _buildWeatherMiniChip(
                  icon: Icons.air_rounded,
                  label: 'ลม ${data.windSpeed.toStringAsFixed(0)} km/h',
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                _buildWeatherMiniChip(
                  icon: Icons.wb_sunny_rounded,
                  label: 'UV ${data.uvIndex.toStringAsFixed(1)}',
                  color: Colors.amberAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Action Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'พยากรณ์ 24 ชม. & 7 วันข้างหน้า',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMiniChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityAlert() {
    return Consumer<MapOfflineService>(
      builder: (context, offlineService, _) {
        if (!offlineService.showDownloadPrompt) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.orangeAccent.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.orangeAccent,
                size: 28,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "อินเทอร์เน็ตไม่เสถียร",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "แนะนำให้สำรองแผนที่ออฟไลน์ไว้เพื่อความปลอดภัยก่อนเดินทางติดขัด",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  // Reset prompt
                  offlineService.setShowDownloadPrompt(false);

                  // Capture messenger before async gap (fixes use_build_context_synchronously)
                  final messenger = ScaffoldMessenger.of(context);

                  // Start download logic (needs current position)
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    offlineService.downloadAreaTiles(
                      latlong.LatLng(pos.latitude, pos.longitude),
                    );

                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("กำลังเริ่มดาวน์โหลดแผนที่ออฟไลน์..."),
                          backgroundColor: Colors.blueAccent,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Download trigger error: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("ดาวน์โหลด"),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => offlineService.setShowDownloadPrompt(false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafetyCheckStatus() {
    return Consumer<SafetyCheckService>(
      builder: (context, safetyService, _) {
        final isActive = safetyService.isActive;
        final minutes = (safetyService.remainingSeconds / 60).floor();
        final seconds = safetyService.remainingSeconds % 60;
        final isWarning = safetyService.isWarning;

        final color = isActive
            ? (isWarning ? Colors.redAccent : Colors.blueAccent)
            : Colors.white24;

        final borderColor = isActive
            ? color.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.1);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SafetyCheckScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isActive ? Icons.shield_rounded : Icons.shield_outlined,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? (isWarning
                                  ? "เตือน: เวลาใกล้หมดแล้ว!"
                                  : "ระบบเช็คอินกำลังทำงาน")
                            : "ระบบเช็คอินอัตโนมัติ",
                        style: TextStyle(
                          color: isWarning ? Colors.redAccent : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isActive
                            ? "เหลือเวลา: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}${safetyService.isRecurring ? ' (โหมดวนลูป)' : ''}"
                            : "ตั้งเวลาเพื่อส่ง SOS อัตโนมัติหากขาดการติดต่อ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceHealthDashboard() {
    return Consumer2<DeviceHealthService, NearbyService>(
      builder: (context, healthService, nearbyService, _) {
        final battery = healthService.batteryLevel;
        final gps = healthService.isGpsEnabled;
        final meshCount = nearbyService.connectedDevices.length;

        // Custom styling for Battery status
        Color batteryColor = Colors.greenAccent;
        IconData batteryIcon = Icons.battery_full_rounded;
        if (battery < 20) {
          batteryColor = Colors.redAccent;
          batteryIcon = Icons.battery_alert_rounded;
        } else if (battery < 50) {
          batteryColor = Colors.orangeAccent;
          batteryIcon = Icons.battery_charging_full_rounded;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "DEVICE HEALTH DASHBOARD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "SECURE",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Health Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Battery Item
                  Expanded(
                    child: _buildHealthStatusItem(
                      icon: batteryIcon,
                      iconColor: batteryColor,
                      label: "แบตเตอรี่",
                      value: "$battery%",
                      subValue: battery < 20 ? "กรุณาชาร์จ" : "ปกติ",
                      subValueColor: battery < 20 ? Colors.redAccent : Colors.white54,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 45,
                    color: Colors.white10,
                  ),
                  // GPS Item
                  Expanded(
                    child: _buildHealthStatusItem(
                      icon: gps ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                      iconColor: gps ? Colors.greenAccent : Colors.redAccent,
                      label: "สัญญาณ GPS",
                      value: gps ? "เปิดใช้งาน" : "ปิดใช้งาน",
                      subValue: gps ? "ระบุตำแหน่งได้" : "ระบุไม่ได้",
                      subValueColor: gps ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 45,
                    color: Colors.white10,
                  ),
                  // Mesh Nodes Item (Tappable Quick Access)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NearbyChatScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: _buildHealthStatusItem(
                        icon: Icons.hub_rounded,
                        iconColor: meshCount > 0 ? const Color(0xFF00ADB5) : Colors.white30,
                        label: "เครือข่าย Mesh",
                        value: "$meshCount โหนด",
                        subValue: meshCount > 0 ? "แตะเพื่อแชท" : "ไม่มีการเชื่อมต่อ",
                        subValueColor: meshCount > 0 ? const Color(0xFF00ADB5) : Colors.white30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthStatusItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subValue,
    required Color subValueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: TextStyle(
            color: subValueColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalIDMini(ProfileProvider provider) {
    final profile = provider.profile;
    final blood = profile['bloodType']?.isNotEmpty == true
        ? profile['bloodType']
        : '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(height: 15),
          const Text(
            "ประวัติสุขภาพ",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            'หมู่เลือด - $blood',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalMini() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.greenAccent,
              size: 20,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "โรงพยาบาลใกล้ที่สุด",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            _isLoadingHospital
                ? '...'
                : (_nearestDistance != null
                      ? '${_nearestDistance!.toStringAsFixed(1)} Km'
                      : '-'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'ดูทั้งหมด',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final item = _emergencyNumbers[index];
        return GestureDetector(
          onTap: () => _makeCall(item['number']),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (item['color'] as Color).withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item['color'] as Color).withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['number'],
                  style: TextStyle(
                    color: item['color'],
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _getEmergencyName(context, item['key']),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final item = _services[index];
        return _InteractiveGlassCard(
          onTap: () => _handleServiceTap(index),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'], color: item['color'], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getServiceName(context, item['key']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InteractiveGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveGlassCard({required this.child, required this.onTap});

  @override
  State<_InteractiveGlassCard> createState() => _InteractiveGlassCardState();
}

class _InteractiveGlassCardState extends State<_InteractiveGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isPressed
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
