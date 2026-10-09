import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';
import '../models/hike_summary.dart';

/// 🏆 หน้าต่างสรุปผลกิจกรรมการเดินป่า (Hike Summary Dialog)
class HikeSummaryDialog extends StatelessWidget {
  final HikeSummary summary;
  final VoidCallback onDismiss;

  const HikeSummaryDialog({
    super.key,
    required this.summary,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ไอคอนถ้วยรางวัล / ยอดเขา
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: Colors.greenAccent,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  context.isThai
                      ? 'สิ้นสุดการเดินป่าสำเร็จ!'
                      : 'Hike Adventure Completed!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  context.isThai
                      ? 'ข้อมูลเส้นทางและสถิติการผจญภัยของคุณ'
                      : 'Your trail track & adventure statistics',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),

                const SizedBox(height: 24),

                // แผงกริดสถิติ 4 ช่อง
                Row(
                  children: [
                    _buildStatTile(
                      icon: Icons.route_rounded,
                      label: context.isThai ? 'ระยะทางรวม' : 'Total Distance',
                      value: summary.formattedDistance,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatTile(
                      icon: Icons.timer_outlined,
                      label: context.isThai ? 'เวลาที่ใช้' : 'Duration',
                      value: summary.formattedDuration,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildStatTile(
                      icon: Icons.terrain_rounded,
                      label: context.isThai ? 'ระดับความสูงสูงสุด' : 'Max Elevation',
                      value: summary.maxAltitude != null
                          ? '${summary.maxAltitude!.toStringAsFixed(0)} ${context.isThai ? 'ม.' : 'm'}'
                          : '--',
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatTile(
                      icon: Icons.flag_circle_rounded,
                      label: context.isThai ? 'จุดบันทึกรอยทาง' : 'Trail Points',
                      value: '${summary.breadcrumbCount} ${context.isThai ? 'จุด' : 'pts'}',
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ปุ่มยืนยันเสร็จสิ้น
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context); // ปิด Dialog
                      onDismiss(); // ออกจากหน้าจอเดินป่า
                    },
                    child: Text(
                      context.isThai
                          ? 'บันทึกและกลับสู่หน้าหลัก'
                          : 'Save & Return to Home',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
