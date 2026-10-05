// ============================================================================
// 🏥 BANTAWAN Floating Facility Card (Mockup-Inspired Quick Detail Overlay)
//
// การ์ดลอยแสดงรายละเอียดสรุปสถานพยาบาลที่เลือกบนแผนที่
// สไตล์ Glassmorphism ตามแบบ Mockup: ไอคอนวงกลม, ชื่อ, ระยะทาง, ป้ายสถานะ 3 รายการ,
// คำอธิบายย่อ และปุ่ม "นำทางทันที / More Details"
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter1/models/medical_facility.dart';
import 'package:flutter1/providers/map_provider.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'package:flutter1/core/utils/medical_facility_classifier.dart';

/// การ์ดลอยแสดงข้อมูลสถานพยาบาลที่เลือกบนแผนที่
class FloatingFacilityCard extends StatelessWidget {
  final MedicalFacility facility;
  final VoidCallback onClose;

  const FloatingFacilityCard({
    super.key,
    required this.facility,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    final refPos = provider.searchCenter;
    final distanceKm = facility.distanceFrom(
      refPos.latitude,
      refPos.longitude,
    );

    final Color accentColor = _getAccentColor(facility.type);
    final IconData icon = _getFacilityIcon(facility.type);
    final bool isOpen = _checkIsOpen(facility);
    final bool isNavigating = provider.routePoints.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131D31).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Avatar + Title + Distance/Status + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${distanceKm.toStringAsFixed(1)} กม.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 3.5,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              color: isOpen
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 7,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen
                                  ? (facility.isOpen24Hours
                                      ? 'เปิด 24 ชม.'
                                      : 'เปิดทำการ')
                                  : 'ปิดทำการ',
                              style: TextStyle(
                                color: isOpen
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Mockup-Inspired Metric Pills Row (3 Items)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPill(
                      icon: facility.hasEmergency
                          ? Icons.local_hospital_rounded
                          : Icons.verified_user_rounded,
                      label: facility.hasEmergency
                          ? 'แผนกฉุกเฉิน (ER)'
                          : 'รักษาทั่วไป',
                      accentColor: facility.hasEmergency
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      icon: Icons.access_time_filled_rounded,
                      label: facility.isOpen24Hours
                          ? 'เปิดตลอด 24 ชม.'
                          : (facility.openingHours ?? 'เวลาทำการปกติ'),
                      accentColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      icon: Icons.phone_rounded,
                      label: facility.phone.isNotEmpty
                          ? facility.phone
                          : 'สายด่วน 1669',
                      accentColor: Colors.amberAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Short Address / Description
              if (facility.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    facility.address,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // 4. Action Buttons (Primary Full-Width "More Details" / "นำทาง")
              Row(
                children: [
                  // Call button (if phone available)
                  if (facility.phone.isNotEmpty) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => CallService.makeCall(facility.phone),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Navigate Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isNavigating) {
                          provider.clearRoute();
                        } else {
                          provider.getRouteTo(facility);
                        }
                      },
                      icon: Icon(
                        isNavigating
                            ? Icons.close_rounded
                            : Icons.navigation_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        isNavigating ? 'ยกเลิกนำทาง' : 'เริ่มนำทางทันที',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNavigating
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // "เปิดด้วย Google Maps" button
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: () => _openInGoogleMaps(facility),
                      icon: const Icon(
                        Icons.map_rounded,
                        size: 16,
                        color: Color(0xFF38BDF8),
                      ),
                      label: const Text(
                        'Google Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(MedicalFacility facility) async {
    final lat = facility.latitude;
    final lon = facility.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open Google Maps: $e');
    }
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Color _getAccentColor(String type) {
    switch (type) {
      case 'hospital':
        return const Color(0xFFEF4444);
      case 'pharmacy':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  static IconData _getFacilityIcon(String type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'pharmacy':
        return Icons.medication_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  static bool _checkIsOpen(MedicalFacility facility) {
    return MedicalFacilityClassifier.isFacilityOpen(facility);
  }
}
