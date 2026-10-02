import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mesh_peer.dart';
import '../services/nearby_service.dart';

/// ============================================================================
/// 🪪 BANTAWAN Offline Tactical Survivor & Emergency Medical Profile Sheet
/// แสดงบัตรประจำตัวฉุกเฉินและข้อมูลทางการแพทย์ของผู้ใช้งานในเครือข่ายออฟไลน์ Mesh
/// ============================================================================
class PeerProfileSheet extends StatelessWidget {
  final MeshPeer peer;
  final NearbyService? service;
  final VoidCallback? onStartChat;

  const PeerProfileSheet({
    super.key,
    required this.peer,
    this.service,
    this.onStartChat,
  });

  static Future<void> show(
    BuildContext context, {
    required MeshPeer peer,
    NearbyService? service,
    VoidCallback? onStartChat,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PeerProfileSheet(
        peer: peer,
        service: service,
        onStartChat: onStartChat,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final status = service != null
        ? service!.getPeerConnectionStatus(peer)
        : peer.connectionStatus;
    final isDirect = status == PeerConnectionStatus.direct;
    final isOnline = status != PeerConnectionStatus.offline;
    final blood = peer.bloodType.isNotEmpty ? peer.bloodType : 'ไม่ระบุ';
    final allergies = peer.allergies.isNotEmpty ? peer.allergies : 'ไม่มีประวัติแพ้ยา/อาหาร';
    final conditions = peer.conditions.isNotEmpty ? peer.conditions : 'ไม่มีโรคประจำตัวที่ระบุ';
    final hospital = peer.hospitalPref.isNotEmpty ? peer.hospitalPref : 'ไม่ระบุโรงพยาบาล';

    // ย่อ Public Key Fingerprint
    final pubKey = peer.publicKeyHex;
    final fingerprint = pubKey.length >= 16
        ? '${pubKey.substring(0, 8)}...${pubKey.substring(pubKey.length - 8)}'
        : (pubKey.isNotEmpty ? pubKey : 'ยังไม่ได้แลกเปลี่ยนกุญแจ');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: BoxDecoration(
            color: const Color(0xFF0F141C).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Header: Avatar + Callsign + Mesh Status
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isDirect
                            ? Colors.blueAccent.withValues(alpha: 0.25)
                            : Colors.purpleAccent.withValues(alpha: 0.25),
                        child: Text(
                          peer.peerName.isNotEmpty
                              ? peer.peerName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDirect ? Colors.blueAccent : Colors.purpleAccent,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F141C), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                peer.peerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: !isOnline
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : (isDirect
                                        ? Colors.blueAccent.withValues(alpha: 0.15)
                                        : Colors.purpleAccent.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: !isOnline
                                      ? Colors.white12
                                      : (isDirect
                                          ? Colors.blueAccent.withValues(alpha: 0.4)
                                          : Colors.purpleAccent.withValues(alpha: 0.4)),
                                ),
                              ),
                              child: Text(
                                !isOnline
                                    ? 'OFFLINE'
                                    : (isDirect ? 'DIRECT 1 HOP' : 'RELAY ${peer.hopCount} HOPS'),
                                style: TextStyle(
                                  color: !isOnline
                                      ? Colors.white38
                                      : (isDirect ? Colors.blueAccent : Colors.purpleAccent),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnline
                              ? '🟢 ออนไลน์อยู่ในรัศมี Mesh Network'
                              : '🟡 ได้ยินสัญญาณล่าสุดเมื่อไม่นานมานี้',
                          style: TextStyle(
                            color: isOnline ? Colors.greenAccent : Colors.amberAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. E2EE Public Key Fingerprint Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(
                      pubKey.isNotEmpty ? Icons.vpn_key_rounded : Icons.vpn_key_off_rounded,
                      color: pubKey.isNotEmpty ? Colors.purpleAccent : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'X25519 PUBLIC KEY FINGERPRINT',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fingerprint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      pubKey.isNotEmpty ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: pubKey.isNotEmpty ? Colors.purpleAccent : Colors.orangeAccent,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Section: Emergency Medical Profile (ICE)
              Row(
                children: [
                  const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ข้อมูลการแพทย์ฉุกเฉิน (IN CASE OF EMERGENCY)',
                    style: TextStyle(
                      color: Colors.redAccent.shade100,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  if (peer.isPrivacyProtected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Colors.amberAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ปิดการแชร์',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (peer.isMinimalShared)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'เฉพาะข้อมูลวิกฤต',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (peer.isPrivacyProtected)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผู้ใช้เปิดโหมดปิดบังข้อมูลสุขภาพ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ข้อมูลทางการแพทย์ถูกเก็บเป็นความลับเฉพาะในเครื่องต้นทางเท่านั้น',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Medical Cards Grid
                Row(
                children: [
                  // Blood Type Card
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'กรุ๊ปเลือด',
                                style: TextStyle(
                                  color: Colors.redAccent.shade100,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            blood,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Organ Donor / Age Card
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Colors.tealAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text(
                                'บริจาคอวัยวะ',
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            peer.isOrganDonor ? 'ยินยอม' : 'ไม่ระบุ',
                            style: TextStyle(
                              color: peer.isOrganDonor ? Colors.tealAccent : Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Allergies Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ประวัติการแพ้ยา / อาหาร',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            allergies,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Medical Conditions Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.monitor_heart_outlined, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'โรคประจำตัว / ข้อควรระวัง',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conditions,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Preferred Hospital Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'โรงพยาบาลที่ต้องการส่งตัว',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hospital,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

              // 5. Action Button: Start E2EE Private Chat
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  onStartChat?.call();
                },
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: Text('เปิดแชทส่วนตัวกับ ${peer.peerName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 6,
                  shadowColor: Colors.purpleAccent.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
