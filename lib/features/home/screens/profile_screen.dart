// ============================================================================
// 🪪 BANTAWAN Tactical Medical ID & Profile Manager: ProfileScreen
// 
// หน้าจอข้อมูลบัตรประจำตัวการแพทย์ฉุกเฉิน (Medical ID Profile Screen)
// จัดการและแก้ไขข้อมูลส่วนตัว กรุ๊ปเลือด โรคประจำตัว ประวัติแพ้ยา ประกันสุขภาพ
// ความยินยอมบริจาคอวัยวะ ผู้ติดต่อฉุกเฉิน ICE และการสลับภาษาใช้งานของแอปพลิเคชัน
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter1/core/navigation/main_navigation.dart';
import '../services/profile_service.dart';
import 'package:flutter1/providers/profile_provider.dart';
import 'package:flutter1/features/emergency/services/emergency_contact_service.dart';
import 'package:flutter1/features/emergency/services/call_service.dart';
import '../services/language_service.dart';
import 'package:flutter1/features/emergency/screens/emergency_contact_screen.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';

/// 🪪 หน้าจอแสดงและแก้ไขข้อมูลประวัติการแพทย์ฉุกเฉิน (Medical ID Profile Screen)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// 📝 State ควบคุมการแก้ไขฟิลด์โปรไฟล์ทางการแพทย์ และการซิงก์ Provider
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _hospitalPrefController = TextEditingController();

  bool _organDonor = false;
  bool _anonymousMode = false;
  bool _shareMedicalInfo = true;
  bool _minimalMedicalInfo = false;
  List<Map<String, String>> _iceContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _insuranceController.dispose();
    _hospitalPrefController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    _populateControllers(profileProvider.profile);
    final contacts = await EmergencyContactService.getContacts();
    if (mounted) {
      setState(() {
        _iceContacts = contacts;
      });
    }
  }

  void _populateControllers(Map<String, String> profile) {
    _nameController.text = profile['name'] ?? '';
    _dobController.text = profile['dob'] ?? '';
    _ageController.text = profile['age'] ?? '';
    _weightController.text = profile['weight'] ?? '';
    _heightController.text = profile['height'] ?? '';
    _bloodTypeController.text = profile['bloodType'] ?? '';
    _allergiesController.text = profile['allergies'] ?? '';
    _conditionsController.text = profile['conditions'] ?? '';
    _insuranceController.text = profile['insurance'] ?? '';
    _hospitalPrefController.text = profile['hospitalPref'] ?? '';
    _organDonor = profile['organDonor'] == 'true';
    _anonymousMode = profile['anonymousMode'] == 'true';
    _shareMedicalInfo = profile['shareMedicalInfo'] != 'false';
    _minimalMedicalInfo = profile['minimalMedicalInfo'] == 'true';
  }

  Future<void> _showSaveConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.greenAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.saveProfile,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            isThai
                ? 'ยืนยันการบันทึกข้อมูลการแพทย์ของคุณเพื่อความปลอดภัยสูงสุดหรือไม่?'
                : 'Confirm saving your medical identification details for maximum safety?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      isThai ? 'ยกเลิก' : 'Cancel',
                      style: const TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isThai ? 'ยืนยัน' : 'Confirm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final newProfile = {
      'name': _nameController.text,
      'dob': _dobController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
      'height': _heightController.text,
      'bloodType': _bloodTypeController.text,
      'allergies': _allergiesController.text,
      'conditions': _conditionsController.text,
      'insurance': _insuranceController.text,
      'hospitalPref': _hospitalPrefController.text,
      'organDonor': _organDonor.toString(),
      'anonymousMode': _anonymousMode.toString(),
      'shareMedicalInfo': _shareMedicalInfo.toString(),
      'minimalMedicalInfo': _minimalMedicalInfo.toString(),
    };
    await profileProvider.updateProfile(newProfile);
    setState(() => _isEditing = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE53935),
            onPrimary: Colors.white,
            surface: Color(0xFF1a1a2e),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dobStr = picked.toString().split(' ')[0];
      setState(() {
        _dobController.text = dobStr;
        _ageController.text = ProfileService.calculateAge(dobStr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          final profile = profileProvider.profile;
          final statusColor = profileProvider.healthStatusColor;

          return Stack(
            children: [
              // Tactical Background
              _buildBackground(statusColor),

              SafeArea(
                child: profileProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                        ),
                      )
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildSliverAppBar(profileProvider),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: _isEditing
                                  ? _buildEditForm()
                                  : _buildDisplayTabs(profile, profileProvider),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(Color statusColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withValues(alpha: 0.1),
              const Color(0xFF0F0F23),
              Colors.black,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ProfileProvider provider) {
    final statusColor = provider.healthStatusColor;
    final profile = provider.profile;

    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          _isEditing ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          if (_isEditing) {
            setState(() => _isEditing = false);
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              final mainNav = context
                  .findAncestorStateOfType<MainNavigationState>();
              if (mainNav != null) mainNav.changeTab(0);
            }
          }
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: _isEditing
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : Colors.blueAccent.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _isEditing
                      ? Colors.greenAccent
                      : Colors.blueAccent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
            icon: Icon(
              _isEditing ? Icons.check_rounded : Icons.edit_rounded,
              color: _isEditing ? Colors.greenAccent : Colors.blueAccent,
              size: 16,
            ),
            label: Text(
              _isEditing ? 'บันทึก' : 'แก้ไขข้อมูล',
              style: TextStyle(
                color: _isEditing ? Colors.greenAccent : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_isEditing) {
                _showSaveConfirmation();
              } else {
                _loadProfile();
                setState(() => _isEditing = true);
              }
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildAvatar(statusColor, provider.completenessScore),
            const SizedBox(height: 12),
            Text(
              profile['name']?.isNotEmpty == true
                  ? profile['name']!
                  : "GUEST USER",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCompletionBadge(statusColor, provider.completenessScore),
                _buildMeshCallsignBadge(profile),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Color statusColor, double score) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Shadow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 46,
          backgroundColor: statusColor.withValues(alpha: 0.5),
          child: const CircleAvatar(
            radius: 44,
            backgroundColor: Color(0xFF1E1E2E),
            child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
          ),
        ),
        // Progress Ring
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            backgroundColor: Colors.white10,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionBadge(Color statusColor, double score) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        isThai
            ? "ข้อมูลการแพทย์สมบูรณ์ ${(score * 100).round()}%"
            : "${(score * 100).round()}% MEDICAL DATA COMPLETE",
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMeshCallsignBadge(Map<String, String> profile) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final isAnonymous = profile['anonymousMode'] == 'true';
    final name = profile['name'];
    final hasName = name?.isNotEmpty == true;
    final callsign = isAnonymous
        ? (isThai ? "โหมดนิรนาม (ANONYMOUS)" : "GHOST CALLSIGN")
        : (hasName ? name! : "Survivor");

    final badgeColor = isAnonymous ? Colors.amberAccent : Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnonymous ? Icons.visibility_off_rounded : Icons.wifi_tethering_rounded,
            color: badgeColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isThai ? "CALLSIGN: $callsign" : "MESH CALLSIGN: $callsign",
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayTabs(
    Map<String, String> profile,
    ProfileProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
          tabs: [
            Tab(text: l10n.medicalId.toUpperCase()),
            Tab(text: l10n.profile.toUpperCase()),
          ],
        ),
        const SizedBox(height: 20),
        _tabController.index == 0
            ? _buildMedicalTab(profile)
            : _buildPersonalTab(profile),
      ],
    );
  }

  Widget _buildMedicalTab(Map<String, String> profile) {
    final l10n = AppLocalizations.of(context)!;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Column(
      children: [
        _buildTacticalCard(
          title: l10n.medicalIDHeader.toUpperCase(),
          icon: Icons.emergency_rounded,
          accentColor: Colors.redAccent,
          child: Column(
            children: [
              _buildTacticalTile(
                l10n.bloodTypeShort,
                profile['bloodType'],
                Icons.bloodtype_rounded,
                Colors.redAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                l10n.allergiesLabel,
                profile['allergies'],
                Icons.warning_rounded,
                Colors.orangeAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                l10n.conditionsLabel,
                profile['conditions'],
                Icons.medical_services_rounded,
                Colors.blueAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                isThai ? 'การบริจาคอวัยวะ' : 'Organ Donor',
                profile['organDonor'] == 'true'
                    ? (isThai ? 'ยินดีบริจาคอวัยวะ' : 'Willing to Donate')
                    : (isThai ? 'ไม่ยินยอมบริจาค / ไม่ระบุ' : 'Not specified'),
                Icons.favorite_rounded,
                Colors.pinkAccent,
              ),
            ],
          ),
        ),
        _buildIceContactCard(),
      ],
    );
  }

  Widget _buildIceContactCard() {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final hasContacts = _iceContacts.isNotEmpty;
    final primaryContact = hasContacts ? _iceContacts.first : null;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone_rounded, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  isThai ? "ผู้ติดต่อฉุกเฉินด่วน (ICE CONTACT)" : "IN CASE OF EMERGENCY (ICE)",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyContactScreen(),
                      ),
                    );
                    _loadProfile();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isThai ? "จัดการ ➔" : "Manage ➔",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasContacts && primaryContact != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.greenAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryContact['name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${primaryContact['relationship'] ?? 'ญาติ'} • ${primaryContact['phone'] ?? ''}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => CallService.makeCall(primaryContact['phone'] ?? ''),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text(isThai ? "โทรออก" : "Call"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isThai ? "ยังไม่ได้เพิ่มรายชื่อผู้ติดต่อฉุกเฉิน" : "No emergency contacts set yet",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactScreen(),
                        ),
                      );
                      _loadProfile();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(isThai ? "เพิ่มรายชื่อ" : "Add"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab(Map<String, String> profile) {
    final l10n = AppLocalizations.of(context)!;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final bmi = ProfileService.calculateBMI(
      profile['weight'] ?? '',
      profile['height'] ?? '',
    );
    final age = profile['age']?.isNotEmpty == true 
        ? profile['age']! 
        : ProfileService.calculateAge(profile['dob'] ?? '');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                l10n.weightLabel.toUpperCase(),
                profile['weight'] ?? "-",
                "kg",
                Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                l10n.heightLabel.toUpperCase(),
                profile['height'] ?? "-",
                "cm",
                Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(l10n.bmiLabel.toUpperCase(), bmi, "INDEX", Colors.orangeAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTacticalCard(
          title: isThai ? "ข้อมูลส่วนตัวและการประกันภัย" : "PERSONAL & INSURANCE",
          icon: Icons.shield_rounded,
          accentColor: Colors.greenAccent,
          child: Column(
            children: [
              _buildTacticalTile(
                isThai ? 'ชื่อสัญญาณวิทยุ / Mesh Callsign' : 'Mesh Callsign',
                profile['name']?.isNotEmpty == true ? profile['name']! : "Survivor",
                Icons.wifi_tethering_rounded,
                Colors.cyanAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                isThai ? 'วันเกิด' : 'Date of Birth',
                profile['dob']?.isNotEmpty == true ? profile['dob']! : null,
                Icons.calendar_today_rounded,
                Colors.amberAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                l10n.ageLabel,
                age != '-' ? age : null,
                Icons.cake_rounded,
                Colors.purpleAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                l10n.insuranceLabel,
                profile['insurance'],
                Icons.policy_rounded,
                Colors.greenAccent,
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildTacticalTile(
                l10n.hospitalPrefLabel,
                profile['hospitalPref'],
                Icons.local_hospital_rounded,
                Colors.blueAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPrivacyOverviewCard(profile),
        const SizedBox(height: 16),
        _buildLanguageSelector(),
      ],
    );
  }

  Widget _buildTacticalCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTacticalTile(
    String label,
    String? value,
    IconData icon,
    Color color,
  ) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value?.isNotEmpty == true ? value! : (isThai ? "ไม่ได้ระบุ" : "NOT SPECIFIED"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, String unit, Color color) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEditForm() {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Column(
      children: [
        _buildSectionHeader(isThai ? "ข้อมูลระบุตัวตน & เครือข่าย" : "Identity & Mesh Network"),
        _buildGlassTextField(
          isThai ? 'ชื่อ-นามสกุล (ชื่อแสดงบน Mesh Chat)' : 'Full Name (Mesh Callsign)',
          _nameController,
          Icons.person_pin_rounded,
          helperText: isThai
              ? '📡 ชื่อนี้จะถูกใช้เป็นชื่ออุปกรณ์ (Callsign) ในการส่งข้อความผ่าน Mesh Network'
              : '📡 Used as your device Callsign in offline Mesh Chat',
        ),
        _buildGlassTextField(
          isThai ? 'วันเกิด (ดด/วว/ปปปป)' : 'Date of Birth (DOB)',
          _dobController,
          Icons.calendar_today_rounded,
          readOnly: true,
          onTap: () => _selectDate(context),
        ),

        _buildSectionHeader(isThai ? "ข้อมูลสัดส่วนร่างกาย" : "Medical Metrics"),
        Row(
          children: [
            Expanded(
              child: _buildGlassTextField(
                isThai ? 'น้ำหนัก (กก.)' : 'Weight (kg)',
                _weightController,
                Icons.monitor_weight_rounded,
                isNumber: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassTextField(
                isThai ? 'ส่วนสูง (ซม.)' : 'Height (cm)',
                _heightController,
                Icons.height_rounded,
                isNumber: true,
              ),
            ),
          ],
        ),
        _buildGlassTextField(
          isThai ? 'หมู่เลือด' : 'Blood Type',
          _bloodTypeController,
          Icons.bloodtype_rounded,
        ),

        _buildSectionHeader(isThai ? "ข้อมูลความเจ็บป่วยและการประกันภัย" : "Critical Info & Insurance"),
        _buildGlassTextField(
          isThai ? 'อาการแพ้' : 'Allergies',
          _allergiesController,
          Icons.warning_rounded,
        ),
        _buildGlassTextField(
          isThai ? 'โรคประจำตัว' : 'Medical Conditions',
          _conditionsController,
          Icons.sick_rounded,
        ),
        _buildGlassTextField(
          isThai ? 'บริษัทประกันภัย' : 'Insurance Provider',
          _insuranceController,
          Icons.policy_rounded,
        ),
        _buildGlassTextField(
          isThai ? 'โรงพยาบาลที่เลือก' : 'Preferred Hospital',
          _hospitalPrefController,
          Icons.local_hospital_rounded,
        ),

        _buildSectionHeader(isThai ? "🛡️ การตั้งค่าความเป็นส่วนตัว & การปิดบังข้อมูล" : "🛡️ Privacy & Data Masking"),
        _buildPrivacyToggles(),

        _buildSectionHeader(isThai ? "การตั้งค่าภาษาและการบริจาค" : "Language & Settings"),
        _buildLanguageSelector(),
        const SizedBox(height: 12),
        _buildOrganDonorToggle(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPrivacyOverviewCard(Map<String, String> profile) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final isAnonymous = profile['anonymousMode'] == 'true';
    final shareMedical = profile['shareMedicalInfo'] != 'false';
    final minimalMedical = profile['minimalMedicalInfo'] == 'true';

    return _buildTacticalCard(
      title: isThai ? "🛡️ ความเป็นส่วนตัว & การแชร์ข้อมูล (PRIVACY STATUS)" : "🛡️ PRIVACY & MESH SHARING",
      icon: Icons.shield_rounded,
      accentColor: Colors.amberAccent,
      child: Column(
        children: [
          _buildTacticalTile(
            isThai ? 'สถานะตัวตนบนบลูทูธ (Callsign Mode)' : 'Bluetooth Identity Mode',
            isAnonymous
                ? (isThai ? '👻 โหมดไม่ระบุตัวตน (Anonymous Survivor)' : '👻 Anonymous Survivor')
                : (isThai ? '👤 แสดงชื่อจริงตามที่ระบุ' : '👤 Standard Callsign'),
            isAnonymous ? Icons.visibility_off_rounded : Icons.person_rounded,
            isAnonymous ? Colors.amberAccent : Colors.cyanAccent,
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildTacticalTile(
            isThai ? 'การแชร์ข้อมูลสุขภาพฉุกเฉิน (Medical ID Broadcast)' : 'Medical ID Broadcast',
            !shareMedical
                ? (isThai ? '🔒 ปิดการแชร์ (เก็บเฉพาะในเครื่อง)' : '🔒 Private (Local Only)')
                : (minimalMedical
                    ? (isThai ? '🩺 แชร์เฉพาะข้อมูลวิกฤต (กรุ๊ปเลือด + แพ้ยา)' : '🩺 Minimal (Blood & Allergies)')
                    : (isThai ? '🌐 แชร์ข้อมูลสุขภาพครบถ้วน' : '🌐 Full Emergency Broadcast')),
            !shareMedical
                ? Icons.lock_rounded
                : (minimalMedical ? Icons.security_rounded : Icons.medical_services_rounded),
            !shareMedical
                ? Colors.redAccent
                : (minimalMedical ? Colors.blueAccent : Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggles() {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Icon(Icons.visibility_off_rounded, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isThai ? 'โหมดไม่ระบุตัวตน (Anonymous)' : 'Anonymous Callsign',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isThai
                        ? 'ใช้ชื่อรหัสสุ่ม Survivor_XXXX แทนชื่อจริงเมื่อส่งข้อความและค้นหาโหนด'
                        : 'Use randomized Survivor_XXXX callsign on Mesh Network',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                value: _anonymousMode,
                activeThumbColor: Colors.amberAccent,
                onChanged: (val) => setState(() => _anonymousMode = val),
              ),
              const Divider(color: Colors.white10, height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Icon(Icons.medical_information_rounded, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isThai ? 'แชร์ข้อมูลสุขภาพผ่านบลูทูธ' : 'Broadcast Medical ID',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isThai
                        ? 'อนุญาตให้เพื่อนใน Mesh เปิดดูบัตรประวัติการแพทย์เพื่อการปฐมพยาบาล'
                        : 'Allow nearby Mesh peers to view your Medical ID for emergency first aid',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                value: _shareMedicalInfo,
                activeThumbColor: Colors.greenAccent,
                onChanged: (val) => setState(() => _shareMedicalInfo = val),
              ),
              if (_shareMedicalInfo) ...[
                const Divider(color: Colors.white10, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isThai ? 'จำกัดการแชร์เฉพาะข้อมูลวิกฤต' : 'Minimal First-Aid Only',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isThai
                          ? 'ส่งเฉพาะ "กรุ๊ปเลือด + แพ้ยา" และปิดบังโรคประจำตัว/ประกัน/โรงพยาบาล'
                          : 'Broadcast only blood type & allergies; mask conditions & insurance',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                  value: _minimalMedicalInfo,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (val) => setState(() => _minimalMedicalInfo = val),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentCode = languageProvider.appLocale.languageCode;
    final isThai = currentCode == 'th';

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                isThai ? 'ภาษาของแอปพลิเคชัน (App Language)' : 'Application Language',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    languageProvider.changeLanguage(const Locale('th'));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isThai
                          ? Colors.blueAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isThai ? Colors.blueAccent : Colors.white10,
                        width: isThai ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇹🇭', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'ภาษาไทย',
                            style: TextStyle(
                              color: isThai ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    languageProvider.changeLanguage(const Locale('en'));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isThai
                          ? Colors.purpleAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !isThai ? Colors.purpleAccent : Colors.white10,
                        width: !isThai ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇺🇸', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'English',
                            style: TextStyle(
                              color: !isThai ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildOrganDonorToggle() {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return _buildGlassCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          isThai ? 'การบริจาคอวัยวะ' : 'Organ Donor',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isThai ? 'ฉันยินยอมบริจาคอวัยวะกรณีฉุกเฉิน' : 'I am willing to donate my organs in emergencies',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        value: _organDonor,
        activeThumbColor: Colors.greenAccent,
        onChanged: (val) => setState(() => _organDonor = val),
      ),
    );
  }

  Widget _buildGlassTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              helperText: helperText,
              helperStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
              helperMaxLines: 2,
              prefixIcon: Icon(icon, color: Colors.white38, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}
