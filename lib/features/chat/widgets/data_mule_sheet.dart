// ============================================================================
// 🎒 BANTAWAN Data Mule Management Sheet: DataMuleSheet
// 
// แผงควบคุมและจัดการระบบ "คนเดินสาร" (Store-Carry-and-Forward Mesh Carrier)
// ช่วยให้ผู้ใช้เปิด/ปิดโหมดอาสาสมัคร, ตรวจดูซองจดหมายที่กำลังช่วยแบก, และจัดการพื้นที่
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mule_envelope.dart';
import '../services/nearby_service.dart';
import '../services/chat_database_helper.dart';
import '../services/identity_service.dart';

class DataMuleSheet extends StatefulWidget {
  final NearbyService service;

  const DataMuleSheet({
    super.key,
    required this.service,
  });

  static Future<void> show(BuildContext context, NearbyService service) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DataMuleSheet(service: service),
    );
  }

  @override
  State<DataMuleSheet> createState() => _DataMuleSheetState();
}

class _DataMuleSheetState extends State<DataMuleSheet> {
  Map<String, int> _stats = {'count': 0, 'urgentCount': 0, 'totalSizeBytes': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    setState(() => _isLoading = true);
    await widget.service.loadCarriedEnvelopes();
    final stats = await ChatDatabaseHelper.instance.getMuleStorageStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteEnvelope(String envelopeId) async {
    HapticFeedback.mediumImpact();
    await ChatDatabaseHelper.instance.deleteMuleEnvelope(envelopeId);
    await _refreshStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ลบซองจดหมายออกจากเครื่องเรียบร้อยแล้ว'),
          backgroundColor: Colors.purple.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handlePurgeExpired() async {
    HapticFeedback.selectionClick();
    final purged = await ChatDatabaseHelper.instance.purgeExpiredMuleEnvelopes();
    await _refreshStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧹 ล้างซองจดหมายหมดอายุ/ส่งแล้ว $purged รายการ'),
          backgroundColor: Colors.indigo.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final envelopes = widget.service.carriedEnvelopes;
    final isEnabled = widget.service.isDataMuleEnabled;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF10141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle Bar ด้านบน
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.purpleAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text('🎒', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'อาสาสมัครคนเดินสาร',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Data Mule Mesh • นำส่งสารข้ามพื้นที่แบบ Zero-Knowledge',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
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
              ),

              const Divider(color: Colors.white10, height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // สวิตช์เปิด/ปิดโหมดคนเดินสาร
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isEnabled
                              ? Colors.purpleAccent.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'โหมดรับฝากส่งสารฉุกเฉิน',
                                        style: TextStyle(
                                          color: isEnabled ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isEnabled
                                            ? Colors.greenAccent.withValues(alpha: 0.15)
                                            : Colors.white12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isEnabled ? 'เปิดใช้งาน' : 'ปิดอยู่',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isEnabled ? Colors.greenAccent : Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ยินยอมให้เครื่องช่วยรับฝากซองจดหมายเข้ารหัสจากผู้ประสบภัยรอบข้าง เพื่อนำไปส่งมอบให้ผู้รับปลายทางเมื่อคุณเดินผ่านจุดที่มีสัญญาณ (ปลอดภัย 100% คนกลางไม่สามารถแอบอ่านได้)',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: isEnabled,
                            activeThumbColor: Colors.purpleAccent,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              widget.service.toggleDataMule(val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // กล่องสถิติความจุ (Storage Quota Stats)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'ซองในกระเป๋า',
                            value: '${_stats['count'] ?? 0} ซอง',
                            icon: Icons.backpack_rounded,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'ฉุกเฉิน SOS',
                            value: '${_stats['urgentCount'] ?? 0} ซอง',
                            icon: Icons.emergency_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'ขนาดข้อมูล',
                            value: '${((_stats['totalSizeBytes'] ?? 0) / 1024).toStringAsFixed(1)} KB',
                            icon: Icons.storage_rounded,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // รายการซองจดหมายที่กำลังช่วยแบก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ซองจดหมายที่กำลังช่วยนำส่ง (Envelopes)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (envelopes.isNotEmpty)
                          TextButton.icon(
                            onPressed: _handlePurgeExpired,
                            icon: const Icon(Icons.cleaning_services_rounded, size: 14, color: Colors.white54),
                            label: const Text(
                              'ล้างที่หมดอายุ',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: Colors.purpleAccent),
                        ),
                      )
                    else if (envelopes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.all_inbox_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'กระเป๋าส่งสารว่างเปล่า',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ยังไม่มีซองจดหมายค้างในเครื่อง เมื่อคุณเดินผ่านผู้ประสบภัยที่ไม่มีสัญญาณ เครื่องจะช่วยรับฝากซองจดหมายเข้ารหัสอัตโนมัติ',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: envelopes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final env = envelopes[index];
                          return _buildEnvelopeCard(env);
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveRecipientName(String nodeId) {
    if (nodeId == '@RESCUE_TEAM' || nodeId == '@PUBLIC_SOS') return null;
    // 1. จาก IdentityService Trust Store
    final trust = IdentityService.instance.getStoredTrust(nodeId);
    if (trust != null && trust.displayName.isNotEmpty) {
      return trust.displayName;
    }
    // 2. จาก discoveredMeshPeers
    final peer = widget.service.discoveredMeshPeers[nodeId];
    if (peer != null && peer.peerName.isNotEmpty && !peer.peerName.startsWith('node_')) {
      return peer.peerName;
    }
    // 3. จากประวัติข้อความแชท
    for (final msg in widget.service.messages) {
      if (msg.recipientId == nodeId &&
          msg.recipientName != null &&
          msg.recipientName!.isNotEmpty &&
          !msg.recipientName!.startsWith('node_')) {
        return msg.recipientName;
      }
      if (msg.senderId == nodeId &&
          msg.senderName.isNotEmpty &&
          !msg.senderName.startsWith('node_')) {
        return msg.senderName;
      }
    }
    return null;
  }

  Widget _buildEnvelopeCard(MuleEnvelope env) {
    final isSOS = env.isUrgentSOS;
    final hoursLeft = env.expiresAt.difference(DateTime.now()).inHours;
    final String targetLabel;
    if (env.recipientNodeId == '@RESCUE_TEAM') {
      targetLabel = '🚨 ศูนย์กู้ภัย / ทีมช่วยเหลือ';
    } else if (env.recipientNodeId == '@PUBLIC_SOS') {
      targetLabel = '📢 สัญญาณแจ้งเหตุสาธารณะ';
    } else {
      final friendlyName = _resolveRecipientName(env.recipientNodeId);
      if (friendlyName != null && friendlyName.isNotEmpty) {
        targetLabel = '$friendlyName (@${env.recipientNodeId})';
      } else {
        targetLabel = '@${env.recipientNodeId}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSOS
            ? Colors.redAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSOS
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.purpleAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSOS
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : Colors.purpleAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSOS ? Icons.warning_rounded : Icons.mark_email_unread_rounded,
              size: 18,
              color: isSOS ? Colors.redAccent : Colors.purpleAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'จาก: ${env.senderCallsign}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSOS)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ส่งถึง: $targetLabel',
                  style: TextStyle(
                    color: isSOS ? Colors.redAccent.shade100 : Colors.purpleAccent.shade100,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 11, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      hoursLeft > 0 ? 'หมดอายุในอีก $hoursLeft ชม.' : 'หมดอายุแล้ว',
                      style: TextStyle(
                        fontSize: 10,
                        color: hoursLeft > 0 ? Colors.white38 : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.lock_rounded, size: 11, color: Colors.white38),
                    const SizedBox(width: 3),
                    const Text(
                      'E2EE เข้ารหัสลับ',
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white38),
            tooltip: 'ลบออกจากเครื่อง',
            onPressed: () => _handleDeleteEnvelope(env.envelopeId),
          ),
        ],
      ),
    );
  }
}
