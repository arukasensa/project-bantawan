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
                      const SizedBox(height: 25),
                      if (widget.topic.warning != null)
                        _buildWarningCard(topicColor),
                      const SizedBox(height: 30),
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
                      const SizedBox(height: 20),
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
                  child: Text(
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 180,
                                  width: double.infinity,
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
