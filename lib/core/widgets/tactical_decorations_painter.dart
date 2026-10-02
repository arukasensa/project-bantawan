// วิดเจ็ต CustomPainter ตกแต่ง UI ลุค Tactical / Survival
// ประกอบด้วยเอฟเฟกต์แสงสแกนเนอร์เรดาร์ (TacticalScanPainter), ตารางพิกัด (TacticalGridPainter), และมุมกรอบเล็งเป้า (TacticalCornerPainter)

import 'package:flutter/material.dart';

/// ตัววาดเส้นสแกนเรดาร์เคลื่อนที่แนวดิ่ง (Radar Scanline Effect)
class TacticalScanPainter extends CustomPainter {
  /// ค่าสัดส่วนตำแหน่งของลำแสงสแกน (0.0 ถึง 1.0)
  final double animationValue;

  /// สีหลักของลำแสงสแกน
  final Color color;

  TacticalScanPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final yPos = size.height * animationValue;
    const scanHeight = 40.0;

    // Draw the scanning band
    canvas.drawRect(
      Rect.fromLTRB(
        0,
        yPos - scanHeight / 2,
        size.width,
        yPos + scanHeight / 2,
      ),
      paint,
    );

    // Draw the sharp scan line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), linePaint);
  }

  @override
  bool shouldRepaint(TacticalScanPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}

class TacticalGridPainter extends CustomPainter {
  final Color color;
  final double opactiy;

  TacticalGridPainter({required this.color, this.opactiy = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opactiy)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TacticalCornerPainter extends CustomPainter {
  final Color color;
  final double length;

  TacticalCornerPainter({required this.color, this.length = 15.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

    // Top Left
    canvas.drawLine(Offset.zero, Offset(length, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, length), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
