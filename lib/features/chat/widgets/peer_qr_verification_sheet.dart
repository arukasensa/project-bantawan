// ============================================================================
// 📱 BANTAWAN Peer QR Identity & Verification Sheet: PeerQrVerificationSheet
// 
// หน้าต่างแสดง QR Code ประจำตัว และสแกน QR Code ของเพื่อน (QR Out-of-band Verification)
// ป้องกันการโจมตีแบบสวมรอย (Impersonation) และ Man-in-the-Middle (MITM)
// - แท็บ 1: QR ของฉัน (My Identity QR) -> สร้างด้วย qr_flutter
// - แท็บ 2: สแกน QR เพื่อน (Scan Peer QR) -> สแกนด้วย mobile_scanner
// ============================================================================

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/identity_service.dart';
import '../services/nearby_service.dart';
import '../models/mesh_peer.dart';
import '../screens/peer_verification_screen.dart';
import 'package:flutter1/core/widgets/tactical_decorations_painter.dart';

/// 📱 [PeerQrVerificationSheet]
/// วิดเจ็ตหน้าต่าง Bottom Sheet สำหรับการยืนยันตัวตนแบบ Out-of-Band (OOB Physical Verification)
/// ทำหน้าที่ป้องกันการโจมตีแบบสวมรอย (Impersonation Attack) และ Man-in-the-Middle (MITM)
/// ประกอบด้วย 2 โหมดการทำงาน:
/// 1. แสดง QR Code ประจำตัวตนเอง (My Identity QR) เพื่อให้เพื่อนสแกนตรวจสอบ
/// 2. กล้องสแกน QR Code ของเพื่อน (Scan Peer QR) พร้อมตัวเลือกกรอก Hex Key ด้วยตนเอง
class PeerQrVerificationSheet extends StatefulWidget {
  /// ไอดีของโหนดเพื่อนที่ต้องการยืนยันตัวตนเบื้องต้น (หากมี)
  final String? initialPeerId;

  const PeerQrVerificationSheet({super.key, this.initialPeerId});

  /// 🚀 เมธอด Static สะดวกใช้สำหรับเปิดแสดงโมดัล Bottom Sheet นี้จากทุกที่ในแอป
  /// @param context BuildContext ของหน้าจอที่เรียก
  /// @param peerId (ทางเลือก) รหัสของโหนดเพื่อนที่ต้องการเปิดเจาะจงเพื่อยืนยันตัวตน
  static Future<void> show(BuildContext context, {String? peerId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeerQrVerificationSheet(initialPeerId: peerId),
    );
  }

  @override
  State<PeerQrVerificationSheet> createState() => _PeerQrVerificationSheetState();
}

class _PeerQrVerificationSheetState extends State<PeerQrVerificationSheet> {
  int _selectedTab = 0; // 0: QR ของฉัน, 1: สแกน QR เพื่อน
  MobileScannerController? _scannerController;
  bool _hasScannedSuccess = false;
  String? _scannedResultText;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identityService = IdentityService.instance;
    final nearbyService = Provider.of<NearbyService>(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
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
              // Top Bar
              _buildTopBar(context),

              // Segmented Tab (QR ของฉัน vs สแกน QR เพื่อน)
              _buildSegmentedTab(),

              const SizedBox(height: 16),

              // Content View
              Expanded(
                child: _selectedTab == 0
                    ? _buildMyQrView(identityService, nearbyService)
                    : _buildScannerView(identityService, nearbyService),
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
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
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
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 0
                        ? Colors.cyanAccent.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 16, color: _selectedTab == 0 ? Colors.cyanAccent : Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        "QR ของฉัน",
                        style: TextStyle(
                          color: _selectedTab == 0 ? Colors.cyanAccent : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTab = 1;
                  _hasScannedSuccess = false;
                  _scannedResultText = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? Colors.purpleAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? Colors.purpleAccent.withValues(alpha: 0.45)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 16, color: _selectedTab == 1 ? Colors.purpleAccent : Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        "สแกน QR เพื่อน",
                        style: TextStyle(
                          color: _selectedTab == 1 ? Colors.purpleAccent : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
  // 📱 Section 2: Tab 1 - My QR Code
  // ============================================================================

  Widget _buildMyQrView(IdentityService identity, NearbyService nearby) {
    // Generate standard BANTAWAN peer payload URI
    final qrPayload = 'bantawan://peer?id=${identity.myNodeId}&key=${identity.myPublicKeyHex}&name=${nearby.deviceName}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // White Frame Container for QR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 210.0,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Callsign & Node ID
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                "@${nearby.deviceName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Node ID: ${identity.myNodeId}",
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Fingerprint Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fingerprint_rounded, color: Colors.cyanAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "CRYPTOGRAPHIC FINGERPRINT (SHA-256)",
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  identity.myFingerprint.replaceAll('\n', ' • '),
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Explanation
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "ให้เพื่อนสแกน QR Code นี้เพื่อยืนยัน Public Key ของคุณ ป้องกันการปลอมแปลงตัวตนในเครือข่าย Mesh",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, height: 1.3),
                ),
              ),
            ],
          ),

