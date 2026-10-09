import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mesh_peer.dart';
import '../services/nearby_service.dart';

/// ============================================================================
/// 🛰️ Tactical Mesh Relay Status & Field Diagnostic Sheet
/// หน้าต่างแสดงผลสถิติและสถานะการทำงานของสะพานรีเลย์ (Multi-Hop Mesh Bridge)
/// สำหรับตรวจสอบภาคสนามว่า Node B มี 2 ลิงก์เชื่อมต่อจริง และกำลังส่งต่อข้อมูลหรือไม่
/// ============================================================================
class MeshRelayStatusSheet extends StatefulWidget {
  const MeshRelayStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MeshRelayStatusSheet(),
    );
  }

  @override
  State<MeshRelayStatusSheet> createState() => _MeshRelayStatusSheetState();
}

class _MeshRelayStatusSheetState extends State<MeshRelayStatusSheet> {
  String? _testingPeerId;
  bool _isProbing = false;

  Future<void> _runTraceRoute(NearbyService service, String peerId, String peerName) async {
    setState(() {
      _testingPeerId = peerId;
      _isProbing = true;
    });
    HapticFeedback.mediumImpact();

    final sent = await service.sendTraceRouteProbe(peerId);
    if (!mounted) return;

    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ไม่สามารถส่ง Trace Probe ไปยัง $peerName ได้ (ไม่มีเส้นทาง)'),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isProbing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<NearbyService>();

    final directCount = service.connectedDevices.length;
    final isBridge = service.isRelayBridgeActive;

    final relayedPeers = service.discoveredMeshPeers.values.where((p) {
      return p.hopCount > 1 &&
          service.getPeerConnectionStatus(p) != PeerConnectionStatus.offline;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Deep Slate Navy
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isBridge ? Colors.purpleAccent.withValues(alpha: 0.4) : Colors.cyanAccent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBridge ? Colors.purpleAccent : Colors.cyanAccent).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isBridge
                          ? Colors.purpleAccent.withValues(alpha: 0.15)
                          : Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBridge ? Icons.alt_route_rounded : Icons.radar_rounded,
                      color: isBridge ? Colors.purpleAccent : Colors.cyanAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สถานะเครือข่าย MESH RELAY',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBridge
                              ? '🟢 เครื่องนี้ทำหน้าที่เป็น "สะพานรีเลย์กลาง (Node B)"'
                              : 'โหนดปลายทาง (End Node)',
                          style: TextStyle(
                            color: isBridge ? Colors.greenAccent : Colors.white60,
                            fontSize: 12,
                            fontWeight: isBridge ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 📊 Card 1: Live Link Topology Counters
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'ต่อตรง (Direct BLE)',
                      value: '$directCount / 4',
                      subtext: directCount >= 2 ? 'เชื่อมต่อครบ 2 ฝั่ง' : (directCount == 1 ? 'ต่อตรง 1 ฝั่ง' : 'ยังไม่มีใครต่อ'),
                      color: directCount >= 2 ? Colors.greenAccent : Colors.blueAccent,
                      icon: Icons.bluetooth_connected_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'โหนดรีเลย์ (2+ Hops)',
                      value: '${relayedPeers.length}',
                      subtext: relayedPeers.isNotEmpty ? 'ได้ยินผ่านสะพาน' : 'ไม่มีโหนดไกล',
                      color: Colors.purpleAccent,
                      icon: Icons.hub_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 📦 Card 2: Packet Forwarding Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sync_alt_rounded, size: 18, color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        Text(
                          'สถิติการส่งต่อข้อมูล (Forwarding Metrics)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat(
                          'ส่งต่อทั้งหมด',
                          '${service.relayedPacketCount}',
                          Colors.cyanAccent,
                        ),
                        _buildSubStat(
                          'แชทสาธารณะ (Public)',
                          '${service.relayedPublicCount}',
                          Colors.lightBlueAccent,
                        ),
                        _buildSubStat(
                          'แชทส่วนตัว (E2EE)',
                          '${service.relayedPrivateCount}',
                          Colors.purpleAccent,
                        ),
                      ],
                    ),
                    if (service.lastRelayedPacketInfo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'แพ็กเก็ตล่าสุด: ${service.lastRelayedPacketInfo}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 🛰️ Trace Route Result Banner (ถ้ามี)
              if (service.lastTraceAckResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.lastTraceAckResult!,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 🔗 Direct Connections List
              Text(
                'โหนดที่เชื่อมต่อตรงกับเครื่องนี้ (1-Hop Links):',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (service.connectedDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'ยังไม่มีอุปกรณ์ใดเชื่อมต่อตรงในขณะนี้\n(กรุณารอการจับคู่บลูทูธ 30-60 วินาที)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                )
              else
                ...service.connectedDevices.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Endpoint: ${entry.key}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DIRECT 1-HOP',
                            style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // 🟣 Relayed Peers List
              Text(
                'โหนดที่มองเห็นผ่าน Mesh Relay (2+ Hops):',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (relayedPeers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'ไม่มีโหนดที่ได้ยินผ่านคนกลางในขณะนี้\n(โหนดปลายทางจะปรากฏเมื่อเครื่องกลางส่ง Announce มา)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                )
              else
                ...relayedPeers.map((peer) {
                  final isCurrentlyTesting = _isProbing && _testingPeerId == peer.peerId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.purpleAccent, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                peer.peerName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Node ID: ${peer.peerId}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: isCurrentlyTesting
                              ? null
                              : () => _runTraceRoute(service, peer.peerId, peer.peerName),
                          icon: isCurrentlyTesting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                                )
                              : const Icon(Icons.send_rounded, size: 12),
                          label: Text(
                            isCurrentlyTesting ? 'กำลังยิง...' : 'ยิง Trace Test',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purpleAccent,
                            side: const BorderSide(color: Colors.purpleAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
