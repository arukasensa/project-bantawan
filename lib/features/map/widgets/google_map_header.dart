// ============================================================================
// 🔍 BANTAWAN Map Floating Search Bar Header: GoogleMapHeader
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Tactical GIS Map & Medical POIs)            │
// ├─────────────────────────────────────────────────────────┤
// │                  GoogleMapHeader                        │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │  Search Text Field    │    Clear / Loading State  │  │
// │  │  (POI Keyword Query)  │ (Active Spinner / Clear)  │  │
// │  ├───────────────────────┼───────────────────────────┤  │
// │  │  Back Navigation      │   Frosted Glass UI        │  │
// │  │  (Pop Navigation)     │ (Dark Translucent Capsule)│  │
// │  └───────────────────────┴───────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// ส่วนหัวค้นหาพิกัดและสถานที่บนแผนที่ (Map Search Header)
// ช่องค้นหาแบบลอยด้านบน (Floating Search Bar) พร้อมปุ่มย้อนกลับและสถานะการค้นหา
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter1/providers/map_provider.dart';

/// 🔍 วิดเจ็ตแถบค้นหาสถานที่ด้านบนของหน้าจอแผนที่ (Floating Search Bar Header)
class GoogleMapHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onBack;

  const GoogleMapHeader({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    return Column(
      children: [
        // Search Bar Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: onSearch,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาโรงพยาบาล/ร้านยา...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {
                        searchController.clear();
                        provider.handleSearch('');
                      },
                    );
                  },
                ),
                _buildSearchButton(),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () => onSearch(searchController.text),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
        ),
        child: const Icon(
          Icons.search_rounded,
          color: Colors.blueAccent,
          size: 20,
        ),
      ),
    );
  }
}
