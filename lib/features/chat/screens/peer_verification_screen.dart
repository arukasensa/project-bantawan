// ============================================================================
// 🛡️ BANTAWAN Peer Verification Screen: PeerVerificationScreen
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │              Peer Identity Verification Layer           │
// │            (PeerVerificationScreen: UI Fingerprint)     │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// └─────────────────────────────────────────────────────────┘
// 
// หน้าจอสำหรับตรวจสอบและยืนยัน Cryptographic Fingerprint ของ Peer คู่สนทนา
// ช่วยป้องกันการถูกปลอมแปลงตัวตน (Impersonation / MITM Attack)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mesh_peer.dart';
import '../models/peer_trust.dart';
import '../services/identity_service.dart';
import '../widgets/peer_qr_verification_sheet.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 🛡️ หน้าจอแสดงผลและยืนยัน Cryptographic Fingerprint ของ Peer คู่สนทนา
class PeerVerificationScreen extends StatefulWidget {
  final MeshPeer peer;

  const PeerVerificationScreen({
    super.key,
    required this.peer,
  });

  @override
  State<PeerVerificationScreen> createState() => _PeerVerificationScreenState();
}

class _PeerVerificationScreenState extends State<PeerVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final identityService = IdentityService.instance;
    final trustState = identityService.getTrustState(
      widget.peer.peerId,
      widget.peer.publicKeyHex,
    );
    final peerFingerprint = identityService.computeFingerprint(widget.peer.publicKeyHex);
    final myFingerprint = identityService.myFingerprint;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          context.isThai ? 'ตรวจสอบตัวตนคู่สนทนา' : 'Verify Peer Identity',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent),
            tooltip: context.isThai ? 'สแกน QR Code เพื่อยืนยัน' : 'Scan QR Code to Verify',
            onPressed: () {
              PeerQrVerificationSheet.show(context, peerId: widget.peer.peerId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👤 Header Info Card
            _buildPeerHeaderCard(trustState),
            const SizedBox(height: 16),

            // ⚠️ Warning banner if Key has CHANGED
            if (trustState == PeerTrustState.changed) ...[
              _buildChangedWarningBanner(),
              const SizedBox(height: 16),
            ],

            // 🔐 Peer's Fingerprint Card
            _buildFingerprintCard(
              title: context.isThai
                  ? '🔑 Fingerprint ของ ${widget.peer.peerName}'
                  : '🔑 ${widget.peer.peerName}\'s Fingerprint',
              subtitle: context.isThai
                  ? 'เปรียบเทียบข้อความนี้กับหน้าจอของ ${widget.peer.peerName}'
                  : 'Compare this fingerprint with ${widget.peer.peerName}\'s screen',
              fingerprint: peerFingerprint,
              accentColor: trustState == PeerTrustState.verified
                  ? const Color(0xFF4ADE80)
                  : (trustState == PeerTrustState.changed ? const Color(0xFFFB923C) : const Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 16),

            // 📱 My Fingerprint Card
            _buildFingerprintCard(
              title: context.isThai
                  ? '📱 Fingerprint ของเครื่องคุณ'
                  : '📱 Your Device Fingerprint',
              subtitle: context.isThai
                  ? 'ให้ ${widget.peer.peerName} ตรวจสอบรหัสนี้บนเครื่องของเขา'
                  : 'Ask ${widget.peer.peerName} to verify this code on their device',
              fingerprint: myFingerprint,
              accentColor: const Color(0xFFA78BFA),
            ),
            const SizedBox(height: 24),

            // ℹ️ Informational Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.isThai
                          ? 'การยืนยัน Fingerprint จะทำเฉพาะครั้งแรกเพื่อความมั่นใจ โดย Fingerprint สร้างขึ้นจาก Public Key ประจำเครื่องอย่างถาวร'
                          : 'Fingerprint verification confirms peer identity authenticity. Fingerprints are permanently derived from each device’s cryptographic public key.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 🔘 Verify / Action Buttons
            _buildActionButtons(trustState, identityService),
          ],
        ),
      ),
    );
  }

  /// 👤 การ์ดแสดงชื่อและสถานะ Trust
  Widget _buildPeerHeaderCard(PeerTrustState trustState) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (trustState) {
      case PeerTrustState.verified:
        badgeColor = Colors.greenAccent;
        badgeIcon = Icons.verified_user_rounded;
        badgeText = context.isThai ? 'ยืนยันตัวตนแล้ว (Verified)' : 'Verified';
        break;
      case PeerTrustState.changed:
        badgeColor = Colors.orangeAccent;
        badgeIcon = Icons.warning_amber_rounded;
        badgeText = context.isThai ? 'Key มีการเปลี่ยนแปลง (Identity Changed)' : 'Identity Key Changed';
        break;
      case PeerTrustState.unverified:
      case PeerTrustState.unknown:
        badgeColor = Colors.white54;
        badgeIcon = Icons.gpp_maybe_rounded;
        badgeText = context.isThai ? 'ยังไม่ได้ยืนยัน (Unverified)' : 'Unverified';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha:0.4), width: 1.5),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: badgeColor.withValues(alpha:0.15),
            child: Icon(Icons.person_rounded, size: 32, color: badgeColor),
          ),
          const SizedBox(height: 10),
          Text(
            widget.peer.peerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Node ID: ${widget.peer.peerId}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha:0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 16, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ ป้ายเตือนเมื่อ Key เปลี่ยน
  Widget _buildChangedWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.isThai
                  ? 'คำเตือน: Public Key ของ Peer นี้ไม่ตรงกับที่เคยยืนยันไว้ก่อนหน้า อาจเกิดจากการลงแอปใหม่ หรือเสี่ยงต่อการถูกแทรกแซงตัวตน (MITM Attack)'
                  : 'Warning: Public Key for this peer does not match previous records. They may have reinstalled the app, or there is an active impersonation / MITM risk.',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 การ์ดแสดง Fingerprint Monospace
  Widget _buildFingerprintCard({
    required String title,
    required String subtitle,
    required String fingerprint,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white54),
                tooltip: context.isThai ? 'คัดลอก Fingerprint' : 'Copy Fingerprint',
                onPressed: () {
                  if (fingerprint.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.isThai ? 'ยังไม่มีข้อมูล Fingerprint ให้คัดลอก' : 'No fingerprint data to copy'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: fingerprint.replaceAll('\n', ' ')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.isThai ? 'คัดลอก Fingerprint เรียบร้อย' : 'Fingerprint copied to clipboard'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final groups = fingerprint.isNotEmpty
                  ? fingerprint.split(RegExp(r'\s+')).where((g) => g.trim().isNotEmpty).toList()
                  : <String>[];

              if (groups.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // แถวที่ 1 (4 กลุ่มแรก)
                      _buildFingerprintRow(groups.sublist(0, groups.length >= 4 ? 4 : groups.length), accentColor),
                      if (groups.length > 4) ...[
                        const SizedBox(height: 8),
                        // แถวที่ 2 (4 กลุ่มหลัง)
                        _buildFingerprintRow(groups.sublist(4), accentColor),
                      ],
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  context.isThai ? 'ยังไม่มีข้อมูล Public Key (ยังไม่ได้รับ Key)' : 'No Public Key data received yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// สร้างแถวกล่องตัวเลข 4 หลักที่คมชัด ไม่บวม สว่างชัดเจน
  Widget _buildFingerprintRow(List<String> rowGroups, Color accentColor) {
    return Row(
      children: rowGroups.map((group) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF162032),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              group,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 🔘 ปุ่มแอ็กชันยืนยันตัวตน
  Widget _buildActionButtons(PeerTrustState trustState, IdentityService identityService) {
    if (trustState == PeerTrustState.verified) {
      return Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withValues(alpha:0.2),
              foregroundColor: Colors.greenAccent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.greenAccent),
              ),
            ),
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              context.isThai ? 'ยืนยันตัวตนเรียบร้อยแล้ว' : 'Identity Verified',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: null,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.isThai ? 'ยกเลิกการยืนยัน (Reset Trust)' : 'Reset Verification Trust'),
            onPressed: () async {
              await identityService.resetTrust(widget.peer.peerId);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.isThai ? 'ยกเลิกการยืนยันเรียบร้อยแล้ว' : 'Verification reset successfully')),
                );
              }
            },
          ),
        ],
      );
    }

    final hasKey = widget.peer.publicKeyHex.isNotEmpty;
    if (!hasKey) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.isThai
                        ? 'ยังไม่ได้รับ Public Key จากคู่สนทนานี้ในระบบ Mesh กรุณารอให้คู่สนทนาออนไลน์ หรือสแกน QR Code เพื่อแลกเปลี่ยนกุญแจทันที'
                        : 'No Public Key received yet from this peer via Mesh. Wait until peer is online or scan QR Code to exchange keys immediately.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              context.isThai ? 'สแกน QR Code เพื่อรับ Key ทันที' : 'Scan QR Code to Receive Key',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              PeerQrVerificationSheet.show(context, peerId: widget.peer.peerId);
            },
          ),
        ],
      );
    }

    final isChanged = trustState == PeerTrustState.changed;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isChanged ? Colors.orangeAccent : Colors.cyan,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      icon: const Icon(Icons.verified_user_rounded),
      label: Text(
        isChanged
            ? (context.isThai ? 'ยืนยันตัวตน Key ใหม่ (Accept New Key)' : 'Accept New Key')
            : (context.isThai ? 'ยืนยันตัวตนคู่สนทนา (Mark as Verified)' : 'Mark as Verified'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () async {
        await identityService.verifyPeer(
          peerId: widget.peer.peerId,
          displayName: widget.peer.peerName,
          publicKeyHex: widget.peer.publicKeyHex,
        );
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.isThai
                    ? 'ยืนยันตัวตนของ ${widget.peer.peerName} เรียบร้อยแล้ว'
                    : 'Successfully verified ${widget.peer.peerName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      },
    );
  }
}
