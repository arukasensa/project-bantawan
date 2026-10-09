// ============================================================================
// 🧩 BANTAWAN Main Navigation Shell: MainNavigation (Core Navigation Layer)
// 
// โครงสร้างเมนูนำทางหลักของแอปพลิเคชัน (Main Navigation Shell)
// จัดการ Bottom Navigation Bar แบบลอย (Floating Glassmorphism Bar)
// สลับหน้าจอระหว่าง Home, First Aid, SOS, Map, และ Profile ด้วย IndexedStack
// เพื่อคงสถานะ State ของทุกหน้าจอไว้โดยไม่ต้อง Rebuild ใหม่
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'package:flutter1/features/home/screens/home_screen.dart';
import 'package:flutter1/features/first_aid/screens/first_aid_list_screen.dart';
import 'package:flutter1/features/emergency/screens/sos_screen.dart';
import 'package:flutter1/features/map/screens/map_screen.dart';
import 'package:flutter1/features/home/screens/profile_screen.dart';

/// 🧩 วิดเจ็ตนำทางหลักควบคุม Bottom Navigation Bar ของแอป BANTAWAN
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

/// 🧭 State ควบคุมการสลับแท็บและการคงสถานะหน้าจอด้วย IndexedStack
class MainNavigationState extends State<MainNavigation> {
  /// ดัชนีแท็บปัจจุบัน (0: Home, 1: First Aid, 2: SOS, 3: Map, 4: Profile)
  int _currentIndex = 0;

  /// ฟังก์ชันสำหรับเปลี่ยนแท็บจากภายนอกหรือปุ่มลัด
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true, // Floating navigation bar
        backgroundColor: Colors.black,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            FirstAidListScreen(),
            SosScreen(),
            MapScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _currentIndex == 3 ? null : _buildFloatingNavBar(),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    final l10n = AppLocalizations.of(context);
    final bool isThai = Localizations.localeOf(context).languageCode == 'th';

    final String homeLabel = l10n?.navHome ?? (isThai ? 'หน้าหลัก' : 'Home');
    final String firstAidLabel = l10n?.navFirstAid ?? (isThai ? 'ปฐมพยาบาล' : 'First Aid');
    final String sosLabel = l10n?.navSOS ?? 'SOS';
    final String mapLabel = l10n?.navMap ?? (isThai ? 'แผนที่' : 'Map');
    final String profileLabel = l10n?.navProfile ?? (isThai ? 'โปรไฟล์' : 'Profile');

    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_rounded, homeLabel)),
                Expanded(
                  child: _buildNavItem(
                    1,
                    Icons.menu_book_rounded,
                    firstAidLabel,
                    iconColor: Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    Icons.sos_rounded,
                    sosLabel,
                    isSOS: true,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    Icons.map_rounded,
                    mapLabel,
                    iconColor: Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(4, Icons.person_rounded, profileLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    Color? iconColor,
    bool isSOS = false,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = isSOS ? Colors.redAccent : (iconColor ?? Colors.white);
    final Color inactiveColor = Colors.white.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: () => changeTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 32 : 24,
                  height: isSelected ? 32 : 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: isSOS ? 22 : (isSelected ? 20 : 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: activeColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
