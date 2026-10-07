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
import 'package:flutter1/features/home/services/language_service.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';

/// ⚙️ [BantawanSettingsSheet] หน้าต่างการตั้งค่าและเอกสารสถาปัตยกรรมระบบออฟไลน์
/// ประกอบด้วย 2 แท็บหลัก:
/// 1. [ข้อมูล (Info)]: รายละเอียดสถาปัตยกรรม Mesh Routing, สถิติเครือข่าย และความปลอดภัย
/// 2. [ตั้งค่า (Settings)]: การปรับแต่ง Callsign, พารามิเตอร์เครือข่าย, สวิตช์ Data Mule และเสียง
class BantawanSettingsSheet extends StatefulWidget {
  const BantawanSettingsSheet({super.key});

  /// 🚀 แสดงหน้าต่างการตั้งค่า [BantawanSettingsSheet] ในรูปแบบ Modal Bottom Sheet
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
  bool _autoPlayVoice = true;

  @override
  Widget build(BuildContext context) {
    final nearbyService = Provider.of<NearbyService>(context);
    final identityService = IdentityService.instance;
    final l10n = AppLocalizations.of(context);
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
              _buildSegmentedTab(l10n),

              const SizedBox(height: 12),

              // 3. Tab Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildInfoTab()
                    : _buildSettingsTab(nearbyService, identityService, l10n),
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

  Widget _buildSegmentedTab(AppLocalizations? l10n) {
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
                    l10n?.infoTab ?? "ข้อมูล (Info)",
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
                    l10n?.settingsTab ?? "ตั้งค่า (Settings)",
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
    AppLocalizations? l10n,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // 1. หมวดตัวตนและการแสดงผล
        _buildSectionHeader(l10n != null ? (l10n.localeName == 'th' ? "ลักษณะที่ปรากฏ (Appearance)" : "Appearance") : "ลักษณะที่ปรากฏ (Appearance)"),
        _buildCardContainer(
          children: [
            // Callsign Quick Edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.tacticalCallsign ?? "นามเรียกขาน (Callsign)",
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                  label: Text(l10n?.changeCallsign ?? "เปลี่ยนชื่อ", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Language Selector bound to LanguageProvider
            Builder(
              builder: (ctx) {
                final languageProvider = Provider.of<LanguageProvider>(ctx);
                final currentCode = languageProvider.appLocale.languageCode;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language_rounded, color: Colors.cyanAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.appLanguage ?? "ภาษาของแอป",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      child: DropdownButton<String>(
                        value: currentCode,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.cyanAccent),
                        items: const [
                          DropdownMenuItem(
                            value: 'th',
                            child: Row(
                              children: [
                                Text('🇹🇭', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text('ภาษาไทย'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('🇺🇸', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text('English'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null && val != currentCode) {
                            HapticFeedback.selectionClick();
                            languageProvider.changeLanguage(Locale(val));
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. หมวดโครงข่าย Bluetooth Mesh
        _buildSectionHeader(l10n != null && l10n.localeName.startsWith('th') ? "การเชื่อมต่อและโครงข่าย Mesh" : "Connectivity & Mesh Network"),
        _buildCardContainer(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.meshRelayTitle ?? "บริดจ์และการส่งต่อทอด (Mesh Relay)",
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n?.meshRelayDesc ?? "ส่งต่อแพ็กเก็ตข้อความและ SOS ข้ามโหนดในรัศมีบลูทูธแบบ Multi-hop",
                        style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
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
                Text(
                  l10n != null && l10n.localeName.startsWith('th') ? "รัศมีการส่งต่อสูงสุด (Max TTL)" : "Maximum Relay Radius (Max TTL)",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    l10n != null && l10n.localeName.startsWith('th') ? "5 HOPS (ทอด)" : "5 HOPS",
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 4. หมวดความปลอดภัยและการเข้ารหัส (E2EE)
        _buildSectionHeader(l10n != null && l10n.localeName.startsWith('th') ? "กุญแจและความปลอดภัย (E2EE Cryptography)" : "Keys & Security (E2EE Cryptography)"),
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
                        style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "X25519 PUBLIC KEY FINGERPRINT",
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        identity.myFingerprint.replaceAll('\n', ' • '),
                        style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 0.8),
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
        _buildSectionHeader(l10n != null && l10n.localeName.startsWith('th') ? "เสียงและกฎความปลอดภัยสื่อฉุกเฉิน" : "Audio & Emergency Media Rules"),
        _buildCardContainer(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.autoPlayVoice ?? "เล่นเสียงสดอัตโนมัติ (Live Voice Messages)",
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n != null && l10n.localeName.startsWith('th')
                            ? "สตรีมขณะพูด เสียงสดขาเข้าจะเล่นอัตโนมัติทันทีที่ได้รับ"
                            : "Stream while speaking, incoming voice plays automatically upon receipt",
                        style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
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
            Text(
              l10n != null && l10n.localeName.startsWith('th')
                  ? "• กฎความปลอดภัย BLE 32KB Strict Safety Cap:\n  - ภาพถ่ายบีบอัดระดับยุทธวิธี 360x360 WebP (< 25KB)\n  - ข้อความเสียงจำกัดเวลาสูงสุด 6 วินาที (< 18KB)"
                  : "• BLE 32KB Strict Safety Cap Rules:\n  - Tactical compressed photos 360x360 WebP (< 25KB)\n  - Voice messages limited to max 6 seconds (< 18KB)",
              style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
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
          title: "Local Database & Storage Layer",
          description: "ระบบจัดเก็บประวัติการสื่อสารและความปลอดภัยแบบกระจายศูนย์ผ่าน SQLite ท้องถิ่น",
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
    final l10n = AppLocalizations.of(context);
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 1)),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: Colors.cyanAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n?.changeCallsign ?? (isThai ? "เปลี่ยนนามเรียกขาน (@)" : "Change Callsign (@)"),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isThai
                  ? "ชื่อนี้จะแสดงในห้องแชทสาธารณะ #mesh และรายชื่อผู้ใช้ใกล้เคียง:"
                  : "This callsign is visible on #mesh and nearby peer discovery:",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
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
            child: Text(
              l10n?.cancelButton ?? (isThai ? "ยกเลิก" : "Cancel"),
              style: const TextStyle(color: Colors.white54),
            ),
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
            child: Text(
              isThai ? "บันทึกชื่อ" : "Save Callsign",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
