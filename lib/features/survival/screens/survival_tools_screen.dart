// ============================================================================
// 🧰 BANTAWAN Tactical Survival Tools Hub: SurvivalToolsScreen
//
// หน้าจอรวมชุดเครื่องมือเอาชีวิตรอดทางยุทธวิธี (Tactical Survival Tools Hub)
// ประกอบด้วยเข็มทิศดิจิทัล (Digital Compass), มาตรวัดระดับความสูง/พิกัด GPS,
// เครื่องส่งสัญญาณแสงไฟฉาย (Strobe & Morse), นกหวีดฉุกเฉินความถี่สูง, และบันทึกกิจกรรมเดินป่า
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';
import 'package:flutter1/features/chat/screens/nearby_chat_screen.dart';
import 'package:flutter1/features/emergency/services/emergency_tool_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter1/features/emergency/screens/safety_check_screen.dart';
import '../services/hike_service.dart';
import 'package:flutter1/features/map/services/map_offline_service.dart';
import 'hike_dashboard_screen.dart';
import 'package:flutter1/core/widgets/tactical_decorations_painter.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// 🧰 หน้าจอรวมเครื่องมือเอาชีวิตรอดและเข็มทิศทางยุทธวิธี (Survival Tools Screen)
class SurvivalToolsScreen extends StatefulWidget {
  /// หมวดหมู่เริ่มต้นที่ต้องการให้เลื่อนไปแสดงผล (ถ้ามี)
  final String? initialCategory;

  const SurvivalToolsScreen({super.key, this.initialCategory});

  @override
  State<SurvivalToolsScreen> createState() => _SurvivalToolsScreenState();
}

