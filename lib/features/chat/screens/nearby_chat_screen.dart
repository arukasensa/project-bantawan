// ============================================================================
// 📡 BANTAWAN Offline Mesh Chat & Radar Center: NearbyChatScreen (Layer 1 UI)
//
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │      (UI / Offline Chat / SOS Alert / Location Pin)     │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// ├─────────────────────────────────────────────────────────┤
// │                BANTAWAN Mesh Routing Engine             │
// ├─────────────────────────────────────────────────────────┤
// │            Transport Layer (Nearby Connections)          │
// └─────────────────────────────────────────────────────────┘
//
// หน้าจอศูนย์สื่อสารและเรดาร์ออฟไลน์ ให้บริการแชทสาธารณะ (Public Mesh),
// แชทส่วนตัวเข้ารหัส (Private E2EE), เรดาร์สแกน Node, ส่งพิกัด GPS ฉุกเฉิน
// และแสดงบัตรประจำตัวฉุกเฉิน Medical ID
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/nearby_service.dart';
import '../services/identity_service.dart';
import '../models/mesh_peer.dart';
import '../models/peer_trust.dart';
import 'peer_verification_screen.dart';
import '../widgets/peer_profile_sheet.dart';
import '../widgets/notice_board_sheet.dart';
import '../widgets/bantawan_settings_sheet.dart';
import '../widgets/peer_qr_verification_sheet.dart';
import '../widgets/data_mule_bag_sheet.dart';
import 'package:flutter1/features/home/services/profile_service.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter1/features/map/screens/map_screen.dart';
import 'package:latlong2/latlong.dart';

/// 📱 หน้าจอห้องสนทนาออฟไลน์และค้นหาอุปกรณ์ใกล้เคียง (Nearby Chat Screen)
class NearbyChatScreen extends StatefulWidget {
  const NearbyChatScreen({super.key});

  @override
  State<NearbyChatScreen> createState() => _NearbyChatScreenState();
}

