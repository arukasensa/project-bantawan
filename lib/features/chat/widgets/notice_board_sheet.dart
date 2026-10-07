// ============================================================================
// 📌 BANTAWAN Offline Mesh Notice Board Sheet (ประกาศ @ #mesh)
// สไตล์ bitchat: กระดานปักประกาศฉุกเฉินสาธารณะออฟไลน์ กระจายต่อแบบ Epidemic Gossip
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mesh_notice.dart';
import '../services/nearby_service.dart';

/// 📌 [NoticeBoardSheet] กระดานปักประกาศฉุกเฉินสาธารณะออฟไลน์ (Offline Mesh Bulletin Board)
/// ออกแบบตามแนวคิด Epidemic Gossip Protocol สำหรับกระจายข่าวสารเตือนภัยในพื้นที่ประสบภัย:
/// - โพสต์ประกาศฉุกเฉินหรือแจ้งข่าวสารทั่วไปในห้อง `#mesh` โดยไม่ต้องพึ่งพาเซิร์ฟเวอร์
/// - กำหนดระยะเวลาหมดอายุของประกาศได้ (1 วัน, 3 วัน, 7 วัน) เพื่อป้องกันข้อมูลเก่าคั่งค้าง
/// - ไฮไลต์ประกาศด่วนวิกฤต (SOS / Urgent Notice) ด้วยสีกรอบและเอฟเฟกต์สะดุดตา
/// - มีระบบแชร์พิกัดจุดเกิดเหตุ/จุดแจกจ่ายเสบียงประกอบในประกาศ
class NoticeBoardSheet extends StatefulWidget {
  final NearbyService service;

  const NoticeBoardSheet({
    super.key,
    required this.service,
  });

  /// 🚀 แสดงหน้าต่างกระดานประกาศ [NoticeBoardSheet] ในรูปแบบ Modal Bottom Sheet
  static Future<void> show(BuildContext context, NearbyService service) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoticeBoardSheet(service: service),
    );
  }

  @override
  State<NoticeBoardSheet> createState() => _NoticeBoardSheetState();
}

class _NoticeBoardSheetState extends State<NoticeBoardSheet> {
  final TextEditingController _contentController = TextEditingController();
  bool _isUrgent = false;
  Duration _selectedDuration = const Duration(days: 1); // 1d, 3d, 7d
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 📢 [Post Notice Handler]
  /// ประมวลผลการโพสต์ประกาศใหม่ขึ้นบนเครือข่ายออฟไลน์:
  /// 1. ตรวจสอบข้อความไม่เป็นค่าว่าง
  /// 2. เรียกใช้ [NearbyService.postNotice] เพื่อบันทึกลง SQLite และบรอดแคสต์แพ็กเก็ต `MESH_NOTICE`
  /// 3. รีเซ็ตฟอร์มและสถานะความเร่งด่วนกลับเป็นค่าเริ่มต้น
  Future<void> _handlePostNotice() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();

    try {
      await widget.service.postNotice(
        content: text,
        expiresIn: _selectedDuration,
        isUrgent: _isUrgent,
      );

      _contentController.clear();
      setState(() {
        _isUrgent = false;
        _isPosting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isUrgent
                        ? '🚨 ปักประกาศฉุกเฉินและกระจายสัญญาณไปยังทุกโหนดแล้ว'
                        : '📌 ปักประกาศออฟไลน์สำเร็จ กระจายต่อแบบ Peer-to-Peer',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF161B26),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: _isUrgent ? Colors.redAccent.withValues(alpha: 0.5) : Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการปักประกาศ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteNotice(MeshNotice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141926),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'ลบประกาศนี้?',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'ประกาศจะถูกลบออกจากเครื่องของคุณและไม่ถูกส่งต่อไปยังโหนดอื่นอีก',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบประกาศ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await widget.service.deleteNotice(notice.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF0D121F).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Top drag bar & header
              _buildHeader(context),

              // Notices list
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.service,
                  builder: (context, _) {
                    final notices = widget.service.notices;
                    if (notices.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildNoticeCard(notices[index]);
                      },
                    );
                  },
                ),
              ),

              // Bottom Input Composer
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _buildComposer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.cyanAccent, size: 24),
              const SizedBox(width: 8),
              const Text(
                'ประกาศ @ #mesh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ปักประกาศสั้น ๆ ให้คนรอบตัว ส่งต่อจากมือถือสู่มือถือได้แม้ออฟไลน์ และหายไปเองหลังผ่านไปสองสามวัน',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.08),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.push_pin_outlined,
                size: 40,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ยังไม่มีประกาศในรัศมีโครงข่าย',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เขียนข้อความประกาศคนแรกด้านล่างเพื่อกระจายข่าวสารสำคัญ แจ้งจุดนัดพบ หรือขอความช่วยเหลือแม้ออฟไลน์',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(MeshNotice notice) {
    final isMyNotice = notice.authorId == widget.service.nodeId;
    final isUrgent = notice.isUrgent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFF281118).withValues(alpha: 0.7)
            : const Color(0xFF141A29).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? Colors.redAccent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Badge Row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isUrgent
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : Colors.cyanAccent.withValues(alpha: 0.15),
                child: Text(
                  notice.authorName.isNotEmpty
                      ? notice.authorName.characters.first.toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isUrgent ? Colors.redAccent : Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            notice.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMyNotice) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'ของคุณ',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'ด่วนพิเศษ',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isMyNotice)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'ลบประกาศ',
                  onPressed: () => _confirmDeleteNotice(notice),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Notice Content
          SelectableText(
            notice.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 12),

          // Metadata Footer (Hop & Expiry Countdown)
          Row(
            children: [
              // Hop count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      notice.hopCount == 1 ? Icons.wifi_tethering_rounded : Icons.alt_route_rounded,
                      size: 11,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.hopCount == 1 ? 'ได้ยินตรง' : '${notice.hopCount} ทอด',
                      style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Expiry countdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: isUrgent ? Colors.redAccent.withValues(alpha: 0.8) : Colors.amberAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.remainingTimeFormatted,
                    style: TextStyle(
                      color: isUrgent ? Colors.redAccent.withValues(alpha: 0.9) : Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D17),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isUrgent
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'เขียนข้อความประกาศสั้น ๆ ส่งต่อทุกคน...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action row: Urgent switch, Expiry chips, Send button
          Row(
            children: [
              // Urgent Toggle Button
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isUrgent = !_isUrgent);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isUrgent
                        ? Colors.redAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isUrgent
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: _isUrgent ? Colors.redAccent : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ฉุกเฉิน',
                        style: TextStyle(
                          color: _isUrgent ? Colors.redAccent : Colors.white70,
                          fontSize: 12,
                          fontWeight: _isUrgent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Expiry Duration Chips
              _buildDurationChip(const Duration(days: 1), '1 วัน'),
              const SizedBox(width: 4),
              _buildDurationChip(const Duration(days: 3), '3 วัน'),
              const SizedBox(width: 4),
              _buildDurationChip(const Duration(days: 7), '7 วัน'),

              const Spacer(),

              // Submit / Post Button
              ElevatedButton(
                onPressed: _isPosting ? null : _handlePostNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUrgent ? Colors.redAccent : const Color(0xFF00ADB5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'ปักประกาศ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(Duration duration, String label) {
    final isSelected = _selectedDuration == duration;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDuration = duration);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