          // ปุ่มลัดไปหน้าตรวจ Fingerprint & กดยืนยันตัวตนคู่สนทนา (หากเปิดมาจากแชทเพื่อน)
          if (widget.initialPeerId != null) ...[
            const SizedBox(height: 20),
            Builder(
              builder: (ctx) {
                final targetPeer = nearby.discoveredMeshPeers[widget.initialPeerId];
                final peerName = targetPeer?.peerName ?? 'คู่สนทนา';
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                      foregroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: Text(
                      'ตรวจสอบ Fingerprint และกดยืนยันตัวตน @$peerName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final resolved = targetPeer ?? MeshPeer(
                        peerId: widget.initialPeerId!,
                        peerName: peerName,
                        publicKeyHex: '',
                        hopCount: 1,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PeerVerificationScreen(peer: resolved),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // 📷 Section 3: Tab 2 - Scanner View
  // ============================================================================

  Widget _buildScannerView(IdentityService identity, NearbyService nearby) {
    if (_hasScannedSuccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
              ),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันตัวตนสำเร็จ! (Identity Verified)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _scannedResultText ?? "บันทึกกุญแจ Public Key ของเพื่อนแล้ว",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text("กลับไปยังห้องแชท", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Camera Viewfinder Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // MobileScanner Camera Preview
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null && !_hasScannedSuccess) {
                          _processScannedPayload(rawValue, identity, nearby);
                          break;
                        }
                      }
                    },
                  ),

                  // Viewfinder Tactical Reticle
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TacticalCornerPainter(
                        color: Colors.purpleAccent,
                        length: 24,
                      ),
                    ),
                  ),

                  // Central Target Box
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.6), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Controls: Torch + Paste Key + Manual Verify Option
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _scannerController?.toggleTorch(),
                      icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 18),
                      label: const Text("เปิด/ปิด ไฟฉาย", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.purpleAccent.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showManualPasteDialog(identity, nearby),
                      icon: const Icon(Icons.paste_rounded, color: Colors.purpleAccent, size: 18),
                      label: const Text("กรอก Key ด้วยตนเอง", style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              if (widget.initialPeerId != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.verified_user_rounded, size: 16),
                  label: const Text(
                    "หรือ ตรวจสอบ Fingerprint และกดยืนยันด้วยตนเอง",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final targetPeer = nearby.discoveredMeshPeers[widget.initialPeerId];
                    final peerName = targetPeer?.peerName ?? 'คู่สนทนา';
                    Navigator.pop(context);
                    final resolved = targetPeer ?? MeshPeer(
                      peerId: widget.initialPeerId!,
                      peerName: peerName,
                      publicKeyHex: '',
                      hopCount: 1,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PeerVerificationScreen(peer: resolved),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 🔍 Section 4: Payload Processing & Manual Paste
  // ============================================================================

  /// 🔍 ถอดรหัสและประมวลผลข้อมูลที่ได้จากการสแกน QR Code หรือกรอกด้วยตนเอง
  /// รองรับ 3 รูปแบบข้อมูล:
  /// 1. Custom URI: `bantawan://peer?id=...&key=...&name=...`
  /// 2. โครงสร้าง JSON: `{"id": "...", "key": "...", "name": "..."}`
  /// 3. Raw Hex String: กุญแจ X25519 Public Key 64 ตัวอักษร
  /// เมื่อตรวจสอบพบ Key จะทำการผูกความเชื่อถือลงใน IdentityService ทันที
  void _processScannedPayload(
    String raw,
    IdentityService identity,
    NearbyService nearby,
  ) {
    String? peerId;
    String? peerKey;
    String? peerName;

    try {
      if (raw.startsWith('bantawan://peer')) {
        final uri = Uri.parse(raw);
        peerId = uri.queryParameters['id'];
        peerKey = uri.queryParameters['key'];
        peerName = uri.queryParameters['name'];
      } else if (raw.trim().startsWith('{')) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        peerId = map['id']?.toString();
        peerKey = map['key']?.toString();
        peerName = map['name']?.toString();
      } else {
        // Raw public key hex
        peerKey = raw.trim();
        peerId = widget.initialPeerId;
        peerName = 'Unknown Peer';
      }

      if (peerKey != null && peerKey.isNotEmpty) {
        final targetPeerId = peerId ?? widget.initialPeerId ?? 'node_${peerKey.substring(0, 8)}';
        final targetName = peerName ?? 'Peer';

        identity.verifyPeer(
          peerId: targetPeerId,
          displayName: targetName,
          publicKeyHex: peerKey,
        );

        // Also update discovered peer in nearbyService if present
        if (nearby.discoveredMeshPeers.containsKey(targetPeerId)) {
          final old = nearby.discoveredMeshPeers[targetPeerId]!;
          nearby.discoveredMeshPeers[targetPeerId] = MeshPeer(
            peerId: old.peerId,
            peerName: old.peerName,
            publicKeyHex: peerKey,
            hopCount: old.hopCount,
            lastSeen: DateTime.now(),
            emergencyProfile: old.emergencyProfile,
          );
        }

        HapticFeedback.heavyImpact();
        setState(() {
          _hasScannedSuccess = true;
          _scannedResultText = "ยืนยัน Public Key ของ @$targetName ($targetPeerId) สำเร็จแล้ว!";
        });
      }
    } catch (e) {
      debugPrint('[QR Scan] Failed to parse: $e');
    }
  }

  /// 📋 แสดงกล่องโต้ตอบสำหรับวางรหัส Public Key หรือ URI ด้วยตนเอง (Manual Fallback)
  /// ใช้ในกรณีที่กล้องสมาร์ตโฟนไม่สามารถโฟกัส QR Code ได้ หรืออยู่ในที่มืดสนิท
  void _showManualPasteDialog(IdentityService identity, NearbyService nearby) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent, width: 1)),
        title: const Text("วาง Public Key หรือ QR Data", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: "วางรหัส หรือ bantawan://peer?...",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _processScannedPayload(controller.text.trim(), identity, nearby);
            },
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }
}
