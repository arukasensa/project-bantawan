// ============================================================================
// 📞 BANTAWAN ICE Personal Emergency Contacts: EmergencyContactScreen
// 
// หน้าจอจัดการรายชื่อผู้ติดต่อฉุกเฉินส่วนตัว (In Case of Emergency - ICE Contacts Screen)
// จัดการเพิ่ม แก้ไข ลบ รายชื่อบุคคลใกล้ชิดและญาติ พร้อมปุ่มโทรด่วน ปุ่มส่งพิกัด SMS ฉุกเฉิน
// และปุ่มแชร์โปรไฟล์การแพทย์ฉุกเฉิน
// ============================================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../services/emergency_contact_service.dart';
import '../services/call_service.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 📞 หน้าจอจัดการและแสดงรายชื่อผู้ติดต่อฉุกเฉินส่วนตัว (ICE Contacts Screen)
class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

/// 📋 State ควบคุมการโหลด เพิ่ม แก้ไข ลบผู้ติดต่อฉุกเฉินและการยิง SMS พิกัด
class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  /// รายการผู้ติดต่อฉุกเฉินทั้งหมด
  List<Map<String, String>> _contacts = [];

  /// สถานะกำลังโหลดข้อมูล
  bool _isLoading = true;

  final List<Map<String, dynamic>> _relationshipTypes = [
    {'key': 'family', 'icon': Icons.home_rounded},
    {'key': 'lover', 'icon': Icons.favorite_rounded},
    {'key': 'relative', 'icon': Icons.family_restroom_rounded},
    {'key': 'friend', 'icon': Icons.group_rounded},
    {'key': 'colleague', 'icon': Icons.work_rounded},
    {'key': 'other', 'icon': Icons.person_rounded},
  ];

  String _getRelationshipLabel(BuildContext context, String keyOrLabel) {
    final isThai = context.isThai;
    switch (keyOrLabel) {
      case 'family':
      case 'ครอบครัว':
        return isThai ? 'ครอบครัว' : 'Family';
      case 'lover':
      case 'คนรัก':
        return isThai ? 'คนรัก' : 'Partner';
      case 'relative':
      case 'ญาติ':
        return isThai ? 'ญาติ' : 'Relative';
      case 'friend':
      case 'เพื่อนสนิท':
      case 'คนสนิท':
        return isThai ? 'เพื่อนสนิท' : 'Friend';
      case 'colleague':
      case 'เพื่อนร่วมงาน':
        return isThai ? 'เพื่อนร่วมงาน' : 'Colleague';
      default:
        return isThai ? 'อื่นๆ' : 'Other';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await EmergencyContactService.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _addContact(
    String name,
    String phone,
    String relationship,
  ) async {
    if (name.isEmpty || phone.isEmpty) return;

    final newContact = {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
    setState(() {
      _contacts.add(newContact);
    });

    await EmergencyContactService.addContact(
      name,
      phone,
      relationship: relationship,
    );
  }

  Future<void> _deleteContact(int index) async {
    final contact = _contacts[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.isThai ? 'ยืนยันการลบ' : 'Confirm Delete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            context.isThai
                ? 'คุณแน่ใจหรือไม่ว่าต้องการลบรายชื่อ "${contact['name']}" ออกจากการติดต่อฉุกเฉิน?'
                : 'Are you sure you want to remove "${contact['name']}" from emergency contacts?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                context.isThai ? 'ยกเลิก' : 'Cancel',
                style: const TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                context.isThai ? 'ลบรายชื่อ' : 'Delete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ).animateScale(),
    );

    if (confirm != true) return;

    setState(() {
      _contacts.removeAt(index);
    });

    await EmergencyContactService.deleteContact(index);
  }

  Future<void> _makeCall(String phone) async {
    await CallService.makeCall(phone);
  }

  Future<void> _sendLocation(String phone) async {
    final isThai = context.isThai;
    try {
      Position position = await Geolocator.getCurrentPosition();
      String mapLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      String message = isThai
          ? "ช่วยด้วย! ฉันต้องการความช่วยเหลือด่วน\nพิกัดของฉัน: $mapLink"
          : "HELP! I need emergency assistance\nMy coordinates: $mapLink";

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint("Error sending location: $e");
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRelationship = _relationshipTypes[0]['key'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.isThai ? 'เพิ่มผู้ติดต่อฉุกเฉิน' : 'Add Emergency Contact',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      nameController,
                      context.isThai ? 'ชื่อผู้ติดต่อ' : 'Contact Name',
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      phoneController,
                      context.isThai ? 'เบอร์โทรศัพท์' : 'Phone Number',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.isThai ? 'ความสัมพันธ์' : 'Relationship',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _relationshipTypes.length,
                      itemBuilder: (context, index) {
                        final type = _relationshipTypes[index];
                        final isSelected = selectedRelationship == type['key'];
                        return InkWell(
                          onTap: () => setDialogState(
                            () => selectedRelationship = type['key'],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF1E293B).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type['icon'],
                                  size: 16,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _getRelationshipLabel(context, type['key']),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Text(
                        context.isThai ? 'ยกเลิก' : 'Cancel',
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            phoneController.text.isNotEmpty) {
                          _addContact(
                            nameController.text,
                            phoneController.text,
                            selectedRelationship,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        context.isThai ? 'บันทึก' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              context.isThai ? 'ผู้ติดต่อฉุกเฉิน' : 'Emergency Contacts',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              context.isThai
                  ? '${_contacts.length} รายชื่อ'
                  : '${_contacts.length} Contacts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _showAddDialog,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F23), Color(0xFF16213E), Color(0xFF050510)],
          ),
        ),
        child: Stack(
          children: [
            // Background Glows
            Positioned(
              top: 100,
              right: -50,
              child: _buildGlowLight(200, Colors.red.withValues(alpha: 0.1)),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: _buildGlowLight(250, Colors.blue.withValues(alpha: 0.05)),
            ),

            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    )
                  : _contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        return _buildContactCard(_contacts[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowLight(double size, Color color) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_disabled_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          Text(
            context.isThai ? 'ยังไม่มีรายชื่อผู้ติดต่อ' : 'No Emergency Contacts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.isThai
                ? 'เพิ่มคนสนิทของคุณเพื่อขอความช่วยเหลือได้เร็วขึ้น'
                : 'Add your close contacts for quick emergency assistance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              context.isThai ? 'เพิ่มตอนนี้' : 'Add Now',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact, int index) {
    final String rawRel = contact['relationship'] ?? 'friend';
    final IconData icon = _relationshipTypes.firstWhere(
      (element) => element['key'] == rawRel || element['key'] == 'friend',
      orElse: () => _relationshipTypes.last,
    )['icon'];
    final String displayRelationship = _getRelationshipLabel(context, rawRel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with Alive Glow
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.redAccent, size: 28),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            contact['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayRelationship,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact['phone'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    _buildActionButton(
                      Icons.location_on_rounded,
                      Colors.blueAccent,
                      () => _sendLocation(contact['phone'] ?? ''),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.phone_rounded,
                      Colors.greenAccent,
                      () => _makeCall(contact['phone'] ?? ''),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.delete_outline_rounded,
                      Colors.white24,
                      () => _deleteContact(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

extension on Widget {
  Widget animateScale() => TweenAnimationBuilder(
    duration: const Duration(milliseconds: 300),
    tween: Tween<double>(begin: 0.9, end: 1.0),
    curve: Curves.easeOutBack,
    builder: (context, double value, child) =>
        Transform.scale(scale: value, child: child),
    child: this,
  );
}
