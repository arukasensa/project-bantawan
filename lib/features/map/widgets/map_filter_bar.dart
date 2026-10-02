// แถบชิปเลือกตัวกรองรัศมีค้นหา (Map Radius Filter Bar)
// แถบแนวนอนเลื่อนได้สำหรับเลือกขนาดรัศมีการค้นหาสถานที่ (10, 20, 50, 100 กม.)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter1/providers/map_provider.dart';

/// วิดเจ็ตแถบตัวเลือกขนาดรัศมีค้นหาบนแผนที่
class MapFilterBar extends StatelessWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildChip('10 กม.', '10', provider, true),
            _buildChip('20 กม.', '20', provider, true),
            _buildChip('50 กม.', '50', provider, true),
            _buildChip('100 กม.', '100', provider, true),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    String value,
    MapProvider provider,
    bool isRadius,
  ) {
    final bool isSelected = isRadius
        ? provider.searchRadius == double.parse(value)
        : provider.selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          if (isRadius) {
            provider.setSearchRadius(double.parse(value));
          } else {
            provider.setFilter(value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent
                : const Color(0xFF1E293B).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
