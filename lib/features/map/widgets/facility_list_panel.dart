// ============================================================================
// 🏥 BANTAWAN Facility List Panel (Left Side Panel / Collapsible Drawer)
//
// ถอดแบบดีไซน์จาก Mockup แผงควบคุมฝั่งซ้าย:
// - Header พร้อมปุ่มย้อนกลับ, โลโก้/ชื่อ BANTAWAN MEDICAL และปุ่ม Info
// - แถบค้นหาพร้อมไอคอนแว่นขยาย
// - ตัวกรอง: "Show me: เปิดอยู่ตอนนี้", "Sort by: ใกล้ที่สุด", ชิปประเภท (รพ./คลินิก/ร้านยา)
// - รายชื่อสถานพยาบาลพร้อมไอคอนวงกลม, ระยะห่าง, เวลาเปิด-ปิด, และเส้นขอบเรืองแสงเมื่อถูกเลือก
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter1/models/medical_facility.dart';
import 'package:flutter1/providers/map_provider.dart';

/// แผงแสดงรายชื่อสถานพยาบาลและการค้นหาแบบครบวงจร
class FacilityListPanel extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final Function(MedicalFacility) onSelectFacility;
  final VoidCallback? onBack;

  const FacilityListPanel({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onSelectFacility,
    this.onBack,
  });

  @override
  State<FacilityListPanel> createState() => _FacilityListPanelState();
}

class _FacilityListPanelState extends State<FacilityListPanel> {
  bool _onlyOpenNow = false;
  String _sortBy = 'nearest'; // 'nearest' or 'name'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context);

    // Filter & Sort facilities locally for real-time responsiveness
    List<MedicalFacility> displayedList = List.from(provider.facilities);

    // 1. Text Search Filter
    final query = widget.searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      displayedList = displayedList.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query) ||
            f.type.toLowerCase().contains(query);
      }).toList();
    }

    // 2. "Show me: Open Now" Filter
    if (_onlyOpenNow) {
      displayedList = displayedList.where((f) => _checkIsOpen(f)).toList();
    }

    // 3. Sort Filter
    if (_sortBy == 'nearest') {
      displayedList.sort((a, b) {
        final distA = a.distanceFrom(
          provider.searchCenter.latitude,
          provider.searchCenter.longitude,
        );
        final distB = b.distanceFrom(
          provider.searchCenter.latitude,
          provider.searchCenter.longitude,
        );
        return distA.compareTo(distB);
      });
    } else {
      displayedList.sort((a, b) => a.name.compareTo(b.name));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Header Row (Back button + Title + Info button)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                if (widget.onBack != null) ...[
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],

                // App Brand Badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BANTAWAN MED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'พิกัดสถานพยาบาลรอบตัว',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Info / Offline Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${displayedList.length} แห่ง',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      onChanged: (val) => setState(() {}),
                      onSubmitted: widget.onSearch,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาโรงพยาบาล, คลินิก, ร้านยา...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (widget.searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () {
                        widget.searchController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Dropdowns & Filter Controls Row (Mockup: "Show me: Open Now", "Sort by: Nearest")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // "Show me: Open Now" toggle button
                InkWell(
                  onTap: () {
                    setState(() {
                      _onlyOpenNow = !_onlyOpenNow;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _onlyOpenNow
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _onlyOpenNow
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'เปิดอยู่ตอนนี้',
                          style: TextStyle(
                            color: _onlyOpenNow
                                ? const Color(0xFF10B981)
                                : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _onlyOpenNow ? Icons.check_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _onlyOpenNow
                              ? const Color(0xFF10B981)
                              : Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // "Sort by: Nearest" button
                InkWell(
                  onTap: () {
                    setState(() {
                      _sortBy = (_sortBy == 'nearest') ? 'name' : 'nearest';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sortBy == 'nearest' ? 'ใกล้ที่สุด' : 'ตามชื่อ A-Z',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 14,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. Quick Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('ทั้งหมด', 'all', provider),
                const SizedBox(width: 6),
                _buildCategoryChip('🏥 รพ.', 'hospital', provider),
                const SizedBox(width: 6),
                _buildCategoryChip('🩺 คลินิก', 'clinic', provider),
                const SizedBox(width: 6),
                _buildCategoryChip('💊 ร้านยา', 'pharmacy', provider),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),

          // 5. Scrollable Facility List
          Expanded(
            child: displayedList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ไม่พบสถานพยาบาลตามตัวกรอง',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    itemCount: displayedList.length,
                    itemBuilder: (context, index) {
                      final item = displayedList[index];
                      final isSelected =
                          provider.selectedFacility?.id == item.id;
                      final distance = item.distanceFrom(
                        provider.searchCenter.latitude,
                        provider.searchCenter.longitude,
                      );
                      final Color accentColor = _getAccentColor(item.type);
                      final bool isOpen = _checkIsOpen(item);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onSelectFacility(item),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF131D31)
                                    : const Color(0xFF1E293B).withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF10B981) // Glowing neon green border like Adidas in mockup
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Circular Facility Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.5),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getFacilityIcon(item.type),
                                        color: accentColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              '${distance.toStringAsFixed(1)} กม.',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                              ),
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white38,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Text(
                                              isOpen
                                                  ? (item.isOpen24Hours
                                                      ? 'เปิด 24 ชม.'
                                                      : 'เปิดทำการ')
                                                  : 'ปิดทำการ',
                                              style: TextStyle(
                                                color: isOpen
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right side Badges (Verified & ER Status)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : Colors.white38,
                                        size: 16,
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.hasEmergency)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFEF4444)
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'ER 24h',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, MapProvider provider) {
    final bool isSelected = provider.selectedFilter == value;
    return InkWell(
      onTap: () => provider.setFilter(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
    if (facility.isOpen24Hours) return true;
    if (facility.openingHours == null) return true;
    final lower = facility.openingHours!.toLowerCase();
    return lower.contains('open') || lower.contains('24');
  }
}
