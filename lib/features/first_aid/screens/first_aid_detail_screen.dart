// ============================================================================
// 🏥 BANTAWAN Step-by-Step Tactical First Aid Guide: FirstAidDetailScreen
// 
// หน้าจอขั้นตอนการปฐมพยาบาลทีละลำดับ (Step-by-Step Tactical First Aid Guide)
// แสดงขั้นตอนพร้อมรูปประกอบ, ระบบอ่านออกเสียงบรรยาย (TTS Voice Guidance),
// เครื่องให้จังหวะปั๊มหัวใจ CPR Metronome (100-120 BPM) พร้อมระบบสั่น Haptic
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../services/first_aid_service.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import 'package:flutter1/features/home/services/language_service.dart';
import '../widgets/first_aid_visualizer.dart';

/// 🏥 หน้าจอขั้นตอนรายละเอียดการปฐมพยาบาลทีละลำดับ (First Aid Detail Screen)
class FirstAidDetailScreen extends StatefulWidget {
  final FirstAidTopic topic;

  const FirstAidDetailScreen({super.key, required this.topic});

  @override
  State<FirstAidDetailScreen> createState() => _FirstAidDetailScreenState();
}

/// 🎙️ State ควบคุมเสียงอ่าน TTS เสียงบรรยายภาษาไทย/อังกฤษ และ CPR Metronome
class _FirstAidDetailScreenState extends State<FirstAidDetailScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  int _currentStepIndex = -1;
  late AnimationController _voiceAnimController;

  // Language override state
  bool? _overrideIsThai;

  // TTS Speech Rate state
  double _speechRate = 0.5; // 0.3 (Slow), 0.5 (Normal), 0.7 (Fast)

  // CPR Metronome State
  bool _isMetronomeActive = false;
  Timer? _metronomeTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _voiceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  bool get _isThai {
    if (_overrideIsThai != null) return _overrideIsThai!;
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      return langProvider.appLocale.languageCode == 'th';
    } catch (_) {}
    return true; // Default to Thai for BANTAWAN
  }

  Future<void> _setTtsLanguage(bool isThai) async {
    try {
      if (isThai) {
        var res = await _flutterTts.setLanguage("th-TH");
        if (res == 0 || res == false) {
          res = await _flutterTts.setLanguage("th_TH");
        }
        if (res == 0 || res == false) {
          await _flutterTts.setLanguage("th");
        }
      } else {
        var res = await _flutterTts.setLanguage("en-US");
        if (res == 0 || res == false) {
          await _flutterTts.setLanguage("en");
        }
      }
    } catch (e) {
      debugPrint("TTS setLanguage error: $e");
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      debugPrint("TTS init error: $e");
    }

    _flutterTts.setCompletionHandler(() {
      if (_isSpeaking && _currentStepIndex < widget.topic.steps.length - 1) {
        _readNextStep();
      } else {
        setState(() {
          _isSpeaking = false;
          _currentStepIndex = -1;
        });
        _voiceAnimController.stop();
      }
    });
  }

  Future<void> _toggleLanguage() async {
    HapticFeedback.selectionClick();
    final newIsThai = !_isThai;
    setState(() {
      _overrideIsThai = newIsThai;
    });

    // Update global LanguageProvider if available
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      langProvider.changeLanguage(Locale(newIsThai ? 'th' : 'en'));
    } catch (_) {}

    // If speaking, restart TTS in the new language!
    if (_isSpeaking) {
      await _flutterTts.stop();
      final activeIndex = _currentStepIndex >= 0 ? _currentStepIndex : 0;
      final step = widget.topic.steps[activeIndex];
      final stepTitle = step.getTitle(newIsThai);
      final stepDesc = step.getDescription(newIsThai);
      final prefix = newIsThai ? "ขั้นตอนที่ ${step.stepNumber}" : "Step ${step.stepNumber}";
      final text = "$prefix: $stepTitle. $stepDesc";

      await _setTtsLanguage(newIsThai);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _toggleSpeechRate() async {
    HapticFeedback.lightImpact();
    double newRate = 0.5;
    if (_speechRate == 0.5) {
      newRate = 0.35; // Slow & Clear for Emergency
    } else if (_speechRate == 0.35) {
      newRate = 0.65; // Fast
    } else {
      newRate = 0.5; // Normal
    }

    setState(() {
      _speechRate = newRate;
    });

    await _flutterTts.setSpeechRate(newRate);
    if (_isSpeaking && _currentStepIndex >= 0) {
      await _speakStep(_currentStepIndex);
    }
  }

  void _toggleCprMetronome() {
    HapticFeedback.heavyImpact();
    if (_isMetronomeActive) {
      _metronomeTimer?.cancel();
      setState(() {
        _isMetronomeActive = false;
      });
    } else {
      setState(() {
        _isMetronomeActive = true;
      });
      // 110 BPM = 545 milliseconds per pulse
      _metronomeTimer = Timer.periodic(const Duration(milliseconds: 545), (_) {
        HapticFeedback.mediumImpact();
      });
    }
  }

  Future<void> _readNextStep() async {
    setState(() {
      _currentStepIndex++;
    });

    final step = widget.topic.steps[_currentStepIndex];
    final isThai = _isThai;
    final stepTitle = step.getTitle(isThai);
    final stepDesc = step.getDescription(isThai);
    final prefix = isThai
        ? "ขั้นตอนที่ ${step.stepNumber}"
        : "Step ${step.stepNumber}";

    final text = "$prefix: $stepTitle. $stepDesc";

    await _setTtsLanguage(isThai);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.speak(text);
  }

  Future<void> _speakStep(int index) async {
    if (_isSpeaking && _currentStepIndex == index) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _currentStepIndex = -1;
      });
      _voiceAnimController.stop();
      return;
    }

    await _flutterTts.stop();

    setState(() {
      _isSpeaking = true;
      _currentStepIndex = index;
    });
    _voiceAnimController.repeat(reverse: true);

    final step = widget.topic.steps[index];
    final isThai = _isThai;
    final stepTitle = step.getTitle(isThai);
    final stepDesc = step.getDescription(isThai);
    final prefix = isThai
        ? "ขั้นตอนที่ ${step.stepNumber}"
        : "Step ${step.stepNumber}";

    final text = "$prefix: $stepTitle. $stepDesc";

    await _setTtsLanguage(isThai);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.speak(text);
  }

  Future<void> _toggleVoiceGuide() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _currentStepIndex = -1;
      });
      _voiceAnimController.stop();
    } else {
      _speakStep(0);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _metronomeTimer?.cancel();
    _voiceAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color topicColor = Color(int.parse(widget.topic.color));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradient(),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(topicColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTacticalProtocolHUD(topicColor),
                      if (widget.topic.warning != null) ...[
                        _buildWarningCard(topicColor),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isThai
                                ? 'ขั้นตอนการช่วยเหลือ (${widget.topic.steps.length})'
                                : 'Rescue Steps (${widget.topic.steps.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.topic.id == 'cpr')
                            _buildCprMetronomeButton(topicColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final step = widget.topic.steps[index];
                  return _buildStepItem(
                    step,
                    topicColor,
                    index == _currentStepIndex,
                  );
                }, childCount: widget.topic.steps.length),
              ),
              SliverToBoxAdapter(
                child: _buildDosAndDontsSection(topicColor),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          _buildFloatingBottomControls(topicColor),
        ],
      ),
    );
  }

  Widget _buildCprMetronomeButton(Color color) {
    return GestureDetector(
      onTap: _toggleCprMetronome,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isMetronomeActive
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isMetronomeActive ? color : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: _isMetronomeActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isMetronomeActive ? Icons.favorite_rounded : Icons.speed_rounded,
              color: _isMetronomeActive ? color : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isMetronomeActive
                  ? (_isThai ? '110 BPM จังหวะปั๊ม' : '110 BPM CPR Beat')
                  : (_isThai ? 'เปิดจังหวะปั๊ม (110 BPM)' : 'CPR Metronome (110 BPM)'),
              style: TextStyle(
                color: _isMetronomeActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent.withValues(alpha: 0.12),
              const Color(0xFF0F0F23),
              const Color(0xFF050510),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Color color) {
    final isThai = _isThai;
    final rateLabel = _speechRate == 0.35
        ? '0.7x'
        : (_speechRate == 0.65 ? '1.3x' : '1.0x');

    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Speech Rate Selector Chip
        GestureDetector(
          onTap: _toggleSpeechRate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  rateLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Language Switcher Pill (TH / EN)
        GestureDetector(
          onTap: _toggleLanguage,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isThai
                    ? [Colors.blueAccent, Colors.blue.shade700]
                    : [Colors.purpleAccent, Colors.deepPurple],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isThai ? Colors.blueAccent : Colors.purpleAccent).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  isThai ? 'TH' : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Voice Guide Toggle Button
        IconButton(
          icon: Icon(
            _isSpeaking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: _isSpeaking ? color : Colors.white54,
          ),
          onPressed: _toggleVoiceGuide,
        ),
        const SizedBox(width: 10),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Glow
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Hero(
                  tag: 'icon_${widget.topic.id}',
                  child: widget.topic.iconAsset != null
                      ? Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              widget.topic.iconAsset!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Text(
                                  widget.topic.icon,
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          widget.topic.icon,
                          style: const TextStyle(fontSize: 80),
                        ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.topic.getTitle(isThai),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  widget.topic.getSubtitle(isThai),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalProtocolHUD(Color color) {
    final isThai = _isThai;
    final urgency = widget.topic.getUrgency(isThai);
    final keyMetric = widget.topic.getKeyMetric(isThai);
    final quickTip = widget.topic.getQuickTip(isThai);

    if (urgency == null && keyMetric == null && quickTip == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protocol Cards
        if (urgency != null || keyMetric != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (urgency != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              isThai ? 'ระดับความฉุกเฉิน' : 'URGENCY LEVEL',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              urgency,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (keyMetric != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isThai
                                        ? 'ตัวชี้วัดช่วยชีวิต (Key Metric)'
                                        : 'LIFESAVING KEY METRIC',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    keyMetric,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // Quick Tip Directive Banner
        if (quickTip != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt_rounded, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isThai ? 'คำแนะนำด่วนทันที' : 'TACTICAL QUICK ACTION',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quickTip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWarningCard(Color color) {
    final isThai = _isThai;
    final warningText = widget.topic.getWarning(isThai);
    if (warningText == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 32,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? 'ข้อควรระวังสำคัญ' : 'Important Warning',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      warningText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(FirstAidStep step, Color color, bool isHighlight) {
    final isThai = _isThai;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical Timeline Element
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isHighlight
                          ? color
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighlight
                            ? color
                            : Colors.white.withValues(alpha: 0.1),
                        width: 2,
                      ),
                      boxShadow: isHighlight
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: TextStyle(
                          color: isHighlight ? Colors.white : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (step.stepNumber < widget.topic.steps.length)
                    Container(
                      width: 2,
                      height:
                          (step.imageAsset != null || step.visualType != null)
                          ? 220
                          : 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isHighlight
                                ? color
                                : Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              // Step Content Card
              Expanded(
                child: GestureDetector(
                  onTap: () => _speakStep(widget.topic.steps.indexOf(step)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? color.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isHighlight
                                ? color.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.getTitle(isThai),
                              style: TextStyle(
                                color: isHighlight
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.9),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              step.getDescription(isThai),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            if (step.imageAsset != null) ...[
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => _showFullscreenImage(
                                  context,
                                  step,
                                  color,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 190,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: FutureBuilder<Uint8List>(
                                          future: rootBundle
                                              .load(step.imageAsset!)
                                              .then(
                                                (data) => data.buffer.asUint8List(),
                                              ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        _buildImagePlaceholder(color),
                                              );
                                            } else if (snapshot.hasError) {
                                              return _buildImagePlaceholder(color);
                                            }
                                            return Container(
                                              color: Colors.white.withValues(
                                                alpha: 0.04,
                                              ),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: color.withValues(
                                                      alpha: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Zoom Hint Badge Overlay
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 0.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.zoom_in_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isThai ? 'แตะขยายภาพ' : 'Tap to zoom',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (step.visualType != null) ...[
                              const SizedBox(height: 20),
                              FirstAidVisualizer(
                                visualType: step.visualType!,
                                themeColor: color,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, FirstAidStep step, Color color) {
    if (step.imageAsset == null) return;
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isThai ? 'ขั้นตอนที่ ${step.stepNumber}' : 'Step ${step.stepNumber}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.getTitle(_isThai),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Zoomable Image View
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Container(
                    color: Colors.black,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(
                        step.imageAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: color,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isThai ? 'หนีบนิ้วเพื่อซูมขยายภาพ (Pinch to Zoom)' : 'Pinch to Zoom & Pan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDosAndDontsSection(Color color) {
    final isThai = _isThai;
    final dos = widget.topic.getDos(isThai);
    final donts = widget.topic.getDonts(isThai);

    if (dos.isEmpty && donts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isThai ? 'แนวทางปฏิบัติ & ข้อควรระวัง' : 'Clinical Protocol & Safety Guidelines',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DOs Card
          if (dos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isThai ? 'สิ่งที่ควรทำ (DOs)' : 'RECOMMENDED (DOs)',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...dos.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF34D399),
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // DON'Ts Card
          if (donts.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isThai
                                ? 'สิ่งที่ห้ามทำเด็ดขาด (DON\'Ts)'
                                : 'STRICTLY PROHIBITED (DON\'Ts)',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...donts.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFF87171),
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color) {
    return Container(
      height: 180,
      color: Colors.white.withValues(alpha: 0.04),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: color.withValues(alpha: 0.4),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _isThai ? 'ภาพประกอบ' : 'Illustration',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBottomControls(Color color) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Guide Floating Buddy
          if (_isSpeaking) _buildVoiceBuddy(color),
          const SizedBox(height: 15),
          // Emergency Action Bar
          Row(
            children: [
              Expanded(flex: 4, child: _buildEmergencyPhoneButton()),
              const SizedBox(width: 15),
              Expanded(flex: 1, child: _buildVoiceToggleFab(color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBuddy(Color color) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _voiceAnimController, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              _isThai
                  ? 'กำลังบรรยายแต่ละขั้นตอน...'
                  : 'Narrating step-by-step...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyPhoneButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CallService.makeCall('1669'),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                _isThai ? 'โทรฉุกเฉิน 1669' : 'Call Emergency 1669',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceToggleFab(Color color) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleVoiceGuide,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Icon(
              _isSpeaking ? Icons.stop_rounded : Icons.headset_rounded,
              color: _isSpeaking ? color : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
