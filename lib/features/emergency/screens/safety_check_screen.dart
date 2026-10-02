// ============================================================================
// 🛡️ BANTAWAN Safety Check-in System: SafetyCheckScreen (Emergency Layer)
// 
// หน้าจอระบบตรวจสอบความปลอดภัย (Safety Check-in Screen)
// ให้ผู้ใช้ตั้งเวลาสำหรับสถานการณ์เสี่ยง พร้อมปุ่มยืนยันความปลอดภัย "ฉันปลอดภัยดี" (I'm Safe)
// หากผู้ใช้ไม่กดตอบรับภายในเวลาที่กำหนด ระบบจะทริกเกอร์สัญญาณฉุกเฉินและส่งพิกัดให้อัตโนมัติ
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/safety_check_service.dart';

/// 🛡️ หน้าจออินเทอร์เฟซเช็กความปลอดภัยกรณีตกอยู่ในภาวะเสี่ยง (Safety Check-in Screen)
class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({super.key});

  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

/// ⏱️ State ควบคุมการนับเวลาถอยหลัง และแอนิเมชันกะพริบแจ้งเตือนความปลอดภัย
class _SafetyCheckScreenState extends State<SafetyCheckScreen>
    with SingleTickerProviderStateMixin {
  /// จำนวนนาทีที่เลือกสำหรับนับเวลาถอยหลัง (เช่น 15, 30, 60 นาที)
  int _selectedMinutes = 30;

  /// Animation Controller สำหรับเอฟเฟกต์ไฟกะพริบชีพจร
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safetyService = Provider.of<SafetyCheckService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Dynamic Background
          _buildAnimatedBackground(safetyService),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildShieldInterface(safetyService),
                        const SizedBox(height: 40),
                        _buildControlPanel(safetyService),
                        const SizedBox(height: 40),
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

  Widget _buildAnimatedBackground(SafetyCheckService service) {
    Color baseColor = service.isActive
        ? (service.isWarning ? Colors.red : Colors.blueAccent)
        : const Color(0xFF0F172A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.5,
          colors: [baseColor.withValues(alpha: 0.15), Colors.black],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "AUTO CHECK-IN",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildShieldInterface(SafetyCheckService service) {
    final minutes = (service.remainingSeconds / 60).floor();
    final seconds = service.remainingSeconds % 60;

    Color shieldColor = service.isActive
        ? (service.isWarning
              ? const Color(0xFFEF4444)
              : (service.progress < 0.5
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF3B82F6)))
        : Colors.white38;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulsating Neon Aura
          if (service.isActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 290 + (_pulseController.value * 35),
                  height: 290 + (_pulseController.value * 35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        shieldColor.withValues(
                          alpha: 0.25 * (1 - _pulseController.value),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

          // Glowing Background Core
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  shieldColor.withValues(alpha: 0.15),
                  const Color(0xFF0F172A).withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: shieldColor.withValues(alpha: 0.25),
                  blurRadius: 35,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Main Glass Shield Ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: shieldColor.withValues(alpha: 0.6),
                width: 2.5,
              ),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.04),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: shieldColor.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            service.isActive
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            color: shieldColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.isActive
                              ? "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
                              : "READY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: service.isActive ? -1 : 2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: shieldColor.withValues(alpha: 0.6),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: shieldColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: shieldColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            service.isActive
                                ? (service.isWarning
                                      ? "CRITICAL ALERT"
                                      : "PROTECTED")
                                : "TAP TO START",
                            style: TextStyle(
                              color: shieldColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // High Precision Progress Ring
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: service.isActive ? service.progress : 1.0,
              strokeWidth: 4.5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(shieldColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(SafetyCheckService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildRecurringToggle(service),
          const SizedBox(height: 24),
          if (!service.isActive)
            _buildSetupControls()
          else
            _buildActiveControls(service),
        ],
      ),
    );
  }

  Widget _buildRecurringToggle(SafetyCheckService service) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: service.isRecurring
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  color: service.isRecurring
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "โหมดวนลูป (Recurring)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "เริ่มนับใหม่ทันทีหลังจากกดปุ่มยืนยัน",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: service.isRecurring,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  service.toggleRecurring();
                },
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupControls() {
    return Column(
      children: [
        _buildTimeSelector(),
        const SizedBox(height: 32),
        _buildActionButton(
          label: "ACTIVATE SHIELD",
          icon: Icons.security_rounded,
          color: const Color(0xFF3B82F6),
          isPrimary: true,
          onTap: () {
            HapticFeedback.heavyImpact();
            context.read<SafetyCheckService>().startCheck(
              _selectedMinutes,
              recurring: context.read<SafetyCheckService>().isRecurring,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveControls(SafetyCheckService service) {
    return Column(
      children: [
        _buildActionButton(
          label: "I AM SAFE",
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          isPrimary: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            service.resetCheck();
          },
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          label: "DEACTIVATE SYSTEM",
          icon: Icons.power_settings_new_rounded,
          color: Colors.white24,
          onTap: () {
            HapticFeedback.lightImpact();
            service.stopCheck();
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    final times = [10, 30, 60, 120];
    return Row(
      children: times.map((t) {
        final isSelected = _selectedMinutes == t;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMinutes = t);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF60A5FA)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                          blurRadius: 12,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "MIN",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.85)],
                    )
                  : null,
              color: isPrimary ? null : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
