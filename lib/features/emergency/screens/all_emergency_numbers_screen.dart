// ============================================================================
// ☎️ BANTAWAN National Emergency Hotline Directory: AllEmergencyNumbersScreen
// 
// หน้าจอรวมเบอร์สายด่วนฉุกเฉินระดับประเทศ (All Emergency Hotline Directory)
// รวบรวมเบอร์ติดต่อฉุกเฉินทุกหมวดหมู่ (การแพทย์ กู้ภัย ตำรวจ ทางหลวง ดับเพลิง สาธารณูปโภค)
// พร้อมระบบค้นหาคำด้วยคีย์เวิร์ด และกดโทรออกได้ทันทีผ่าน CallService
// ============================================================================

import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'dart:ui';

/// ☎️ หน้าจอแสดงรายชื่อและเบอร์โทรสายด่วนฉุกเฉินทั้งหมด (National Emergency Numbers)
class AllEmergencyNumbersScreen extends StatefulWidget {
  const AllEmergencyNumbersScreen({super.key});

  @override
  State<AllEmergencyNumbersScreen> createState() =>
      _AllEmergencyNumbersScreenState();
}

/// 🔍 State ควบคุมช่องค้นหาคำคีย์เวิร์ด และการกรองรายชื่อเบอร์โทรฉุกเฉิน
class _AllEmergencyNumbersScreenState extends State<AllEmergencyNumbersScreen> {
  /// ตัวควบคุมช่องค้นหาเบอร์หรือชื่อหน่วยงาน
  final TextEditingController _searchController = TextEditingController();

  /// คำค้นหาปัจจุบัน
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'การแพทย์ & กู้ภัย',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFE53935),
      'numbers': [
        {'name': 'สถาบันการแพทย์ฉุกเฉินแห่งชาติ', 'number': '1669'},
        {'name': 'ศูนย์นเรนทร (กทม.)', 'number': '1646'},
        {'name': 'มูลนิธิวชิรพยาบาล', 'number': '1554'},
        {'name': 'หน่วยแพทย์ฉุกเฉิน (กรมการแพทย์)', 'number': '1154'},
        {'name': 'สายด่วนกู้ภัย (บรรเทาสาธารณภัย)', 'number': '1784'},
        {'name': 'ศูนย์ส่งกลับ รพ.ตำรวจ', 'number': '1691'},
      ],
    },
    {
      'title': 'ความปลอดภัย & ตำรวจ',
      'icon': Icons.local_police_rounded,
      'color': Color(0xFF1E88E5),
      'numbers': [
        {'name': 'เหตุด่วนเหตุร้าย (ตำรวจ)', 'number': '191'},
        {'name': 'ตำรวจท่องเที่ยว', 'number': '1155'},
        {'name': 'ตำรวจทางหลวง', 'number': '1193'},
        {'name': 'กรมทางหลวงชนบท', 'number': '1146'},
        {'name': 'แจ้งรถถูกโจรกรรม', 'number': '1192'},
        {'name': 'กองปราบปราม', 'number': '1195'},
        {'name': 'ศูนย์รับแจ้งการตกค้าง (ตม.)', 'number': '1178'},
      ],
    },
    {
      'title': 'เหตุฉุกเฉินอื่นๆ',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFFF6F00),
      'numbers': [
        {'name': 'ดับเพลิง / สัตว์มีพิษเข้าบ้าน', 'number': '199'},
        {'name': 'ศูนย์เตือนภัยพิบัติแห่งชาติ', 'number': '192'},
        {'name': 'สายด่วนกรมสุขภาพจิต', 'number': '1323'},
        {'name': 'ศูนย์รับแจ้งอุบัติเหตุทางน้ำ', 'number': '1196'},
      ],
    },
    {
      'title': 'สาธารณูปโภค',
      'icon': Icons.power_rounded,
      'color': Color(0xFF43A047),
      'numbers': [
        {'name': 'การไฟฟ้านครหลวง', 'number': '1130'},
        {'name': 'การไฟฟ้าส่วนภูมิภาค', 'number': '1129'},
        {'name': 'การประปานครหลวง', 'number': '1125'},
        {'name': 'การประปาส่วนภูมิภาค', 'number': '1162'},
        {'name': 'แจ้งเหตุน้ำมันเชื้อเพลิง', 'number': '1165'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;

    return _categories
        .map((cat) {
          final filteredNumbers = (cat['numbers'] as List<Map<String, String>>)
              .where(
                (n) =>
                    n['name']!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    n['number']!.contains(_searchQuery),
              )
              .toList();

          return {...cat, 'numbers': filteredNumbers};
        })
        .where((cat) => (cat['numbers'] as List).isNotEmpty)
        .toList();
  }

  Future<void> _makeCall(String number) async {
    await CallService.makeCall(number);
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

          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowSphere(200, Colors.blue.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlowSphere(250, Colors.red.withValues(alpha: 0.05)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchBar(),
                Expanded(
                  child: _filteredCategories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            return _buildCategorySection(
                              _filteredCategories[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowSphere(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สายด่วนปฏิบัติการ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'รวมเบอร์โทรฉุกเฉินทั่วประเทศไทย',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ค้นหาหน่วยงานหรือเบอร์โทร...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final Color color = category['color'];
    final List<Map<String, String>> numbers = category['numbers'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category['icon'], color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                category['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${numbers.length} รายการ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: numbers.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.02),
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final item = numbers[index];
                  return _InteractiveNumberTile(
                    color: color,
                    name: item['name']!,
                    number: item['number']!,
                    onTap: () => _makeCall(item['number']!),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white.withValues(alpha: 0.1),
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            'ไม่พบข้อมูลที่คุณกำลังค้นหา',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: const Text(
              'ล้างการค้นหา',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveNumberTile extends StatefulWidget {
  final Color color;
  final String name;
  final String number;
  final VoidCallback onTap;

  const _InteractiveNumberTile({
    required this.color,
    required this.name,
    required this.number,
    required this.onTap,
  });

  @override
  State<_InteractiveNumberTile> createState() => _InteractiveNumberTileState();
}

class _InteractiveNumberTileState extends State<_InteractiveNumberTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.number,
                    style: TextStyle(
                      color: widget.color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: _isPressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!_isPressed)
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
