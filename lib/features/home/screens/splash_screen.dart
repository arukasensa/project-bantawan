// ============================================================================
// 🚀 BANTAWAN App Startup & Tactical Radar Splash Screen: SplashScreen
// 
// หน้าจอต้อนรับเริ่มต้นเข้าสู่แอปพลิเคชัน (Tactical Radar Sweep Splash Screen)
// แสดงแอนิเมชันเรดาร์สแกนทางยุทธวิธี คลื่นชีพจร Pulse และแถบดาวน์โหลดความพร้อมของระบบ
// ก่อนทำการนำทางเข้าสู่ MainNavigation สลับแท็บหลัก
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter1/core/navigation/main_navigation.dart';

/// 🚀 หน้าจอเริ่มต้นต้อนรับเข้าสู่แอปพลิเคชัน (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// 🛰️ State ควบคุมแอนิเมชันเรดาร์ การหมุนสแกน 360 องศา และการเปลี่ยนหน้าอัตโนมัติ
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Radar sweep rotation
  late AnimationController _radarController;
  // Pulse rings expanding
  late AnimationController _pulseController;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  // Logo + text fade/slide in
  late AnimationController _entryController;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  // Bottom bar loading
  late AnimationController _loadController;
  late Animation<double> _loadProgress;
  // Exit fade
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Radar: continuous 360° rotation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse rings
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulse1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.0, 1.0, curve: Curves.easeOut)),
    );
    _pulse2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );

    // Entry: logo + title stagger
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.75, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );
    _entryController.forward();

    // Loading bar: 0→1 over 2 seconds
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadProgress = CurvedAnimation(parent: _loadController, curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _loadController.forward();
    });

    // Exit fade: 400ms fade to black then navigate
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Total 2.5s then exit
    Future.delayed(const Duration(milliseconds: 2100), () async {
      if (!mounted) return;
      await _exitController.forward();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainNavigation(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    _loadController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Stack(
            children: [
              Opacity(
                opacity: 1.0 - _exitFade.value,
                child: child,
              ),
              // Black overlay for exit transition
              if (_exitFade.value > 0)
                Opacity(
                  opacity: _exitFade.value,
                  child: const ColoredBox(color: Color(0xFF070B14), child: SizedBox.expand()),
                ),
            ],
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Background HUD Grid
        CustomPaint(
          size: Size.infinite,
          painter: _HudGridPainter(),
        ),

        // Radar sweep + pulse rings (centered)
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring 1
                AnimatedBuilder(
                  animation: _pulse1,
                  builder: (_, _) => _buildPulseRing(_pulse1.value, 140),
                ),
                // Pulse ring 2
                AnimatedBuilder(
                  animation: _pulse2,
                  builder: (_, _) => _buildPulseRing(_pulse2.value, 140),
                ),

                // Outer static ring
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                ),
                // Inner ring
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E5F3A).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),

                // Radar Sweep
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (_, _) {
                    return CustomPaint(
                      size: const Size(220, 220),
                      painter: _RadarSweepPainter(
                        angle: _radarController.value * 2 * math.pi,
                      ),
                    );
                  },
                ),

                // Cross-hair lines
                _buildCrossHair(),

                // Logo in center
                AnimatedBuilder(
                  animation: _entryController,
                  builder: (_, child) => FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A1628),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.radar_rounded,
                        color: Color(0xFF00D4FF),
                        size: 46,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // App Name & version (below radar)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 170), // push below radar circle

              // App Title
              AnimatedBuilder(
                animation: _titleFade,
                builder: (_, _) => Opacity(
                  opacity: _titleFade.value,
                  child: const Text(
                    'BANTAWAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle HUD style
              AnimatedBuilder(
                animation: _subtitleFade,
                builder: (_, _) => Opacity(
                  opacity: _subtitleFade.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHudDot(),
                      const SizedBox(width: 8),
                      Text(
                        'EMERGENCY RESPONSE SYSTEM',
                        style: TextStyle(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHudDot(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom loading bar
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: AnimatedBuilder(
            animation: _loadProgress,
            builder: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HUD label
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SYSTEM INIT',
                        style: TextStyle(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_loadProgress.value * 100).toInt()}%',
                        style: TextStyle(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Track
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _loadProgress.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066CC), Color(0xFF00D4FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Corner HUD decorations
        ..._buildCornerDecorations(),
      ],
    );
  }

  Widget _buildPulseRing(double progress, double maxRadius) {
    return Opacity(
      opacity: (1.0 - progress) * 0.5,
      child: Container(
        width: maxRadius * 2 * progress,
        height: maxRadius * 2 * progress,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00D4FF),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCrossHair() {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _CrossHairPainter(),
    );
  }

  Widget _buildHudDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF00D4FF),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    const color = Color(0xFF1E3A5F);
    const size = 20.0;
    const thickness = 1.5;

    Widget corner(Alignment alignment, bool flipX, bool flipY) {
      return Positioned(
        top: flipY ? null : 32,
        bottom: flipY ? 32 : null,
        left: flipX ? null : 24,
        right: flipX ? 24 : null,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            flipX ? -1 : 1,
            flipY ? -1 : 1,
            1,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CornerPainter(color: color, thickness: thickness),
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, false, false),
      corner(Alignment.topRight, true, false),
      corner(Alignment.bottomLeft, false, true),
      corner(Alignment.bottomRight, true, true),
    ];
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

class _HudGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RadarSweepPainter extends CustomPainter {
  final double angle;
  _RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Sweep gradient (pie slice, 90° arc)
    const sweepAngle = math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - sweepAngle,
        endAngle: angle,
        colors: [
          Colors.transparent,
          const Color(0xFF00D4FF).withValues(alpha: 0.0),
          const Color(0xFF00D4FF).withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(angle - sweepAngle),
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, angle - sweepAngle, sweepAngle, true, sweepPaint);

    // Sweep line (leading edge)
    final linePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_RadarSweepPainter old) => old.angle != angle;
}

class _CrossHairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  const _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
