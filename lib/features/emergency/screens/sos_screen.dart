// ============================================================================
// 🚨 BANTAWAN Critical SOS Response Hub: SosScreen (Emergency Layer)
// 
// หน้าจอปุ่มสัญญาณฉุกเฉินระดับวิกฤต (Critical SOS Response Hub)
// มีระบบกดค้าง (Hold-to-Activate) 3 วินาที เพื่อป้องกันการลื่นกดพลาด
// เปล่งเสียงไซเรนความถี่สูง, อ่านประกาศเตือนภัยผ่านเสียงพูด TTS,
// และส่งพิกัด GPS SOS พร้อม SMS ฉุกเฉินหาผู้ติดต่อ ICE โดยอัตโนมัติ
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../services/emergency_contact_service.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import '../services/call_service.dart';
import 'package:flutter/services.dart';
import 'emergency_contact_screen.dart';
import 'package:flutter1/core/navigation/main_navigation.dart';

/// 🚨 หน้าจอศูนย์ส่งสัญญาณขอความช่วยเหลือฉุกเฉินระดับวิกฤต (SOS Emergency Hub)
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

/// 🔴 State ควบคุมการกดค้าง 3 วินาที นับถอยหลัง แอนิเมชันไซเรน และเสียงเตือน TTS
class _SosScreenState extends State<SosScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// สถานะกำลังแตะกดค้างที่ปุ่ม SOS
  bool _isHolding = false;
  double _progress = 0;

  late AnimationController _holdController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _shakeController;

  bool _showHoldHint = false;
  bool _isSosLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        setState(() {
          _progress = _holdController.value;
        });

        if (_holdController.value >= 1.0) {
          _finalSOS();
        }
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isSosLaunched) {
      _isSosLaunched = false;
      _showPostSmsConfirmation();
    }
  }

  void _onHoldStart() {
    setState(() {
      _isHolding = true;
    });
    HapticFeedback.heavyImpact();
    _holdController.forward();
  }

  void _onHoldEnd() {
    if (_isHolding) {
      _resetAll();
    }
  }

  Future<void> _finalSOS() async {
    _resetAll();
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();

    final contacts = await EmergencyContactService.getContacts();

    if (contacts.isEmpty) {
      if (!mounted) return;
      _showResultDialog(
        title: AppLocalizations.of(context)!.noEmergencyContacts,
        message: AppLocalizations.of(context)!.addEmergencyContactsHint,
        isError: true,
      );
      return;
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
          forceLocationManager: true,
        ),
      );
      String mapLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";

      String message = "ช่วยด้วย! ฉันต้องการความช่วยเหลือด่วน\nพิกัด: $mapLink";

      if (!mounted) return;
      String separator = Theme.of(context).platform == TargetPlatform.iOS
          ? ';'
          : ',';
      String recipients = contacts.map((c) => c['phone']).join(separator);

      final Uri smsLaunchUri = Uri(
        scheme: 'sms',
        path: recipients,
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
        _isSosLaunched = true;
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'ผิดพลาด',
        message: 'ไม่สามารถส่ง SMS หรือดึงพิกัดได้: $e',
        isError: true,
      );
    }
  }

  void _resetAll() {
    _holdController.reset();

    setState(() {
      _isHolding = false;
      _progress = 0;
    });
  }

  void _showPostSmsConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
          title: Column(
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.blueAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.sosHaveYouSent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.smsConfirmHint(1),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.yesAlreadySent,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _finalSOS();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.reSendLimit,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isError,
  }) async {
    if (isError) {
      showDialog(
        context: context,
        builder: (_) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.okButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final contacts = await EmergencyContactService.getContacts();
      if (!mounted) return;

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _SOSCallingScreen(contacts: contacts);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F23),
                    Color(0xFF16213E),
                    Color(0xFF050510),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderText(),
                      const Spacer(),
                      _buildSOSButton(),
                      const Spacer(),
                      _buildBottomSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            final mainNav = context.findAncestorStateOfType<MainNavigationState>();
            if (mainNav != null) mainNav.changeTab(0);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'SOS PREMIER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    String text = '';
    Color color = Colors.white;

    if (_isHolding) {
      text = 'กำลังส่งสัญญาณ SOS... (ปล่อยเพื่อยกเลิก)';
      color = const Color(0xFFFF453A);
    } else if (_showHoldHint) {
      text = 'กดค้าง 1 วินาทีเพื่อส่ง SOS ทันที';
      color = Colors.redAccent;
    } else {
      text = 'กดค้างที่ปุ่ม SOS เพื่อส่งความช่วยเหลือทันที';
      color = Colors.white70;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rippleController,
        _shakeController,
      ]),
      builder: (context, child) {
        return GestureDetector(
          onLongPressStart: (_) => _onHoldStart(),
          onLongPressEnd: (_) => _onHoldEnd(),
          onTap: () {
            _shakeController.forward(from: 0.0);
            setState(() => _showHoldHint = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _showHoldHint = false);
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(280, 280),
                painter: _SOSProgressPainter(
                  progress: _progress,
                ),
              ),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFB71C1C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: 2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _isHolding ? 'กำลังส่ง...' : 'กดค้างส่งทันที',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          if (!_isHolding)
            Column(
              children: [
                Center(
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.emergencyContacts,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildStatusRow(
                  Icons.location_on_rounded,
                  AppLocalizations.of(context)!.sosLoggingLocation,
                ),
                _buildStatusRow(
                  Icons.verified_user_rounded,
                  AppLocalizations.of(context)!.sosSendingMedicalData,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SOSProgressPainter extends CustomPainter {
  final double progress;

  _SOSProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = const Color(0xFFFF453A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SOSProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SOSCallingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;

  const _SOSCallingScreen({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.sosSent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            ...contacts.map(
              (c) => ListTile(
                title: Text(
                  c['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  c['phone'],
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.blueAccent),
                  onPressed: () => CallService.makeCall(c['phone']),
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.finishButton),
            ),
          ],
        ),
      ),
    );
  }
}
