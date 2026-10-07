// ============================================================================
// 🛣️ BANTAWAN Turn-by-Turn Routing Panel: RoutingInstructionsPanel
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │               RoutingInstructionsPanel                  │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Turn-by-Turn Steps   │    Maneuver Icon Mapper   │  │
// │  │  (OSRM / Longdo Path) │ (Turn Left/Right/Straight)│  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Step Distance Meters │   Dismiss Navigation Bar  │  │
// │  │  (Segment Distance)   │ (Close Step-by-Step HUD)  │  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// แผงแสดงขั้นตอนการเลี้ยวนำทาง (Turn-by-Turn Routing Panel)
// กล่องลอยแสดงรายการขั้นตอนการเลี้ยว ระยะทาง และเวลาเดินทางอย่างละเอียด
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter1/providers/map_provider.dart';

/// 🛣️ วิดเจ็ตแผงแสดงขั้นตอนการนำทางแบบเลี้ยวต่อเลี้ยว (Turn-by-Turn Routing Panel)
class RoutingInstructionsPanel extends StatelessWidget {
  const RoutingInstructionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);
    final instructions = provider.routeInstructions;

    if (instructions.isEmpty || provider.selectedFacility == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 20,
      bottom: 100,
      width: 320,
      child: Column(
        children: [
          // Header
          _buildHeader(context, provider),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: instructions.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      indent: 60,
                    ),
                    itemBuilder: (context, index) {
                      final step = instructions[index];
                      final maneuver = step['maneuver'] as Map<String, dynamic>;
                      final instruction = maneuver['instruction'] ?? 'ขับตรงไป';
                      final distance = step['distance'] ?? 0;
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getDirectionIcon(maneuver['type'], maneuver['modifier']),
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${(distance as num).toStringAsFixed(0)} เมตร',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MapProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ไปยัง ${provider.selectedFacility?.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${provider.eta} • ${provider.routeDistance?.toStringAsFixed(1)} กม.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => provider.selectFacility(null),
                child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDirectionIcon(String? type, String? modifier) {
    if (type == 'turn') {
      if (modifier?.contains('left') ?? false) return Icons.turn_left_rounded;
      if (modifier?.contains('right') ?? false) return Icons.turn_right_rounded;
    }
    if (type == 'depart') return Icons.play_arrow_rounded;
    if (type == 'arrive') return Icons.location_on_rounded;
    return Icons.arrow_upward_rounded;
  }
}
