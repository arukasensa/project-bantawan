// ============================================================================
// 🛡️ BANTAWAN Safety Check-in System: SafetyCheckScreen (Emergency Layer)
// 
// หน้าจอระบบตรวจสอบความปลอดภัย (Dead Man's Switch & Safety Check-in)
// ออกแบบตามธีม Tactical Mesh Chat HUD: Deep Space Gradient, Ambient Glow,
// Concentric Holographic Radar & Shield Dial, Frosted Glassmorphism,
// Status Telemetry Strip, และ Tactical Micro-animations
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/safety_check_service.dart';
import 'package:flutter1/core/widgets/tactical_decorations_painter.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 🛡️ หน้าจออินเทอร์เฟซเช็กความปลอดภัยกรณีตกอยู่ในภาวะเสี่ยง (Safety Check-in Screen)
class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({super.key});

  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

/// ⏱️ State ควบคุมการนับเวลาถอยหลัง แอนิเมชันเรดาร์ และการตกแต่งสไตล์ Tactical HUD
class _SafetyCheckScreenState extends State<SafetyCheckScreen>
    with TickerProviderStateMixin {
  /// จำนวนนาทีที่เลือกสำหรับนับเวลาถอยหลัง (10, 30, 60, 120 นาที)
  int _selectedMinutes = 30;

  /// Animation Controller สำหรับเอฟเฟกต์ไฟกะพริบชีพจรและรัศมีเรืองแสง (Pulsing Glow Aura)
  late AnimationController _pulseController;

  /// Animation Controller สำหรับการหมุนสแกนเส้นขีดเรดาร์รอบหน้าปัด (Radar Sweep)
  late AnimationController _radarSweepController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarSweepController.dispose();
    super.dispose();
  }

  /// คำนวณสีหลักประจำสถานะ (Cyan: สแตนด์บาย, Emerald: ปลอดภัย/นับถอยหลังปกติ, Amber: เตือนครึ่งเวลา, Crimson: เตือนวิกฤต)
  Color _resolveStatusColor(SafetyCheckService service) {
    if (!service.isActive) {
      return const Color(0xFF00E5FF); // Cyber Cyan
    }
    if (service.isWarning) {
      return const Color(0xFFFF1744); // Crimson Alert
    }
    if (service.progress < 0.35) {
      return const Color(0xFFF59E0B); // Amber Warning
    }
    return const Color(0xFF10B981); // Emerald Active
  }

  @override
  Widget build(BuildContext context) {
    final safetyService = Provider.of<SafetyCheckService>(context);
    final themeColor = _resolveStatusColor(safetyService);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Cyberpunk Tactical Theme Background
          _buildTacticalBackground(safetyService, themeColor),

          // 2. Subtle Tactical Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: TacticalGridPainter(
                color: themeColor,
                opactiy: 0.035,
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, safetyService, themeColor),
                _buildTelemetryStatusBanner(safetyService, themeColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),

                        // Holographic Radar Shield Dial
                        _buildTacticalShieldDial(safetyService, themeColor),

                        const SizedBox(height: 18),

                        // Tactical Notice Ticker Banner
                        _buildNoticeTickerBanner(safetyService, themeColor),

                        const SizedBox(height: 18),

                        // Recurring Mode Switch Card
                        _buildRecurringCard(safetyService, themeColor),

                        const SizedBox(height: 20),

                        // Duration Selector (10, 30, 60, 120 MIN)
                        _buildDurationSelector(safetyService, themeColor),

                        const SizedBox(height: 28),

                        // Bottom Action Buttons
                        _buildActionControls(safetyService, themeColor),

                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🌌 Section 1: Background & Ambient Lighting
  // ============================================================================

  Widget _buildTacticalBackground(SafetyCheckService service, Color themeColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseVal = _pulseController.value;
        return Stack(
          children: [
            // Deep Tactical Mesh Gradient (Same as NearbyChatScreen)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F0F23),
                      Color(0xFF080C16),
                      Color(0xFF050510),
                    ],
                  ),
                ),
              ),
            ),

            // Upper Ambient Radial Glow (Pulsing smoothly)
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColor.withValues(alpha: 0.15 + (0.08 * pulseVal)),
                        themeColor.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Cyberpunk Ambient Glow (Subtle Purple/Indigo)
            Positioned(
              bottom: -100,
              left: -40,
              right: -40,
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // 🛰️ Section 2: Header HUD & Telemetry Status Banner
  // ============================================================================

  Widget _buildHeader(
    BuildContext context,
    SafetyCheckService service,
    Color themeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Frosted Glass Back Button
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            themeColor: themeColor,
            onTap: () => Navigator.pop(context),
          ),

          // Title & Subtitle HUD
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "AUTO CHECK-IN",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        shadows: [
                          Shadow(
                            color: themeColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "TACTICAL LIFELINE MONITOR",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge Pill
          _buildStatusBadgePill(service, themeColor),
        ],
      ),
    );
  }

  Widget _buildStatusBadgePill(SafetyCheckService service, Color themeColor) {
    String label;
    IconData icon;

    if (!service.isActive) {
      label = "STANDBY";
      icon = Icons.circle_outlined;
    } else if (service.isWarning) {
      label = "ALERT";
      icon = Icons.warning_amber_rounded;
    } else {
      label = "ARMED";
      icon = Icons.security_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: themeColor, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: themeColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStatusBanner(
    SafetyCheckService service,
    Color themeColor,
  ) {
    final isScanning = service.isActive;
    String statusText;

    if (!service.isActive) {
      statusText = context.l10n.safetyStandbyDesc;
    } else if (service.isWarning) {
      statusText = context.l10n.safetyCrisisDesc;
    } else {
      statusText = context.l10n.safetyActiveDesc;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Pulse Radar Dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(
                        alpha: isScanning ? _pulseController.value : 0.4,
                      ),
                      blurRadius: 8,
                      spreadRadius: isScanning ? 2 : 0,
                    ),
                  ],
                ),
              );
            },
          ),
          Flexible(
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: service.isWarning
                    ? const Color(0xFFFF5252)
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🛡️ Section 3: Holographic HUD Shield & Radar Dial
  // ============================================================================

  Widget _buildTacticalShieldDial(
    SafetyCheckService service,
    Color themeColor,
  ) {
    final minutes = (service.remainingSeconds / 60).floor();
    final seconds = service.remainingSeconds % 60;

    return GestureDetector(
      onTap: () {
        if (!service.isActive) {
          HapticFeedback.heavyImpact();
          service.startCheck(
            _selectedMinutes,
            recurring: service.isRecurring,
          );
        } else {
          HapticFeedback.mediumImpact();
          service.resetCheck();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _radarSweepController]),
        builder: (context, child) {
          final pulseVal = _pulseController.value;
          final sweepAngle = _radarSweepController.value * 2 * math.pi;

          return SizedBox(
            width: 270,
            height: 270,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Outer Pulsating Neon Shockwave
                if (service.isActive)
                  Container(
                    width: 250 + (pulseVal * 30),
                    height: 250 + (pulseVal * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withValues(
                          alpha: 0.3 * (1 - pulseVal),
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),

                // 2. Tactical Custom Radar Dial (Ticks, guide rings, and progress)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TacticalDialPainter(
                      progress: service.isActive ? service.progress : 1.0,
                      sweepAngle: sweepAngle,
                      themeColor: themeColor,
                      isActive: service.isActive,
                      isWarning: service.isWarning,
                    ),
                  ),
                ),

                // 3. Center Frosted Glass HUD Disc
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColor.withValues(alpha: 0.12),
                        const Color(0xFF0F1424).withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(
                      color: themeColor.withValues(
                        alpha: service.isActive ? 0.6 : 0.25,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(
                          alpha: service.isActive ? 0.3 : 0.1,
                        ),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.02),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Shield Icon Badge
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeColor.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: themeColor.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                service.isActive
                                    ? (service.isWarning
                                        ? Icons.warning_amber_rounded
                                        : Icons.shield_rounded)
                                    : Icons.shield_outlined,
                                color: themeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Main Countdown / Status Text
                            Text(
                              service.isActive
                                  ? "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
                                  : "READY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: service.isActive ? 42 : 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: service.isActive ? -1 : 3,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                shadows: [
                                  Shadow(
                                    color: themeColor.withValues(alpha: 0.75),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Status Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: themeColor.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                service.isActive
                                    ? (service.isWarning
                                        ? "CRITICAL ALERT"
                                        : "SYSTEM ARMED")
                                    : "TAP TO ARM",
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // 📢 Section 4: Notice Ticker Banner (Matches Chat Screen's Notice Ticker)
  // ============================================================================

  Widget _buildNoticeTickerBanner(
    SafetyCheckService service,
    Color themeColor,
  ) {
    final isUrgent = service.isWarning;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUrgent
                ? const Color(0xFF381015).withValues(alpha: 0.85)
                : const Color(0xFF101B2B).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUrgent
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : Colors.cyanAccent.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? Colors.redAccent : Colors.cyanAccent)
                    .withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isUrgent
                    ? Icons.warning_amber_rounded
                    : Icons.sensors_rounded,
                color: isUrgent ? Colors.redAccent : Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isUrgent
                            ? (context.isThai ? '[เตือนภัยด่วน] ' : '[URGENT ALERT] ')
                            : (context.isThai ? '[ระบบเฝ้าระวัง] ' : '[TACTICAL WATCH] '),
                        style: TextStyle(
                          color: isUrgent
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      TextSpan(
                        text: isUrgent
                            ? (context.isThai
                                ? 'ระบบกำลังจะยิงสัญญาณ SOS พร้อมพิกัด GPS อัตโนมัติในไม่ช้า'
                                : 'SOS signal with GPS coords will broadcast shortly.')
                            : (context.isThai
                                ? 'หากหมดเวลาโดยไม่มีการตอบรับ ระบบจะยิงพิกัด GPS ฉุกเฉินผ่าน Mesh ทันที'
                                : 'If timer expires without response, emergency GPS coords will broadcast via Mesh immediately.'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SOS MESH',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🔁 Section 5: Recurring Mode Switch Card
  // ============================================================================

  Widget _buildRecurringCard(
    SafetyCheckService service,
    Color themeColor,
  ) {
    final isRecurring = service.isRecurring;
    final accent = isRecurring ? const Color(0xFF10B981) : Colors.white38;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isRecurring
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (isRecurring)
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Glowing Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Subtitle, & Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          context.isThai ? "โหมดวนลูป (Recurring)" : "Recurring Mode",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isRecurring
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRecurring ? "AUTO-RESET" : "ONE-SHOT",
                            style: TextStyle(
                              color: isRecurring
                                  ? const Color(0xFF10B981)
                                  : Colors.white38,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.isThai
                          ? "เริ่มนับรอบใหม่อัตโนมัติทันทีหลังกดยืนยันตัวตน"
                          : "Automatically resets countdown after safety check-in",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Modern Styled Switch
              Switch(
                value: service.isRecurring,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  service.toggleRecurring();
                },
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ⏱️ Section 6: Tactical Duration Selector (10, 30, 60, 120 MIN)
  // ============================================================================

  Widget _buildDurationSelector(
    SafetyCheckService service,
    Color themeColor,
  ) {
    final times = [10, 30, 60, 120];
    final isLocked = service.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                context.isThai ? "เลือกระยะเวลานับถอยหลัง (CHECK-IN DURATION)" : "CHECK-IN DURATION",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (isLocked) ...[
                const Spacer(),
                Text(
                  context.isThai ? "• กำลังนับเวลาอยู่" : "• Timer Running",
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: times.map((t) {
            final isSelected = _selectedMinutes == t;
            return Expanded(
              child: GestureDetector(
                onTap: isLocked
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMinutes = t);
                      },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLocked && !isSelected ? 0.4 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF2979FF),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : const Color(0xFF0F172A).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF80D8FF)
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$t",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                shadows: isSelected
                                    ? [
                                        const Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "MIN",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.white38,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================================
  // ⚡ Section 7: Action Controls (Activate / I Am Safe / Deactivate)
  // ============================================================================

  Widget _buildActionControls(
    SafetyCheckService service,
    Color themeColor,
  ) {
    if (!service.isActive) {
      // Standby CTA: ACTIVATE SHIELD
      return _buildTacticalButton(
        label: "${context.l10n.activateShield} • $_selectedMinutes ${context.isThai ? 'นาที' : 'MIN'}",
        subtitle: context.isThai ? "เปิดระบบเฝ้าระวังอัตโนมัติ" : "Activate automated lifeline watch",
        icon: Icons.shield_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
        ),
        glowColor: const Color(0xFF00E5FF),
        onTap: () {
          HapticFeedback.heavyImpact();
          service.startCheck(
            _selectedMinutes,
            recurring: service.isRecurring,
          );
        },
      );
    }

    // Active Controls: I AM SAFE + DEACTIVATE SYSTEM
    return Column(
      children: [
        // Primary Safe Confirmation Button
        _buildTacticalButton(
          label: context.l10n.iAmSafe,
          subtitle: context.isThai ? "กดเพื่อรีเซ็ตเวลานับถอยหลังรอบใหม่" : "Tap to reset safety countdown",
          icon: Icons.check_circle_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          glowColor: const Color(0xFF10B981),
          isPulseActive: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            service.resetCheck();
          },
        ),

        const SizedBox(height: 14),

        // Secondary Deactivate System Button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            service.stopCheck();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.power_settings_new_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.deactivateSystem,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
    bool isPulseActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: isPulseActive ? 0.45 : 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🎨 Helper Custom Painters & Small Widgets
// ============================================================================

/// ตัววาดเส้นขีดมาตรวัดเรดาร์และวงแหวนความคืบหน้าระดับ Tactical HUD
class _TacticalDialPainter extends CustomPainter {
  final double progress;
  final double sweepAngle;
  final Color themeColor;
  final bool isActive;
  final bool isWarning;

  _TacticalDialPainter({
    required this.progress,
    required this.sweepAngle,
    required this.themeColor,
    required this.isActive,
    required this.isWarning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. วาดเส้นขีดมาตรวัดรอบนอก (Tactical Radar Ticks)
    final tickPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const tickCount = 36;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi / tickCount) + (isActive ? sweepAngle : 0);
      final isMajor = i % 9 == 0;
      final tickLength = isMajor ? 8.0 : 4.0;
      final startR = radius - 4;
      final endR = startR - tickLength;

      final p1 = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );

      final currentTickPaint = isMajor
          ? (Paint()
            ..color = themeColor.withValues(alpha: 0.8)
            ..strokeWidth = 2.0)
          : tickPaint;

      canvas.drawLine(p1, p2, currentTickPaint);
    }

    // 2. รางวงกลมพื้นหลัง (Background Track)
    final trackRadius = radius - 18;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, trackRadius, trackPaint);

    // 3. วงแหวนความคืบหน้าแบบเรืองแสง (Glowing Progress Arc)
    if (isActive) {
      final progressPaint = Paint()
        ..color = themeColor
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Glow shadow ใต้วงแหวน
      final glowPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.4)
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final sweepRadian = 2 * math.pi * progress.clamp(0.0, 1.0);
      const startRadian = -math.pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        startRadian,
        sweepRadian,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        startRadian,
        sweepRadian,
        false,
        progressPaint,
      );
    } else {
      // วงแหวนตกแต่งในโหมด Standby
      final standbyPaint = Paint()
        ..color = themeColor.withValues(alpha: 0.3)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, trackRadius, standbyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isWarning != isWarning;
  }
}

/// ปุ่มไอคอนกระจกฝ้า (Glassmorphic Icon Button) สำหรับปุ่มย้อนกลับ
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color themeColor;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
