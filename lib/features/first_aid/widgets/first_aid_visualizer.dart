// วิดเจ็ตแอนิเมชันภาพเคลื่อนไหวแสดงขั้นตอนการปฐมพยาบาล (First Aid Visualizer)
// จำลองภาพกราฟิก Vector แบบเคลื่อนไหว (เช่น จังหวะปั๊มหัวใจ CPR, การกดห้ามเลือด, การเข้าเฝือก)

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// วิดเจ็ตแสดงภาพกราฟิกเคลื่อนไหวประกอบขั้นตอนการปฐมพยาบาล
class FirstAidVisualizer extends StatefulWidget {
  final String visualType;
  final Color themeColor;

  const FirstAidVisualizer({
    super.key,
    required this.visualType,
    required this.themeColor,
  });

  @override
  State<FirstAidVisualizer> createState() => _FirstAidVisualizerState();
}

/// State ควบคุมรอบลูปแอนิเมชันของภาพประกอบปฐมพยาบาล
class _FirstAidVisualizerState extends State<FirstAidVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.themeColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(color: widget.themeColor.withValues(alpha: 0.05)),
              ),
            ),
            // The dynamic visualization
            _buildVisualContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualContent() {
    switch (widget.visualType) {
      case 'call_1669':
        return _buildCall1669();
      case 'pulse':
        return _buildPulseECG();
      case 'positioning':
        return _buildPositioning();
      case 'elevation':
      case 'legs_elevated':
        return _buildElevation();
      case 'bandage':
      case 'burn_care':
        return _buildBandage();
      case 'remove_tight':
        return _buildRemoveTight();
      case 'cover_burn':
        return _buildCoverBurn();
      case 'immobilize':
        return _buildImmobilize();
      case 'splinting':
        return _buildSplinting();
      case 'cold_pack':
      case 'ice_pack':
      case 'cool_towel':
        return _buildColdPack();
      case 'rescue_gear':
        return _buildRescueGear();
      case 'check_breathing':
      case 'fresh_air':
        return _buildBreathingAir();
      case 'clean_water':
        return _buildCleanWater();
      case 'hospital_go':
        return _buildHospitalGo();
      case 'loosen_clothing':
        return _buildLoosenClothing();
      case 'shade':
        return _buildShade();
      case 'cut_power':
        return _buildCutPower();
      case 'chemical_id':
        return _buildChemicalId();
      case 'tilt_recovery':
        return _buildTiltRecovery();
      case 'bee_sting':
        return _buildBeeSting();
      case 'epipen':
        return _buildEpiPen();
      default:
        return Icon(
          Icons.medical_services_rounded,
          color: widget.themeColor.withValues(alpha: 0.5),
          size: 50,
        );
    }
  }

  // 1. Call 1669 Layout
  Widget _buildCall1669() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double pulse = 1.0 + 0.12 * math.sin(_controller.value * 2 * math.pi);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.25 * pulse),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'สายด่วนฉุกเฉิน 1669',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. Pulse ECG Live Waveform
  Widget _buildPulseECG() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ECGPainter(
              progress: _controller.value,
              color: widget.themeColor,
            ),
          );
        },
      ),
    );
  }

  // 3. Positioning
  Widget _buildPositioning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.accessibility_new_rounded,
          color: widget.themeColor,
          size: 48,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded, color: widget.themeColor.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 5),
            const Text(
              'โน้มตัวผู้ป่วยไปด้านหน้าเล็กน้อย',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // 4. Elevation
  Widget _buildElevation() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = 8 * math.sin(_controller.value * 2 * math.pi);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -offset),
              child: Icon(
                Icons.upgrade_rounded,
                color: widget.themeColor,
                size: 54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ยกอวัยวะให้สูงกว่าระดับหัวใจ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  // 5. Bandage / Wound wrap
  Widget _buildBandage() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.themeColor.withValues(alpha: 0.2),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.healing_rounded,
              color: widget.themeColor,
              size: 48,
            ),
          ],
        );
      },
    );
  }

  // 6. Remove Tight Items
  Widget _buildRemoveTight() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCrossedIcon(Icons.watch_rounded, 'นาฬิกา'),
        const SizedBox(width: 30),
        _buildCrossedIcon(Icons.blur_circular_rounded, 'แหวน'),
      ],
    );
  }

  Widget _buildCrossedIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white24, size: 40),
            Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 45,
                height: 4,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  // 7. Cover Burn with Plastic Wrap
  Widget _buildCoverBurn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.layers_clear_rounded,
          color: widget.themeColor,
          size: 48,
        ),
        const SizedBox(height: 10),
        const Text(
          'ปิดแผลหลวมๆ ด้วยพลาสติกใส/ผ้าสะอาด',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // 8. Immobilize
  Widget _buildImmobilize() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double opacity = 0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              color: widget.themeColor.withValues(alpha: opacity),
              size: 48,
            ),
            const SizedBox(height: 10),
            const Text(
              'จัดให้นิ่งที่สุด / ห้ามเคลื่อนย้าย',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  // 9. Splinting
  Widget _buildSplinting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 80,
          decoration: BoxDecoration(
            color: widget.themeColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 15),
        const Icon(Icons.accessibility_new_rounded, color: Colors.white38, size: 48),
        const SizedBox(width: 15),
        Container(
          width: 8,
          height: 80,
          decoration: BoxDecoration(
            color: widget.themeColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // 10. Cold Pack
  Widget _buildColdPack() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double rotation = _controller.value * 2 * math.pi;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: rotation * 0.2,
              child: const Icon(
                Icons.ac_unit_rounded,
                color: Colors.lightBlueAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ประคบเย็นเพื่อลดบวม/ความร้อน',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        );
      },
    );
  }

  // 11. Rescue Gear (Reach, Throw)
  Widget _buildRescueGear() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double scale = 1.0 + 0.1 * math.sin(_controller.value * 2 * math.pi);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Icon(
                Icons.waves_rounded,
                color: widget.themeColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ยื่นอุปกรณ์ลอยตัว/ห่วงชูชีพ',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        );
      },
    );
  }

  // 12. Breathing Air Flow
  Widget _buildBreathingAir() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AirFlowPainter(
              progress: _controller.value,
              color: widget.themeColor,
            ),
          );
        },
      ),
    );
  }

  // 13. Clean Water
  Widget _buildCleanWater() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaterPainter(
              progress: _controller.value,
              color: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  // 14. Hospital/Ambulance Go
  Widget _buildHospitalGo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double screenWidth = 260.0;
        double xOffset = -screenWidth / 2 + (screenWidth * _controller.value);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(xOffset, 0),
              child: Icon(
                Icons.local_shipping_rounded,
                color: widget.themeColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'รีบนำส่งโรงพยาบาลฉุกเฉิน',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        );
      },
    );
  }

  // 15. Loosen clothing
  Widget _buildLoosenClothing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.checkroom_rounded,
          color: widget.themeColor,
          size: 48,
        ),
        const SizedBox(height: 10),
        const Text(
          'ปลดกระดุม/คลายเสื้อผ้าให้หลวม',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // 16. Shade Cloud/Sun
  Widget _buildShade() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_queue_rounded,
          color: widget.themeColor,
          size: 48,
        ),
        const SizedBox(height: 10),
        const Text(
          'ย้ายเข้าที่ร่มและมีลมโกรก',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // 17. Cut Power
  Widget _buildCutPower() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        bool flash = _controller.value * 10 % 2 > 1;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_off_rounded,
              color: flash ? Colors.yellowAccent : Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 10),
            const Text(
              'สับคัตเอาท์/ตัดแหล่งกระแสไฟ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  // 18. Chemical Bottle/ID
  Widget _buildChemicalId() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.science_rounded,
          color: widget.themeColor,
          size: 48,
        ),
        const SizedBox(height: 10),
        const Text(
          'ตรวจสอบขวด/ฉลากสารเคมีที่ได้รับ',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // 19. Recovery Position (Tilt on side)
  Widget _buildTiltRecovery() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -math.pi / 2,
          child: Icon(
            Icons.accessibility_new_rounded,
            color: widget.themeColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'จัดท่านอนตะแคงข้าง เพื่อป้องกันการสำลัก',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // 20. Bee Sting
  Widget _buildBeeSting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.bug_report_rounded,
          color: Colors.amber,
          size: 48,
        ),
        const SizedBox(height: 10),
        Text(
          'สังเกตจุดแมลงกัดต่อย/ปฏิกิริยาบวม',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
      ],
    );
  }

  // 21. EpiPen Injection
  Widget _buildEpiPen() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double offset = 12 * math.sin(_controller.value * 2 * math.pi);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, offset.abs()),
              child: Icon(
                Icons.colorize_rounded,
                color: widget.themeColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ฉีดยา EpiPen เข้ากล้ามเนื้อต้นขา',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Custom Painters for Animations
// ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    double gridSpacing = 20.0;
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ECGPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ECGPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double midY = size.height / 2;
    double width = size.width;

    path.moveTo(0, midY);

    // Dynamic ECG path points
    List<Offset> points = [];
    double pulseStart = width * 0.35;
    double pulseEnd = width * 0.65;

    for (double x = 0; x <= width; x += 1) {
      double y = midY;
      if (x > pulseStart && x < pulseEnd) {
        double relX = (x - pulseStart) / (pulseEnd - pulseStart); // 0 to 1
        // Form heart beat shape
        if (relX < 0.2) {
          y = midY; // normal
        } else if (relX < 0.3) {
          y = midY - 10; // P wave
        } else if (relX < 0.4) {
          y = midY;
        } else if (relX < 0.45) {
          y = midY + 15; // Q wave
        } else if (relX < 0.55) {
          y = midY - 60; // R wave (sharp peak)
        } else if (relX < 0.65) {
          y = midY + 40; // S wave (deep trough)
        } else if (relX < 0.8) {
          y = midY - 15; // T wave
        } else {
          y = midY;
        }
      }
      points.add(Offset(x, y));
    }

    // Draw partial path based on progress to animate the heartbeat scan
    double drawLimit = width * progress;
    path.moveTo(points.first.dx, points.first.dy);
    for (var pt in points) {
      if (pt.dx <= drawLimit) {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    canvas.drawPath(path, paint);

    // Glowing scan head dot
    if (drawLimit < width) {
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      double activeY = midY;
      for (var pt in points) {
        if ((pt.dx - drawLimit).abs() < 2) {
          activeY = pt.dy;
          break;
        }
      }
      canvas.drawCircle(Offset(drawLimit, activeY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ECGPainter oldDelegate) => true;
}

class _AirFlowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AirFlowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double midY = size.height / 2;

    for (int line = 0; line < 3; line++) {
      final path = Path();
      double lineOffset = (line - 1) * 20.0;
      double phase = progress * 2 * math.pi + (line * math.pi / 3);

      path.moveTo(40, midY + lineOffset);
      for (double x = 40; x < size.width - 40; x += 10) {
        double y = midY + lineOffset + 8 * math.sin((x / 30) - phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AirFlowPainter oldDelegate) => true;
}

class _WaterPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaterPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Draw tap faucet
    final tapPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width / 2 - 30, 30), Offset(size.width / 2, 30), tapPaint);
    canvas.drawLine(Offset(size.width / 2, 30), Offset(size.width / 2, 50), tapPaint);

    // Droplets falling down
    double tapExitY = 50;
    double bottomY = size.height - 30;

    for (int i = 0; i < 4; i++) {
      double dropProgress = (progress + (i * 0.25)) % 1.0;
      double y = tapExitY + (bottomY - tapExitY) * dropProgress;
      double sizeMult = 2.0 + 3.0 * dropProgress;
      canvas.drawCircle(Offset(size.width / 2, y), sizeMult, paint);
    }

    // Water level/puddle at the bottom
    final puddlePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, bottomY),
        width: 60,
        height: 12,
      ),
      puddlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => true;
}
