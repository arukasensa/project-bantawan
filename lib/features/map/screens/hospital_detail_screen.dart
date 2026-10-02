// ============================================================================
// 🏥 BANTAWAN Medical Facility Detail Screen: HospitalDetailScreen
// 
// หน้าจอแสดงข้อมูลสถานพยาบาลเชิงลึก (Hospital Detail Screen)
// แสดงข้อมูลติดต่อ, เบอร์ฉุกเฉิน, สถานะเปิดทำการ 24 ชม., แผนกการรักษา,
// สิทธิการรักษาพยาบาล และปุ่มนำทาง GPS ลากเส้นทาง
// ============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter1/models/medical_facility.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'dart:ui';

/// 🏥 หน้าจอแสดงรายละเอียดเชิงลึกของสถานพยาบาล (Hospital Detail Screen)
class HospitalDetailScreen extends StatelessWidget {
  /// ข้อมูลสถานพยาบาลเป้าหมาย
  final MedicalFacility facility;

  /// ระยะทางห่างจากตำแหน่งปัจจุบันของผู้ใช้ (กิโลเมตร)
  final double? distance;

  HospitalDetailScreen({super.key, required this.facility, this.distance});

  // --- Hybrid Data Mockup (ส่วนเสริมเพื่อความสมบูรณ์) ---
  final List<String> _mockGallery = [
    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1587351021759-3e566b9af9ef?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&q=80&w=800',
  ];

  final List<Map<String, dynamic>> _mockDepartments = [
    {
      'name': 'แผนกฉุกเฉิน (ER)',
      'status': 'Open 24/7',
      'wait': 'Immediate',
      'color': Colors.redAccent,
    },
    {
      'name': 'อายุรกรรม (Internal Med)',
      'status': '08:00 - 20:00',
      'wait': '15 min',
      'color': Colors.blueAccent,
    },
    {
      'name': 'ศัลยกรรม (Surgery)',
      'status': '08:00 - 16:00',
      'wait': 'Appointment',
      'color': Colors.teal,
    },
    {
      'name': 'กุมารเวช (Pediatrics)',
      'status': '08:00 - 20:00',
      'wait': '10 min',
      'color': Colors.orangeAccent,
    },
  ];

  final List<Map<String, dynamic>> _mockFacilities = [
    {'name': 'Parking', 'icon': Icons.local_parking_rounded},
    {'name': '24/7 ATM', 'icon': Icons.atm_rounded},
    {'name': 'Cafeteria', 'icon': Icons.coffee_rounded},
    {'name': 'Free Wi-Fi', 'icon': Icons.wifi_rounded},
    {'name': 'Pharmacy', 'icon': Icons.local_pharmacy_rounded},
    {'name': 'Wheelchair', 'icon': Icons.accessible_rounded},
  ];

  // -----------------------------------------------------

  Future<void> _makeCall(String phone) async {
    await CallService.makeCall(phone);
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    if (!urlString.startsWith('http')) {
      urlString = 'https://$urlString';
    }
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMap() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${facility.latitude},${facility.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showNotifyERDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotifySheet(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHospital = facility.type == 'hospital';
    final themeColor = isHospital
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F0F23),
                    Color(0xFF16213E),
                    Color(0xFF050510),
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, themeColor, isHospital),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Critical Actions Row
                      _buildMainActions(context, themeColor),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'GALLERY',
                        Icons.photo_library_rounded,
                      ),
                      _buildGallery(),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'CORE INFORMATION',
                        Icons.info_outline_rounded,
                      ),
                      _buildInfoCard(context, themeColor),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'DEPARTMENTS (Live Status)',
                        Icons.monitor_heart_rounded,
                      ),
                      _buildDepartmentsList(),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'FACILITIES',
                        Icons.check_circle_outline_rounded,
                      ),
                      _buildFacilitiesGrid(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Notify ER Floating Button
          if (facility.hasEmergency || isHospital)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildNotifyERButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    Color color,
    bool isHospital,
  ) {
    return SliverAppBar(
      expandedHeight: 250,
      backgroundColor: Colors.transparent,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            Image.network(
              _mockGallery[0],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: color.withValues(alpha: 0.2)),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    const Color(0xFF0F0F23),
                  ],
                ),
              ),
            ),
            // Title Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isHospital ? 'HOSPITAL' : 'CLINIC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    facility.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (distance != null) ...[
                        const Icon(
                          Icons.near_me_rounded,
                          color: Colors.blueAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance!.toStringAsFixed(1)} KM Away',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (facility.isOpen24Hours)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OPEN 24H',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions(BuildContext context, Color themeColor) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Navigate',
            Icons.directions_rounded,
            Colors.blueAccent,
            _launchMap,
          ),
        ),
        if (facility.phone.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Call Now',
              Icons.phone_in_talk_rounded,
              Colors.greenAccent,
              () => _makeCall(facility.phone),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _mockGallery.length,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: NetworkImage(_mockGallery[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Color themeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.location_on_outlined, facility.address),
              const Divider(color: Colors.white10),
              if (facility.operator != null) ...[
                _buildInfoRow(
                  Icons.business_rounded,
                  'Operator: ${facility.operator}',
                ),
                const Divider(color: Colors.white10),
              ],
              if (facility.website != null)
                _buildInfoRow(
                  Icons.language_rounded,
                  facility.website ?? 'No Website',
                  onTap: () => _launchUrl(facility.website ?? ''),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null
                      ? Colors.blueAccent
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.open_in_new_rounded,
                color: Colors.blueAccent,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsList() {
    return Column(
      children: _mockDepartments.map((dept) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: dept['color'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dept['status'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Wait Time',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  Text(
                    dept['wait'],
                    style: TextStyle(
                      color: dept['wait'] == 'Immediate'
                          ? Colors.greenAccent
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFacilitiesGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _mockFacilities.map((fac) {
        return Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(fac['icon'], color: Colors.white70, size: 24),
              const SizedBox(height: 8),
              Text(
                fac['name'],
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotifyERButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNotifyERDialog(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFFF5252)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'NOTIFY ER - I\'M COMING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifySheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notify Emergency Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sending an advance alert helps the hospital prepare for your arrival. This is a simulation.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 30),
          _buildActionButton(
            'SEND ALERT NOW',
            Icons.send_rounded,
            const Color(0xFFE53935),
            () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.greenAccent,
                  content: const Text(
                    'Alert Sent! Hospital is preparing for your arrival.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
