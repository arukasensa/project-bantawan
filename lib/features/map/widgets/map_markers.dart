// ============================================================================
// 📍 BANTAWAN Tactical Map Facility Marker Builder: TacticalFacilityMarker
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │               TacticalFacilityMarker                    │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Medical Classification│     Glow Aura Animation   │  │
// │  │  (Hospital/Clinic/Phar)│  (Active Selection Halo)  │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Color-Coded Badges   │     FlutterMap Marker     │  │
// │  │  (Red / Cyan / Green) │  (Custom Layer Component) │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// ตัวสร้างหมุดสถานพยาบาลบนแผนที่ (Map Markers Builder)
// สร้างหมุด FlutterMap Marker แบบ Tactical มีแสงเรืองรอง (Glow) เมื่อถูกเลือก
// แยกสีและไอคอนตามประเภท (โรงพยาบาล: แดง, คลินิก: ฟ้า, ร้านขายยา: เขียว)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter1/models/medical_facility.dart';
import 'package:flutter1/core/utils/medical_facility_classifier.dart';

/// 📍 คลาสตัวช่วยสร้างหมุดระบุพิกัดสถานพยาบาลบนแผนที่ (Tactical Marker Builder)
class TacticalFacilityMarker {
  /// 🎯 สร้างคอมโพเนนต์ Marker สำหรับวางบน FlutterMap Layer พร้อมเอฟเฟกต์ Glow และป้ายกำกับ
  static Marker build({
    required MedicalFacility facility,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final Color color = _getFacilityColor(facility);
    final IconData icon = _getFacilityIcon(facility);
    final String pillText = _getPillText(facility);

    return Marker(
      point: LatLng(facility.latitude, facility.longitude),
      width: isSelected ? 120 : 88,
      height: isSelected ? 110 : 80,
      alignment: Alignment.center,
      rotate: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Circular Pin
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected) _buildGlow(color),
                  Container(
                    width: isSelected ? 44 : 38,
                    height: isSelected ? 44 : 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white,
                        width: isSelected ? 2.5 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? const Color(0xFF10B981) : color)
                              .withValues(alpha: isSelected ? 0.6 : 0.35),
                          blurRadius: isSelected ? 14 : 8,
                          spreadRadius: isSelected ? 2 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: isSelected ? 32 : 28,
                        height: isSelected ? 32 : 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isSelected ? 18 : 16,
                        ),
                      ),
                    ),
                  ),

                  // Status Indicator Pip (Top Right)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _isOpen(facility)
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: (_isOpen(facility)
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              // 2. Mockup-Style Capsule Pill Badge Underneath
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPillIcon(facility),
                      color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      pillText,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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

  static String _getPillText(MedicalFacility facility) {
    if (facility.isOpen24Hours) return '24 ชม.';
    if (facility.hasEmergency) return 'ฉุกเฉิน';
    if (facility.type == 'hospital') return 'รพ.';
    if (facility.type == 'pharmacy') return 'ร้านยา';
    return 'คลินิก';
  }

  static IconData _getPillIcon(MedicalFacility facility) {
    if (facility.isOpen24Hours) return Icons.access_time_filled_rounded;
    if (facility.hasEmergency) return Icons.local_hospital_rounded;
    if (facility.type == 'hospital') return Icons.local_hospital_rounded;
    if (facility.type == 'pharmacy') return Icons.medication_rounded;
    return Icons.health_and_safety_rounded;
  }

  static Color _getFacilityColor(MedicalFacility facility) {
    switch (facility.type) {
      case 'hospital':
        return const Color(0xFFEF4444); // Red/Rose
      case 'pharmacy':
        return const Color(0xFF10B981); // Emerald green
      default:
        return const Color(0xFF0EA5E9); // Sky blue
    }
  }

  static IconData _getFacilityIcon(MedicalFacility facility) {
    switch (facility.type) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'pharmacy':
        return Icons.medication_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  static bool _isOpen(MedicalFacility facility) {
    return MedicalFacilityClassifier.isFacilityOpen(facility);
  }

  static Widget _buildGlow(Color color) {
    return PulsingGlow(color: color);
  }
}

class PulsingGlow extends StatefulWidget {
  final Color color;
  const PulsingGlow({super.key, required this.color});

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 30 + (40 * _animation.value),
          height: 30 + (40 * _animation.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3 * (1 - _animation.value)),
          ),
        );
      },
    );
  }
}