/// State ควบคุมเซนเซอร์เข็มทิศ พิกัด GPS และเครื่องมือฮาร์ดแวร์
class _SurvivalToolsScreenState extends State<SurvivalToolsScreen>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  double? _heading;
  bool _isLoading = true;
  bool?
  _compassSupported; // null = กำลังตรวจสอบ, true = รองรับ, false = ไม่รองรับ
  bool _compassPermissionDenied = false;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  String? _selectedCategory;

  // Scan Animation
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initSurvivalData();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initSurvivalData() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _currentPosition = lastPos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting last position: $e");
    }

    try {
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high, // Optimized from best
          timeLimit: const Duration(seconds: 10),
          forceLocationManager: true, // Better compatibility for APKs
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = currentPos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting current position: $e");
    }

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high, // Optimized from best
            distanceFilter: 5,
            forceLocationManager: true, // Better compatibility for APKs
          ),
        ).listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _isLoading = false;
            });
          }
        });

    await _initCompass();
  }

  Future<void> _initCompass() async {
    // 1. ตรวจสอบว่า FlutterCompass รองรับ Hardware Magnetometer ของเครื่องหรือไม่
    if (FlutterCompass.events == null) {
      if (mounted) setState(() => _compassSupported = false);
      return;
    }

    // 2. ตรวจสอบและขอสิทธิ์ Location (จำเป็นสำหรับ flutter_compass บน Android)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _compassPermissionDenied = true;
          _compassSupported = false;
        });
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          _compassPermissionDenied = true;
          _compassSupported = false;
        });
      }
      return;
    }

    // 3. เริ่ม subscribe compass events
    if (mounted) setState(() => _compassSupported = true);

    _compassSubscription = FlutterCompass.events!.listen(
      (event) {
        if (mounted && event.heading != null) {
          final double raw = event.heading!;
          // ปรับมุมองศาให้อยู่ในช่วง 0° - 359° เสมอ (ไม่ติดลบ)
          final double normalized = (raw % 360 + 360) % 360;
          setState(() => _heading = normalized);
        }
      },
      onError: (err) {
        debugPrint('[COMPASS] Stream error: $err');
        if (mounted) setState(() => _compassSupported = false);
      },
    );
  }

  Future<void> _shareLocationSMS() async {
    if (_currentPosition != null) {
      final text =
          "ฉันหลงทาง/ต้องการความช่วยเหลือ\nพิกัด: Lat ${_currentPosition!.latitude}, Long ${_currentPosition!.longitude}\nhttps://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}";
      final url = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  Future<void> _shareLocationLink() async {
    if (_currentPosition != null) {
      final link =
          "https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}";
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("คัดลอกลิงก์แผนที่เรียบร้อยแล้ว"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _makeEmergencyCall(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
            child: CustomPaint(
              painter: TacticalGridPainter(color: Colors.blueAccent),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedCategory == null
                        ? _buildCategorySelection()
                        : _buildDisasterTools(_selectedCategory!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 120,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (_selectedCategory != null) {
            setState(() => _selectedCategory = null);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _selectedCategory == null
              ? AppLocalizations.of(context)!.survivalTitle
              : _getDisasterTitle(_selectedCategory!),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  String _getDisasterTitle(String category) {
    switch (category) {
      case 'flood':
        return 'เหตุอุทกภัย (น้ำท่วม)';
      case 'fire':
        return 'เหตุอัคคีภัย (ไฟไหม้)';
      case 'earthquake':
        return 'เหตุแผ่นดินไหว';
      case 'lost':
        return 'สถานการณ์หลงทาง';
      default:
        return AppLocalizations.of(context)!.survivalTitle;
    }
  }

  Widget _buildCategorySelection() {
    return Column(
      key: const ValueKey('selection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          "TACTICAL DISASTER INTERFACE",
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "เลือกสถานการณ์เพื่อเข้าถึงระบบช่วยเหลือการสื่อสารแบบจำลองและออฟไลน์",
          style: TextStyle(color: Colors.white30, fontSize: 11),
        ),
        const SizedBox(height: 25),
        _buildCategoryCard(
          'flood',
          'น้ำท่วม',
          'ฉุกเฉินน้ำท่วมและการสื่อสารออฟไลน์',
          Icons.water_drop_rounded,
          Colors.blueAccent,
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          'fire',
          'ไฟไหม้',
          'สัญญาณไฟฉายและไซเรนขอความช่วยเหลือ',
          Icons.local_fire_department_rounded,
          Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          'earthquake',
          'แผ่นดินไหว',
          'สัญญาณขอความช่วยเหลือเบื้องต้น',
          Icons.vibration_rounded,
          Colors.redAccent,
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          'lost',
          'การหลงทาง',
          'เข็มทิศและการระบุพิกัดตำแหน่ง',
          Icons.explore_rounded,
          Colors.greenAccent,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  String _getCardSysCode(String id) {
    switch (id) {
      case 'flood':
        return 'SYS-FLD-01';
      case 'fire':
        return 'SYS-FIR-02';
      case 'earthquake':
        return 'SYS-EQK-03';
      case 'lost':
        return 'SYS-LST-04';
      default:
        return 'SYS-TAC-00';
    }
  }

  Widget _buildCategoryCard(
    String id,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: Stack(
        children: [
          // Tactical Scanning Background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TacticalScanPainter(
                      animationValue: _scanController.value,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TacticalCornerPainter(
                          color: color,
                          length: 12.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getCardSysCode(id),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "monospace",
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterTools(String category) {
    return Column(
      key: ValueKey(category),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSafetyTip(category),
        const SizedBox(height: 20),
        _buildAccuracyCard(),
        const SizedBox(height: 20),
        _buildCoordinateGrid(),
        const SizedBox(height: 25),
        if (category == 'lost') ...[
          _buildSafetyCheckShortcut(),
          const SizedBox(height: 25),
          _buildHikeShortcut(),
          const SizedBox(height: 25),
          _buildCompassSection(),
          const SizedBox(height: 25),
          _buildLostGuideSection(),
        ],
        if (category == 'flood') ...[
          _buildFloodDashboard(),
          const SizedBox(height: 25),
          _buildLocalSOSSection(),
          const SizedBox(height: 25),
          _buildFloodGuideSection(),
        ],
        if (category == 'fire' || category == 'earthquake') ...[
          _buildFireSOSSection(),
          const SizedBox(height: 25),
          _buildEmergencySignals(),
          const SizedBox(height: 25),
          if (category == 'fire') _buildFireGuideSection(),
          if (category == 'earthquake') _buildEarthquakeGuideSection(),
        ],
        const SizedBox(height: 25),
        const Text(
          "แชร์ตำแหน่งของท่าน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildSurvivalBtn(
          title: "ส่งพิกัดผ่าน SMS",
          subtitle: "ส่งข้อความขอความช่วยเหลือทันที",
          icon: Icons.sms_rounded,
          color: Colors.greenAccent,
          onTap: _shareLocationSMS,
        ),
        const SizedBox(height: 12),
        _buildSurvivalBtn(
          title: "คัดลอกลิงก์ตำแหน่ง",
          subtitle: "แชร์พิกัดเป็น Google Maps Link",
          icon: Icons.link_rounded,
          color: Colors.blueAccent,
          onTap: _shareLocationLink,
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildFloodDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Point 2: Enhanced Mesh Network
        _buildEnhancedMeshSection(),
      ],
    );
  }

  Widget _buildEnhancedMeshSection() {
    return Consumer<NearbyService>(
      builder: (context, service, _) {
        final bool isAdv = service.isAdvertising;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isAdv) const _MeshScanningPing(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isAdv ? Colors.blue : Colors.white)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdv
                                ? Icons.wifi_tethering_rounded
                                : Icons.wifi_tethering_off_rounded,
                            color: isAdv ? Colors.blueAccent : Colors.white38,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "เครือข่ายสื่อสารออฟไลน์ (Mesh Network)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isAdv
                                ? "ระบบกำลังสแกนหาคนรอบข้าง..."
                                : "ปิดการสื่อสารออฟไลน์",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAdv,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (val) {
                        HapticFeedback.mediumImpact();
                        if (val) {
                          service.startEmergencyNetwork();
                        } else {
                          service.stopEmergencyNetwork();
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (isAdv) ...[
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.hub_rounded,
                            color: Colors.blue.withValues(alpha: 0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "เชื่อมต่อแล้ว ${service.connectedDevices.length} โหนด",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyChatScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "เปิดห้องแชท",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalSOSSection() {
    return Consumer<NearbyService>(
      builder: (context, service, _) {
        if (service.isAdvertising != true) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ขอความช่วยเหลือเร่งด่วน (Local SOS)",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "ส่งสัญญาณถึงคนรอบข้างในระยะ 100 เมตร (ออฟไลน์)",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildSOSChip("ติดอยู่บนหลังคา", service),
                _buildSOSChip("ต้องการน้ำ/อาหาร", service),
                _buildSOSChip("มีผู้บาดเจ็บ/สูงอายุ", service),
                _buildSOSChip("ระดับน้ำสูงขึ้น", service),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSOSChip(String text, NearbyService service) {
    return GestureDetector(
      onTap: () async {
        await service.sendLocalSOS(text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("ส่งสัญญาณ: $text เรียบร้อยแล้ว"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFireSOSSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ขอความช่วยเหลือด่วน (SOS)",
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildSOSButton(
                "ดับเพลิง (199)",
                Icons.fire_truck_rounded,
                Colors.orangeAccent,
                () => _makeEmergencyCall('199'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSOSButton(
                "กู้ชีพ (1669)",
                Icons.medical_services_rounded,
                Colors.redAccent,
                () => _makeEmergencyCall('1669'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSOSButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySignals() {
    return Consumer<EmergencyToolService>(
      builder: (context, service, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "สัญญาณขอความช่วยเหลือ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildSignalCard(
                    service.isMorseActive ? "ปิดไฟ SOS" : "ไฟฉาย SOS",
                    Icons.flashlight_on_rounded,
                    service.isMorseActive ? Colors.yellow : Colors.white12,
                    () => service.toggleMorseSOS(!service.isMorseActive),
                    isActive: service.isMorseActive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSignalCard(
                    service.isStrobeActive ? "ปิดแฟลช" : "ไฟแฟลช",
                    Icons.flash_on_rounded,
                    service.isStrobeActive
                        ? Colors.orangeAccent
                        : Colors.white12,
                    () => service.toggleStrobe(!service.isStrobeActive),
                    isActive: service.isStrobeActive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSignalCard(
                    service.isSirenActive ? "ปิดไซเรน" : "ไซเรน",
                    Icons.volume_up_rounded,
                    service.isSirenActive ? Colors.redAccent : Colors.white12,
                    () => service.toggleSiren(!service.isSirenActive),
                    isActive: service.isSirenActive,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSafetyCheckShortcut() {
    return _buildSurvivalBtn(
      title: "ระบบเช็คอินอัตโนมัติ (Safety Check)",
      subtitle: "ส่ง SOS อัตโนมัติหากคุณขาดการติดต่อ",
      icon: Icons.timer_rounded,
      color: Colors.orangeAccent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SafetyCheckScreen()),
        );
      },
    );
  }

  Widget _buildHikeShortcut() {
    return Consumer<HikeService>(
      builder: (context, hikeService, _) {
        final isActive = hikeService.isHikeActive;
        return _buildSurvivalBtn(
          title: isActive
              ? "กำลังบันทึกการเดินป่า (Hike Active)"
              : "เริ่มเดินป่า (Hike Mode)",
          subtitle: isActive
              ? "บันทึกเส้นทางแล้ว.. คลิกเพื่อหยุด"
              : "บันทึกเส้นทางเดินและปักหมุดปากทาง",
          icon: Icons.forest_rounded,
          color: isActive ? Colors.greenAccent : Colors.lightGreenAccent,
          onTap: () async {
            // Capture context-sensitive references BEFORE any await
            // This is the safe way to use BuildContext across async gaps.
            final messenger = ScaffoldMessenger.of(context);
            final offlineService = Provider.of<MapOfflineService>(
              context,
              listen: false,
            );

            if (isActive) {
              hikeService.stopHike();
              messenger.showSnackBar(
                const SnackBar(content: Text("สิ้นสุดการบันทึกการเดินป่า")),
              );
            } else {
              try {
                // Try fast last-known position first
                Position? pos = await Geolocator.getLastKnownPosition();

                // Fallback: try live location with shorter timeout
                if (pos == null) {
                  try {
                    pos = await Geolocator.getCurrentPosition(
                      locationSettings: AndroidSettings(
                        accuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 20),
                        forceLocationManager: true,
                      ),
                    );
                  } catch (_) {
                    pos = null;
                  }
                }

                // Default center if GPS fails (Bangkok)
                final center = pos != null
                    ? LatLng(pos.latitude, pos.longitude)
                    : const LatLng(13.7563, 100.5018);

                if (!context.mounted) return;

                // Use context only synchronously after mounted check.
                // rootContext captured for the navigator push inside the dialog button.
                final rootContext = context;

                // Show Download Progress Dialog
                showDialog(
                  context: rootContext,
                  barrierDismissible: false,
                  builder: (dialogContext) => Consumer<MapOfflineService>(
                    builder: (dialogContext, offlineService, _) {
                      return Dialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "เตรียมความพร้อมการเดินป่า",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "กำลังเตรียมพื้นที่เดินป่า (10 ตร.กม.) และแผนที่ Offline",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 25),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: offlineService.progress,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  color: Colors.greenAccent,
                                  minHeight: 12,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                offlineService.status,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (offlineService.progress >= 1.0)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      hikeService.startHike(center);
                                      await Future.delayed(
                                        const Duration(milliseconds: 350),
                                      );
                                      if (!rootContext.mounted) return;
                                      Navigator.push(
                                        rootContext,
                                        MaterialPageRoute(
                                          builder: (_) => HikeDashboardScreen(
                                            initialPosition: center,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "เริ่มการผจญภัย (โหมดเดินป่า)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        offlineService.cancelDownload();
                                        Navigator.pop(dialogContext);
                                      },
                                      child: Text(
                                        "ยกเลิก",
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );

                // Start download using the pre-captured reference
                await offlineService.downloadAreaTiles(center);
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("ไม่สามารถระบุพิกัดได้")),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSignalCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : Colors.white38, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloodGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "คู่มือเอาตัวรอดน้ำท่วม",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildDetailedGuideTile(
          title: "การเตรียมตัวก่อนน้ำท่วม",
          icon: Icons.inventory_2_rounded,
          color: Colors.blueAccent,
          steps: [
            "เตรียมถังอุปกรณ์ฉุกเฉิน (Go-Bag): อาหารแห้ง, น้ำดื่ม, ยาน้ำสำรอง, ไฟฉาย และแบตสำรอง",
            "ย้ายของมีค่าและอุปกรณ์ไฟฟ้าขึ้นที่สูงที่สุดของบ้าน",
            "ตรวจสอบจุดตัดไฟ (Breaker) และเตรียมปิดเมื่อน้ำเริ่มเข้าบ้าน",
          ],
        ),
        _buildDetailedGuideTile(
          title: "เมื่อเกิดสถานการณ์วิกฤต",
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          steps: [
            "ห้ามเดินหรือขับรถฝ่ากระแสน้ำเชี่ยวเด็ดขาด (น้ำแค่ระดับเข่าก็พัดรถปลิวได้)",
            "หากติดอยู่ในอาคาร ให้ขึ้นไปบนชั้นบนสุดหรือหลังคา และส่งสัญญาณ SOS",
            "ใช้น้ำดื่มที่บรรจุขวดเท่านั้น ห้ามดื่มน้ำท่วมเพราะเสี่ยงเชื้อโรคสูง",
          ],
        ),
      ],
    );
  }

  Widget _buildFireGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "คู่มือเอาตัวรอดจากไฟไหม้",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildDetailedGuideTile(
          title: "เทคนิคการหนีไฟ",
          icon: Icons.smoke_free_rounded,
          color: Colors.orangeAccent,
          steps: [
            "หมอบต่ำและคลาน: อากาศบริสุทธิ์จะอยู่สูงจากพื้นไม่เกิน 1 ฟุต ควันเป็นสาเหตุการตายหลัก",
            "ใช้ผ้าชุบน้ำปิดจมูก: ช่วยกรองฝุ่นควันและความร้อนเบื้องต้น",
            "เช็คประตูก่อนเปิด: ใช้หลังมือแตะบานประตู หากร้อนห้ามเปิดเด็ดขาด!",
          ],
        ),
        _buildDetailedGuideTile(
          title: "หากไฟไหม้เสื้อผ้า",
          icon: Icons.transfer_within_a_station_rounded,
          color: Colors.redAccent,
          steps: [
            "หยุด (Stop): อย่าวิ่ง เพราะจะยิ่งเร่งให้ไฟลุกพรึบ",
            "หมอบ (Drop): ลงไปนอนราบกับพื้นทันที",
            "กลิ้ง (Roll): ตัวไปมาจนกว่าไฟจะดับสนิท",
          ],
        ),
      ],
    );
  }

  Widget _buildEarthquakeGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "คู่มือแผ่นดินไหว",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildDetailedGuideTile(
          title: "กฎเหล็ก หมอบ-ป้อง-เกาะ",
          icon: Icons.vibration_rounded,
          color: Colors.redAccent,
          steps: [
            "หมอบ (Drop): ลงกับพื้นทันทีเพื่อป้องกันการหกล้ม",
            "ป้อง (Cover): หาที่กำบังใต้โต๊ะที่แข็งแรง ป้องหัวและคอ",
            "เกาะ (Hold on): เกาะขาโต๊ะไว้จนกว่าการสั่นสะเทือนจะหยุด",
          ],
        ),
        _buildDetailedGuideTile(
          title: "หลังการสั่นสะเทือน",
          icon: Icons.check_circle_outline_rounded,
          color: Colors.greenAccent,
          steps: [
            "ระวัง Aftershocks: อาจเกิดการสั่นซ้ำได้ตลอดเวลา",
            "ตรวจสอบกลิ่นแก๊ส: หากได้กลิ่นให้รีบเปิดระบายอากาศและหาที่ปลอดภัย",
            "ห้ามใช้ลิฟต์: ให้ใช้บันไดหนีไฟเพื่อลงจากอาคารเท่านั้น",
          ],
        ),
      ],
    );
  }

  Widget _buildLostGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "คู่มือเมื่อหลงทาง/ติดในป่า",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildDetailedGuideTile(
          title: "ตั้งสติด้วยกฎ S.T.O.P",
          icon: Icons.front_hand_rounded,
          color: Colors.redAccent,
          steps: [
            "Sit (นั่ง): นั่งลงสงบสติ อย่าเพิ่งเดินจนกว่าจะรู้ทิศแน่ชัด",
            "Think (คิด): ทบทวนจุดสุดท้ายที่รู้ตัว และทิศทางของดวงอาทิตย์",
            "Observe (สังเกต): หาแหล่งน้ำ พื้นที่เปิดโล่ง หรือร่องรอยเส้นทาง",
          ],
        ),
        _buildDetailedGuideTile(
          title: "การส่งสัญญาณขอความช่วยเหลือ",
          icon: Icons.record_voice_over_rounded,
          color: Colors.blueAccent,
          steps: [
            "สัญญาณควัน: ก่อไฟหรือทำให้เกิดควันในที่โล่ง (สัญลักษณ์สากล)",
            "แสงสะท้อน: ใช้กระจกหรือโลหะเงาๆ สะท้อนแสงแดดเรียกเครื่องบินกู้ภัย",
            "เสียงสัญญาณ: เป่านกหวีดหรือตะโกน 3 ครั้งติดต่อกันเป็นระยะ",
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedGuideTile({
    required String title,
    required List<String> steps,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String category) {
    String tip = "";
    IconData icon = Icons.info_outline;
    Color color = Colors.blueAccent;
    switch (category) {
      case 'flood':
        tip = "ตัดไฟ หาที่สูง และใช้ Nearby Chat ติดต่อคนรอบข้าง";
        icon = Icons.flood_rounded;
        color = Colors.blue;
        break;
      case 'fire':
        tip = "หมอบต่ำเลี่ยงควัน ใช้ไฟฉายและไซเรนเพื่อขอทาง";
        icon = Icons.fire_truck_rounded;
        color = Colors.orange;
        break;
      case 'earthquake':
        tip = "หมอบ ป้อง เกาะ และใช้ไซเรนหากติดอยู่ใต้ซาก";
        icon = Icons.vibration_rounded;
        color = Colors.red;
        break;
      case 'lost':
        tip = "หยุดอยู่กับที่ (STOP) ใช้เข็มทิศและลูกศรนำทาง";
        icon = Icons.explore_rounded;
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final accuracy = _currentPosition?.accuracy ?? 0;
    final color = accuracy < 10
        ? Colors.greenAccent
        : (accuracy < 30 ? Colors.orangeAccent : Colors.redAccent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.gps_fixed_rounded, color: color),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.signalAccuracy,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _isLoading
                          ? "กำลังค้นหา..."
                          : '${accuracy.toStringAsFixed(1)} เมตร',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
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

  Widget _buildCoordinateGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                "ละติจูด",
                _currentPosition?.latitude.toString() ?? '...',
                Icons.location_on_rounded,
                Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueCard(
                "ลองจิจูด",
                _currentPosition?.longitude.toString() ?? '...',
                Icons.location_on_rounded,
                Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildValueCard(
          "ความสูง (MSL)",
          "${_currentPosition?.altitude.toStringAsFixed(1) ?? '...'} เมตร",
          Icons.terrain_rounded,
          Colors.tealAccent,
        ),
      ],
    );
  }

  Widget _buildValueCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassSection() {
    // กำลังโหลด / ตรวจสอบ
    if (_compassSupported == null) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'กำลังเริ่มต้นเข็มทิศ...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // ไม่รองรับหรือปฏิเสธสิทธิ์
    if (_compassSupported == false) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.explore_off_rounded,
              color: Colors.orangeAccent,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เข็มทิศไม่พร้อมใช้งาน',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _compassPermissionDenied
                        ? 'กรุณาเปิดสิทธิ์ตำแหน่ง (Location) ในการตั้งค่าแอปเพื่อใช้เข็มทิศ'
                        : 'อุปกรณ์นี้ไม่มี Magnetometer หรือไม่รองรับเซ็นเซอร์เข็มทิศ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (_compassPermissionDenied) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                      icon: const Icon(
                        Icons.settings_rounded,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      label: const Text(
                        'เปิดการตั้งค่าแอป',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // เข็มทิศพร้อมใช้งาน
    return Center(
      child: Column(
        children: [
          const Text(
            "ทิศทางการมุ่งหน้า",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            '${((_heading ?? 0).round() % 360)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getDirectionLabel(_heading),
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: CompassPainter(),
                  ),
                ),
                const Icon(
                  Icons.navigation_rounded,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurvivalBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDirectionLabel(double? heading) {
    if (heading == null) return "...";
    final double h = (heading % 360 + 360) % 360;

    if (h >= 337.5 || h < 22.5) return "เหนือ (N)";
    if (h >= 22.5 && h < 67.5) return "ตะวันออกเฉียงเหนือ (NE)";
    if (h >= 67.5 && h < 112.5) return "ตะวันออก (E)";
    if (h >= 112.5 && h < 157.5) return "ตะวันออกเฉียงใต้ (SE)";
    if (h >= 157.5 && h < 202.5) return "ใต้ (S)";
    if (h >= 202.5 && h < 247.5) return "ตะวันตกเฉียงใต้ (SW)";
    if (h >= 247.5 && h < 292.5) return "ตะวันตก (W)";
    if (h >= 292.5 && h < 337.5) return "ตะวันตกเฉียงเหนือ (NW)";

    return "เหนือ (N)";
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw cardinal direction letters
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final directions = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};

    for (var angle in directions.keys) {
      final label = directions[angle]!;
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N' ? Colors.redAccent : Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      // Convert angle to radians and adjust so 0 is North (up)
      // CustomPaint normally uses 0 for East (right), so subtract 90 degrees
      final radians = (angle - 90) * math.pi / 180;

      final x =
          center.dx + (radius - 25) * math.cos(radians) - textPainter.width / 2;
      final y =
          center.dy +
          (radius - 25) * math.sin(radians) -
          textPainter.height / 2;

      canvas.save();
      // We don't want the text to rotate with the compass dial,
      // but CompassPainter is already inside a Transform.rotate.
      // Wait, CompassPainter marks are rotated, so if we want letters to stay upright
      // relative to the dial, we just draw them.
      // The current Transform.rotate rotates the WHOLE CustomPaint.
      canvas.drawText(textPainter, Offset(x, y));
      canvas.restore();
    }

    for (var i = 0; i < 360; i += 10) {
      final radians = (i - 90) * math.pi / 180;
      final x1 = center.dx + (radius - 8) * math.cos(radians);
      final y1 = center.dy + (radius - 8) * math.sin(radians);
      final x2 = center.dx + radius * math.cos(radians);
      final y2 = center.dy + radius * math.sin(radians);
      paint.color = (i % 90 == 0) ? Colors.blueAccent : Colors.white24;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension CanvasExtension on Canvas {
  void drawText(TextPainter tp, Offset offset) {
    tp.paint(this, offset);
  }
}

class _WaveAnimation extends StatefulWidget {
  const _WaveAnimation();

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: WavePainter(_controller.value));
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    const int waves = 2;
    final double waveWidth = size.width / waves;
    final double waveHeight = 15.0;

    path.moveTo(-size.width + (progress * size.width), size.height * 0.7);

    for (int i = 0; i < waves * 3; i++) {
      path.relativeQuadraticBezierTo(
        waveWidth / 4,
        -waveHeight,
        waveWidth / 2,
        0,
      );
      path.relativeQuadraticBezierTo(
        waveWidth / 4,
        waveHeight,
        waveWidth / 2,
        0,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a second wave with different color and offset
    final paint2 = Paint()
      ..color = Colors.blue.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(
      -size.width + ((progress + 0.5) % 1.0 * size.width),
      size.height * 0.75,
    );
    for (int i = 0; i < waves * 3; i++) {
      path2.relativeQuadraticBezierTo(
        waveWidth / 4,
        waveHeight,
        waveWidth / 2,
        0,
      );
      path2.relativeQuadraticBezierTo(
        waveWidth / 4,
        -waveHeight,
        waveWidth / 2,
        0,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MeshScanningPing extends StatefulWidget {
  const _MeshScanningPing();

  @override
  State<_MeshScanningPing> createState() => _MeshScanningPingState();
}

class _MeshScanningPingState extends State<_MeshScanningPing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blueAccent.withValues(
                alpha: 1.0 - _controller.value,
              ),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 60 * _controller.value,
              height: 60 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(
                  alpha: (1.0 - _controller.value) * 0.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
