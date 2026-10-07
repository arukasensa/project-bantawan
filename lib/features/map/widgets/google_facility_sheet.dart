// ============================================================================
// 🏥 BANTAWAN Medical Facility Detail BottomSheet: GoogleFacilitySheet
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │                  GoogleFacilitySheet                    │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Draggable Sheet HUD │    Distance & Travel Est. │  │
// │  │  (Snap 0.15 - 0.85)   │  (Haversine / Route Dist) │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Emergency Call (1669)│    Route Guidance & Audio │  │
// │  │  (CallService Direct) │ (Polyline Draw & StartNav)│  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// แถบเลื่อนแสดงรายละเอียดสถานที่ (Facility Details BottomSheet)
// Draggable BottomSheet สไตล์โมเดิร์น กระจกฝ้า (Glassmorphism)
// แสดงข้อมูลสถานพยาบาล เบอร์โทร เวลาเปิด-ปิด ปุ่มนำทาง และปุ่มโทรออกฉุกเฉิน
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter1/providers/map_provider.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';

/// 🏥 วิดเจ็ต BottomSheet แสดงรายละเอียดของสถานพยาบาลที่เลือก (Facility Details BottomSheet)
class GoogleFacilitySheet extends StatelessWidget {
  final VoidCallback? onTranslate;

  const GoogleFacilitySheet({super.key, this.onTranslate});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    final facility = provider.selectedFacility;

    if (facility == null) return const SizedBox.shrink();

    final hasActiveRoute = provider.routePoints.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              // Stack แยกส่วน header คงที่ออกจาก ListView ที่เลื่อนได้
              child: Stack(
                children: [
                  // เนื้อหาที่เลื่อนได้
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // Drag Handle indicator
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),

                      // Title, Type (ไม่มี close button แล้ว — ย้ายไป Stack)
                      Padding(
                        padding: const EdgeInsets.only(right: 40), // เว้นพื้นที่ให้ปุ่ม X
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (facility.type == 'hospital'
                                            ? Colors.redAccent
                                            : Colors.greenAccent)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (facility.type == 'hospital'
                                              ? Colors.redAccent
                                              : Colors.greenAccent)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    facility.type.toUpperCase(),
                                    style: TextStyle(
                                      color: facility.type == 'hospital'
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (facility.isOpen24Hours)
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Colors.greenAccent,
                                        size: 6,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'เปิด 24 ชั่วโมง',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Modern Pill Action Bar (Navigate, Call, Stop)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            // Navigate Button
                            _buildPillAction(
                              icon: Icons.directions_rounded,
                              label: hasActiveRoute ? 'กำลังนำทาง' : 'นำทาง',
                              bgColor: hasActiveRoute
                                  ? Colors.blueAccent
                                  : Colors.blueAccent.withValues(alpha: 0.15),
                              textColor: Colors.white,
                              iconColor: Colors.white,
                              borderColor: Colors.blueAccent.withValues(alpha: 0.5),
                              onTap: () {
                                provider.getRouteTo(facility);
                                provider.setFollowMode('headingUp');
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildPillAction(
                              icon: Icons.call_rounded,
                              label: 'โทรออก',
                              bgColor: Colors.greenAccent.withValues(alpha: 0.15),
                              textColor: Colors.greenAccent,
                              iconColor: Colors.greenAccent,
                              borderColor: Colors.greenAccent.withValues(alpha: 0.3),
                              onTap: () {
                                if (facility.phone.isNotEmpty) {
                                  CallService.makeCall(facility.phone);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ไม่มีเบอร์โทรศัพท์ติดต่อสำหรับสถานที่นี้'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildPillAction(
                              icon: Icons.map_rounded,
                              label: 'Google Maps',
                              bgColor: Colors.redAccent.withValues(alpha: 0.15),
                              textColor: const Color(0xFFFF6B6B),
                              iconColor: const Color(0xFFFF6B6B),
                              borderColor: Colors.redAccent.withValues(alpha: 0.3),
                              onTap: () => _openGoogleMaps(
                                context,
                                facility.latitude,
                                facility.longitude,
                              ),
                            ),
                            if (hasActiveRoute) ...[
                              const SizedBox(width: 10),
                              _buildPillAction(
                                icon: Icons.navigation_rounded,
                                label: 'สิ้นสุดนำทาง',
                                bgColor: Colors.redAccent.withValues(alpha: 0.15),
                                textColor: Colors.redAccent,
                                iconColor: Colors.redAccent,
                                borderColor: Colors.redAccent.withValues(alpha: 0.3),
                                onTap: () {
                                  provider.clearRoute();
                                  provider.selectFacility(null);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 40),
                      _buildInfoRow(
                        Icons.location_on_rounded,
                        facility.address,
                        Colors.blueAccent,
                      ),
                      _buildInfoRow(
                        Icons.near_me_rounded,
                        'ระยะทางจากพิกัดคุณ: ${facility.distanceFrom(provider.currentPosition.latitude, provider.currentPosition.longitude).toStringAsFixed(1)} กม.',
                        Colors.orangeAccent,
                      ),
                      if (facility.phone.isNotEmpty)
                        _buildInfoRow(
                          Icons.phone_rounded,
                          'ติดต่อ: ${facility.phone}',
                          Colors.greenAccent,
                        ),
                      if (facility.openingHours != null && facility.openingHours!.isNotEmpty)
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          'เวลาทำการ: ${facility.openingHours}',
                          Colors.amberAccent,
                        ),
                      if (facility.website != null && facility.website!.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(facility.website!);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: _buildInfoRow(
                            Icons.language_rounded,
                            'เว็บไซต์: ${facility.website} (แตะเพื่อเปิด)',
                            Colors.cyanAccent,
                          ),
                        ),
                      if (facility.wheelchair != null && facility.wheelchair!.isNotEmpty)
                        _buildInfoRow(
                          Icons.wheelchair_pickup_rounded,
                          'การรองรับวีลแชร์: ${facility.wheelchair == 'yes' ? 'รองรับ' : 'ไม่ระบุ/ไม่รองรับ'}',
                          Colors.purpleAccent,
                        ),
                      if (facility.description != null && facility.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Text(
                            facility.description!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),

                  // ปุ่ม X คงที่ที่มุมบนขวา (ไม่เลื่อนตามเนื้อหา)
                  // กดแล้วแค่ซ่อน sheet — ไม่ยกเลิก facility/เส้นทาง
                  Positioned(
                    top: 12,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => provider.setShowDetails(false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
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

  Widget _buildPillAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: bgColor == Colors.blueAccent
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเปิด Google Maps ได้'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