/// State ควบคุมห้องแชท แอนิเมชันเรดาร์ และการเลือกคุยส่วนตัว
class _NearbyChatScreenState extends State<NearbyChatScreen>
    with TickerProviderStateMixin {
  /// Controller สำหรับช่องพิมพ์ข้อความ
  final TextEditingController _msgController = TextEditingController();

  /// Controller สำหรับเลื่อนดูรายการข้อความแชท
  final ScrollController _scrollController = ScrollController();

  /// Animation Controller สำหรับหมุนสแกนเรดาร์ตรวจจับ Node
  late AnimationController _radarController;

  bool _isLocationPressed = false;
  bool _isSendPressed = false;

  /// ดัชนีแท็บปัจจุบัน (0: แชทสาธารณะ Public Mesh, 1: รายการแชทส่วนตัว Private Peers)
  int _currentTabIndex = 0;

  /// รหัสประจำตัวของ Peer ที่กำลังเปิดห้องแชทส่วนตัวอยู่ (ผูกกับ peerId / nodeId ถาวร)
  String? _activePrivatePeer;
  String? _activePrivatePeerName;

  /// เครื่องมืออัดเสียง และสถานะการบันทึกข้อความเสียง (Voice Message Recording)
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NearbyService>(context, listen: false).checkHardwareReadiness();
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _radarController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    try {
      Provider.of<NearbyService>(context, listen: false).activeChatPeerId =
          null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyService = Provider.of<NearbyService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Theme Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0F23), Color(0xFF050510)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, nearbyService),
                _buildHardwareWarningBanner(nearbyService),
                _buildConnectionStatus(nearbyService),


                // Main Content View
                Expanded(
                  child: _currentTabIndex == 0
                      ? _buildPublicChatView(nearbyService)
                      : (_activePrivatePeer == null
                            ? _buildPrivatePeersListView(nearbyService)
                            : _buildPrivateChatRoomView(nearbyService)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NearbyService service) {
    final isInsidePrivateRoom =
        _currentTabIndex == 1 && _activePrivatePeer != null;
    final isPeopleList =
        _currentTabIndex == 1 && _activePrivatePeer == null;
    final activePeer = isInsidePrivateRoom
        ? _resolveActivePeer(service, _activePrivatePeer!)
        : null;
    final activeDisplayName = isInsidePrivateRoom
        ? _resolvePeerDisplayName(
            service,
            _activePrivatePeer!,
            activePeer?.peerName ?? _activePrivatePeerName,
          )
        : '';
    final allPeers = _getDiscoveredMeshPeers(service);
    final onlinePeers = allPeers
        .where((p) =>
            service.getPeerConnectionStatus(p) != PeerConnectionStatus.offline)
        .toList();
    final offlinePeers = allPeers
        .where((p) =>
            service.getPeerConnectionStatus(p) == PeerConnectionStatus.offline)
        .toList();
    final onlineCount = onlinePeers.length;
    final offlineCount = offlinePeers.length;

    // ------------------------------------------------------------------------
    // Mode 1: People / Discovered Peers List View (bitchat Screenshot 3)
    // ------------------------------------------------------------------------
    if (isPeopleList) {
      final isThai = Localizations.localeOf(context).languageCode == 'th';
      String subtitleText;
      if (onlineCount > 0 && offlineCount > 0) {
        subtitleText = isThai
            ? '#mesh ($onlineCount คนในระยะ • $offlineCount อยู่นอกระยะ)'
            : '#mesh ($onlineCount nearby • $offlineCount out of range)';
      } else if (onlineCount > 0) {
        subtitleText = isThai
            ? '#mesh ($onlineCount คนในระยะ)'
            : '#mesh ($onlineCount nearby)';
      } else if (offlineCount > 0) {
        subtitleText = isThai
            ? '#mesh (0 คนในระยะ • บันทึกไว้ $offlineCount คน)'
            : '#mesh (0 nearby • $offlineCount saved)';
      } else {
        subtitleText = isThai
            ? '#mesh (0 คนในระยะ)'
            : '#mesh (0 nearby)';
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'people',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      color: onlineCount > 0 ? Colors.greenAccent : Colors.cyanAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: onlineCount > 0 ? Colors.greenAccent : Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // [⛶] QR Code Button -> opens PeerQrVerificationSheet
            IconButton(
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.cyanAccent,
                size: 24,
              ),
              tooltip: 'สแกน / แสดง QR Code ยืนยันตัวตน',
              onPressed: () {
                HapticFeedback.lightImpact();
                PeerQrVerificationSheet.show(context);
              },
            ),
            // [✕] Close Button -> returns to #mesh public chat
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'กลับสู่ #mesh',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentTabIndex = 0;
                  _activePrivatePeer = null;
                  _activePrivatePeerName = null;
                });
                service.activeChatPeerId = null;
              },
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // Mode 2: Private 1-on-1 Chat Room (E2EE Chat)
    // ------------------------------------------------------------------------
    if (isInsidePrivateRoom) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _activePrivatePeer = null;
                  _activePrivatePeerName = null;
                });
                service.activeChatPeerId = null;
              },
            ),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (activePeer != null) {
                        _showPeerProfile(activePeer, service);
                      } else {
                        _showPeerProfileForName(_activePrivatePeer!, service);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '🔒 $activeDisplayName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ),
                  if (activePeer != null)
                    GestureDetector(
                      onTap: () {
                        _showPeerVerification(
                          service,
                          peer: activePeer,
                          peerId: activePeer.peerId,
                        );
                      },
                      child: ListenableBuilder(
                        listenable: IdentityService.instance,
                        builder: (context, _) {
                          final trustState = IdentityService.instance
                              .getTrustState(
                                activePeer.peerId,
                                activePeer.publicKeyHex,
                              );
                          String text;
                          Color color;
                          if (trustState == PeerTrustState.verified) {
                            text = '✓ Verified (แตะดูสถานะ)';
                            color = Colors.greenAccent;
                          } else if (trustState == PeerTrustState.changed) {
                            text = '⚠️ Key Changed! (แตะกดยืนยัน)';
                            color = Colors.orangeAccent;
                          } else {
                            text = '⚪ Not Verified (แตะเพื่อกดยืนยัน)';
                            color = Colors.white70;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded, size: 13, color: color),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        _showVerificationDialog(
                          service,
                          peerId: _activePrivatePeer,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'แตะเพื่อยืนยันตัวตน (E2EE)',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // [🛡️] Verify / QR Button
            IconButton(
              icon: ListenableBuilder(
                listenable: IdentityService.instance,
                builder: (context, _) {
                  final trustState = activePeer != null
                      ? IdentityService.instance.getTrustState(
                          activePeer.peerId,
                          activePeer.publicKeyHex,
                        )
                      : PeerTrustState.unknown;
                  final isVerified = trustState == PeerTrustState.verified;
                  return Icon(
                    isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                    color: isVerified ? Colors.greenAccent : Colors.purpleAccent,
                    size: 22,
                  );
                },
              ),
              tooltip: 'ตรวจสอบและกดยืนยันตัวตน',
              onPressed: () {
                _showVerificationDialog(
                  service,
                  peer: activePeer,
                  peerId: activePeer?.peerId ?? _activePrivatePeer,
                );
              },
            ),
            // 🪪 Emergency Medical Profile Sheet Button
            IconButton(
              icon: const Icon(
                Icons.badge_outlined,
                color: Colors.purpleAccent,
              ),
              tooltip: 'ดูโปรไฟล์ฉุกเฉิน',
              onPressed: () {
                if (activePeer != null) {
                  _showPeerProfile(activePeer, service);
                } else {
                  _showPeerProfileForName(_activePrivatePeer!, service);
                }
              },
            ),
            // Trash Icon
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white60,
                size: 20,
              ),
              tooltip: 'ล้างประวัติแชทห้องนี้',
              onPressed: () => _confirmClearChat(service, true),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // Mode 3: Public Mesh Chat View (bitchat Screenshot 1)
    // ------------------------------------------------------------------------
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back button to exit to previous screen
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {
              service.activeChatPeerId = null;
              Navigator.pop(context);
            },
          ),

          // Left: "bantawan/@callsign" (bitchat-style brand & callsign)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clickable "bantawan/" -> opens Settings & Info Sheet
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      BantawanSettingsSheet.show(context);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'bantawan/',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Clickable "@callsign" -> opens Quick Rename Dialog
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showChangeCallsignDialog(service);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@${service.deviceName}',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_rounded,
                            color: Colors.cyanAccent,
                            size: 11,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Controls: 📌 Notices, 🎒 Data Mule, #mesh, 👥 People
          // 📌 Notice Board
          ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              final hasUrgent = service.notices.any((n) => n.isUrgent);
              final noticeCount = service.notices.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    icon: Icon(
                      Icons.push_pin_rounded,
                      color: hasUrgent
                          ? Colors.redAccent
                          : (noticeCount > 0
                              ? Colors.cyanAccent
                              : Colors.white60),
                      size: 20,
                    ),
                    tooltip: 'ประกาศ @ #mesh',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      NoticeBoardSheet.show(context, service);
                    },
                  ),
                  if (noticeCount > 0)
                    Positioned(
                      top: 4,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: hasUrgent
                              ? Colors.redAccent
                              : const Color(0xFF00ADB5),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Center(
                          child: Text(
                            noticeCount > 9 ? '9+' : '$noticeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // 🗑️ ปุ่มล้างประวัติแชทสาธารณะ
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white60,
              size: 20,
            ),
            tooltip: 'ล้างประวัติแชทสาธารณะ',
            onPressed: () {
              HapticFeedback.lightImpact();
              _confirmClearChat(service, false);
            },
          ),
          // 🎒 ปุ่มกระเป๋าคนส่งสาร (Data Mule Bag)
          ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              final bagCount = service.carriedEnvelopes.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    icon: Icon(
                      Icons.backpack_outlined,
                      color: bagCount > 0 ? Colors.amberAccent : Colors.white60,
                      size: 20,
                    ),
                    tooltip: 'กระเป๋าคนส่งสาร (Data Mule)',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      DataMuleBagSheet.show(context, service);
                    },
                  ),
                  if (bagCount > 0)
                    Positioned(
                      top: 4,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.amberAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Center(
                          child: Text(
                            bagCount > 9 ? '9+' : '$bagCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // #mesh channel badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '#mesh',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 👥 [Count] People button -> switches to people view
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _currentTabIndex = 1;
                _activePrivatePeer = null;
                _activePrivatePeerName = null;
              });
              service.activeChatPeerId = null;
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: onlineCount > 0
                    ? Colors.purpleAccent.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: onlineCount > 0
                      ? Colors.purpleAccent.withValues(alpha: 0.5)
                      : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 15,
                    color: onlineCount > 0
                        ? Colors.purpleAccent
                        : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$onlineCount',
                    style: TextStyle(
                      color: onlineCount > 0 ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeCallsignDialog(NearbyService service) {
    final controller = TextEditingController(text: service.deviceName);
    final l10n = AppLocalizations.of(context);
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: Colors.cyanAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n?.changeCallsign ?? (isThai ? "เปลี่ยนนามเรียกขาน (@)" : "Change Callsign (@)"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isThai
                  ? "ชื่อนี้จะแสดงใน #mesh และระบุตัวตนในเครือข่ายออฟไลน์:"
                  : "This callsign is visible on #mesh and identifies your offline node:",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              maxLength: 18,
              decoration: InputDecoration(
                prefixText: "@ ",
                prefixStyle: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n?.cancelButton ?? (isThai ? "ยกเลิก" : "Cancel"),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final profile = await ProfileService.getProfile();
                profile['name'] = newName;
                await ProfileService.saveProfile(profile);
                await service.updateProfileInfo();
                if (mounted) setState(() {});
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(
              isThai ? "บันทึกชื่อ" : "Save Callsign",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareWarningBanner(NearbyService service) {
    if (service.hardwareWarningMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Color(0xFFFCA5A5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service.hardwareWarningMessage!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              await Geolocator.openLocationSettings();
              await service.checkHardwareReadiness();
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Text(
                'เปิดตั้งค่า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(NearbyService service) {
    final count = service.connectedDevices.length;
    final isScanning = service.isAdvertising || service.isDiscovering;

    // ⚡ กรณีระบบปิดอยู่: แสดงแถบกดเปิดสัญญาณ Mesh ได้ทันที ไม่ต้องสลับหน้า
    if (!isScanning && count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "ระบบออฟไลน์ปิดอยู่",
              style: TextStyle(
                color: Color(0xFFFCD34D),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await service.startEmergencyNetwork();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar_rounded, size: 13, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      "เปิดสัญญาณ Mesh",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isThai = Localizations.localeOf(context).languageCode == 'th';
    String statusText;
    if (service.isDiscoveryPaused && count >= 4) {
      statusText = isThai
          ? '⚡ เชื่อมต่อเต็ม 4 อุปกรณ์ (พักสแกนชั่วคราว)'
          : '⚡ Max 4 devices connected (Scan paused)';
    } else if (count > 0) {
      statusText = AppLocalizations.of(context)!.connectedDevices(count);
    } else {
      statusText = AppLocalizations.of(context)!.searchingPeers;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isScanning && count == 0)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 10 * _radarController.value,
                        height: 10 * _radarController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withValues(
                            alpha: 1 - _radarController.value,
                          ),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.greenAccent : Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // 🔄 ปุ่มกระตุ้นการสแกนบลูทูธใหม่ (Force Rescan)
          InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final ok = await service.forceRescan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? '🔄 กำลังรีเฟรชการสแกนบลูทูธ...'
                          : '⏳ กรุณารอสักครู่ก่อนรีเฟรชการสแกนซ้ำ (จำกัด 5 วิ)',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(
                Icons.refresh_rounded,
                size: 14,
                color: Colors.cyanAccent.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ปุ่มปิดสัญญาณ Mesh เมื่อไม่ใช้งาน
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              await service.stopEmergencyNetwork();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(
                Icons.power_settings_new_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// แถบประกาศสำคัญแบบ Ticker สไตล์ bitchat @ #mesh
  Widget _buildNoticeTickerBanner(NearbyService service) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.notices.isEmpty) return const SizedBox.shrink();
        final latest = service.notices.first;
        final hasUrgent = service.notices.any((n) => n.isUrgent);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              NoticeBoardSheet.show(context, service);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasUrgent
                    ? const Color(0xFF381015).withValues(alpha: 0.85)
                    : const Color(0xFF101B2B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasUrgent
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : Colors.cyanAccent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasUrgent
                        ? Icons.warning_amber_rounded
                        : Icons.campaign_rounded,
                    color: hasUrgent ? Colors.redAccent : Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: hasUrgent ? '[ด่วน] ' : '[ประกาศ] ',
                            style: TextStyle(
                              color: hasUrgent
                                  ? Colors.redAccent
                                  : Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${latest.authorName}: ${latest.content}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${service.notices.length} ปักหมุด',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// View 1: หน้าแชทสาธารณะ (Public Mesh Chat View)
  Widget _buildPublicChatView(NearbyService service) {
    final publicMessages = service.messages.where((msg) {
      return msg.recipientId == null || msg.recipientId == 'ALL';
    }).toList();

    return Column(
      children: [
        _buildNoticeTickerBanner(service),

        // 💬 bitchat-style intro banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "* คุณอยู่ใน #mesh — เข้าถึงคนในระยะ Bluetooth Mesh *",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "* แตะ bantawan/ เพื่อดูวิธีใช้และตั้งค่า · แตะ @ เพื่อเปลี่ยนชื่อ *",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: publicMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ambient radar beacon matching bitchat screenshot 1
                      AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, child) {
                          return Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent.withValues(
                                  alpha: 0.3 * (1 - _radarController.value),
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blueAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!service.isAdvertising && !service.isDiscovering) ...[
                        Text(
                          "ระบบสัญญาณ Mesh ปิดอยู่",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amberAccent.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await service.startEmergencyNetwork();
                          },
                          icon: const Icon(
                            Icons.wifi_tethering_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                          label: const Text(
                            "เปิดสัญญาณ Mesh & บลูทูธ",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                            shadowColor: Colors.cyanAccent.withValues(alpha: 0.4),
                          ),
                        ),
                      ] else ...[
                        Text(
                          AppLocalizations.of(context)!.noMessages,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: publicMessages.length,
                  itemBuilder: (context, index) {
                    final msg = publicMessages[index];
                    final isMe =
                        msg.senderId == service.nodeId ||
                        msg.senderId == service.deviceName;
                    return _buildChatBubble(msg, isMe);
                  },
                ),
        ),
        _buildInputArea(service, isPrivate: false),
      ],
    );
  }

  Widget _buildPeerSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// View 2: รายชื่อผู้ใช้ใกล้เคียงและประวัติแชทส่วนตัว (Private Discovered Peers & Recent Contacts List View)
  Widget _buildPrivatePeersListView(NearbyService service) {
    final allPeers = _getDiscoveredMeshPeers(service);
    final onlinePeers = allPeers
        .where((p) =>
            service.getPeerConnectionStatus(p) != PeerConnectionStatus.offline)
        .toList();
    final offlinePeers = allPeers
        .where((p) =>
            service.getPeerConnectionStatus(p) == PeerConnectionStatus.offline)
        .toList();

    if (allPeers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ไม่มีใครอยู่ใกล้...',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.purpleAccent.withValues(
                              alpha: 0.35 * (1 - _radarController.value),
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.purpleAccent.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'กำลังสแกนหาอุปกรณ์ใกล้เคียงผ่าน Bluetooth Mesh...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 🟢 โซนที่ 1: คนในระยะ MESH ตอนนี้ (In-Range / Active)
        if (onlinePeers.isNotEmpty) ...[
          _buildPeerSectionHeader(
            icon: Icons.sensors_rounded,
            iconColor: Colors.greenAccent,
            title: 'คนในระยะ MESH ตอนนี้',
            badgeText: '${onlinePeers.length} ออนไลน์',
            badgeColor: Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          ..._buildPeerTileList(service, onlinePeers),
          const SizedBox(height: 16),
        ],

        // ⚪ โซนที่ 2: ผู้ติดต่อที่เคยบันทึกไว้ / อยู่นอกระยะ (Known Contacts / Offline)
        if (offlinePeers.isNotEmpty) ...[
          _buildPeerSectionHeader(
            icon: Icons.vpn_key_rounded,
            iconColor: Colors.amberAccent,
            title: 'ผู้ติดต่อที่เคยบันทึกไว้ / อยู่นอกระยะ',
            badgeText: '${offlinePeers.length} คน',
            badgeColor: Colors.amberAccent,
            subtitle: 'เคยแลกเปลี่ยน Key แล้ว • อยู่นอกระยะการส่งสัญญาณ (ออฟไลน์)',
          ),
          const SizedBox(height: 8),
          ..._buildPeerTileList(service, offlinePeers),
        ],
      ],
    );
  }

  List<Widget> _buildPeerTileList(NearbyService service, List<MeshPeer> peers) {
    return peers.map((peer) {
      final status = service.getPeerConnectionStatus(peer);
      final bool isDirect = status == PeerConnectionStatus.direct;
      final bool isOffline = status == PeerConnectionStatus.offline;
      final storedTrust = IdentityService.instance.getStoredTrust(peer.peerId);
      final bool isVerified = storedTrust?.trustState == PeerTrustState.verified;
      final bool hasKey = peer.publicKeyHex.isNotEmpty || storedTrust != null;

      final Color statusColor = isDirect
          ? Colors.greenAccent
          : (status == PeerConnectionStatus.relayed
                ? Colors.purpleAccent
                : Colors.white38);
      final String statusText = isDirect
          ? 'เชื่อมต่อตรง (Direct BLE)'
          : (status == PeerConnectionStatus.relayed
                ? 'ผ่าน Mesh Relay (${peer.hopCount} ทอด)'
                : (isVerified
                    ? 'อยู่นอกระยะ • ยืนยัน Key แล้ว'
                    : (hasKey
                        ? 'อยู่นอกระยะ • มี Key ในระบบ'
                        : 'อยู่นอกระยะ • ฝากข้อความได้')));

      final pendingCount = service.messages
          .where((m) => m.recipientId == peer.peerId && m.status == 'PENDING')
          .length;

      final String buttonLabel = pendingCount > 0
          ? 'ฝากไว้ ($pendingCount)'
          : (isOffline ? 'ฝากข้อความ' : 'แชท');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDirect
                ? Colors.blueAccent.withValues(alpha: 0.25)
                : (isOffline
                      ? Colors.white10
                      : Colors.purpleAccent.withValues(alpha: 0.2)),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          onTap: () => _showPeerProfile(peer, service),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: isDirect
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : (isOffline
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.purpleAccent.withValues(alpha: 0.2)),
                child: Text(
                  peer.peerName.isNotEmpty
                      ? peer.peerName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isDirect
                        ? Colors.blueAccent
                        : (isOffline ? Colors.white54 : Colors.purpleAccent),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  peer.peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isVerified)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 10, color: Colors.greenAccent),
                      SizedBox(width: 3),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (hasKey && isOffline)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_rounded, size: 9, color: Colors.cyanAccent),
                      SizedBox(width: 3),
                      Text(
                        'E2EE KEY',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDirect
                      ? Colors.blueAccent.withValues(alpha: 0.15)
                      : (isOffline
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.purpleAccent.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDirect
                      ? '1 hop'
                      : (isOffline ? 'Offline' : '${peer.hopCount} hops'),
                  style: TextStyle(
                    color: isDirect
                        ? Colors.blueAccent
                        : (isOffline ? const Color(0xFF94A3B8) : Colors.purpleAccent),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  isOffline
                      ? Icons.offline_bolt_outlined
                      : Icons.lock_outline_rounded,
                  size: 12,
                  color: statusColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _activePrivatePeer = peer.peerId;
                    _activePrivatePeerName = peer.peerName;
                  });
                  service.activeChatPeerId = peer.peerId;
                  service.sendReadAckForPeer(peer.peerId);
                },
                icon: Icon(
                  isOffline ? Icons.backpack_rounded : Icons.chat_rounded,
                  size: 13,
                ),
                label: Text(buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOffline
                      ? (pendingCount > 0
                            ? Colors.orangeAccent.withValues(alpha: 0.25)
                            : Colors.amberAccent.withValues(alpha: 0.12))
                      : Colors.purpleAccent.withValues(alpha: 0.3),
                  foregroundColor: isOffline
                      ? (pendingCount > 0
                            ? Colors.orangeAccent
                            : Colors.amberAccent)
                      : Colors.purpleAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isOffline
                          ? (pendingCount > 0
                                ? Colors.orangeAccent
                                : Colors.amberAccent.withValues(alpha: 0.5))
                          : Colors.purpleAccent,
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                tooltip: 'ลบออกจากรายการ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _confirmDeletePeer(service, peer),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 🛡️ เปิดหน้าจอตรวจสอบ Fingerprint และกดยืนยันตัวตนคู่สนทนา (PeerVerificationScreen)
  void _showPeerVerification(
    NearbyService service, {
    MeshPeer? peer,
    String? peerId,
    String? name,
  }) {
    HapticFeedback.selectionClick();
    MeshPeer? targetPeer = peer;
    final resolvedId = peer?.peerId ??
        peerId ??
        (name != null
            ? (name.startsWith('node_') ? name : 'node_$name')
            : null);
    if (targetPeer == null && resolvedId != null) {
      targetPeer = _resolveActivePeer(service, resolvedId);
    }
    final resolvedName = _resolvePeerDisplayName(
      service,
      resolvedId ?? '',
      name ?? targetPeer?.peerName,
    );

    targetPeer ??= MeshPeer(
      peerId: resolvedId ?? 'unknown_peer',
      peerName: resolvedName,
      publicKeyHex: '',
      hopCount: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeerVerificationScreen(peer: targetPeer!),
      ),
    );
  }

  /// 🛡️ แสดงตัวเลือกการยืนยันตัวตน (สแกน QR Code หรือตรวจสอบ Fingerprint & กดยืนยันด้วยตนเอง)
  void _showVerificationDialog(
    NearbyService service, {
    MeshPeer? peer,
    String? peerId,
  }) {
    HapticFeedback.lightImpact();
    final targetId = peer?.peerId ?? peerId ?? _activePrivatePeer;
    final targetPeer = targetId != null
        ? (peer ?? _resolveActivePeer(service, targetId))
        : null;
    final displayName = targetId != null
        ? _resolvePeerDisplayName(
            service,
            targetId,
            targetPeer?.peerName ?? _activePrivatePeerName,
          )
        : 'คู่สนทนา';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'การยืนยันตัวตน: @$displayName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Colors.cyanAccent.withValues(alpha: 0.35),
                ),
              ),
              tileColor: Colors.cyanAccent.withValues(alpha: 0.08),
              leading: const CircleAvatar(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                child: Icon(Icons.fingerprint_rounded),
              ),
              title: const Text(
                'ตรวจสอบ Fingerprint & กดยืนยันตัวตน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'เปรียบเทียบรหัส Fingerprint กับเพื่อน แล้วกดยืนยันตัวตนด้วยตนเอง',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.cyanAccent,
              ),
              onTap: () {
                Navigator.pop(bCtx);
                _showPeerVerification(
                  service,
                  peer: targetPeer,
                  peerId: targetId,
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Colors.purpleAccent.withValues(alpha: 0.35),
                ),
              ),
              tileColor: Colors.purpleAccent.withValues(alpha: 0.08),
              leading: const CircleAvatar(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                child: Icon(Icons.qr_code_scanner_rounded),
              ),
              title: const Text(
                'สแกน / แสดง QR Code ยืนยันตัวตน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'ใช้กล้องสแกน QR เพื่อน หรือเปิด QR ให้เพื่อนสแกนผ่านกล้อง',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.purpleAccent,
              ),
              onTap: () {
                Navigator.pop(bCtx);
                PeerQrVerificationSheet.show(context, peerId: targetId);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🪪 เปิดหน้าต่างดูโปรไฟล์ฉุกเฉินและข้อมูลทางการแพทย์ของ Peer ในเครือข่ายออฟไลน์
  void _showPeerProfile(MeshPeer peer, NearbyService service) {
    HapticFeedback.selectionClick();
    PeerProfileSheet.show(
      context,
      peer: peer,
      service: service,
      onStartChat: () {
        setState(() {
          _activePrivatePeer = peer.peerId;
          _activePrivatePeerName = peer.peerName;
          _currentTabIndex = 1; // สลับไปยังแท็บแชทส่วนตัว
        });
        service.activeChatPeerId = peer.peerId;
        service.sendReadAckForPeer(peer.peerId);
      },
    );
  }

  /// 🪪 ค้นหาและเปิดดูโปรไฟล์ฉุกเฉินจากชื่อ Callsign หรือ Peer ID
  void _showPeerProfileForName(
    String name,
    NearbyService service, {
    String? peerId,
  }) {
    HapticFeedback.selectionClick();
    MeshPeer? targetPeer;
    final allKnown = _getDiscoveredMeshPeers(service);

    // 1. ค้นหาจาก peerId ก่อนเสมอ (หากระบุมา)
    if (peerId != null && peerId.isNotEmpty) {
      for (var peer in allKnown) {
        if (peer.peerId == peerId) {
          targetPeer = peer;
          break;
        }
      }
      if (targetPeer == null) {
        final trust = IdentityService.instance.getStoredTrust(peerId);
        if (trust != null) {
          targetPeer = MeshPeer(
            peerId: trust.peerId,
            peerName: trust.displayName.isNotEmpty ? trust.displayName : name,
            publicKeyHex: trust.publicKeyHex,
            hopCount: 99,
            lastSeen: trust.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        }
      }
    }

    // 2. หากยังไม่พบ ค้นหาจาก name หรือ peerId
    if (targetPeer == null) {
      for (var peer in allKnown) {
        if (peer.peerId == name || peer.peerName == name) {
          targetPeer = peer;
          break;
        }
      }
    }

    final trust = IdentityService.instance.getStoredTrust(name);
    if (targetPeer == null && trust != null) {
      targetPeer = MeshPeer(
        peerId: trust.peerId,
        peerName: trust.displayName,
        publicKeyHex: trust.publicKeyHex,
        hopCount: 99,
        lastSeen: trust.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    final resolvedName = _resolvePeerDisplayName(service, peerId ?? name, name);
    final resolvedPeerId = (peerId != null && peerId.startsWith('node_'))
        ? peerId
        : (name.startsWith('node_') ? name : 'node_$name');

    targetPeer ??= MeshPeer(
      peerId: resolvedPeerId,
      peerName: resolvedName,
      publicKeyHex: '',
      hopCount: service.connectedDevices.containsValue(name) ? 1 : 2,
    );

    _showPeerProfile(targetPeer, service);
  }

  /// 🗑️ แสดง Dialog ยืนยันการลบโหนดเพื่อนและประวัติการคุย
  Future<void> _confirmDeletePeer(NearbyService service, MeshPeer peer) async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ลบ ${peer.peerName}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'ประวัติการสนทนาและกุญแจความปลอดภัยกับ ${peer.peerName} (${peer.peerId}) จะถูกลบออกจากเครื่องของคุณอย่างถาวร',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ลบรายชื่อ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.deletePeer(peer.peerId);
      if (mounted) {
        setState(() {
          if (_activePrivatePeer == peer.peerId) {
            _activePrivatePeer = null;
            _activePrivatePeerName = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบ ${peer.peerName} ออกจากรายการเรียบร้อยแล้ว'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// 🗑️ แสดง Dialog ยืนยันการล้างประวัติข้อความแชท (Clear Chat Dialog)
  Future<void> _confirmClearChat(
    NearbyService service,
    bool isInsidePrivateRoom,
  ) async {
    HapticFeedback.selectionClick();
    final activePeer = isInsidePrivateRoom
        ? _resolveActivePeer(service, _activePrivatePeer!)
        : null;
    final activeDisplayName = isInsidePrivateRoom
        ? _resolvePeerDisplayName(
            service,
            _activePrivatePeer!,
            activePeer?.peerName ?? _activePrivatePeerName,
          )
        : '';

    final l10n = AppLocalizations.of(context);
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    final String title = isInsidePrivateRoom
        ? (isThai ? 'ล้างแชทกับ $activeDisplayName?' : 'Clear chat with $activeDisplayName?')
        : (isThai ? 'ล้างประวัติแชทสาธารณะ?' : 'Clear public chat history?');

    final String message = isInsidePrivateRoom
        ? (isThai
            ? 'ข้อความทั้งหมดในห้องแชทส่วนตัวนี้จะถูกลบออกจากฐานข้อมูลเครื่องของคุณอย่างถาวร'
            : 'All messages in this private chat room will be permanently deleted from your local device.')
        : (isThai
            ? 'ข้อความแชทสาธารณะทั้งหมดในเครื่องจะถูกล้าง (ไม่รวมข้อความส่วนตัว)'
            : 'All public mesh chat messages will be cleared (private chats excluded).');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n?.cancelButton ?? (isThai ? 'ยกเลิก' : 'Cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isThai ? 'ล้างข้อความ' : 'Clear Chat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isInsidePrivateRoom) {
        await service.clearPrivateChat(_activePrivatePeer!);
      } else {
        await service.clearPublicChat();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInsidePrivateRoom
                  ? (isThai ? 'ล้างข้อความกับ $activeDisplayName เรียบร้อยแล้ว' : 'Cleared chat with $activeDisplayName')
                  : (isThai ? 'ล้างข้อความแชทสาธารณะเรียบร้อยแล้ว' : 'Public chat history cleared'),
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// View 3: ห้องแชทส่วนตัวกับผู้ใช้ที่เลือก (Private E2EE Chatroom View)
  Widget _buildPrivateChatRoomView(NearbyService service) {
    final peerId = _activePrivatePeer!;
    final peer = _resolveActivePeer(service, peerId);
    final peerDisplayName = _resolvePeerDisplayName(
      service,
      peerId,
      peer?.peerName ?? _activePrivatePeerName,
    );

    if (_activePrivatePeerName == null ||
        _activePrivatePeerName!.startsWith('node_')) {
      if (!peerDisplayName.startsWith('node_')) {
        _activePrivatePeerName = peerDisplayName;
      }
    }

    final privateMessages = service.messages.where((msg) {
      final isRecipientMe =
          msg.recipientId == service.nodeId ||
          msg.recipientId == service.deviceName;
      final isRecipientPeer =
          msg.recipientId == peerId || msg.recipientName == peerDisplayName;
      final isSenderPeer =
          msg.senderId == peerId || msg.senderName == peerDisplayName;
      final isSenderMe =
          msg.senderId == service.nodeId || msg.senderId == service.deviceName;

      return (isSenderMe && isRecipientPeer) || (isSenderPeer && isRecipientMe);
    }).toList();

    return Column(
      children: [
        // 🛰️ แถบข้อมูลสถานะการเชื่อมต่อ Mesh และการเข้ารหัสลับ (Tactical Security Ribbon)
        _buildPrivateChatSubHeader(service, peerId, peerDisplayName, peer),

        // รายการข้อความแชท หรือหน้าจอเริ่มต้นความปลอดภัย
        Expanded(
          child: privateMessages.isEmpty
              ? _buildPrivateChatEmptyState(
                  service,
                  peerId,
                  peerDisplayName,
                  peer,
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: privateMessages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == privateMessages.length) {
                      return _buildPrivateChatSessionNotice(peerDisplayName);
                    }
                    final msg = privateMessages[index];
                    final isMe =
                        msg.senderId == service.nodeId ||
                        msg.senderId == service.deviceName;
                    return _buildChatBubble(msg, isMe);
                  },
                ),
        ),
        _buildInputArea(
          service,
          isPrivate: true,
          targetPeerId: peerId,
          targetPeerName: peerDisplayName,
        ),
      ],
    );
  }

  /// 🛰️ แถบข้อมูลสถานะการเชื่อมต่อ Mesh และการเข้ารหัสลับ (Private Chat Sub-Header Ribbon)
  Widget _buildPrivateChatSubHeader(
    NearbyService service,
    String peerId,
    String peerDisplayName,
    MeshPeer? peer,
  ) {
    final status = peer != null
        ? service.getPeerConnectionStatus(peer)
        : PeerConnectionStatus.offline;
    final bool isDirect = status == PeerConnectionStatus.direct;
    final bool isRelayed = status == PeerConnectionStatus.relayed;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isDirect) {
      statusColor = Colors.greenAccent;
      statusLabel = 'เชื่อมต่อโดยตรง (1 ทอด)';
      statusIcon = Icons.link_rounded;
    } else if (isRelayed) {
      statusColor = Colors.amberAccent;
      statusLabel = 'รีเลย์ผ่านโครงข่าย (${peer?.hopCount ?? 2} ทอด)';
      statusIcon = Icons.hub_rounded;
    } else {
      statusColor = Colors.white38;
      statusLabel = 'อยู่นอกระยะสัญญาณ (รอส่งอัตโนมัติ)';
      statusIcon = Icons.cloud_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131F),
        border: Border(
          bottom: BorderSide(
            color: isDirect
                ? Colors.greenAccent.withValues(alpha: 0.18)
                : isRelayed
                    ? Colors.amberAccent.withValues(alpha: 0.18)
                    : Colors.white10,
          ),
        ),
      ),
      child: Row(
        children: [
          // จุดไฟสถานะเรืองแสง
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isDirect || isRelayed)
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.7),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Icon(statusIcon, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // ป้าย E2EE แบบกดเพื่อดูตัวเลือกยืนยันตัวตนได้
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showVerificationDialog(
                service,
                peer: peer,
                peerId: peer?.peerId ?? peerId,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 11,
                    color: Color(0xFFC4B5FD),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'E2EE • X25519',
                    style: TextStyle(
                      color: Color(0xFFE9D5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 แถบแจ้งเตือนระดับการเข้ารหัสในห้องแชท (Chat Stream Session Notice)
  Widget _buildPrivateChatSessionNotice(String peerDisplayName) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: Colors.purpleAccent,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'การสนทนานี้เข้ารหัสแบบ E2EE (X25519 + AES-256) ระหว่างคุณและ @$peerDisplayName ข้อมูลปลอดภัย 100%',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 🛡️ หน้าจอเริ่มต้นเมื่อยังไม่มีข้อความ (Tactical Cybersecurity Empty State)
  Widget _buildPrivateChatEmptyState(
    NearbyService service,
    String peerId,
    String peerDisplayName,
    MeshPeer? peer,
  ) {
    final hasEmergencyProfile = peer?.emergencyProfile != null &&
        peer!.emergencyProfile!.values.any((v) => v.trim().isNotEmpty);
    final medData = peer?.emergencyProfile ?? {};

    final status = peer != null
        ? service.getPeerConnectionStatus(peer)
        : PeerConnectionStatus.offline;
    final bool isDirect = status == PeerConnectionStatus.direct;
    final bool isRelayed = status == PeerConnectionStatus.relayed;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้โล่ไซเบอร์เรืองแสง (Cyberpunk Glowing Tactical Shield)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purpleAccent.withValues(alpha: 0.25),
                          Colors.cyanAccent.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131A2A),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.purpleAccent,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ชื่อคู่สนทนา
              Text(
                '@$peerDisplayName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // ป้ายสถานะการเชื่อมต่อ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: (isDirect
                              ? Colors.greenAccent
                              : isRelayed
                                  ? Colors.amberAccent
                                  : Colors.white24)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDirect
                                ? Colors.greenAccent
                                : isRelayed
                                    ? Colors.amberAccent
                                    : Colors.white24)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDirect
                              ? Icons.wifi_tethering_rounded
                              : isRelayed
                                  ? Icons.hub_rounded
                                  : Icons.cloud_off_rounded,
                          size: 12,
                          color: isDirect
                              ? Colors.greenAccent
                              : isRelayed
                                  ? Colors.amberAccent
                                  : Colors.white60,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isDirect
                              ? 'เชื่อมต่อโดยตรง (1 Hop)'
                              : isRelayed
                                  ? 'รีเลย์ผ่านโครงข่าย (${peer?.hopCount ?? 2} Hops)'
                                  : 'อยู่นอกระยะ (Store-and-Forward)',
                          style: TextStyle(
                            color: isDirect
                                ? Colors.greenAccent
                                : isRelayed
                                    ? Colors.amberAccent
                                    : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // การ์ดรับรองความปลอดภัยระดับสูง E2EE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Colors.purpleAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'การสื่อสารส่วนตัวเข้ารหัสลับ E2EE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ข้อความ รูปภาพ และเสียงทั้งหมดถูกเข้ารหัสบนเครื่องของคุณด้วยโปรโตคอล X25519 ECDH และ AES-256-GCM ปลายทางเท่านั้นที่สามารถถอดรหัสได้ แม้โหนดกลางทางใน Mesh จะช่วยส่งต่อ แต่ไม่สามารถอ่านข้อมูลได้',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // การ์ดพรีวิวข้อมูลทางการแพทย์ฉุกเฉิน ICE (หากมี)
              if (hasEmergencyProfile) ...[
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPeerProfile(peer, service);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1326).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.pinkAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'ข้อมูลการแพทย์ฉุกเฉิน (ICE)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                medData['blood_type']?.isNotEmpty == true
                                    ? 'กรุ๊ปเลือด: ${medData['blood_type']} • แตะเพื่อดูประวัติฉุกเฉิน'
                                    : 'แตะเพื่อเปิดดูข้อมูลทางการแพทย์และเบอร์ติดต่อญาติ',
                                style: TextStyle(
                                  color: Colors.pinkAccent.shade100,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ชิปการดำเนินการด่วน (Quick Action Chips)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    backgroundColor: const Color(0xFF131A2A),
                    side: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                    avatar: const Icon(
                      Icons.my_location_rounded,
                      size: 14,
                      color: Colors.cyanAccent,
                    ),
                    label: const Text(
                      'แชร์พิกัดของฉัน',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      _shareCurrentLocation(
                        service,
                        isPrivate: true,
                        targetPeerId: peerId,
                        targetPeerName: peerDisplayName,
                      );
                    },
                  ),
                  ActionChip(
                    backgroundColor: const Color(0xFF131A2A),
                    side: BorderSide(
                      color: Colors.purpleAccent.withValues(alpha: 0.3),
                    ),
                    avatar: const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Colors.purpleAccent,
                    ),
                    label: const Text(
                      'ดูข้อมูลฉุกเฉิน',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (peer != null) {
                        _showPeerProfile(peer, service);
                      } else {
                        _showPeerProfileForName(peerId, service);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ค้นหาและดึง MeshPeer ตาม peerId จากทั้ง live peers, known peers, และ trust store
  MeshPeer? _resolveActivePeer(NearbyService service, String peerId) {
    if (service.discoveredMeshPeers.containsKey(peerId)) {
      return service.discoveredMeshPeers[peerId];
    }
    final allKnown = _getDiscoveredMeshPeers(service);
    for (final p in allKnown) {
      if (p.peerId == peerId) {
        return p;
      }
    }
    final trust = IdentityService.instance.getStoredTrust(peerId);
    if (trust != null) {
      return MeshPeer(
        peerId: trust.peerId,
        peerName: trust.displayName,
        publicKeyHex: trust.publicKeyHex,
        hopCount: 99,
        lastSeen: trust.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    return null;
  }

  /// แปลง Peer ID เป็น Display Name ที่เป็นมิตรและเป็นระเบียบตามสไตล์ Tactical (ไม่แสดง node_xxx หรือ Survivor_xxxx เลขสุ่ม)
  String _resolvePeerDisplayName(
    NearbyService service,
    String peerId, [
    String? fallbackName,
  ]) {
    bool isUglyName(String? name) {
      if (name == null || name.trim().isEmpty) return true;
      final trimmed = name.trim();
      final lower = trimmed.toLowerCase();
      if (lower.startsWith('node_')) return true;
      if (lower == 'survivor') return true;
      if (lower.startsWith('survivor_')) return true;
      if (lower.startsWith('survivor ')) {
        final remainder = lower.substring('survivor '.length).replaceAll(' ', '');
        if (RegExp(r'^[0-9a-f]+$').hasMatch(remainder)) return true;
      }
      if (RegExp(r'^[0-9a-fA-F]{4,}$').hasMatch(trimmed.replaceAll(' ', ''))) return true;
      return false;
    }

    if (!isUglyName(fallbackName)) {
      return fallbackName!.trim();
    }
    final resolvedPeer = _resolveActivePeer(service, peerId);
    if (resolvedPeer != null && !isUglyName(resolvedPeer.peerName)) {
      return resolvedPeer.peerName.trim();
    }
    for (final msg in service.messages.reversed) {
      if (msg.senderId == peerId && !isUglyName(msg.senderName)) {
        return msg.senderName.trim();
      }
      if (msg.recipientId == peerId && !isUglyName(msg.recipientName)) {
        return msg.recipientName!.trim();
      }
    }
    if (fallbackName != null && !isUglyName(fallbackName)) {
      return fallbackName.trim();
    }
    return NearbyService.generateTacticalCallsign(peerId);
  }

  List<MeshPeer> _getDiscoveredMeshPeers(NearbyService service) {
    final map = Map<String, MeshPeer>.from(service.discoveredMeshPeers);

    bool isUgly(String? name) {
      if (name == null || name.trim().isEmpty) return true;
      final lower = name.trim().toLowerCase();
      if (lower.startsWith('node_')) return true;
      if (lower == 'survivor') return true;
      if (lower.startsWith('survivor_')) return true;
      if (lower.startsWith('survivor ')) {
        final remainder = lower.substring('survivor '.length).replaceAll(' ', '');
        if (RegExp(r'^[0-9a-f]+$').hasMatch(remainder)) return true;
      }
      return false;
    }

    // 1. ดึงรายชื่อเพื่อนจาก IdentityService (Trust Store / Known Identities)
    for (var trust in IdentityService.instance.allTrustedPeers) {
      if (trust.peerId != service.nodeId &&
          trust.peerId != service.deviceName) {
        if (!map.containsKey(trust.peerId)) {
          final cleanTrustName = !isUgly(trust.displayName)
              ? trust.displayName
              : NearbyService.generateTacticalCallsign(trust.peerId);
          // โหนดออฟไลน์ที่เคยรู้จักและมี Public Key บันทึกไว้
          map[trust.peerId] = MeshPeer(
            peerId: trust.peerId,
            peerName: cleanTrustName,
            publicKeyHex: trust.publicKeyHex,
            hopCount: 99,
            lastSeen:
                trust.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        }
      }
    }

    // 2. ดึงคู่สนทนาจากประวัติข้อความเดิม (Previous Messages)
    for (var msg in service.messages) {
      final String? targetId =
          (msg.recipientId != null &&
              msg.recipientId != 'ALL' &&
              msg.recipientId != service.nodeId &&
              msg.recipientId != service.deviceName)
          ? msg.recipientId
          : ((msg.senderId != service.nodeId &&
                    msg.senderId != service.deviceName)
                ? msg.senderId
                : null);

      final String? targetName = (targetId == msg.recipientId)
          ? msg.recipientName
          : msg.senderName;

      if (targetId != null &&
          targetId.startsWith('node_') &&
          !map.containsKey(targetId)) {
        final rawName = targetName?.trim() ?? '';
        final cleanName = !isUgly(rawName)
            ? rawName
            : NearbyService.generateTacticalCallsign(targetId);
        map[targetId] = MeshPeer(
          peerId: targetId,
          peerName: cleanName,
          publicKeyHex: '',
          hopCount: 99,
          lastSeen: msg.timestamp,
        );
      }
    }

    // 3. อัปเดตสถานะ Direct Connected Devices บนโหนดถาวรที่มีอยู่แล้ว
    // หากพบอุปกรณ์ที่ต่อบลูทูธตรงอยู่ แต่ยังไม่เคยได้รับ Announce ให้กระตุ้นขอ Announce ทันที
    for (var entry in service.connectedDevices.entries) {
      final endpointId = entry.key;
      final name = entry.value;
      if (name != service.deviceName && name.isNotEmpty) {
        bool foundInMesh = false;
        for (var peerId in map.keys.toList()) {
          final peer = map[peerId]!;
          if (peer.directEndpoint == endpointId || peer.peerName == name) {
            map[peerId] = peer.copyWith(
              hopCount: 1,
              directEndpoint: endpointId,
            );
            foundInMesh = true;
            break;
          }
        }
        if (!foundInMesh) {
          // หากยังไม่ได้รับ PEER_ANNOUNCE จากเครื่องนี้ ให้ร้องขอ Announce เพื่อแลกเปลี่ยน Node ID & Public Key ทันที
          service.broadcastPeerAnnounce(targetEndpointId: endpointId);
        }
      }
    }

    // เรียงลำดับ: โหนดออนไลน์ (Hop 1 ก่อน -> Hop 2+) ตามด้วยโหนดออฟไลน์ (เรียงตามล่าสุดที่คุย)
    final list = map.values
        .where(
          (p) =>
              p.peerId != service.deviceName &&
              p.peerId != service.nodeId &&
              p.peerId.startsWith('node_'),
        )
        .toList();

    list.sort((a, b) {
      final aStatus = service.getPeerConnectionStatus(a);
      final bStatus = service.getPeerConnectionStatus(b);
      final aOnline = aStatus != PeerConnectionStatus.offline;
      final bOnline = bStatus != PeerConnectionStatus.offline;
      if (aOnline && !bOnline) return -1;
      if (!aOnline && bOnline) return 1;
      if (aOnline && bOnline) {
        return a.hopCount.compareTo(b.hopCount);
      }
      return b.lastSeen.compareTo(a.lastSeen);
    });

    return list;
  }

  /// 🎙️ เริ่มอัดเสียง (Start Audio Recording)
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // ปรับ Audio Quality ให้เหมาะกับช่องสัญญาณ BLE วิทยุ (16kHz Mono เพื่อให้ไฟล์มีขนาดเล็กเพียง 8-15KB)
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 16000,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordSeconds++;
            });
            // 🎙️ จำกัดความยาวเสียงไม่เกิน 6 วินาที เพื่อป้องกัน Payload เกินเพดาน 32KB ของ Nearby Connections
            if (_recordSeconds >= 6) {
              final service = context.read<NearbyService>();
              _stopAndSendRecording(
                service,
                isPrivate: _currentTabIndex == 1,
                targetPeerId: _activePrivatePeer,
                targetPeerName: _activePrivatePeerName,
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  /// 🛑 หยุดอัดเสียงและส่งข้อความเสียง (Stop and Send Voice Message)
  Future<void> _stopAndSendRecording(
    NearbyService service, {
    bool isPrivate = false,
    String? targetPeerId,
    String? targetPeerName,
  }) async {
    _recordTimer?.cancel();
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      final duration = _recordSeconds;

      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });

      if (path != null && duration > 0) {
        final err = await service.sendVoiceMessage(
          audioPath: path,
          durationSeconds: duration,
          recipientId: isPrivate ? targetPeerId : null,
          recipientName: isPrivate ? targetPeerName : null,
        );
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });
    }
  }

  /// ❌ ยกเลิกการอัดเสียง (Cancel Recording)
  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  /// 📷 เลือกรูปภาพจากกล้องหรือคลังและส่งผ่าน Mesh (บีบอัดเป็น Tactical Micro-Image ขนาด < 20KB สำหรับ BLE)
  Future<void> _pickAndSendImage(
    ImageSource source,
    NearbyService service, {
    bool isPrivate = false,
    String? targetPeerId,
    String? targetPeerName,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 360,
        maxHeight: 360,
        imageQuality: 40,
      );

      if (pickedFile != null) {
        final err = await service.sendImageMessage(
          imagePath: pickedFile.path,
          recipientId: isPrivate ? targetPeerId : null,
          recipientName: isPrivate ? targetPeerName : null,
        );
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  /// 📌 แสดง Modal ตัวเลือกแนบสื่อออฟไลน์ (Attachment Options Modal)
  void _showAttachmentOptions(
    NearbyService service, {
    bool isPrivate = false,
    String? targetPeerId,
    String? targetPeerName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ส่งสื่อออฟไลน์ (Offline Attachments)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'ถ่ายภาพ',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(
                      ImageSource.camera,
                      service,
                      isPrivate: isPrivate,
                      targetPeerId: targetPeerId,
                      targetPeerName: targetPeerName,
                    );
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.photo_library_rounded,
                  label: 'คลังภาพ',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(
                      ImageSource.gallery,
                      service,
                      isPrivate: isPrivate,
                      targetPeerId: targetPeerId,
                      targetPeerName: targetPeerName,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 🔍 แสดงรูปภาพแบบเต็มจอ (Full Screen Lightbox)
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: File(imagePath).existsSync()
                  ? Image.file(File(imagePath), fit: BoxFit.contain)
                  : const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 80,
                    ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(NearbyMessage msg, bool isMe) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
        bottom: 4,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final service = Provider.of<NearbyService>(
                          context,
                          listen: false,
                        );
                        _showPeerProfileForName(
                          msg.senderName,
                          service,
                          peerId: msg.senderId,
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.senderName,
                            style: TextStyle(
                              color: Colors.blueAccent.shade100,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                    if (msg.isEncrypted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFC4B5FD),
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'E2EE DIRECT',
                              style: TextStyle(
                                color: Color(0xFFE9D5FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (msg.isRelayed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hub_rounded,
                              color: Colors.amberAccent,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Mesh Relay',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? (msg.isEncrypted
                          ? const LinearGradient(
                              colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: msg.isEncrypted
                            ? Colors.purpleAccent.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                boxShadow: [
                  if (isMe)
                    BoxShadow(
                      color: msg.isEncrypted
                          ? Colors.purple.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.mediaType == 'IMAGE' && msg.mediaPath != null) ...[
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, msg.mediaPath!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 220,
                            maxHeight: 220,
                          ),
                          child: File(msg.mediaPath!).existsSync()
                              ? Image.file(
                                  File(msg.mediaPath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.white10,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.white38,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'ไม่พบไฟล์รูปภาพ',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (msg.content.isNotEmpty &&
                        msg.content != '[รูปภาพ]') ...[
                      const SizedBox(height: 6),
                      Text(
                        msg.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ] else if (msg.mediaType == 'AUDIO' &&
                      msg.mediaPath != null) ...[
                    VoicePlayerBubble(
                      audioPath: msg.mediaPath!,
                      durationSeconds: msg.durationSeconds ?? 0,
                      isMe: isMe,
                    ),
                  ] else if (msg.isLocation) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.myLocation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${msg.latitude?.toStringAsFixed(5)}, ${msg.longitude?.toStringAsFixed(5)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (msg.latitude != null && msg.longitude != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                    initialPosition: LatLng(
                                      msg.latitude!,
                                      msg.longitude!,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.map_rounded, size: 14),
                          label: Text(l10n.viewInMap),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final url =
                                'https://www.google.com/maps/search/?api=1&query=${msg.latitude},${msg.longitude}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            "Google Maps",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      msg.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFFCBD5E1),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe &&
                          msg.recipientId != null &&
                          msg.recipientId != 'ALL') ...[
                        const SizedBox(width: 4),
                        _buildDeliveryStatusIcon(msg.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 📊 [Delivery Status Icon Builder]
  /// แสดงไอคอนและป้ายสถานะของการนำส่งข้อความแชท:
  /// - `READ` (ฟ้า cyan ✓✓): ผู้รับเปิดอ่านข้อความแล้ว (ได้รับ Read Receipt ACK)
  /// - `DELIVERED` (ขาวเทา ✓✓): ข้อความส่งถึงเครื่องปลายทางเรียบร้อยแล้ว (ได้รับ Delivery ACK)
  /// - `PENDING` (เหลืองอำพัน ⏳): บันทึกลงคิว Store-and-Forward ในเครื่อง รอส่งอัตโนมัติเมื่อพบสัญญาณ
  /// - `MULE_CARRIED` (ส้มทอง 🎒): ฝากส่งผ่านคนเดินสาร (Data Mule) กำลังช่วยหิ้วไปส่งให้ปลายทาง
  /// - อื่นๆ (นาฬิกา ⏱️): กำลังส่งแพ็กเก็ตผ่านคลื่นวิทยุ (In-flight / Sending)
  Widget _buildDeliveryStatusIcon(String status) {
    if (status == 'READ') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded, size: 12, color: Colors.cyanAccent),
        ],
      );
    } else if (status == 'DELIVERED') {
      return const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70);

    } else if (status == 'PENDING') {
      return Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.amberAccent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 9, color: Colors.amberAccent),
            SizedBox(width: 2),
            Text(
              'รอสัญญาณ',
              style: TextStyle(
                fontSize: 9,
                color: Colors.amberAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'MULE_CARRIED') {
      return Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.backpack_outlined, size: 9, color: Colors.orangeAccent),
            SizedBox(width: 2),
            Text(
              'ฝากคนส่งสาร',
              style: TextStyle(
                fontSize: 9,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return const Icon(
        Icons.access_time_rounded,
        size: 10,
        color: Colors.white54,
      );
    }
  }

  /// 📍 ฟังก์ชันแชร์พิกัด GPS ปัจจุบัน (รองรับทั้งสาธารณะและส่วนตัว)
  Future<void> _shareCurrentLocation(
    NearbyService service, {
    bool isPrivate = false,
    String? targetPeerId,
    String? targetPeerName,
  }) async {
    HapticFeedback.lightImpact();
    setState(() => _isLocationPressed = true);
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (mounted) {
          setState(() => _isLocationPressed = false);
        }
      },
    );
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (isPrivate && targetPeerId != null) {
        await service.sendPrivateLocation(
          recipientId: targetPeerId,
          recipientName: targetPeerName ?? targetPeerId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      } else {
        await service.sendLocation(
          pos.latitude,
          pos.longitude,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.locationError,
          ),
        ),
      );
    }
  }

  /// ⌨️ [Chat Input Area Builder]
  /// แถบควบคุมและกรอกข้อมูลด้านล่างหน้าจอแชท รองรับการส่งทั้งข้อความและสื่อมัลติมีเดีย:
  /// - ช่องพิมพ์ข้อความ (Text Input Field) พร้อมปุ่มส่ง
  /// - ปุ่มอัดคลิปเสียงฉุกเฉิน (Voice Note PTT / Hold-to-record สูงสุด 6 วินาที)
  /// - ปุ่มแนบภาพถ่ายฉุกเฉิน (Camera / Image Picker)
  /// - ปุ่มแชร์พิกัด GPS ละติจูด/ลองจิจูด ปัจจุบัน
  /// - ควบคุมการส่ง: หากเป็นห้องแชทสาธารณะจะส่งแบบ Flooding (TTL=3)
  ///   หากเป็นห้องแชทส่วนตัว จะตรวจสอบการออนไลน์ -> ส่งตรง / รีเลย์ / เสนอฝากคนเดินสาร (Data Mule)
  Widget _buildInputArea(
    NearbyService service, {
    required bool isPrivate,
    String? targetPeerId,
    String? targetPeerName,
  }) {
    if (_isRecording) {
      final minutes = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (_recordSeconds % 60).toString().padLeft(2, '0');

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          border: const Border(top: BorderSide(color: Colors.redAccent)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.fiber_manual_record_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'กำลังบันทึกเสียง... $minutes:$seconds (สูงสุด 6 วิ)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _cancelRecording,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white60,
                size: 18,
              ),
              label: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _stopAndSendRecording(
                service,
                isPrivate: isPrivate,
                targetPeerId: targetPeerId,
                targetPeerName: targetPeerName,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrivate
            ? const Color(0xFF0F172A).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: isPrivate
                ? Colors.purpleAccent.withValues(alpha: 0.25)
                : Colors.white10,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _msgController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  maxLength: NearbyService.maxMessageLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        if (!isFocused &&
                            currentLength < (maxLength ?? 1000) * 0.8) {
                          return null;
                        }
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            fontSize: 10,
                            color: currentLength >= (maxLength ?? 1000) * 0.9
                                ? Colors.redAccent
                                : Colors.white38,
                          ),
                        );
                      },
                  decoration: InputDecoration(
                    hintText: isPrivate
                        ? 'พิมพ์ข้อความส่วนตัวหา ${targetPeerName ?? targetPeerId}...'
                        : AppLocalizations.of(context)!.typeEmergencyMsg,
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: isPrivate
                                ? Colors.purpleAccent
                                : Colors.blueAccent,
                          ),
                          tooltip: 'แนบรูปภาพถ่าย/จากคลัง',
                          onPressed: () => _showAttachmentOptions(
                            service,
                            isPrivate: isPrivate,
                            targetPeerId: targetPeerId,
                            targetPeerName: targetPeerName,
                          ),
                        ),
                        AnimatedScale(
                          scale: _isLocationPressed ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: IconButton(
                            icon: Icon(
                              Icons.location_on_rounded,
                              color: isPrivate
                                  ? Colors.purpleAccent
                                  : Colors.blueAccent,
                            ),
                            tooltip: 'แชร์ตำแหน่งที่ตั้ง GPS',
                            onPressed: () => _shareCurrentLocation(
                              service,
                              isPrivate: isPrivate,
                              targetPeerId: targetPeerId,
                              targetPeerName: targetPeerName,
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
          const SizedBox(width: 12),
          _msgController.text.isEmpty
              ? GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isPrivate
                          ? Colors.purpleAccent
                          : Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white),
                  ),
                )
              : GestureDetector(
                  onTapDown: (_) => setState(() => _isSendPressed = true),
                  onTapUp: (_) => setState(() => _isSendPressed = false),
                  onTapCancel: () => setState(() => _isSendPressed = false),
                  onTap: () async {
                    if (_msgController.text.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      final content = _msgController.text;
                      String? error;
                      if (isPrivate && targetPeerId != null) {
                        final targetPeer = service.discoveredMeshPeers[targetPeerId];
                        final isTargetOnline = targetPeer != null &&
                            service.getPeerConnectionStatus(targetPeer) != PeerConnectionStatus.offline;

                        if (!isTargetOnline && service.connectedDevices.isNotEmpty) {
                          // 🎒 ปลายทางออฟไลน์ แต่มีอุปกรณ์อื่นเชื่อมต่ออยู่ -> แสดงตัวเลือกฝากคนเดินสาร (Data Mule) หรือรอส่งเอง
                          _showOfflineSendChoiceModal(
                            service: service,
                            recipientId: targetPeerId,
                            recipientName: targetPeerName ?? targetPeerId,
                            content: content,
                          );
                          return;
                        }

                        error = await service.sendPrivateMessage(
                          recipientId: targetPeerId,
                          recipientName: targetPeerName ?? targetPeerId,
                          content: content,
                        );
                      } else {
                        error = await service.sendMessage(content);
                      }
                      if (error != null) {
                        // 🚦 Rate limit hit — แจ้งผู้ใช้ด้วย SnackBar
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.deepOrange.shade800,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        HapticFeedback.heavyImpact();
                      } else {
                        _msgController.clear();
                        setState(() {});
                      }
                    }
                  },
                  child: AnimatedScale(
                    scale: _isSendPressed ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPrivate
                            ? Colors.purpleAccent
                            : Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  /// 🎒 [Smart Offline Routing Choice Modal]
  /// แสดงกล่องโต้ตอบด้านล่างจอ (Bottom Sheet) ให้ผู้ใช้ตัดสินใจเลือกวิธีการส่งข้อความ
  /// ในกรณีที่ผู้รับเป้าหมาย [recipientId] อยู่นอกระยะการเชื่อมต่อ (Offline)
  /// 
  /// ตัวเลือกสำหรับผู้ใช้:
  /// 1. 🎒 [ฝากคนเดินสาร (Data Mule)]: เข้ารหัสลับแบบ E2EE แล้วส่งซองให้เพื่อนที่เชื่อมต่ออยู่
  ///    ช่วยหิ้วไปส่งให้ผู้รับปลายทางทันทีที่เขาเดินทางไปพบกัน (คนหิ้วอ่านข้อความไม่ได้: Zero-Knowledge)
  /// 2. ⏳ [รอส่งเองเมื่อพบกัน (Store & Forward)]: บันทึกข้อความลงคิว `pending_messages` ในเครื่องตนเอง
  ///    และจะส่งให้อัตโนมัติเมื่อเครื่องเราเข้าใกล้หรือพบกับผู้รับปลายทางด้วยตัวเอง
  void _showOfflineSendChoiceModal({
    required NearbyService service,
    required String recipientId,
    required String recipientName,
    required String content,
  }) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.amberAccent, width: 2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.backpack_rounded,
                      color: Colors.amberAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isThai
                              ? 'ปลายทางอยู่นอกระยะการเชื่อมต่อ'
                              : 'Recipient is Out of Direct Range',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isThai
                              ? 'เลือกวิธีส่งข้อความถึง @$recipientName'
                              : 'Choose dispatch method to @$recipientName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isThai
                            ? 'ขณะนี้มีอุปกรณ์อื่นเชื่อมต่ออยู่ในระยะ ${service.connectedDevices.length} เครื่อง สามารถฝากข้อความเข้ารหัสลับ (E2EE) ไปกับคนเหล่านี้ได้'
                            : 'Currently ${service.connectedDevices.length} peer(s) connected nearby. You can entrust encrypted (E2EE) envelopes with them.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: Data Mule Carrier
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSelectCarrierDialog(
                      service: service,
                      recipientId: recipientId,
                      recipientName: recipientName,
                      content: content,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade900.withValues(alpha: 0.4),
                          Colors.amber.shade800.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: Colors.amberAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isThai
                                        ? 'ฝากคนเดินสาร (Data Mule)'
                                        : 'Carrier Data Mule',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isThai ? 'แนะนำ' : 'Recommended',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isThai
                                    ? 'เข้ารหัสลับ E2EE ให้เพื่อนที่เชื่อมต่ออยู่ช่วยหิ้วไปส่งให้ทันทีที่เขาเดินไปเจอ @$recipientName (คนหิ้วอ่านข้อความไม่ได้)'
                                    : 'E2EE encrypted envelope entrusted to nearby peers to deliver when in proximity to @$recipientName (zero-knowledge)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.amberAccent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Option 2: Store & Forward
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final err = await service.sendPrivateMessage(
                      recipientId: recipientId,
                      recipientName: recipientName,
                      content: content,
                    );
                    if (err == null) {
                      _msgController.clear();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.schedule_send_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isThai
                                      ? 'บันทึกข้อความรอส่งอัตโนมัติเมื่อพบปลายทาง'
                                      : 'Message queued locally for delivery upon encounter',
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF334155),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_send_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isThai
                                    ? 'รอส่งเองเมื่อพบกัน (Store & Forward ปกติ)'
                                    : 'Hold locally until encounter (Direct Store & Forward)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isThai
                                    ? 'เก็บไว้ในคิวเครื่องตนเอง และจะส่งให้อัตโนมัติเมื่อเครื่องเราเข้าใกล้หรือเชื่อมต่อกับปลายทางโดยตรง'
                                    : 'Queue locally and deliver automatically when you directly reconnect with recipient',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.25,
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
            ],
          ),
        );
      },
    );
  }

  /// 🎒 [Carrier Selection Dialog]
  /// แสดงหน้าต่างสำหรับเลือกโหนดเพื่อนบ้าน (Carrier Node) ที่จะทำหน้าที่เป็นคนเดินสาร (Data Mule)
  /// - หากมีอุปกรณ์เชื่อมต่ออยู่เพียง 1 เครื่อง: จะเลือกโหนดนั้นและฝากส่งทันทีโดยอัตโนมัติ
  /// - หากมีอุปกรณ์เชื่อมต่ออยู่หลายเครื่อง: จะเปิด AlertDialog ให้ผู้ใช้เลือกโหนดที่ต้องการฝากส่ง
  /// - นำพาซองจดหมาย E2EE ไปส่งมอบให้ [recipientId] เมื่อคนเดินสารเดินทางไปพบผู้รับในอนาคต
  void _showSelectCarrierDialog({
    required NearbyService service,
    required String recipientId,
    required String recipientName,
    required String content,
  }) {
    final connectedList = service.connectedDevices.entries.toList();
    if (connectedList.isEmpty) return;

    if (connectedList.length == 1) {
      // มีคนเชื่อมต่ออยู่แค่คนเดียว -> ฝากส่งกับคนนี้ทันที
      final carrier = connectedList.first;
      _dispatchToCarrier(
        service: service,
        recipientId: recipientId,
        recipientName: recipientName,
        content: content,
        carrierEndpointId: carrier.key,
        carrierName: carrier.value,
      );
      return;
    }

    // มีคนเชื่อมต่อหลายคน -> แสดง Dialog ให้เลือกว่าจะฝากใคร หรือฝากทุกคนพร้อมกัน (K-Replication)
    final selectedEndpoints = <String>{};
    final l10n = AppLocalizations.of(context);
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.amberAccent, width: 1.2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.backpack_rounded, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.selectCarrier ?? (isThai ? 'เลือกคนส่งสาร (Data Mule)' : 'Select Carrier (Data Mule)'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai
                          ? 'เลือกอุปกรณ์ที่จะช่วยนำพาซองจดหมายเข้ารหัสลับ (E2EE) ไปส่งมอบ:'
                          : 'Select device to carry encrypted (E2EE) envelope:',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // 🚀 ปุ่มลัด: ฝากทุกคนที่เชื่อมต่ออยู่ (K-Copies Multi-Carrier Replication)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        final allEndpoints = connectedList.map((e) => e.key).toList();
                        _dispatchToCarriers(
                          service: service,
                          recipientId: recipientId,
                          recipientName: recipientName,
                          content: content,
                          carrierEndpointIds: allEndpoints,
                          carrierSummaryName: isThai
                              ? 'ทุกคนที่เชื่อมต่อ (${allEndpoints.length} คน)'
                              : 'All connected peers (${allEndpoints.length})',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade700.withValues(alpha: 0.35),
                              Colors.amber.shade900.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.amberAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add_rounded,
                                color: Color(0xFF1E293B),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isThai
                                        ? 'ฝากทุกคนที่เชื่อมต่อ (${connectedList.length} คน)'
                                        : '${l10n?.dispatchAllConnected ?? 'Dispatch to All Connected'} (${connectedList.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isThai
                                        ? 'กระจายสำเนาความเสี่ยง โอกาสส่งถึงมือสูงสุด'
                                        : 'Replicate across peers for highest delivery probability',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.amberAccent,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      isThai ? 'หรือเลือกคนส่งสารรายคน:' : 'Or select individual carriers:',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),

                    // รายชื่อเพื่อนบ้านที่เชื่อมต่ออยู่พร้อม Checkbox
                    ...connectedList.map((entry) {
                      final isChecked = selectedEndpoints.contains(entry.key);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isChecked,
                        activeColor: Colors.amberAccent,
                        checkColor: const Color(0xFF1E293B),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedEndpoints.add(entry.key);
                            } else {
                              selectedEndpoints.remove(entry.key);
                            }
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Endpoint: ${entry.key}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    l10n?.cancelButton ?? (isThai ? 'ยกเลิก' : 'Cancel'),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                if (selectedEndpoints.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      final endpoints = selectedEndpoints.toList();
                      final summaryName = endpoints.length == 1
                          ? (connectedList.firstWhere((e) => e.key == endpoints.first, orElse: () => MapEntry('', isThai ? 'คนส่งสาร' : 'Carrier')).value)
                          : (isThai ? '${endpoints.length} คน' : '${endpoints.length} carriers');
                      _dispatchToCarriers(
                        service: service,
                        recipientId: recipientId,
                        recipientName: recipientName,
                        content: content,
                        carrierEndpointIds: endpoints,
                        carrierSummaryName: summaryName,
                      );
                    },
                    child: Text(
                      isThai ? 'ฝากส่ง (${selectedEndpoints.length} คน)' : 'Dispatch (${selectedEndpoints.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🚀 [Dispatch To Single Carrier Method]
  Future<void> _dispatchToCarrier({
    required NearbyService service,
    required String recipientId,
    required String recipientName,
    required String content,
    required String carrierEndpointId,
    required String carrierName,
  }) {
    return _dispatchToCarriers(
      service: service,
      recipientId: recipientId,
      recipientName: recipientName,
      content: content,
      carrierEndpointIds: [carrierEndpointId],
      carrierSummaryName: carrierName,
    );
  }

  /// 🚀 [Dispatch To Multiple Carriers Method]
  /// ดำเนินการสร้างและส่งมอบซองจดหมายคนเดินสาร (Data Mule Envelope) ไปยัง Carriers ที่ระบุ
  Future<void> _dispatchToCarriers({
    required NearbyService service,
    required String recipientId,
    required String recipientName,
    required String content,
    required List<String> carrierEndpointIds,
    required String carrierSummaryName,
  }) async {
    final err = await service.dispatchMultiCarrierEnvelopes(
      recipientId: recipientId,
      recipientName: recipientName,
      content: content,
      carrierEndpointIds: carrierEndpointIds,
    );

    if (err == null) {
      _msgController.clear();
      setState(() {});
      if (mounted) {
        final isThai = Localizations.localeOf(context).languageCode == 'th';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.backpack_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    carrierEndpointIds.length > 1
                        ? (isThai
                            ? '🎒 ฝากซองจดหมายผ่าน $carrierSummaryName เรียบร้อยแล้ว!'
                            : '🎒 Envelopes dispatched to $carrierSummaryName successfully!')
                        : (isThai
                            ? '🎒 ฝากซองจดหมายผ่าน @$carrierSummaryName เรียบร้อยแล้ว!'
                            : '🎒 Envelope dispatched via @$carrierSummaryName successfully!'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.6)),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

/// 🎙️ เครื่องเล่นข้อความเสียงในกล่องแชท (Voice Message Player Widget)
class VoicePlayerBubble extends StatefulWidget {
  final String audioPath;
  final int durationSeconds;
  final bool isMe;

  const VoicePlayerBubble({
    super.key,
    required this.audioPath,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoicePlayerBubble> createState() => _VoicePlayerBubbleState();
}

class _VoicePlayerBubbleState extends State<VoicePlayerBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (File(widget.audioPath).existsSync()) {
        await _player.play(DeviceFileSource(widget.audioPath));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displaySec = _isPlaying
        ? _position.inSeconds
        : widget.durationSeconds;
    final minutes = (displaySec ~/ 60).toString().padLeft(2, '0');
    final seconds = (displaySec % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(
            _isPlaying
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            color: widget.isMe ? Colors.white : Colors.blueAccent,
            size: 36,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(12, (index) {
                final height =
                    (index % 3 == 0 ? 16 : (index % 2 == 0 ? 10 : 20))
                        .toDouble();
                final double progressRatio = widget.durationSeconds > 0
                    ? (_position.inSeconds / widget.durationSeconds)
                    : 0.0;
                final bool isPlayed = index < (progressRatio * 12);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: isPlayed ? 1.0 : 0.4)
                        : Colors.blueAccent.withValues(
                            alpha: isPlayed ? 1.0 : 0.4,
                          ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                color: widget.isMe ? Colors.white70 : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
