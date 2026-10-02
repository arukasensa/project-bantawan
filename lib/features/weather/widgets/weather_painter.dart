// วิดเจ็ต CustomPainter วาดอนุภาคฝุ่นมลพิษในอากาศ (Weather Particle Painter)
// จำลองการเคลื่อนที่ของอนุภาคฝุ่น PM2.5 แบบสุ่ม ทรงกลมฟุ้งเบลอ ลอยตามกระแสลม

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ตัววาดอนุภาคฝุ่นละอองลอยบน Canvas
class WeatherParticlePainter extends CustomPainter {
  /// รายการเม็ดฝุ่นทั้งหมด
  final List<WeatherParticle> particles;

  /// สัดส่วนเวลาแอนิเมชันสำหรับคำนวณตำแหน่งพิกัด
  final double animationValue;

  /// สีหลักของอนุภาคฝุ่น
  final Color baseColor;

  WeatherParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate dynamic position
      double y =
          (particle.y + animationValue * particle.speed * 200) % size.height;
      double x =
          (particle.x + math.sin(animationValue * 2 + particle.x) * 20) %
          size.width;

      final pPaint = Paint()
        ..color = baseColor.withValues(alpha: particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particle.size, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeatherParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  WeatherParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  static List<WeatherParticle> generate(int count) {
    final random = math.Random();
    return List.generate(count, (index) {
      return WeatherParticle(
        x: random.nextDouble() * 1000,
        y: random.nextDouble() * 1000,
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.2,
        opacity: random.nextDouble() * 0.5 + 0.2,
      );
    });
  }
}
