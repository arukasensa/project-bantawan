// ============================================================================
// 🎒 BANTAWAN Data Mule Bag Sheet: DataMuleBagSheet
//
// หน้าต่างกระเป๋าคนส่งสาร แสดงรายการซองจดหมายเข้ารหัส (MuleEnvelope) 
// ที่กำลังช่วยเก็บและแบกเดินทางติดตัวไปส่งให้เพื่อนในพื้นที่ภัยพิบัติ
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import '../models/mule_envelope.dart';
import '../services/nearby_service.dart';
import 'tactical_callsign_text.dart';

/// 🎒 [DataMuleBagSheet]
/// วิดเจ็ตหน้าต่าง Bottom Sheet แสดงข้อมูลกระเป๋าคนเดินสาร (Data Mule Tactical Bag)
/// ช่วยให้ผู้ใช้ตรวจสอบรายการซองจดหมาย E2EE ที่เครื่องตนเองกำลังช่วยหิ้วอยู่
/// รวมถึงการเปิด-ปิดโหมดคนเดินสาร (`toggleDataMule`) และการทิ้งซองจดหมายด้วยตนเอง
class DataMuleBagSheet extends StatelessWidget {
  final NearbyService service;

  const DataMuleBagSheet({super.key, required this.service});

  /// 🚀 เมธอด Static สะดวกใช้สำหรับเปิดแสดงกระเป๋าคนเดินสารจากปุ่มบน Top Bar
  static Future<void> show(BuildContext context, NearbyService service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DataMuleBagSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final envelopes = service.carriedEnvelopes;
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.85),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              const SizedBox(height: 12),
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

              // 2. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.backpack_rounded,
                        color: Colors.amberAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n?.carrierBag ?? (isThai ? 'กระเป๋าคนส่งสาร' : 'Courier Tactical Bag'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isThai
                                      ? '${envelopes.length} ซอง'
                                      : '${envelopes.length} ${envelopes.length == 1 ? 'envelope' : 'envelopes'}',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Store-Carry-and-Forward Mesh Carrier',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 3. Status Switch: Enable/Disable Data Mule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        service.isDataMuleEnabled
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        color: service.isDataMuleEnabled
                            ? Colors.greenAccent
                            : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.isDataMuleEnabled
                              ? (isThai ? 'พร้อมรับฝากซองจดหมายเพื่อนำส่ง' : 'Ready to store and forward envelopes')
                              : (isThai ? 'หยุดพักการรับฝากซองจดหมายชั่วคราว' : 'Store-and-forward temporarily paused'),
                          style: TextStyle(
                            color: service.isDataMuleEnabled
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: service.isDataMuleEnabled,
                        activeThumbColor: Colors.amberAccent,
                        activeTrackColor: Colors.amberAccent.withValues(alpha: 0.3),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          service.toggleDataMule(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),

              // 4. Content List
              Expanded(
                child: envelopes.isEmpty
                    ? _buildEmptyState(context, isThai, l10n)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        itemCount: envelopes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final env = envelopes[index];
                          return _buildEnvelopeCard(context, env, isThai);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isThai, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.backpack_outlined,
                color: Colors.white38,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.offlineBagEmpty ?? (isThai ? 'ยังไม่มีซองจดหมายในกระเป๋า' : 'Your tactical bag is currently empty'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isThai
                  ? 'เมื่อเพื่อนฝากข้อความส่งให้คนที่อยู่นอกระยะ\nซองจดหมายเข้ารหัสจะถูกเก็บไว้ที่นี่เพื่อนำไปส่งมอบให้เมื่อเดินเข้าใกล้'
                  : 'When peers entrust offline messages destined for unreachable nodes,\nencrypted envelopes will be stored here and delivered upon physical encounter.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeCard(BuildContext context, MuleEnvelope env, bool isThai) {
    final hoursLeft = env.expiresAt.difference(DateTime.now()).inHours;
    final recipientCallsign = NearbyService.generateTacticalCallsign(env.recipientNodeId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: env.isUrgentSOS
              ? Colors.redAccent.withValues(alpha: 0.4)
              : Colors.amberAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: env.isUrgentSOS
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      env.isUrgentSOS ? Icons.warning_rounded : Icons.lock_rounded,
                      color: env.isUrgentSOS ? Colors.redAccent : Colors.amberAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      env.isUrgentSOS
                          ? (isThai ? '🚨 ข้อความฉุกเฉิน SOS' : '🚨 Emergency SOS')
                          : (isThai ? '🔒 ซองจดหมาย E2EE' : '🔒 E2EE Envelope'),
                      style: TextStyle(
                        color: env.isUrgentSOS ? Colors.redAccent : Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (env.hopCarryCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isThai ? '🔄 ทอดที่ ${env.hopCarryCount + 1}' : '🔄 Hop ${env.hopCarryCount + 1}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                hoursLeft > 0
                    ? (isThai ? 'หมดอายุในอีก $hoursLeft ชม.' : 'Expires in ${hoursLeft}h')
                    : (isThai ? 'ใกล้หมดอายุ' : 'Expiring soon'),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 6),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                tooltip: isThai ? 'ทิ้งซองจดหมายนี้' : 'Discard this envelope',
                onPressed: () => _confirmDelete(context, env, isThai),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                '${isThai ? 'ส่งถึง' : 'To'}: ',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Expanded(
                child: TacticalCallsignText(
                  name: recipientCallsign,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                '${isThai ? 'ผู้ฝาก' : 'From'}: ',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: TacticalCallsignText(
                  name: env.senderCallsign,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded, color: Colors.amberAccent, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isThai
                        ? 'จะส่งมอบอัตโนมัติทันทีที่ตรวจพบเครื่องเป้าหมาย'
                        : 'Will be automatically delivered once target peer is detected',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MuleEnvelope env, bool isThai) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F2E),
        title: Text(
          isThai ? 'ทิ้งซองจดหมายนี้?' : 'Discard this envelope?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isThai
              ? 'ซองจดหมายที่ฝากไปส่งให้ ${env.recipientNodeId} จะถูกลบออกจากเครื่องของคุณ'
              : 'The envelope addressed to ${env.recipientNodeId} will be removed from your device.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n?.cancelButton ?? (isThai ? 'ยกเลิก' : 'Cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await service.deleteCarriedEnvelope(env.envelopeId);
            },
            child: Text(
              isThai ? 'ลบออก' : 'Discard',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
