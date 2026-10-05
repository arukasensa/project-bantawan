// ============================================================================
// ⚙️ BANTAWAN Settings & Info Sheet: BantawanSettingsSheet
// 
// หน้าต่างการตั้งค่าและเอกสารสถาปัตยกรรมระบบ (Settings & Info Sheet)
// สไตล์ Bitchat UI: แถบสลับแท็บ [ข้อมูล (Info)] / [ตั้งค่า (Settings)]
// ปรับแต่งตามฟังก์ชันการทำงานจริงของ BANTAWAN:
// - Appearance & Callsign (@callsign)
// - Offline Mesh Routing (TTL / Relay)
// - Data Mule Store-and-Forward
// - E2EE Cryptography (X25519 / Node ID / Fingerprint)
// - Voice & BLE 32KB Strict Safety
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/nearby_service.dart';
import '../services/identity_service.dart';
import 'package:flutter1/features/home/services/profile_service.dart';

class BantawanSettingsSheet extends StatefulWidget {
  const BantawanSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BantawanSettingsSheet(),
    );
  }

  @override
  State<BantawanSettingsSheet> createState() => _BantawanSettingsSheetState();
}

class _BantawanSettingsSheetState extends State<BantawanSettingsSheet> {
  int _selectedTab = 1; // 0: ข้อมูล (Info), 1: ตั้งค่า (Settings)
  int _themeIndex = 1; // 0: เมทริกซ์ (Matrix), 1: ลิควิดกลาส (Liquid Glass)
  String _selectedLanguage = 'ค่าเริ่มต้นของระบบ';
  bool _autoPlayVoice = true;

