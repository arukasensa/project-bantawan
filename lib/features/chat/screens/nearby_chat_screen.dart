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
import '../widgets/peer_profile_sheet.dart';
import '../widgets/notice_board_sheet.dart';
import '../widgets/data_mule_sheet.dart';
import 'peer_verification_screen.dart';
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
                _buildConnectionStatus(nearbyService),

                // Show Tab Bar only if not inside a specific private chat room
                if (_currentTabIndex == 0 || _activePrivatePeer == null)
                  _buildSegmentedTabBar(nearbyService),

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isInsidePrivateRoom
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (isInsidePrivateRoom) {
                setState(() {
                  _activePrivatePeer = null;
                  _activePrivatePeerName = null;
                });
                service.activeChatPeerId = null;
              } else {
                service.activeChatPeerId = null;
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: isInsidePrivateRoom
                  ? () {
                      if (activePeer != null) {
                        _showPeerProfile(activePeer, service);
                      } else {
                        _showPeerProfileForName(_activePrivatePeer!, service);
                      }
                    }
                  : null,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isInsidePrivateRoom
                              ? '🔒 @$activeDisplayName'
                              : '#mesh • แชทออฟไลน์',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isInsidePrivateRoom) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.purpleAccent,
                        ),
                      ],
                    ],
                  ),
                  if (isInsidePrivateRoom)
                    activePeer != null
                        ? ListenableBuilder(
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
                                text = '✓ Identity Verified';
                                color = Colors.greenAccent;
                              } else if (trustState == PeerTrustState.changed) {
                                text = '⚠️ Key Changed!';
                                color = Colors.orangeAccent;
                              } else {
                                text = '⚪ Not Verified (แตะเพื่อยืนยัน)';
                                color = Colors.white70;
                              }
                              return Text(
                                text,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          )
                        : const Text(
                            'แตะเพื่อดูบัตรประจำตัวฉุกเฉิน (E2EE)',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ],
              ),
            ),
          ),
          if (isInsidePrivateRoom && activePeer != null)
            ListenableBuilder(
              listenable: IdentityService.instance,
              builder: (context, _) {
                final trustState = IdentityService.instance.getTrustState(
                  activePeer.peerId,
                  activePeer.publicKeyHex,
                );
                Color iconColor;
                IconData iconData;
                switch (trustState) {
                  case PeerTrustState.verified:
                    iconColor = Colors.greenAccent;
                    iconData = Icons.verified_user_rounded;
                    break;
                  case PeerTrustState.changed:
                    iconColor = Colors.orangeAccent;
                    iconData = Icons.warning_amber_rounded;
                    break;
                  case PeerTrustState.unverified:
                  case PeerTrustState.unknown:
                    iconColor = Colors.white54;
                    iconData = Icons.shield_outlined;
                    break;
                }
                return IconButton(
                  icon: Icon(iconData, color: iconColor, size: 22),
                  tooltip: 'ตรวจสอบ Cryptographic Fingerprint',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PeerVerificationScreen(peer: activePeer),
                      ),
                    );
                  },
                );
              },
            ),
          if (isInsidePrivateRoom)
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

          if (!isInsidePrivateRoom)
            ListenableBuilder(
              listenable: service,
              builder: (context, _) {
                final hasUrgent = service.notices.any((n) => n.isUrgent);
                final noticeCount = service.notices.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.campaign_rounded,
                        color: hasUrgent ? Colors.redAccent : Colors.cyanAccent,
                        size: 24,
                      ),
                      tooltip: 'ประกาศ @ #mesh',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        NoticeBoardSheet.show(context, service);
                      },
                    ),
                    if (noticeCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: hasUrgent
                                ? Colors.redAccent
                                : const Color(0xFF00ADB5),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              noticeCount > 9 ? '9+' : '$noticeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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

          // 🎒 ปุ่มเปิดแผงควบคุมระบบคนเดินสาร (Data Mule)
          ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              final muleCount = service.carriedEnvelopes.length;
              final hasUrgent = service.carriedEnvelopes.any((e) => e.isUrgentSOS);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.backpack_rounded,
                      color: muleCount > 0
                          ? (hasUrgent ? Colors.redAccent : Colors.purpleAccent)
                          : (service.isDataMuleEnabled
                              ? Colors.purpleAccent.withValues(alpha: 0.7)
                              : Colors.white24),
                      size: 22,
                    ),
                    tooltip: 'คนเดินสาร (Data Mule)',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      DataMuleSheet.show(context, service);
                    },
                  ),
                  if (muleCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: hasUrgent ? Colors.redAccent : Colors.purpleAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            muleCount > 9 ? '9+' : '$muleCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
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

          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white60,
              size: 22,
            ),
            tooltip: isInsidePrivateRoom
                ? 'ล้างประวัติแชทห้องนี้'
                : 'ล้างประวัติแชทสาธารณะ',
            onPressed: () => _confirmClearChat(service, isInsidePrivateRoom),
          ),
          IconButton(
            icon: Icon(
              service.isAdvertising
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: service.isAdvertising ? Colors.blueAccent : Colors.white24,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (service.isAdvertising) {
                service.stopEmergencyNetwork();
              } else {
                service.startEmergencyNetwork();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(NearbyService service) {
    final count = service.connectedDevices.length;
    final isScanning = service.isAdvertising || service.isDiscovering;

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
            count > 0
                ? AppLocalizations.of(context)!.connectedDevices(count)
                : (isScanning
                      ? AppLocalizations.of(context)!.searchingPeers
                      : "ระบบออฟไลน์ปิดอยู่"),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// แถบสลับโหมด: แชทสาธารณะ (Public) VS แชทส่วนตัว (Private E2EE)
  Widget _buildSegmentedTabBar(NearbyService service) {
    final peersCount = _getDiscoveredMeshPeers(service).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Public Chat Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentTabIndex = 0;
                  _activePrivatePeer = null;
                  _activePrivatePeerName = null;
                });
                service.activeChatPeerId = null;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentTabIndex == 0
                      ? Colors.blueAccent.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _currentTabIndex == 0
                        ? Colors.blueAccent.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hub_rounded, size: 16, color: Colors.blueAccent),
                    SizedBox(width: 6),
                    Text(
                      '#mesh สาธารณะ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Private Chat Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentTabIndex = 1;
                  _activePrivatePeer = null;
                  _activePrivatePeerName = null;
                });
                service.activeChatPeerId = null;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentTabIndex == 1
                      ? Colors.purpleAccent.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _currentTabIndex == 1
                        ? Colors.purpleAccent.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.alternate_email_rounded,
                      size: 15,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'แชทส่วนตัว',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (peersCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$peersCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
        Expanded(
          child: publicMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white10,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noMessages,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white24),
                      ),
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

  /// View 2: รายชื่อผู้ใช้ใกล้เคียงและประวัติแชทส่วนตัว (Private Discovered Peers & Recent Contacts List View)
  Widget _buildPrivatePeersListView(NearbyService service) {
    final peers = _getDiscoveredMeshPeers(service);

    if (peers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.purpleAccent,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ยังไม่มีประวัติแชทหรือโหนดใกล้เคียง',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'เมื่อคุณค้นพบโหนดข้างเคียง หรือเคยสนทนากับเพื่อน รายชื่อจะปรากฏตรงนี้เพื่อให้คุณกดเปิดแชทส่วนตัวหรือฝากข้อความ E2EE ได้ทันที',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: _buildPeerTileList(service, peers),
    );
  }

  List<Widget> _buildPeerTileList(NearbyService service, List<MeshPeer> peers) {
    return peers.map((peer) {
      final status = service.getPeerConnectionStatus(peer);
      final bool isDirect = status == PeerConnectionStatus.direct;
      final bool isOffline = status == PeerConnectionStatus.offline;
      final Color statusColor = isDirect
          ? Colors.greenAccent
          : (status == PeerConnectionStatus.relayed
                ? Colors.purpleAccent
                : Colors.white38);
      final String statusText = isDirect
          ? 'เชื่อมต่อตรง (Direct BLE)'
          : (status == PeerConnectionStatus.relayed
                ? 'ผ่าน Mesh Relay (${peer.hopCount} ทอด)'
                : 'หลุดการติดต่อ (Offline • ฝากข้อความได้)');

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
              Text(
                peer.peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
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
                        : (isOffline ? Colors.white38 : Colors.purpleAccent),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
                  isOffline ? Icons.mail_outline_rounded : Icons.chat_rounded,
                  size: 14,
                ),
                label: Text(buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOffline
                      ? (pendingCount > 0
                            ? Colors.orangeAccent.withValues(alpha: 0.25)
                            : Colors.amberAccent.withValues(alpha: 0.15))
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
                                : Colors.amberAccent.withValues(alpha: 0.6))
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

    final String title = isInsidePrivateRoom
        ? 'ล้างแชทกับ $activeDisplayName?'
        : 'ล้างประวัติแชทสาธารณะ?';

    final String message = isInsidePrivateRoom
        ? 'ข้อความทั้งหมดในห้องแชทส่วนตัวนี้จะถูกลบออกจากฐานข้อมูลเครื่องของคุณอย่างถาวร'
        : 'ข้อความแชทสาธารณะทั้งหมดในเครื่องจะถูกล้าง (ไม่รวมข้อความส่วนตัว)';

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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
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
          message,
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
              'ล้างข้อความ',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                  ? 'ล้างข้อความกับ $activeDisplayName เรียบร้อยแล้ว'
                  : 'ล้างข้อความแชทสาธารณะเรียบร้อยแล้ว',
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
        Expanded(
          child: privateMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_person_rounded,
                        color: Colors.purpleAccent,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'เริ่มแชทส่วนตัวเข้ารหัสลับกับ $peerDisplayName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ข้อความทั้งหมดจะถูกเข้ารหัสแบบ E2EE ปลอดภัย 100%',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: privateMessages.length,
                  itemBuilder: (context, index) {
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

  /// แปลง Peer ID เป็น Display Name ที่เป็นมิตร (ไม่แสดง node_xxx หากมีชื่อเดิมที่เคยรู้จัก)
  String _resolvePeerDisplayName(
    NearbyService service,
    String peerId, [
    String? fallbackName,
  ]) {
    if (fallbackName != null &&
        fallbackName.trim().isNotEmpty &&
        !fallbackName.startsWith('node_')) {
      return fallbackName.trim();
    }
    final resolvedPeer = _resolveActivePeer(service, peerId);
    if (resolvedPeer != null &&
        resolvedPeer.peerName.trim().isNotEmpty &&
        !resolvedPeer.peerName.startsWith('node_')) {
      return resolvedPeer.peerName.trim();
    }
    for (final msg in service.messages.reversed) {
      if (msg.senderId == peerId &&
          msg.senderName.trim().isNotEmpty &&
          !msg.senderName.startsWith('node_')) {
        return msg.senderName.trim();
      }
      if (msg.recipientId == peerId &&
          msg.recipientName != null &&
          msg.recipientName!.trim().isNotEmpty &&
          !msg.recipientName!.startsWith('node_')) {
        return msg.recipientName!.trim();
      }
    }
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      return fallbackName.trim();
    }
    return peerId;
  }

  List<MeshPeer> _getDiscoveredMeshPeers(NearbyService service) {
    final map = Map<String, MeshPeer>.from(service.discoveredMeshPeers);

    // 1. ดึงรายชื่อเพื่อนจาก IdentityService (Trust Store / Known Identities)
    for (var trust in IdentityService.instance.allTrustedPeers) {
      if (trust.peerId != service.nodeId &&
          trust.peerId != service.deviceName) {
        if (!map.containsKey(trust.peerId)) {
          // โหนดออฟไลน์ที่เคยรู้จักและมี Public Key บันทึกไว้
          map[trust.peerId] = MeshPeer(
            peerId: trust.peerId,
            peerName: trust.displayName,
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
        map[targetId] = MeshPeer(
          peerId: targetId,
          peerName: targetName?.isNotEmpty == true ? targetName! : targetId,
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

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
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
        await service.sendVoiceMessage(
          audioPath: path,
          durationSeconds: duration,
          recipientId: isPrivate ? targetPeerId : null,
          recipientName: isPrivate ? targetPeerName : null,
        );
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

  /// 📷 เลือกรูปภาพจากกล้องหรือคลังและส่งผ่าน Mesh
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await service.sendImageMessage(
          imagePath: pickedFile.path,
          recipientId: isPrivate ? targetPeerId : null,
          recipientName: isPrivate ? targetPeerName : null,
        );
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
                              color: Colors.purpleAccent,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '🔒 E2EE Direct',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
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
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
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
    } else if (status == 'CARRIED') {
      return Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.purpleAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎒', style: TextStyle(fontSize: 8)),
            SizedBox(width: 2),
            Text(
              'ฝากคนเดินสาร',
              style: TextStyle(
                fontSize: 9,
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
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
    } else {
      return const Icon(
        Icons.access_time_rounded,
        size: 10,
        color: Colors.white54,
      );
    }
  }

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
              'กำลังบันทึกเสียง... $minutes:$seconds',
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
        color: Colors.white.withValues(alpha: 0.05),
        border: const Border(top: BorderSide(color: Colors.white10)),
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
                            onPressed: () async {
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
                                final pos =
                                    await Geolocator.getCurrentPosition();
                                if (isPrivate && targetPeerId != null) {
                                  await service.sendPrivateLocation(
                                    recipientId: targetPeerId,
                                    recipientName:
                                        targetPeerName ?? targetPeerId,
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
                                      AppLocalizations.of(
                                        context,
                                      )!.locationError,
                                    ),
                                  ),
                                );
                              }
                            },
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
