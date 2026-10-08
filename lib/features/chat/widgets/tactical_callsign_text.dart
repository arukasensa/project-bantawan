import 'package:flutter/material.dart';

/// 🏷️ วิดเจ็ตแสดงผล Callsign / ชื่อผู้ใช้แบบ Tactical ปรับแต่งตัวเลขและป้ายแท็กให้อัตโนมัติ
///
/// รองรับการแปลงชื่อรหัสฉุกเฉิน เช่น `Survivor #2281`, `Survivor_2281` หรือ `Survivor 2281`
/// ให้แยกส่วนชื่อ "Survivor" และแท็กหมายเลข "#2281" แสดงผลในกล่อง Badge สีฟ้า Cyan โมเดิร์น
/// สไตล์เกมระดับสากล / Tactical Radio Callsign โดยไม่ให้มีตัวเลขติดกันแบบไม่สวยงาม
class TacticalCallsignText extends StatelessWidget {
  final String name;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color tagColor;
  final bool showLock;
  final Color lockColor;
  final TextOverflow overflow;
  final int? maxLines;
  final MainAxisSize mainAxisSize;

  const TacticalCallsignText({
    super.key,
    required this.name,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.color = Colors.white,
    this.tagColor = Colors.cyanAccent,
    this.showLock = false,
    this.lockColor = const Color(0xFFFFD54F),
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
    this.mainAxisSize = MainAxisSize.min,
  });

  static final RegExp _tagPattern =
      RegExp(r'^(.+?)[_#\s]+([0-9A-Fa-f]{3,5})$');

  @override
  Widget build(BuildContext context) {
    // ตัดอีโมจิกุญแจเดิมออกหากติดมากับ string เพื่อแสดงผลด้วย Vector Icon แทน
    final bool hasEmbeddedLock =
        name.startsWith('🔒') || name.startsWith('🔐');
    final cleanName = name
        .replaceFirst(RegExp(r'^[🔒🔐\s]+'), '')
        .trim();

    final effectiveShowLock = showLock || hasEmbeddedLock;

    // ตรวจสอบว่าชื่อมีรูปแบบ Callsign หรือไม่ เช่น "Survivor #2281", "Survivor_2281"
    final match = _tagPattern.firstMatch(cleanName);

    if (match != null) {
      final baseName = match.group(1)!.trim();
      final tag = match.group(2)!.trim();

      // สัดส่วนขนาดฟอนต์แท็กและระยะ Padding ให้สมดุลกับขนาดฟอนต์หลัก
      final tagFontSize = (fontSize * 0.72).clamp(10.0, 14.0);
      final horizontalPadding = (fontSize * 0.35).clamp(5.0, 8.0);
      final verticalPadding = (fontSize * 0.12).clamp(1.5, 3.5);

      return Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (effectiveShowLock) ...[
            Icon(
              Icons.lock_rounded,
              size: (fontSize * 0.95).clamp(13.0, 20.0),
              color: lockColor,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              baseName,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: 0.3,
              ),
              overflow: overflow,
              maxLines: maxLines,
            ),
          ),
          const SizedBox(width: 6),
          // 🏷️ ป้ายแท็กตัวเลขสไตล์ Tactical Modern Chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: tagColor.withValues(alpha: 0.45),
                width: 0.8,
              ),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: tagColor,
                fontSize: tagFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      );
    }

    // กรณีชื่อจริง หรือชื่อที่ไม่ใช่รูปแบบ Callsign ทั่วไป
    if (effectiveShowLock) {
      return Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_rounded,
            size: (fontSize * 0.95).clamp(13.0, 20.0),
            color: lockColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              cleanName,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: 0.3,
              ),
              overflow: overflow,
              maxLines: maxLines,
            ),
          ),
        ],
      );
    }

    return Text(
      cleanName,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0.3,
      ),
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