  @override
  Widget build(BuildContext context) {
    final nearbyService = Provider.of<NearbyService>(context);
    final identityService = IdentityService.instance;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.90,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Column(
            children: [
              // 1. Top Header Handle & Close Button
              _buildTopBar(context),

              // 2. Segmented Tab Switcher (ข้อมูล vs ตั้งค่า)
              _buildSegmentedTab(),

              const SizedBox(height: 12),

              // 3. Tab Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildInfoTab()
                    : _buildSettingsTab(nearbyService, identityService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🔘 Section 1: Top Bar & Segmented Tab
  // ============================================================================

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Close Button [✕]
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
            tooltip: 'ปิดหน้าต่าง',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "ข้อมูล (Info)",
                    style: TextStyle(
                      color: _selectedTab == 0 ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? Colors.cyanAccent.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    "ตั้งค่า (Settings)",
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.cyanAccent : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ⚙️ Section 2: Settings Tab (ตั้งค่าตามความสามารถจริงของ BANTAWAN)
  // ============================================================================

  Widget _buildSettingsTab(
    NearbyService service,
    IdentityService identity,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // 1. หมวดตัวตนและการแสดงผล
        _buildSectionHeader("ลักษณะที่ปรากฏ (Appearance)"),
        _buildCardContainer(
          children: [
            // Callsign Quick Edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "นามเรียกขาน (Callsign)",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "@${service.deviceName}",
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showChangeCallsignDialog(service),
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.cyanAccent),
                  label: const Text("เปลี่ยนชื่อ", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Theme selector (เมทริกซ์ vs ลิควิดกลาส)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ธีมหน้าจอ",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildMiniSegmentItem("เมทริกซ์", _themeIndex == 0, () {
                        setState(() => _themeIndex = 0);
                      }),
                      _buildMiniSegmentItem("ลิควิดกลาส", _themeIndex == 1, () {
                        setState(() => _themeIndex = 1);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Language
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ภาษาของแอป",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'ค่าเริ่มต้นของระบบ', child: Text('ค่าเริ่มต้นของระบบ')),
                    DropdownMenuItem(value: 'ไทย (Thai)', child: Text('ไทย (Thai)')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. หมวดโครงข่าย Bluetooth Mesh
        _buildSectionHeader("การเชื่อมต่อและโครงข่าย Mesh"),
        _buildCardContainer(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "บริดจ์และการส่งต่อทอด (Mesh Relay)",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "ส่งต่อแพ็กเก็ตข้อความและ SOS ข้ามโหนดในรัศมีบลูทูธแบบ Multi-hop",
                        style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: service.isAdvertising || service.isDiscovering,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val) {
                      service.startEmergencyNetwork();
                    } else {
                      service.stopEmergencyNetwork();
                    }
                  },
                  activeThumbColor: Colors.cyanAccent,
                  activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.25),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รัศมีการส่งต่อสูงสุด (Max TTL)", style: TextStyle(color: Colors.white, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Text("5 HOPS (ทอด)", style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. หมวดคนเดินสาร (Data Mule)
        _buildSectionHeader("ระบบคนเดินสาร (Data Mule Protocol)"),
        _buildCardContainer(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "หิ้วซองจดหมายเข้ารหัส (Store & Forward)",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "ฝากข้อความไว้ในเครื่อง และส่งต่ออัตโนมัติเมื่อเดินเข้าไปใกล้โหนดปลายทาง",
                        style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: service.isDataMuleEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    service.toggleDataMule(val);
                  },
                  activeThumbColor: Colors.purpleAccent,
                  activeTrackColor: Colors.purpleAccent.withValues(alpha: 0.25),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ซองจดหมายที่หิ้วอยู่ขณะนี้", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("${service.carriedEnvelopes.length} ซอง", style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 4. หมวดความปลอดภัยและการเข้ารหัส (E2EE)
        _buildSectionHeader("กุญแจและความปลอดภัย (E2EE Cryptography)"),
        _buildCardContainer(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.vpn_key_rounded, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PERSISTENT NODE ID",
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        identity.myNodeId,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "X25519 PUBLIC KEY FINGERPRINT",
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        identity.myFingerprint.replaceAll('\n', ' • '),
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 5. หมวดเสียงและสื่อ (Voice & Media Limits)
        _buildSectionHeader("เสียงและกฎความปลอดภัยสื่อฉุกเฉิน"),
        _buildCardContainer(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "เล่นเสียงสดอัตโนมัติ (Live Voice Messages)",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "สตรีมขณะพูด เสียงสดขาเข้าจะเล่นอัตโนมัติทันทีที่ได้รับ",
                        style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoPlayVoice,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _autoPlayVoice = val);
                  },
                  activeThumbColor: Colors.cyanAccent,
                  activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.25),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            const Text(
              "• กฎความปลอดภัย BLE 32KB Strict Safety Cap:\n  - ภาพถ่ายบีบอัดระดับยุทธวิธี 360x360 WebP (< 25KB)\n  - ข้อความเสียงจำกัดเวลาสูงสุด 6 วินาที (< 18KB)",
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // 📖 Section 3: Info Tab (คู่มือสถาปัตยกรรมและการใช้งาน)
  // ============================================================================

  Widget _buildInfoTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // Title Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BANTAWAN TACTICAL MESH",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        Text(
                          "ระบบสื่อสารทางยุทธวิธีและเครือข่ายออฟไลน์กู้ภัย",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "BANTAWAN ออกแบบมาเพื่อทำงานในภาวะวิกฤตที่เสาสัญญาณมือถือ อินเทอร์เน็ต และระบบไฟฟ้าล่มสลาย สื่อสารได้ผ่านคลื่นสั้น Bluetooth Low Energy (BLE) และ Wi-Fi Direct แบบ Peer-to-Peer 100% โดยไม่ต้องพึ่งพาเซิร์ฟเวอร์",
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        _buildSectionHeader("สถาปัตยกรรมระบบ 5 เลเยอร์"),

        _buildLayerCard(
          layerNumber: "1",
          title: "Tactical HUD & Offline Chat UI",
          description: "ห้องแชทสาธารณะ #mesh, แชทส่วนตัว E2EE, เรดาร์ตรวจจับ Node และพิกัดฉุกเฉินทางการแพทย์",
          color: Colors.cyanAccent,
        ),
        _buildLayerCard(
          layerNumber: "2",
          title: "End-to-End Encryption (E2EE)",
          description: "โปรโตคอล X25519 ECDH + HKDF-SHA256 + AES-256-GCM เข้ารหัสเฉพาะคู่สนทนา โหนดกลางทางอ่านไม่ได้",
          color: Colors.greenAccent,
        ),
        _buildLayerCard(
          layerNumber: "3",
          title: "BANTAWAN Mesh Routing Engine",
          description: "กระจายแพ็กเก็ตแบบ Ad-hoc Multi-hop Flooding พร้อมแคช LRU 1,000 ไอดี ป้องกันการวนลูป และ RPRT ย้อนรอยส่ง ACK",
          color: Colors.blueAccent,
        ),
        _buildLayerCard(
          layerNumber: "4",
          title: "Transport Layer (Nearby Connections)",
          description: "สร้างคลัสเตอร์การเชื่อมต่อ P2P ผ่านคลื่น BLE และ Wi-Fi Direct แบบคู่ขนาน",
          color: Colors.purpleAccent,
        ),
        _buildLayerCard(
          layerNumber: "5",
          title: "Storage & Data Mule Engine",
          description: "ระบบคนเดินสาร Store-and-Forward หิ้วซองจดหมายข้ามพื้นที่ขาดสัญญาณ และ SQLite เก็บประวัติ",
          color: Colors.orangeAccent,
        ),
      ],
    );
  }

  // ============================================================================
  // 🧩 Helper Widgets & Dialogs
  // ============================================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMiniSegmentItem(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLayerCard({
    required String layerNumber,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "L$layerNumber",
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeCallsignDialog(NearbyService service) {
    final controller = TextEditingController(text: service.deviceName);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 1)),
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text("เปลี่ยนนามเรียกขาน (@)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ชื่อนี้จะแสดงในห้องแชทสาธารณะ #mesh และรายชื่อผู้ใช้ใกล้เคียง:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              maxLength: 18,
              decoration: InputDecoration(
                prefixText: "@ ",
                prefixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final profile = await ProfileService.getProfile();
                profile['name'] = newName;
                await ProfileService.saveProfile(profile);
                await service.updateProfileInfo();
                if (mounted) setState(() {});
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text("บันทึกชื่อ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
