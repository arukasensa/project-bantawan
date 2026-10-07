// ============================================================================
// 🧭 BANTAWAN Floating Map Controls Bar: MapControls
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │                     MapControls                         │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Layer Switcher       │    Follow GPS Mode        │  │
// │  │  (OSM Standard / Sat) │  (Active Target Centering)│  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Hike Tracker Toggle  │   Category Filter Quick   │  │
// │  │  (Breadcrumb Service) │ (All / Hospital / Clinic) │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// แถบปุ่มลอยควบคุมแผนที่ (Map Floating Controls Bar)
// รวมปุ่มสลับเลเยอร์แผนที่ (Layers), ปุ่มตามตำแหน่งฉัน (Follow GPS),
// ปุ่มบันทึกการเดินป่า (Hike Tracker), และปุ่มลัดตัวกรองสถานที่
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter1/providers/map_provider.dart';
import 'package:flutter1/features/survival/services/hike_service.dart';

/// 🧭 วิดเจ็ตแถบเครื่องมือควบคุมแผนที่ด้านข้าง (Floating Map Controls Bar)
class MapControls extends StatelessWidget {
  final VoidCallback onToggleLayer;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleHike;

  const MapControls({
    super.key,
    required this.onToggleLayer,
    required this.onToggleFollow,
    required this.onToggleHike,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return _buildVerticalBar([
      _buildControlItem(
        icon: Icons.layers_rounded,
        onTap: onToggleLayer,
        label: 'แผนที่',
      ),
      _buildControlItem(
        icon: provider.followMode != 'none'
            ? Icons.gps_fixed_rounded
            : Icons.gps_not_fixed_rounded,
        onTap: onToggleFollow,
        label: 'ใกล้ฉัน',
        isActive: provider.followMode != 'none',
      ),
      const Divider(color: Colors.white10, height: 16, indent: 8, endIndent: 8),

      // Category Filters
      _buildControlItem(
        icon: Icons.medical_services_rounded,
        onTap: () => provider.setFilter('all'),
        label: 'ทั้งหมด',
        isActive: provider.selectedFilter == 'all',
      ),
      _buildControlItem(
        icon: Icons.local_hospital_rounded,
        onTap: () => provider.setFilter('hospital'),
        label: 'รพ.',
        isActive: provider.selectedFilter == 'hospital',
      ),
      _buildControlItem(
        icon: Icons.medication_rounded,
        onTap: () => provider.setFilter('clinic'),
        label: 'คลินิก',
        isActive: provider.selectedFilter == 'clinic',
      ),
      _buildControlItem(
        icon: Icons.local_pharmacy_rounded,
        onTap: () => provider.setFilter('pharmacy'),
        label: 'ร้านยา',
        isActive: provider.selectedFilter == 'pharmacy',
      ),

      const Divider(color: Colors.white10, height: 16, indent: 8, endIndent: 8),

      _buildControlItem(
        icon: Icons.refresh_rounded,
        onTap: () => provider.loadFacilities(forceRefresh: true),
        label: 'โหลด',
        isActive: provider.isLoading,
        isSpinning: provider.isLoading,
      ),
      _buildControlItem(
        icon: Icons.hiking_rounded,
        onTap: onToggleHike,
        label: 'เดินป่า',
        isActive: Provider.of<HikeService>(context).isHikeActive,
      ),
    ]);
  }

  Widget _buildVerticalBar(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    bool isActive = false,
    bool isSpinning = false,
    Color? activeColor,
  }) {
    final Color highlightColor = activeColor ?? Colors.blueAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? highlightColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isSpinning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: highlightColor,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isActive ? highlightColor : Colors.white70,
                      size: 20,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? highlightColor : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
