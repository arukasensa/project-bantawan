import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter1/features/home/services/profile_service.dart';
import '../models/mesh_peer.dart';
import '../models/mesh_notice.dart';
import '../models/mule_envelope.dart';
import 'crypto_mesh_service.dart';
import 'identity_service.dart';
import 'chat_database_helper.dart';

/// ============================================================================
/// 🏗️ BANTAWAN Layered Network & Security Architecture
/// 
/// ┌─────────────────────────────────────────────────────────┐
/// │                     BANTAWAN App                        │
/// │      (UI / Offline Chat / SOS Alert / Location Pin)     │
/// ├─────────────────────────────────────────────────────────┤
/// │                   E2EE Security Layer                   │
/// │   (CryptoMeshService: X25519 ECDH + HKDF + AES-256-GCM) │
/// ├─────────────────────────────────────────────────────────┤
/// │                BANTAWAN Mesh Routing Engine             │
/// │   (NearbyService: Multi-hop Relay + TTL + RPRT + Dedup)  │
/// ├─────────────────────────────────────────────────────────┤
/// │            Transport Layer (Nearby Connections)          │
/// │        (Google Nearby P2P Cluster: BLE + Wi-Fi Direct)   │
/// └─────────────────────────────────────────────────────────┘
/// 
/// 📦 1. Data Structure Model: NearbyMessage
/// โครงสร้างข้อมูลแพ็กเก็ตข้อความสำหรับการส่งผ่านเครือข่ายไร้สายออฟไลน์ (Offline Mesh Network)
/// ============================================================================
class NearbyMessage {
  final String id;             // ไอดีประจำข้อความ (สุ่ม UUID v4)
  final String senderId;       // ไอดี/ชื่ออุปกรณ์ผู้ส่งต้นทาง
  final String senderName;     // ชื่อผู้ส่งที่จะแสดงบนหน้าจอ
  final String? recipientId;   // ไอดีผู้รับเป้าหมาย (หากเป็น null หรือ 'ALL' หมายถึง Broadcast สาธารณะ)
  final String? recipientName; // ชื่อผู้รับเป้าหมาย
  final String content;        // เนื้อหาข้อความ (หากเข้ารหัสไว้ จะเป็น String CipherText)
  final DateTime timestamp;    // เวลาที่ส่งข้อความ
  final double? latitude;      // พิกัดละติจูด (กรณีแชร์พิกัดฉุกเฉิน)
  final double? longitude;     // พิกัดลองจิจูด (กรณีแชร์พิกัดฉุกเฉิน)
  final bool isLocation;       // ธงระบุว่าเป็นแพ็กเก็ตแชร์พิกัดหรือไม่
  final bool isSOS;            // ธงระบุว่าเป็นสัญญาณเตือนภัยฉุกเฉิน SOS หรือไม่
  final bool isEncrypted;      // ธงระบุว่าข้อความนี้ถูกเข้ารหัสแบบ End-to-End (E2EE) หรือไม่
  final int ttl;               // Time-To-Live: จำนวนทอดสูงสุดที่ข้อความสามารถรีเลย์ข้ามโหนดไปได้
  final bool isRelayed;        // ธงระบุว่าแพ็กเก็ตนี้เดินทางผ่านโหนดกลางทาง (Relay Node) มาหรือไม่

  // --- ฟิลด์สำหรับข้อความสื่อ (Voice / Photo Attachments) ---
  final String? mediaPath;      // พาธไฟล์สื่อบนเครื่องท้องถิ่น (.jpg, .m4a)
  final String? mediaType;      // ประเภทสื่อ: 'IMAGE', 'AUDIO', 'NONE'
  final int? durationSeconds;   // ความยาวคลิปเสียง (วินาที)
  final String? base64Data;     // ข้อมูลไฟล์ Base64 สำหรับส่งผ่านเครือข่าย

  // --- ฟิลด์สำหรับ Mesh Peer Discovery & Profile Sharing ---
  final bool isPeerAnnounce;   // ธงระบุว่าเป็นแพ็กเก็ตประกาศการมีอยู่ของโหนดใน Mesh
  final String? peerPublicKey; // X25519 Public Key ของโหนดเจ้าของประกาศ
  final int hopCount;          // จำนวนทอดระยะห่างจากโหนดต้นทาง (1 = Direct, 2+ = Relayed)
  final Map<String, String>? profileData; // ข้อมูลโปรไฟล์ทางการแพทย์ฉุกเฉิน (ICE Medical Data)
  final String? signature;     // 🔏 ลายเซ็นดิจิทัลสำหรับยืนยันความถูกต้องของข้อมูล (Digital Signature)

  // --- ฟิลด์สำหรับติดตามสถานะข้อความและการตอบรับ (Reverse Mesh ACK) ---
  final String status;         // สถานะข้อความ: 'SENDING' (กำลังส่ง), 'DELIVERED' (ส่งถึงเครื่องรับ), 'READ' (อ่านแล้ว)
  final bool isAck;            // ธงระบุว่าเป็นแพ็กเก็ตตอบรับ ACK หรือไม่ (ไม่ใช่ข้อความแชททั่วไป)
  final String? ackMessageId;  // ไอดีของข้อความต้นทางที่แพ็กเก็ต ACK นี้กำลังตอบกลับ
  final String? ackType;       // ประเภท ACK: 'DELIVERY' (ส่งถึงแล้ว) หรือ 'READ' (อ่านแล้ว)

  NearbyMessage({
    String? id,
    required this.senderId,
    required this.senderName,
    this.recipientId,
    this.recipientName,
    required this.content,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.isLocation = false,
    this.isSOS = false,
    this.isEncrypted = false,
    this.ttl = 3,
    this.isRelayed = false,
    this.mediaPath,
    this.mediaType,
    this.durationSeconds,
    this.base64Data,
    this.isPeerAnnounce = false,
    this.peerPublicKey,
    this.hopCount = 1,
    this.profileData,
    this.signature,
    this.status = 'SENDING',
    this.isAck = false,
    this.ackMessageId,
    this.ackType,
  }) : id = id ?? generateUuidV4();

  /// 🆔 สุ่มสร้าง UUID v4 มาตรฐานสากล (RFC 4122) ป้องกันไอดีแพ็กเก็ตชนกัน 100%
  static String generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // กำหนด RFC 4122 Version 4 (0100) และ Variant (10)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// เมธอดสำหรับคัดลอกและสร้างอินสแตนซ์ใหม่พร้อมอัปเดตฟิลด์บางส่วน (Immutable State Pattern)
  NearbyMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    String? content,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    bool? isLocation,
    bool? isSOS,
    bool? isEncrypted,
    int? ttl,
    bool? isRelayed,
    String? mediaPath,
    String? mediaType,
    int? durationSeconds,
    String? base64Data,
    bool? isPeerAnnounce,
    String? peerPublicKey,
    int? hopCount,
    Map<String, String>? profileData,
    String? signature,
    String? status,
    bool? isAck,
    String? ackMessageId,
    String? ackType,
  }) {
    return NearbyMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocation: isLocation ?? this.isLocation,
      isSOS: isSOS ?? this.isSOS,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      ttl: ttl ?? this.ttl,
      isRelayed: isRelayed ?? this.isRelayed,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      base64Data: base64Data ?? this.base64Data,
      isPeerAnnounce: isPeerAnnounce ?? this.isPeerAnnounce,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
      hopCount: hopCount ?? this.hopCount,
      profileData: profileData ?? this.profileData,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      isAck: isAck ?? this.isAck,
      ackMessageId: ackMessageId ?? this.ackMessageId,
      ackType: ackType ?? this.ackType,
    );
  }

  /// แปลงออบเจกต์ NearbyMessage ให้เป็น Map (JSON Object) สำหรับแปลงเป็นไบต์ก่อนส่งผ่าน Bluetooth/Wi-Fi
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'recipientId': recipientId,
    'recipientName': recipientName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'isLocation': isLocation,
    'isSOS': isSOS,
    'isEncrypted': isEncrypted,
    'ttl': ttl,
    'isRelayed': isRelayed,
    if (mediaType != null) 'mediaType': mediaType,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (base64Data != null) 'base64Data': base64Data,
    'isPeerAnnounce': isPeerAnnounce,
    'peerPublicKey': peerPublicKey,
    'hopCount': hopCount,
    if (profileData != null) 'profileData': profileData,
    if (signature != null) 'signature': signature,
    'status': status,
    'isAck': isAck,
    'ackMessageId': ackMessageId,
    'ackType': ackType,
  };

  /// แปลงข้อมูล JSON ที่ได้รับจากโครงข่ายคลื่นวิทยุไร้สายกลับเป็นออบเจกต์ NearbyMessage
  factory NearbyMessage.fromJson(Map<String, dynamic> json) => NearbyMessage(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? 'unknown',
    senderName: json['senderName'] ?? 'Survivor',
    recipientId: json['recipientId'],
    recipientName: json['recipientName'],
    content: json['content'] ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isLocation: json['isLocation'] ?? false,
    isSOS: json['isSOS'] ?? false,
    isEncrypted: json['isEncrypted'] ?? false,
    ttl: json['ttl'] ?? 3,
    isRelayed: json['isRelayed'] ?? false,
    mediaPath: json['mediaPath'],
    mediaType: json['mediaType'],
    durationSeconds: json['durationSeconds'],
    base64Data: json['base64Data'],
    isPeerAnnounce: json['isPeerAnnounce'] ?? false,
    peerPublicKey: json['peerPublicKey'],
    hopCount: json['hopCount'] ?? 1,
    profileData: json['profileData'] != null
        ? Map<String, String>.from(json['profileData'])
        : null,
    signature: json['signature'],
    status: json['status'] ?? 'SENDING',
    isAck: json['isAck'] ?? false,
    ackMessageId: json['ackMessageId'],
    ackType: json['ackType'],
  );
}

/// 🛡️ True LRU + TTL Bounded Cache Engine:
/// ระบบบริหารจัดการหน่วยความจำแคช Message ID ควบคุมขนาดเมมโมรีไม่ให้โตเกินขีดจำกัด (Bounded Memory Safety)
/// ทำการตัดลบไอดีเก่าสุด (LRU Eviction) เมื่อจำนวนเกิน 1,000 รายการ และล้างไอดีที่อายุเกิน 15 นาทีอัตโนมัติ (TTL Purge)
class LruMessageIdCache {
  static const int _maxEntries = 1000;
  static const Duration _ttl = Duration(minutes: 15);
  final Map<String, DateTime> _cache = {};

  bool contains(String id) {
    _cleanExpired();
    final timestamp = _cache.remove(id);
    if (timestamp != null) {
      _cache[id] = timestamp; // เลื่อนมาเป็น Most Recently Used
      return true;
    }
    return false;
  }

  void add(String id) {
    _cleanExpired();
    if (_cache.containsKey(id)) {
      _cache.remove(id);
    } else if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first); // Evict Least Recently Used
    }
    _cache[id] = DateTime.now();
  }

  void _cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, timestamp) => now.difference(timestamp) > _ttl);
  }

  void clear() => _cache.clear();
}


/// ============================================================================
/// 🌐 2. Core Service Engine: NearbyService
/// ตัวจัดการการสื่อสารออฟไลน์ระดับแอปพลิเคชัน (Singleton Pattern + Provider State Management)
/// ============================================================================
class NearbyService extends ChangeNotifier {
  // สร้าง Singleton Instance ให้เรียกใช้งานออบเจกต์ตัวเดียวตรงกันทั่วทั้งแอปพลิเคชัน
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  /// ยุทธศาสตร์การสื่อสาร (Strategy Pattern):
  /// ใช้ Strategy.P2P_CLUSTER ซึ่งสนับสนุนเครือข่ายออฟไลน์แบบ Peer-to-Peer Ad-hoc Cluster (M2M)
  /// อนุญาตให้แต่ละอุปกรณ์ทำหน้าที่เป็นทั้งโหนดค้นหา (Discoverer) และโหนดโฆษณาสัญญาณ (Advertiser)
  final Strategy strategy = Strategy.P2P_CLUSTER;

  String deviceName = "Survivor"; // ชื่อเรียกประจำอุปกรณ์ (Device Callsign)

  Map<String, String> connectedDevices = {}; // ตารางเก็บอุปกรณ์ที่เชื่อมต่อโดยตรง (endpointId -> deviceName)
  List<NearbyMessage> messages = [];         // รายการข้อความแชททั้งหมดในเซสชัน

  /// 📌 รายการประกาศฉุกเฉินสาธารณะออฟไลน์ (Offline Notice Board @ #mesh)
  List<MeshNotice> notices = [];

  /// 🌐 ตารางจัดเก็บข้อมูลโหนดที่ค้นพบในเครือข่าย Multi-hop Mesh (peerId -> MeshPeer)
  final Map<String, MeshPeer> discoveredMeshPeers = {};
  Timer? _peerAnnounceTimer;

  /// 🌐 ตรวจสอบสถานะการเชื่อมต่อจริงของโหนดในโครงข่าย Mesh แบบ Real-time
  /// ป้องกัน Ghost Node (สถานะค้าง): หากเครื่องเราไม่มีอุปกรณ์เชื่อมต่อตรงเหลืออยู่เลย
  /// หรือสะพานตัวกลาง (Relay Link) หลุดการเชื่อมต่อไป จะถือว่าโหนดนั้น Offline ทันที
  PeerConnectionStatus getPeerConnectionStatus(MeshPeer peer) {
    // 1. หากเครื่องเราไม่มีบลูทูธเชื่อมต่อกับอุปกรณ์ใดๆ เลย โหนดทั้งหมดในโลกต้องเป็น Offline ทันที
    if (connectedDevices.isEmpty) {
      return PeerConnectionStatus.offline;
    }

    // 2. กรณีเป็น Direct BLE Node (1 hop)
    if (peer.hopCount == 1) {
      if (peer.directEndpoint != null && connectedDevices.containsKey(peer.directEndpoint)) {
        return PeerConnectionStatus.direct;
      }
      if (connectedDevices.containsValue(peer.peerName)) {
        return PeerConnectionStatus.direct;
      }
      return PeerConnectionStatus.offline;
    }

    // 3. กรณีเป็น Multi-hop Relayed Node (2+ hops)
    if (peer.isReachable) {
      // ตรวจสอบว่าเส้นทาง Reverse Path สำหรับโหนดนี้ยังชี้ไปยังโหนดตรงที่เชื่อมต่ออยู่หรือไม่
      final nextHopEndpoint = _reversePathTable[peer.peerId] ??
          (peer.hopCount > 1 ? peer.directEndpoint : null);
      if (nextHopEndpoint == null || !connectedDevices.containsKey(nextHopEndpoint)) {
        // โหนดตัวกลางที่เป็นสะพานทางผ่านหลุดไปแล้ว หรือไม่มีสะพานเชื่อมต่อตรงที่ใช้งานได้จริง
        return PeerConnectionStatus.offline;
      }
      return PeerConnectionStatus.relayed;
    }

    return PeerConnectionStatus.offline;
  }

  /// 🛡️ ตารางบันทึก Endpoint ที่กำลังอยู่ระหว่าง Handshake / Request Connection
  /// ป้องกัน Dual-Initiator Collision เมื่อทั้ง 2 ฝั่งค้นพบกันพร้อมกัน
  final Set<String> _pendingConnectionEndpoints = {};

  /// 🛡️ ป้องกัน Broadcast Storming (LRU + TTL Bounded Deduplication Check):
  /// ใช้ LruMessageIdCache ควบคุมขนาดหน่วยความจำคงที่ จำกัด 1,000 ไอดี ล้างไอดีเก่าเกิน 15 นาที
  final LruMessageIdCache _processedMessageIds = LruMessageIdCache();

  /// 🧭 Dynamic Reverse Path Routing Table (RPRT):
  /// บันทึกเส้นทางย้อนกลับ (Message ID / Sender ID -> Endpoint ID ที่ส่งข้อมูลมา)
  /// ใช้ส่งแพ็กเก็ต ACK ย้อนกลับแบบ Unicast โดยไม่ต้องสุ่ม Flood ทั้งเครือข่าย
  final Map<String, String> _reversePathTable = {};

  bool isAdvertising = false; // สถานะกำลังกระจายสัญญาณ
  bool isDiscovering = false; // สถานะกำลังสแกนหาสัญญาณ

  /// 💬 ห้องแชทส่วนตัวที่กำลังเปิดอยู่ในขณะนี้ (peerId) เพื่อไม่ให้แจ้งเตือนซ้ำหากกำลังคุยกันอยู่
  String? activeChatPeerId;

  // --- 🎒 Data Mule (Deprecated / Disabled in favor of Direct & Multi-hop Mesh) ---
  bool isDataMuleEnabled = false;
  List<MuleEnvelope> carriedEnvelopes = [];
  Future<void> loadCarriedEnvelopes() async {}
  void toggleDataMule(bool enabled) {}

  /// 🐕 Watchdog Timer สำหรับตรวจสอบและฟื้นฟู Discovery หากไม่พบโหนดนานผิดปกติ
  Timer? _discoveryWatchdogTimer;

  // --- 🚦 Anti-Flood & Rate Limiting System ---
  /// บันทึกเวลาที่ส่งข้อความตัวอักษร 5 ครั้งล่าสุด เพื่อคำนวณ Rate limit (Sliding Window: สูงสุด 5 ข้อความ ใน 5 วินาที)
  final List<DateTime> _recentTextTimestamps = [];

  /// บันทึกเวลาส่ง SOS ครั้งล่าสุด (Cooldown 3 วินาที)
  DateTime? _lastSosTime;

  /// บันทึกเวลาส่งมีเดีย/เสียง/รูปภาพ ครั้งล่าสุด (Cooldown 4 วินาที)
  DateTime? _lastMediaTime;

  /// ความยาวสูงสุดของข้อความตัวอักษร (1,000 ตัวอักษร)
  static const int maxMessageLength = 1000;

  /// 🚦 ตรวจสอบว่าสามารถส่งข้อความประเภทนี้ได้หรือไม่ (คืนค่า null หากส่งได้ หรือคืนข้อความเตือนหากติด Rate Limit)
  String? checkRateLimit({
    required String type, // 'TEXT', 'SOS', 'MEDIA', 'LOCATION'
    String? content,
  }) {
    final now = DateTime.now();

    if (type == 'TEXT') {
      if (content != null && content.length > maxMessageLength) {
        return 'ข้อความยาวเกินกำหนด (สูงสุด $maxMessageLength ตัวอักษร)';
      }
      // ทำความสะอาด timestamps ที่เก่ากว่า 5 วินาที
      _recentTextTimestamps.removeWhere((t) => now.difference(t).inSeconds >= 5);
      if (_recentTextTimestamps.length >= 5) {
        return 'ส่งข้อความถี่เกินไป กรุณารอสักครู่ (จำกัด 5 ข้อความ/5 วินาที)';
      }
    } else if (type == 'SOS') {
      if (_lastSosTime != null && now.difference(_lastSosTime!).inSeconds < 3) {
        final remaining = 3 - now.difference(_lastSosTime!).inSeconds;
        return 'กรุณารอ $remaining วินาทีก่อนส่งสัญญาณ SOS ซ้ำ';
      }
    } else if (type == 'MEDIA') {
      if (_lastMediaTime != null && now.difference(_lastMediaTime!).inSeconds < 4) {
        final remaining = 4 - now.difference(_lastMediaTime!).inSeconds;
        return 'กรุณารอ $remaining วินาทีก่อนส่งไฟล์สื่อ/เสียงซ้ำ';
      }
    }
    return null;
  }

  void _recordSendTimestamp({required String type}) {
    final now = DateTime.now();
    if (type == 'TEXT') {
      _recentTextTimestamps.add(now);
    } else if (type == 'SOS') {
      _lastSosTime = now;
    } else if (type == 'MEDIA') {
      _lastMediaTime = now;
    }
  }

  // --- 🛡️ Ingress & Relay Rate Limiter (ป้องกัน Flood/DoS Attack ฝั่งรับและรีเลย์) ---
  /// บันทึกประวัติเวลาที่ได้รับแพ็กเก็ตจากแต่ละ senderId (senderId -> List of Timestamps)
  final Map<String, List<DateTime>> _ingressTimestamps = {};

  /// บันทึกรายการ senderId ที่ถูกระงับชั่วคราวเนื่องจากพยายาม Flood (senderId -> expireAt)
  final Map<String, DateTime> _ingressBlacklist = {};

  /// 🛡️ ตรวจสอบว่าแพ็กเก็ตจาก senderId นี้ได้รับอนุญาตให้ประมวลผลและรีเลย์หรือไม่
  /// - จำกัดไม่เกิน 10 แพ็กเก็ตใน 5 วินาที ต่อ 1 senderId
  /// - หากเกิน 20 แพ็กเก็ตใน 5 วินาที จะถูก Blacklist ชั่วคราว 60 วินาที
  bool _checkIngressRateLimit(String senderId) {
    if (senderId.isEmpty) return true;
    final now = DateTime.now();

    // 1. ตรวจสอบสถานะ Blacklist ชั่วคราว
    final blacklistedUntil = _ingressBlacklist[senderId];
    if (blacklistedUntil != null) {
      if (now.isBefore(blacklistedUntil)) {
        debugPrint('[INGRESS GUARD] 🚫 Sender $senderId is in cooldown blacklist. Dropped packet.');
        return false;
      } else {
        _ingressBlacklist.remove(senderId); // พ้นกำหนดโทษแบน
      }
    }

    // 2. ตรวจสอบ Sliding Window 5 วินาที
    final timestamps = _ingressTimestamps.putIfAbsent(senderId, () => []);
    timestamps.removeWhere((t) => now.difference(t).inSeconds >= 5);

    if (timestamps.length >= 20) {
      // พยายาม Flood รุนแรง -> แบน 60 วินาที
      _ingressBlacklist[senderId] = now.add(const Duration(seconds: 60));
      debugPrint('[INGRESS GUARD] 🚨 Excessive flooding from $senderId! Blacklisted for 60s.');
      return false;
    }

    if (timestamps.length >= 10) {
      // เกินเพดาน 10 msg/5s -> ดรอปทิ้ง
      debugPrint('[INGRESS GUARD] ⚠️ Rate limit exceeded from $senderId (${timestamps.length} pkts/5s). Dropped.');
      return false;
    }

    timestamps.add(now);
    return true;
  }

  // ระบบแจ้งเตือนภายในเครื่อง (Local System Notification)
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🆔 รหัสประจำตัวโหนดถาวร (Persistent Cryptographic Node ID)
  String get nodeId => CryptoMeshService.nodeId;

  /// 🚀 เริ่มต้นการทำงานของระบบแจ้งเตือน โหลดข้อมูลโปรไฟล์ และเตรียม X25519 Keys
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);

    // เตรียม Cryptographic Keys ก่อนเพื่อนำ nodeId มาใช้สร้าง Callsign เริ่มต้น
    await CryptoMeshService.initKeys();
    await IdentityService.instance.init();
    await updateProfileInfo();

    // 📦 โหลดประวัติข้อความแชทสาธารณะล่าสุดจากฐานข้อมูล SQLite (ควบคุมขนาด Memory ไม่ให้บวม)
    final storedMessages =
        await ChatDatabaseHelper.instance.getPublicMessages(limit: 100);
    if (storedMessages.isNotEmpty) {
      messages = storedMessages;
      notifyListeners();
    }

    // 🧹 ลบข้อความสาธารณะที่เก่าเกิน 24 ชั่วโมง และข้อความออฟไลน์/แพ็กเก็ตที่หมดอายุ
    await ChatDatabaseHelper.instance.purgeExpiredPublicMessages();
    ChatDatabaseHelper.instance.purgeExpiredPending();
    ChatDatabaseHelper.instance.purgeExpiredProcessedPackets();
    await ChatDatabaseHelper.instance.purgeExpiredNotices();
    await loadNotices();
  }

  /// 👤 ดึงข้อมูลชื่อผู้ใช้จาก ProfileService เพื่อตั้งเป็น Callsign และอัปเดตข้อมูลทางการแพทย์ในเครือข่าย Mesh
  Future<void> updateProfileInfo() async {
    final profile = await ProfileService.getProfile();
    final name = profile['name'] ?? '';
    final isAnonymous = profile['anonymousMode'] == 'true';
    final oldName = deviceName;

    final suffix = nodeId.length >= 4
        ? nodeId.substring(nodeId.length - 4)
        : '${Random.secure().nextInt(9000) + 1000}';

    // 👤 ตรวจสอบโหมดไม่ระบุตัวตน (Anonymous / Ghost Mode)
    if (isAnonymous) {
      deviceName = "Survivor_$suffix";
    } else if (name.isNotEmpty) {
      deviceName = name;
    } else {
      deviceName = "Survivor_$suffix";
    }

    // ล้างรายชื่อเครื่องตนเองชื่อเก่าออกจากรายการอุปกรณ์เชื่อมต่อ ป้องกันชื่อซ้ำ
    if (oldName != deviceName) {
      connectedDevices.removeWhere(
        (id, peerName) => peerName == oldName || peerName == deviceName,
      );
    }

    // สร้าง Emergency Profile ตามการตั้งค่า Privacy Controls
    final sanitizedProfile = _buildSanitizedProfile(profile);

    // อัปเดตข้อมูลโหนดเครื่องตนเองใน discoveredMeshPeers ทันที
    discoveredMeshPeers[nodeId] = MeshPeer(
      peerId: nodeId,
      peerName: deviceName,
      publicKeyHex: CryptoMeshService.myPublicKeyHex,
      hopCount: 1,
      lastSeen: DateTime.now(),
      emergencyProfile: sanitizedProfile,
    );

    notifyListeners();

    // หากเปิดระบบ Mesh อยู่ ให้กระจายข้อมูลโปรไฟล์ใหม่ให้เพื่อนในเครือข่ายรับทราบทันที
    if (isAdvertising || isDiscovering || connectedDevices.isNotEmpty) {
      broadcastPeerAnnounce();
    }
  }

  /// 🛡️ สร้าง Map ข้อมูลโปรไฟล์ทางการแพทย์ฉุกเฉินสำหรับส่งผ่าน Mesh (Privacy Filtered)
  Map<String, String> _buildSanitizedProfile(Map<String, String> profile) {
    final shareMedical = profile['shareMedicalInfo'] != 'false'; // default true
    final minimalMedical = profile['minimalMedicalInfo'] == 'true'; // default false

    // 🔒 โหมดปิดการแชร์ข้อมูลการแพทย์ทั้งหมด (Complete Privacy Protection)
    if (!shareMedical) {
      return {
        'name': deviceName,
        'isPrivacyProtected': 'true',
      };
    }

    // 🩺 โหมดแชร์เฉพาะข้อมูลกู้ชีพวิกฤต (Minimal First-Aid: เฉพาะกรุ๊ปเลือด + แพ้ยา)
    if (minimalMedical) {
      return {
        'name': deviceName,
        if (profile['bloodType'] != null && profile['bloodType']!.isNotEmpty)
          'bloodType': profile['bloodType']!,
        if (profile['allergies'] != null && profile['allergies']!.isNotEmpty)
          'allergies': profile['allergies']!,
        'isMinimalShared': 'true',
      };
    }

    // 📋 โหมดมาตรฐาน: แชร์ข้อมูลสุขภาพครบถ้วนเพื่อการช่วยเหลือยามฉุกเฉิน
    return {
      'name': deviceName,
      if (profile['bloodType'] != null && profile['bloodType']!.isNotEmpty)
        'bloodType': profile['bloodType']!,
      if (profile['allergies'] != null && profile['allergies']!.isNotEmpty)
        'allergies': profile['allergies']!,
      if (profile['conditions'] != null && profile['conditions']!.isNotEmpty)
        'conditions': profile['conditions']!,
      if (profile['hospitalPref'] != null && profile['hospitalPref']!.isNotEmpty)
        'hospitalPref': profile['hospitalPref']!,
      if (profile['organDonor'] != null && profile['organDonor']!.isNotEmpty)
        'organDonor': profile['organDonor']!,
      if (profile['age'] != null && profile['age']!.isNotEmpty)
        'age': profile['age']!
      else if (profile['dob'] != null && profile['dob']!.isNotEmpty)
        'age': ProfileService.calculateAge(profile['dob']!),
      if (profile['weight'] != null && profile['weight']!.isNotEmpty)
        'weight': profile['weight']!,
      if (profile['height'] != null && profile['height']!.isNotEmpty)
        'height': profile['height']!,
      if (profile['insurance'] != null && profile['insurance']!.isNotEmpty)
        'insurance': profile['insurance']!,
    };
  }


  /// 🔑 ร้องขอสิทธิ์ในการใช้บลูทูธ, ตำแหน่ง GPS, และการแจ้งเตือน (จำเป็นสำหรับแจ้งเตือนข้อความฉุกเฉินและ BLE)
  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.notification,
    ].request();

    bool isLocationGranted = statuses[Permission.location]?.isGranted ?? false;
    if (!isLocationGranted) return false;

    bool bluetoothGranted =
        (statuses[Permission.bluetoothScan]?.isGranted ?? true) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? true);

    return isLocationGranted && bluetoothGranted;
  }

  /// 📶 เปิดสวิตช์เครือข่ายฉุกเฉินออฟไลน์ (เริ่มต้นทั้ง Advertising และ Discovery)
  /// พร้อม Jitter, Cool-down, และ Auto-Retry Loop ป้องกัน BLE Packet Collision & Android Throttling
  Future<void> startEmergencyNetwork() async {
    final hasPerm = await checkPermissions();
    if (!hasPerm) {
      debugPrint("Nearby: Missing permissions");
      return;
    }

    try {
      await stopEmergencyNetwork();

      // ⏳ Warm-up Delay 1200ms ให้ระบบปฏิบัติการ Android และชิป Bluetooth เปิดทำงานอย่างสมบูรณ์
      // ป้องกันกรณีผู้ใช้เพิ่งเปิดบลูทูธแล้วฮาร์ดแวร์ยังไม่พร้อม (STATE_TURNING_ON -> STATE_ON)
      await Future.delayed(const Duration(milliseconds: 1200));

      // 🎲 1. Randomized Startup Jitter (100ms - 500ms)
      final jitterMs = 100 + Random().nextInt(400);
      await Future.delayed(Duration(milliseconds: jitterMs));

      // ----------------------------------------------------------------------
      // Step 1: Start Advertising (ลองเปิดโฆษณาสัญญาณด้วย Retry Loop 4 ครั้ง + Exponential Backoff)
      // ----------------------------------------------------------------------
      bool adSuccess = false;
      for (int attempt = 1; attempt <= 4; attempt++) {
        try {
          await Nearby().startAdvertising(
            deviceName,
            strategy,
            onConnectionInitiated: (id, info) {
              _pendingConnectionEndpoints.add(id);
              _onConnectionInitiated(id, info);
            },
            onConnectionResult: (id, status) {
              _pendingConnectionEndpoints.remove(id);
              if (status == Status.CONNECTED) {
                // ✅ Fix 1: populate connectedDevices เฉพาะตอน CONNECTED จริง
                connectedDevices[id] = connectedDevices[id] ?? 'Nearby Peer';
                syncPeersToNewNode(id);
                broadcastPeerAnnounce(targetEndpointId: id);
                _broadcastMeshUpdateToExistingNodes(id);
                debugPrint('[Nearby Advertiser] ✅ Connected: $id (${connectedDevices[id]})');
                // 📬 ส่ง Pending Messages คืนให้ Peer ที่เพิ่ง Connect เข้ามา
                final peerNodeId = discoveredMeshPeers.entries
                    .where((e) => e.value.directEndpoint == id)
                    .map((e) => e.key)
                    .firstOrNull;
                if (peerNodeId != null) {
                  _deliverPendingMessages(id, peerNodeId);
                }
                notifyListeners();
              } else {
                // เชื่อมต่อไม่สำเร็จ — เอา id ออกหากเผลอเพิ่มไว้ก่อนหน้า
                connectedDevices.remove(id);
                debugPrint('[Nearby Advertiser] ❌ Connection failed: $id status=$status');
                notifyListeners();
              }
            },
            onDisconnected: (id) {
              _pendingConnectionEndpoints.remove(id);
              connectedDevices.remove(id);
              for (final entry in discoveredMeshPeers.entries.toList()) {
                if (entry.value.directEndpoint == id) {
                  discoveredMeshPeers[entry.key] = entry.value.copyWith(
                    hopCount: 99,
                    directEndpoint: null,
                    lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
                  );
                }
              }
              _reversePathTable.removeWhere((_, endpoint) => endpoint == id);
              debugPrint('[Nearby Advertiser] 🔌 Disconnected: $id');
              notifyListeners();
              _triggerFastDiscoveryRestart();
            },
            serviceId: "com.bantawan.emergency",
          );
          adSuccess = true;
          break;
        } catch (e) {
          debugPrint("[Nearby Advertising Attempt $attempt Failed]: $e");
          await Future.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
      isAdvertising = adSuccess;

      await Future.delayed(const Duration(milliseconds: 300));

      // ----------------------------------------------------------------------
      // Step 2: Start Discovery (ลองเปิดสแกนค้นหาด้วย Retry Loop 4 ครั้ง)
      // ----------------------------------------------------------------------
      await _startDiscoveryInternal();

      _startPeerAnnounceTimer();
      _startDiscoveryWatchdog();
      notifyListeners();
    } catch (e) {
      debugPrint("Nearby Start Error: $e");
    }
  }

  /// 📡 เริ่มสแกนหาสัญญาณ Discovery ภายใน พร้อม Callback จับคู่ (Auto-Retry 4 ครั้ง)
  Future<void> _startDiscoveryInternal() async {
    for (int attempt = 1; attempt <= 4; attempt++) {
      try {
        await Nearby().startDiscovery(
          deviceName,
          strategy,
          onEndpointFound: (id, name, serviceId) {
            // ✅ Fix 2: ข้ามชื่อตัวเองและป้องกัน Dual-Initiator Conflict
            // หากเชื่อมต่ออยู่แล้ว หรืออยู่ระหว่างส่งคำขอเชื่อมต่อ ให้ข้ามทันที
            if (name == deviceName) return;
            if (connectedDevices.containsKey(id) || _pendingConnectionEndpoints.contains(id)) {
              debugPrint('[Nearby Discovery] ⚠️ Already connected or pending with $id ($name), skipping request.');
              return;
            }

            debugPrint('[Nearby Discovery] 🔍 Found endpoint: $id ($name)');

            // 🛡️ Deterministic Tie-Breaking ป้องกัน Dual-Initiator Collision
            // ให้โหนดที่มีชื่อมากกว่า (Lexicographically) เป็นผู้ส่ง requestConnection ก่อนทันที
            // ส่วนโหนดที่ชื่อน้อยกว่าจะหน่วงเวลา 2.5 - 3.0 วินาที เพื่อรอรับ incoming connection ก่อน
            final shouldInitiateImmediately = deviceName.compareTo(name) > 0;
            final delayMs = shouldInitiateImmediately ? 0 : (2500 + Random().nextInt(500));

            if (!shouldInitiateImmediately) {
              debugPrint('[Nearby Discovery] ⏳ Waiting ${delayMs}ms for higher-order peer $name to initiate...');
            }

            Future.delayed(Duration(milliseconds: delayMs), () {
              if (connectedDevices.containsKey(id) ||
                  _pendingConnectionEndpoints.contains(id) ||
                  !isDiscovering) {
                return;
              }
              _pendingConnectionEndpoints.add(id);
              debugPrint('[Nearby Discovery] 🚀 Requesting connection to: $id ($name)');

              // ร้องขอการเชื่อมต่อยิงจับคู่ (Pairing Connection)
              Nearby().requestConnection(
                deviceName,
                id,
                onConnectionInitiated: (connId, info) {
                  _pendingConnectionEndpoints.add(connId);
                  _onConnectionInitiated(connId, info);
                },
                onConnectionResult: (connResultId, status) {
                  _pendingConnectionEndpoints.remove(connResultId);
                  if (status == Status.CONNECTED) {
                    if (name != deviceName) {
                      connectedDevices[connResultId] = name;
                      syncPeersToNewNode(connResultId);
                      broadcastPeerAnnounce(targetEndpointId: connResultId);
                      _broadcastMeshUpdateToExistingNodes(connResultId);
                      _showProximityAlert(name);
                      debugPrint('[Nearby Discovery] ✅ Connected: $connResultId ($name)');
                      // 📬 ส่ง Pending Messages คืนให้ Peer ที่เพิ่ง Connect เข้ามา
                      Future.delayed(const Duration(seconds: 2), () {
                        final peerNodeId = discoveredMeshPeers.entries
                            .where((e) => e.value.directEndpoint == connResultId)
                            .map((e) => e.key)
                            .firstOrNull;
                        if (peerNodeId != null) {
                          _deliverPendingMessages(connResultId, peerNodeId);
                        }
                      });
                      notifyListeners();
                    }
                  } else {
                    // เชื่อมต่อล้มเหลว — ล้าง id ออก
                    connectedDevices.remove(connResultId);
                    debugPrint('[Nearby Discovery] ❌ Connection failed: $connResultId ($name) status=$status');
                    notifyListeners();
                  }
                },
                onDisconnected: (discId) {
                  _pendingConnectionEndpoints.remove(discId);
                  connectedDevices.remove(discId);
                  for (final entry in discoveredMeshPeers.entries.toList()) {
                    if (entry.value.directEndpoint == discId) {
                      discoveredMeshPeers[entry.key] = entry.value.copyWith(
                        hopCount: 99,
                        directEndpoint: null,
                        lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
                      );
                    }
                  }
                  _reversePathTable.removeWhere((_, endpoint) => endpoint == discId);
                  debugPrint('[Nearby Discovery] 🔌 Disconnected: $discId');
                  notifyListeners();
                  _triggerFastDiscoveryRestart();
                },
              ).catchError((e) {
                _pendingConnectionEndpoints.remove(id);
                debugPrint('[Nearby Discovery] ⚠️ requestConnection error: $e');
                return false;
              });
            });
          },
          onEndpointLost: (id) {
            debugPrint('[Nearby Discovery] 📡 Endpoint lost: $id');
          },
          serviceId: "com.bantawan.emergency",
        );
        isDiscovering = true;
        break;
      } catch (e) {
        debugPrint("[Nearby Discovery Attempt $attempt Failed]: $e");
        await Future.delayed(Duration(milliseconds: 600 * attempt));
      }
    }
  }

  /// 🌐 กระจายข้อมูลให้โหนดเดิมใน Mesh ทราบว่ามีโหนดใหม่เชื่อมต่อเข้ามา (Instant Mesh Discovery Propagation)
  Future<void> _broadcastMeshUpdateToExistingNodes(String newEndpointId) async {
    // หน่วงเวลา 600ms ให้ Node Announce ของโหนดใหม่เดินทางมาถึงและบันทึกใน discoveredMeshPeers เรียบร้อย
    await Future.delayed(const Duration(milliseconds: 600));
    final newPeerEntry = discoveredMeshPeers.entries
        .where((e) => e.value.directEndpoint == newEndpointId)
        .firstOrNull;

    if (newPeerEntry != null) {
      final newPeer = newPeerEntry.value;
      final announceMsg = NearbyMessage(
        senderId: newPeer.peerId,
        senderName: newPeer.peerName,
        content: 'PEER_ANNOUNCE',
        timestamp: DateTime.now(),
        isPeerAnnounce: true,
        peerPublicKey: newPeer.publicKeyHex,
        hopCount: 2, // โหนดอื่นใน Mesh จะเห็นเป็น 2 ทอด (ผ่านเครื่องเรา)
        profileData: newPeer.emergencyProfile,
        ttl: 3,
        isRelayed: true,
      );
      _processedMessageIds.add(announceMsg.id);
      final bytes = utf8.encode(jsonEncode(announceMsg.toJson()));
      for (var existingEndpoint in connectedDevices.keys.toList()) {
        if (existingEndpoint != newEndpointId) {
          try {
            await Nearby().sendBytesPayload(existingEndpoint, bytes);
            debugPrint('[Mesh Propagate] 📡 Announced new peer ${newPeer.peerName} to existing peer $existingEndpoint');
          } catch (e) {
            debugPrint('[Mesh Propagate] ⚠️ Error announcing new peer to $existingEndpoint: $e');
          }
        }
      }
    }
  }

  DateTime? _lastDiscoveryRestartTime;

  /// 🔄 กระตุ้นการรีสตาร์ท Discovery สั้นๆ เพื่อล้างแคช Bluetooth GATT Stack ของ Android
  void _triggerFastDiscoveryRestart() {
    final now = DateTime.now();
    if (_lastDiscoveryRestartTime != null &&
        now.difference(_lastDiscoveryRestartTime!).inSeconds < 8) {
      return; // Cooldown 8 วินาที ป้องกันวนซ้ำถี่เกินไป
    }
    _lastDiscoveryRestartTime = now;
    Future.delayed(const Duration(milliseconds: 1200), () async {
      // รีเฟรชได้เสมอหากอุปกรณ์เชื่อมต่อตรงยังไม่เต็มโควต้า (< 4 โหนด)
      if (connectedDevices.length < 4) {
        debugPrint('[Nearby] 🔄 Auto-recovering: Fast cycling discovery scanner...');
        try {
          await Nearby().stopDiscovery();
          await Future.delayed(const Duration(milliseconds: 400));
          await _startDiscoveryInternal();
        } catch (e) {
          debugPrint('[Nearby] Error during fast discovery restart: $e');
        }
      }
    });
  }

  /// 🐕 เริ่มระบบ Watchdog ตรวจสอบสถานะทุก 40 วินาที
  /// ป้องกัน BLE Scanner หลับหรือค้างบน Android แม้จะเชื่อมต่อกับ Node A อยู่ ก็ยังสแกนหา Node C เจอ
  void _startDiscoveryWatchdog() {
    _discoveryWatchdogTimer?.cancel();
    _discoveryWatchdogTimer = Timer.periodic(const Duration(seconds: 40), (_) async {
      // 1. ฟื้นฟูระบบกรณี Discovery หลุดการทำงาน (เช่น หลังเปิด-ปิดบลูทูธบนเครื่อง)
      if (!isDiscovering) {
        debugPrint('[Nearby Watchdog] Discovery was inactive. Reviving discovery scanner...');
        await _startDiscoveryInternal();
        return;
      }

      // 2. Soft-cycling: หากเชื่อมต่อตรงยังไม่เต็ม 4 โหนด ให้รีเฟรชสแกนเนอร์เงียบๆ ทุก 40 วินาที
      // การ stopDiscovery / startDiscovery จะไม่ตัดการเชื่อมต่อบลูทูธเดิม แต่จะล้างบัฟเฟอร์ BLE ให้ค้นพบโหนดใหม่ได้ทันที
      if (connectedDevices.length < 4) {
        debugPrint('[Nearby Watchdog] Softly cycling BLE discovery scanner to maintain high-sensitivity discovery...');
        try {
          await Nearby().stopDiscovery();
          await Future.delayed(const Duration(milliseconds: 400));
          await _startDiscoveryInternal();
        } catch (e) {
          debugPrint('[Nearby Watchdog] Error cycling discovery: $e');
        }
      }
    });
  }

  /// ⏹️ ปิดการทำงานของเครือข่ายฉุกเฉินและล้างค่าเซสชัน พร้อม Cool-down Delay 800ms ให้ OS เคลียร์ Bluetooth Socket
  Future<void> stopEmergencyNetwork() async {
    _peerAnnounceTimer?.cancel();
    _peerAnnounceTimer = null;
    _discoveryWatchdogTimer?.cancel();
    _discoveryWatchdogTimer = null;
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (e) {
      debugPrint('[Nearby Stop Error]: $e');
    }
    _pendingConnectionEndpoints.clear();
    connectedDevices.clear();
    discoveredMeshPeers.clear();
    _processedMessageIds.clear();
    isAdvertising = false;
    isDiscovering = false;
    notifyListeners();
    // ⏳ หน่วงเวลา Cool-down 800ms ให้ระบบปฏิบัติการ Android Bluetooth Stack เคลียร์ซ็อกเก็ต GATT ให้เรียบร้อย
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// 💾 บันทึกไฟล์สื่อ Base64 ที่ได้รับลงพื้นที่เก็บข้อมูลของอุปกรณ์
  Future<String?> _saveReceivedMedia({
    required String base64Data,
    required String mediaType,
    required String msgId,
  }) async {
    try {
      final bytes = base64Decode(base64Data);
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/chat_media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final ext = mediaType == 'IMAGE' ? 'jpg' : 'm4a';
      final file = File('${mediaDir.path}/${msgId}_$ext');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving received media file: $e');
      return null;
    }
  }

  /// 🤝 Callback ขั้นตอนการ Handshake สถาปนาการเชื่อมต่อแบบไร้สาย และการรับข้อมูล Payload
  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // ✅ Fix 1: ปฏิเสธการเชื่อมต่อกับตัวเอง
    if (info.endpointName == deviceName) {
      Nearby().rejectConnection(id);
      return;
    }
    // ✅ Fix 1: ไม่เพิ่ม connectedDevices ตรงนี้ — รอให้ onConnectionResult (CONNECTED) เป็นผู้เพิ่ม
    // เพื่อป้องกันสถานะ count ผิดพลาดเมื่อ connection สุดท้าย reject/timeout
    debugPrint('[Nearby] 🤝 Connection initiated with: $id (${info.endpointName})');

    // ยอมรับการเชื่อมต่อ (Accept Connection)
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) async {
        // เมื่อได้รับแพ็กเก็ตข้อมูลประเภท Byte Payload
        if (payload.type == PayloadType.BYTES) {
          final str = utf8.decode(payload.bytes!);
          try {
            final json = jsonDecode(str);

            // 📌 ตรวจสอบว่าเป็นแพ็กเก็ตกระดานประกาศฉุกเฉินออฟไลน์ (Offline Mesh Notice) หรือไม่
            if (json is Map<String, dynamic> && json['isNotice'] == true) {
              await _handleIncomingNotice(json, endpointId);
              return;
            }

            final msg = NearbyMessage.fromJson(json);

            // ------------------------------------------------------------------
            // 🛡️ 1. Anti-Replay Timestamp Window Check (ตรวจสอบอายุแพ็กเก็ต)
            // ------------------------------------------------------------------
            final now = DateTime.now();
            final packetAge = now.difference(msg.timestamp);

            // ปฏิเสธแพ็กเก็ตที่หมดอายุ (เกิน 72 ชม. เพื่อรองรับ Store-and-Forward / Chat History Sync) หรือเวลาเพี้ยน
            if (packetAge.inHours > 72 || packetAge.inSeconds < -300) {
              debugPrint(
                '[REPLAY GUARD] Rejected expired packet ${msg.id} with age ${packetAge.inHours}h',
              );
              return;
            }

            // ------------------------------------------------------------------
            // 🛡️ 2. Unique Message ID & Nonce Tracking (ป้องกันวงกลม/แพ็กเก็ตซ้ำ & Persistent Anti-Replay)
            // ------------------------------------------------------------------
            if (_processedMessageIds.contains(msg.id) ||
                await ChatDatabaseHelper.instance.isPacketProcessed(msg.id)) {
              return; // หากเคยได้รับแพ็กเก็ตไอดีนี้แล้ว ให้ทิ้งทันที
            }
            _processedMessageIds.add(msg.id);
            ChatDatabaseHelper.instance.markPacketProcessed(msg.id);

            // ------------------------------------------------------------------
            // 🛡️ 2.5 Ingress & Relay Rate Limiter Guard (ป้องกัน DoS / Mesh Flooding)
            // ------------------------------------------------------------------
            if (!_checkIngressRateLimit(msg.senderId)) {
              return;
            }

            // ------------------------------------------------------------------
            // 🧭 บันทึก Reverse Path Routing Table สำหรับ Unicast ACK
            // ------------------------------------------------------------------
            _reversePathTable[msg.id] = endpointId;
            _reversePathTable[msg.senderId] = endpointId;
            if (_reversePathTable.length > 2000) {
              _reversePathTable.remove(_reversePathTable.keys.first);
            }

            // ------------------------------------------------------------------
            // 📢 1.5. Mesh Peer Discovery & Public Key Exchange Logic (Gap 1)
            // ------------------------------------------------------------------
            if (msg.isPeerAnnounce) {
              await _handlePeerAnnounce(msg, endpointId);
              return;
            }

            // ------------------------------------------------------------------
            // 📬 2. ACK Packet Interception Logic (การจัดการแพ็กเก็ตใบตอบรับสถานะ)
            // ------------------------------------------------------------------
            if (msg.isAck && msg.ackMessageId != null) {
              debugPrint(
                '[ACK RECEIVED] Message ${msg.ackMessageId} status -> ${msg.ackType} via $deviceName',
              );

              // ค้นหาข้อความต้นทางในรายการ แล้วอัปเดตสถานะเป็น 'DELIVERED' หรือ 'READ'
              final targetIndex = messages.indexWhere(
                (m) => m.id == msg.ackMessageId,
              );
              if (targetIndex != -1) {
                final old = messages[targetIndex];
                final newStatus = msg.ackType == 'READ' ? 'READ' : 'DELIVERED';
                if (old.status != 'READ') {
                  messages[targetIndex] = old.copyWith(status: newStatus);
                  ChatDatabaseHelper.instance.updateMessageStatus(old.id, newStatus);
                  notifyListeners(); // แจ้งเตือน UI ให้เปลี่ยนไอคอนติ๊กถูก
                }
              }

              // Multi-hop Reverse Path ACK Routing: ส่งต่อแพ็กเก็ต ACK ย้อนกลับแบบ Unicast Direct
              if (msg.ttl > 1) {
                final relayedAck = msg.copyWith(
                  ttl: msg.ttl - 1,
                  isRelayed: true,
                );
                final ackBytes = utf8.encode(jsonEncode(relayedAck.toJson()));

                // ค้นหา Reverse Path ใน Routing Table
                final targetEndpoint = _reversePathTable[msg.ackMessageId] ??
                    _reversePathTable[msg.recipientId];

                if (targetEndpoint != null &&
                    connectedDevices.containsKey(targetEndpoint) &&
                    targetEndpoint != endpointId) {
                  // 🎯 Unicast Direct ACK Delivery (เจาะจงส่งตรงผ่านท่อเดียว ไม่เปลืองแบนด์วิดท์)
                  debugPrint('[ACK UNICAST] Relaying ACK directly to $targetEndpoint');
                  try {
                    await Nearby().sendBytesPayload(targetEndpoint, ackBytes);
                  } catch (e) {
                    debugPrint('[ACK UNICAST] Error relaying ACK to $targetEndpoint: $e');
                  }
                } else {
                  // 🔄 Flooding Fallback (กรณีโหนดสายขาด หรือหาเส้นทางตรงไม่เจอ)
                  for (var otherEndpointId in connectedDevices.keys.toList()) {
                    if (otherEndpointId != endpointId) {
                      try {
                        await Nearby().sendBytesPayload(otherEndpointId, ackBytes);
                      } catch (e) {
                        debugPrint('[ACK FLOOD] Error relaying ACK to $otherEndpointId: $e');
                      }
                    }
                  }
                }
              }
              return; // ไม่นำแพ็กเก็ต ACK ไปแสดงผลเป็นกล่องข้อความบน UI
            }

            // ------------------------------------------------------------------
            // 🎯 3. Recipient Verification Logic (ตรวจสอบเป้าหมายผู้รับ)
            // ------------------------------------------------------------------
            final bool isForMe =
                msg.recipientId == null ||
                msg.recipientId == 'ALL' ||
                msg.recipientId == nodeId ||
                msg.recipientId == deviceName ||
                msg.senderId == nodeId ||
                msg.senderId == deviceName;
            final bool isPrivateToMe =
                msg.recipientId == nodeId || msg.recipientId == deviceName;

            if (isForMe) {
              // หากเป็นข้อความแชทส่วนตัวที่ถูกเข้ารหัส (E2EE) ให้ทำการถอดรหัสและ Unpack ข้อมูลลับเฉพาะ
              NearbyMessage processedMsg = msg;

              if (msg.isEncrypted && isPrivateToMe) {
                final decryptedContent = CryptoMeshService.decryptPayload(
                  cipherText: msg.content,
                  recipientId: nodeId,
                  senderId: msg.senderId,
                );

                // หากเนื้อหาเป็น Inner Private JSON Payload ให้ดึงพิกัด ข้อมูลสื่อ และชื่อผู้ส่งกลับมา
                if (decryptedContent.startsWith('{') && decryptedContent.endsWith('}')) {
                  try {
                    final innerJson = jsonDecode(decryptedContent);
                    String? savedMediaPath;
                    final String? base64Str = innerJson['base64Data'];
                    final String? mType = innerJson['mediaType'];
                    if (base64Str != null && mType != null) {
                      savedMediaPath = await _saveReceivedMedia(
                        base64Data: base64Str,
                        mediaType: mType,
                        msgId: msg.id,
                      );
                    }

                    processedMsg = msg.copyWith(
                      content: innerJson['content'] as String? ?? decryptedContent,
                      senderName: innerJson['senderName'] as String? ?? msg.senderName,
                      latitude: (innerJson['latitude'] as num?)?.toDouble() ?? msg.latitude,
                      longitude: (innerJson['longitude'] as num?)?.toDouble() ?? msg.longitude,
                      mediaType: mType ?? msg.mediaType,
                      durationSeconds: innerJson['durationSeconds'] as int? ?? msg.durationSeconds,
                      mediaPath: savedMediaPath ?? msg.mediaPath,
                    );
                  } catch (_) {
                    processedMsg = msg.copyWith(content: decryptedContent);
                  }
                } else {
                  processedMsg = msg.copyWith(content: decryptedContent);
                }
              } else if (!msg.isEncrypted && msg.base64Data != null && msg.mediaType != null) {
                // สำหรับแชทสาธารณะ Public Mesh ที่มี Base64 Media
                final savedMediaPath = await _saveReceivedMedia(
                  base64Data: msg.base64Data!,
                  mediaType: msg.mediaType!,
                  msgId: msg.id,
                );
                processedMsg = msg.copyWith(
                  mediaPath: savedMediaPath,
                  base64Data: null,
                );
              }

              messages.insert(0, processedMsg);
              ChatDatabaseHelper.instance.insertMessage(
                processedMsg,
                myNodeId: nodeId,
                myDeviceName: deviceName,
              );

              // แสดงสัญญาณเตือนตามประเภทข้อความ
              if (msg.isSOS) {
                _showSOSAlert(msg.senderName, msg.content);
              } else if (isPrivateToMe) {
                // แจ้งเตือนข้อความส่วนตัว (หากไม่ได้เปิดแชทกับคนนี้อยู่ตรงหน้า)
                if (activeChatPeerId != msg.senderId) {
                  _showPrivateMessageAlert(msg.senderName, processedMsg.content);
                }

                // 📬 ส่งสัญญาณ DELIVERY ACK ตอบกลับไปยังผู้ส่งต้นทาง (Reverse Mesh)
                sendAck(
                  ackMessageId: msg.id,
                  recipientId: msg.senderId,
                  ackType: 'DELIVERY',
                );
              } else {
                // ข้อความแชทสาธารณะ (Public Mesh Message) แจ้งเตือนข้อความเข้า
                _showPublicMessageAlert(msg.senderName, processedMsg.content);
              }
              notifyListeners();
            } else {
              // 🤫 Silent Relay: หากข้อความนี้ส่งถึงคนอื่น เครื่องของเราทำหน้าที่เป็นเพียงสะพานรีเลย์ข้อมูลเงียบๆ
              // โดยจะไม่แสดงข้อความบน UI และไม่สามารถอ่านเนื้อหาที่เข้ารหัสไว้ได้
              debugPrint(
                '[SILENT RELAY] Message ${msg.id} targeted for ${msg.recipientId}. Relaying silently through $deviceName...',
              );
            }

            // ------------------------------------------------------------------
            // 🔄 4. Multi-hop Silent Relay Engine (กระบวนการรีเลย์ข้อมูลด้วย TTL Sanitization)
            // ------------------------------------------------------------------
            // หากข้อความส่วนตัวนี้ส่งถึงเราโดยตรง (ปลายทางคือเรา) ไม่จำเป็นต้องรีเลย์ต่อ
            // รีเลย์เฉพาะข้อความที่ส่งถึงคนอื่น หรือข้อความ Broadcast / SOS สาธารณะ
            if (!isPrivateToMe) {
              final effectiveTtl = min(msg.ttl, 5);
              if (effectiveTtl > 1) {
                final relayedMsg = msg.copyWith(
                  ttl: effectiveTtl - 1,
                  isRelayed: true,
                );
                final relayBytes = utf8.encode(jsonEncode(relayedMsg.toJson()));

                // 🎯 Smart Routing: หากเป็นข้อความส่วนตัว และมี Reverse Path ชี้ไปยังเป้าหมาย ให้ส่งตรงแบบ Unicast
                final nextHopForRecipient = (msg.recipientId != null && msg.recipientId != 'ALL')
                    ? _reversePathTable[msg.recipientId]
                    : null;

                if (nextHopForRecipient != null &&
                    connectedDevices.containsKey(nextHopForRecipient) &&
                    nextHopForRecipient != endpointId) {
                  try {
                    debugPrint('[SILENT RELAY UNICAST] Relaying message ${msg.id} directly to $nextHopForRecipient for ${msg.recipientId}');
                    await Nearby().sendBytesPayload(nextHopForRecipient, relayBytes);
                  } catch (e) {
                    debugPrint('[SILENT RELAY UNICAST] Error forwarding payload to $nextHopForRecipient: $e');
                  }
                } else {
                  // 🔄 Flooding Relay: ส่งต่อไปยังทุกโหนดที่เชื่อมต่ออยู่ ยกเว้นโหนดที่เพิ่งส่งมา
                  for (var otherEndpointId in connectedDevices.keys.toList()) {
                    if (otherEndpointId != endpointId) {
                      try {
                        await Nearby().sendBytesPayload(otherEndpointId, relayBytes);
                      } catch (e) {
                        debugPrint('[SILENT RELAY FLOOD] Error forwarding payload to $otherEndpointId: $e');
                      }
                    }
                  }
                }
              }
            }

          } catch (e) {
            debugPrint("Payload Parse Error: $e");
          }
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
    );
  }

  /// 🌐 1.5 จัดการแพ็กเก็ตแจ้งตัวตนในโครงข่าย Mesh (Peer Discovery Packet Processing)
  Future<void> _handlePeerAnnounce(NearbyMessage msg, String fromEndpointId) async {
    if (msg.senderId == nodeId || msg.senderId == deviceName) return; // ไม่ประมวลผลประกาศของตนเอง

    // 1. 🛡️ Cryptographic Identity Binding Check (ยืนยัน Node ID ตรงกับ Public Key จริง)
    if (msg.peerPublicKey != null && msg.peerPublicKey!.isNotEmpty) {
      if (!CryptoMeshService.verifyPeerNodeId(msg.senderId, msg.peerPublicKey!)) {
        debugPrint('[PEER DISCOVERY Guard] Spoofed Node ID detected! ${msg.senderId} does not match Public Key. Rejected.');
        return;
      }
      CryptoMeshService.registerPeerPublicKey(msg.senderId, msg.peerPublicKey!);
      IdentityService.instance.registerPeerIfNew(
        peerId: msg.senderId,
        displayName: msg.senderName.isNotEmpty ? msg.senderName : msg.senderId,
        publicKeyHex: msg.peerPublicKey!,
      );
    }

    // 1.5 🔏 Digital Signature Verification (ป้องกัน Relay Node ดัดแปลงชื่อ / ข้อมูลสุขภาพระหว่างทาง)
    Map<String, String>? trustedProfile = msg.profileData;
    if (msg.peerPublicKey != null && msg.signature != null) {
      final announceData = CryptoMeshService.computePeerAnnounceSignatureData(
        msg.senderId,
        msg.senderName,
        msg.peerPublicKey!,
        msg.profileData,
      );
      final isValidSig = CryptoMeshService.verifyDataSignature(
        data: announceData,
        signature: msg.signature,
        publicKeyHex: msg.peerPublicKey!,
        senderId: msg.senderId,
      );
      if (!isValidSig) {
        debugPrint('[PEER ANNOUNCE GUARD] 🚨 Signature verification failed for ${msg.senderId}! Tampered medical profile detected. Stripping profile.');
        trustedProfile = null;
      }
    }

    // 2. 🧭 Routing Engine Hop Count & TTL Control (คำนวณระยะทอดอย่างถูกต้อง ไม่เชื่อตัวเลขลอยๆ)
    final bool isDirectLink = connectedDevices.containsKey(fromEndpointId);
    int calculatedHop = 1;
    if (isDirectLink && !msg.isRelayed) {
      calculatedHop = 1;
    } else {
      calculatedHop = max(2, msg.hopCount);
    }

    final existingPeer = discoveredMeshPeers[msg.senderId];
    int bestHop = calculatedHop;

    if (existingPeer != null) {
      final bool hadDirectLink = existingPeer.hopCount == 1 &&
          existingPeer.directEndpoint != null &&
          connectedDevices.containsKey(existingPeer.directEndpoint);
      if (hadDirectLink) {
        bestHop = 1; // ยังต่อตรงอยู่จริง ยึด 1 hop
      } else if (existingPeer.hopCount < calculatedHop &&
                 existingPeer.hopCount > 1 &&
                 _reversePathTable[existingPeer.peerId] != null &&
                 connectedDevices.containsKey(_reversePathTable[existingPeer.peerId])) {
        // หากเคยมีเส้นทางสั้นกว่า (เช่น 2 hop เทียบกับ 3 hop) และเส้นทางเดิมยังเชื่อมต่ออยู่
        bestHop = existingPeer.hopCount;
      } else {
        // อัปเดตระยะ hop ตามที่คำนวณได้ใหม่จากแพ็กเก็ตล่าสุด
        bestHop = calculatedHop;
      }
    }

    // อัปเดตข้อมูลโหนดเดิมที่มีอยู่แล้ว หรือเพิ่มโหนดใหม่ (โดยยึด senderId / nodeId ถาวรเป็นหลัก)
    discoveredMeshPeers[msg.senderId] = MeshPeer(
      peerId: msg.senderId,
      peerName: msg.senderName.isNotEmpty ? msg.senderName : msg.senderId,
      publicKeyHex: msg.peerPublicKey ?? existingPeer?.publicKeyHex ?? '',
      hopCount: bestHop,
      directEndpoint: (bestHop == 1) ? fromEndpointId : null,
      lastSeen: DateTime.now(),
      emergencyProfile: trustedProfile ?? existingPeer?.emergencyProfile,
    );

    // บันทึก Routing Table ชี้ทางกลับไปยังโหนดผู้ส่ง
    _reversePathTable[msg.senderId] = fromEndpointId;

    debugPrint(
      '[PEER DISCOVERY] Discovered peer ${msg.senderName} (${msg.senderId}) via endpoint $fromEndpointId with $bestHop hops (Status: ${discoveredMeshPeers[msg.senderId]?.connectionStatus})',
    );
    notifyListeners();

    // 📬 ส่งข้อความส่วนตัวที่ฝากไว้ในคิว (Store-and-Forward) ให้โหนดนี้ทันทีที่ค้นพบ
    _deliverPendingMessages(fromEndpointId, msg.senderId);

    // 3. Multi-hop Silent Relay Engine (คำนวณ TTL Sanitization ป้องกันวนลูป)
    final effectiveTtl = min(msg.ttl, 5);
    if (effectiveTtl > 1) {
      final relayedAnnounce = msg.copyWith(
        ttl: effectiveTtl - 1,
        hopCount: bestHop + 1,
        isRelayed: true,
      );
      final announceBytes = utf8.encode(jsonEncode(relayedAnnounce.toJson()));
      for (var otherEndpointId in connectedDevices.keys.toList()) {
        if (otherEndpointId != fromEndpointId) {
          try {
            await Nearby().sendBytesPayload(otherEndpointId, announceBytes);
          } catch (e) {
            debugPrint('[PEER ANNOUNCE RELAY] Error forwarding to $otherEndpointId: $e');
          }
        }
      }
    }
  }

  /// 📢 ส่งกระจายสัญญาณประกาศตนเองในเครือข่าย Mesh เพื่อแลกเปลี่ยนชื่อ, X25519 Public Key
  Future<void> broadcastPeerAnnounce({String? targetEndpointId}) async {
    final pubKey = CryptoMeshService.myPublicKeyHex;
    final profile = await ProfileService.getProfile();

    // 🛡️ Privacy Filter: ส่งข้อมูลสุขภาพทางการแพทย์ฉุกเฉินชุดสมบูรณ์
    final Map<String, String> sanitizedProfile = _buildSanitizedProfile(profile);

    // 🔏 สร้าง Digital Signature ประจำแพ็กเก็ตป้องกันการแอบแก้ไขชื่อ/ข้อมูลสุขภาพระหว่างส่ง
    final announcePayload = CryptoMeshService.computePeerAnnounceSignatureData(
      nodeId,
      deviceName,
      pubKey,
      sanitizedProfile,
    );
    final signature = CryptoMeshService.signData(announcePayload);

    final announceMsg = NearbyMessage(
      senderId: nodeId,
      senderName: deviceName,
      content: 'PEER_ANNOUNCE',
      timestamp: DateTime.now(),
      isPeerAnnounce: true,
      peerPublicKey: pubKey,
      hopCount: 1,
      profileData: sanitizedProfile,
      signature: signature,
      ttl: 3, // กระจายผ่าน Relay ข้ามโหนดได้สูงสุด 3 ทอด
    );

    _processedMessageIds.add(announceMsg.id);
    final bytes = utf8.encode(jsonEncode(announceMsg.toJson()));

    if (targetEndpointId != null) {
      try {
        await Nearby().sendBytesPayload(targetEndpointId, bytes);
      } catch (e) {
        debugPrint('[PeerAnnounce] ⚠️ Error sending announce to $targetEndpointId: $e');
      }
    } else {
      for (var endpointId in connectedDevices.keys.toList()) {
        try {
          await Nearby().sendBytesPayload(endpointId, bytes);
        } catch (e) {
          debugPrint('[PeerAnnounce] ⚠️ Error sending announce to $endpointId: $e');
        }
      }
    }
  }

  /// 🔄 ซิงก์ข้อมูลโหนดทั้งหมดและประวัติข้อความสาธารณะให้โหนดใหม่ที่เพิ่งเชื่อมต่อรับทราบทันที (Instant Mesh Sync)
  Future<void> syncPeersToNewNode(String targetEndpointId) async {
    // 1. ส่งประกาศของตนเองให้โหนดใหม่
    await broadcastPeerAnnounce(targetEndpointId: targetEndpointId);

    // 2. ส่งต่อรายชื่อโหนดอื่นๆ ที่ยังออนไลน์อยู่ให้โหนดใหม่
    for (var peer in discoveredMeshPeers.values) {
      if (peer.peerId != nodeId && peer.peerId != deviceName && peer.isReachable) {
        final syncMsg = NearbyMessage(
          senderId: peer.peerId,
          senderName: peer.peerName,
          content: 'PEER_ANNOUNCE',
          timestamp: DateTime.now(),
          isPeerAnnounce: true,
          peerPublicKey: peer.publicKeyHex,
          hopCount: peer.hopCount + 1,
          profileData: peer.emergencyProfile,
          ttl: 2,
          isRelayed: true,
        );
        _processedMessageIds.add(syncMsg.id);
        final bytes = utf8.encode(jsonEncode(syncMsg.toJson()));
        try {
          await Nearby().sendBytesPayload(targetEndpointId, bytes);
        } catch (e) {
          debugPrint('[Mesh Sync] ⚠️ Error syncing peer ${peer.peerName} to $targetEndpointId: $e');
        }
      }
    }

    // 3. 📢 ซิงก์ประวัติข้อความสาธารณะล่าสุด (Public Mesh Chat History Sync) ให้โหนดใหม่เห็นข้อความย้อนหลังทันที
    try {
      final recentMsgs = await ChatDatabaseHelper.instance.getPublicMessages(limit: 20);
      for (var recent in recentMsgs.reversed) {
        if (!recent.isPeerAnnounce && !recent.isAck) {
          final syncBytes = utf8.encode(jsonEncode(recent.toJson()));
          await Nearby().sendBytesPayload(targetEndpointId, syncBytes);
        }
      }
      debugPrint('[Mesh Sync] ✅ Synced ${recentMsgs.length} public messages to new node $targetEndpointId');
    } catch (e) {
      debugPrint('[Mesh Sync] Public messages sync error: $e');
    }

    // 4. 📌 ซิงก์ประกาศฉุกเฉินสาธารณะที่ยังไม่หมดอายุ (Active Offline Notices Sync)
    try {
      final activeNotices = await ChatDatabaseHelper.instance.getActiveNotices();
      for (var notice in activeNotices) {
        if (!notice.isExpired) {
          final noticeBytes = utf8.encode(jsonEncode(notice.toJson()));
          await Nearby().sendBytesPayload(targetEndpointId, noticeBytes);
        }
      }
      debugPrint('[Mesh Sync] 📌 Synced ${activeNotices.length} active notices to new node $targetEndpointId');
    } catch (e) {
      debugPrint('[Mesh Sync] Notices sync error: $e');
    }
  }


  /// ⏱️ ตัวตั้งเวลาส่งสัญญาณประกาศตัวตนเป็นระยะเพื่อรักษา Heartbeat ของโหนดใน Mesh
  void _startPeerAnnounceTimer() {
    _peerAnnounceTimer?.cancel();
    _peerAnnounceTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (isAdvertising || isDiscovering || connectedDevices.isNotEmpty) {
        await broadcastPeerAnnounce();

        // 🌉 Active Relay Bridge Sync: หากเครื่องเราเชื่อมต่อกับอุปกรณ์ตั้งแต่ 2 เครื่องขึ้นไป (ทำหน้าที่เป็น Node B / สะพานกลาง)
        // ให้ส่งประกาศบอกแต่ละฝั่งว่าอีกฝั่งยังเชื่อมต่ออยู่กับเราอย่างต่อเนื่อง เพื่อรักษาเส้นทาง 2-hop ไม่ให้หลุด
        if (connectedDevices.length >= 2) {
          for (final directPeer in discoveredMeshPeers.values) {
            final isDirectlyConnected = directPeer.hopCount == 1 &&
                directPeer.directEndpoint != null &&
                connectedDevices.containsKey(directPeer.directEndpoint);

            if (isDirectlyConnected && directPeer.peerId != nodeId) {
              final bridgeAnnounce = NearbyMessage(
                senderId: directPeer.peerId,
                senderName: directPeer.peerName,
                content: 'PEER_ANNOUNCE',
                timestamp: DateTime.now(),
                isPeerAnnounce: true,
                peerPublicKey: directPeer.publicKeyHex,
                hopCount: 2, // ฝั่งตรงข้ามจะเห็นเป็น 2 ทอดผ่านเครื่องเรา
                profileData: directPeer.emergencyProfile,
                ttl: 2,
                isRelayed: true,
              );
              _processedMessageIds.add(bridgeAnnounce.id);
              final bytes = utf8.encode(jsonEncode(bridgeAnnounce.toJson()));

              // ส่งให้โหนดอื่นๆ ทั้งหมดยกเว้นโหนดที่เป็นเจ้าของประกาศนี้เอง
              for (final otherEndpoint in connectedDevices.keys) {
                if (otherEndpoint != directPeer.directEndpoint) {
                  try {
                    await Nearby().sendBytesPayload(otherEndpoint, bytes);
                  } catch (_) {}
                }
              }
            }
          }
        }
      }
    });
  }

  /// ✉️ ส่งสัญญาณ ACK ตอบรับสถานะกลับไปยังผู้ส่ง (Reverse Mesh Routing)
  Future<void> sendAck({
    required String ackMessageId,
    required String recipientId,
    required String ackType,
  }) async {
    final ackMsg = NearbyMessage(
      senderId: nodeId,
      senderName: deviceName,
      recipientId: recipientId,
      content: 'ACK::$ackType',
      timestamp: DateTime.now(),
      isAck: true,
      ackMessageId: ackMessageId,
      ackType: ackType,
      ttl: 5,
    );

    _processedMessageIds.add(ackMsg.id);
    final json = jsonEncode(ackMsg.toJson());
    final bytes = utf8.encode(json);

    // 🎯 Unicast Smart Routing: ส่งย้อนกลับทาง Reverse Path ถ้ามี
    final targetEndpoint = _reversePathTable[ackMessageId] ?? _reversePathTable[recipientId];
    if (targetEndpoint != null && connectedDevices.containsKey(targetEndpoint)) {
      try {
        await Nearby().sendBytesPayload(targetEndpoint, bytes);
        debugPrint('[Ack] 🎯 Sent $ackType ACK directly to $targetEndpoint for $recipientId');
        return;
      } catch (e) {
        debugPrint('[Ack] ⚠️ Failed direct ACK to $targetEndpoint: $e');
      }
    }

    // Fallback: Flooding
    for (var endpointId in connectedDevices.keys.toList()) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('[Ack] ⚠️ Error sending ACK to $endpointId: $e');
      }
    }
  }

  /// 👁️ ส่งสัญญาณ READ ACK เมื่อผู้ใช้งานเปิดหน้าจอเข้าดูแชทส่วนตัวกับ peerId
  Future<void> sendReadAckForPeer(String peerId) async {
    bool hasChanges = false;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.senderId == peerId &&
          (msg.recipientId == nodeId || msg.recipientId == deviceName) &&
          msg.status != 'READ') {
        messages[i] = msg.copyWith(status: 'READ');
        ChatDatabaseHelper.instance.updateMessageStatus(msg.id, 'READ');
        hasChanges = true;
        sendAck(
          ackMessageId: msg.id,
          recipientId: peerId,
          ackType: 'READ',
        );
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// 📢 ส่งข้อความแชทสาธารณะหาทุกคนในระยะ Mesh Network (Broadcast Message)
  /// คืนค่า String? หากติด Rate Limit / ข้อความยาวเกิน หรือ null หากส่งสำเร็จ
  Future<String?> sendMessage(String content) async {
    final rateLimitError = checkRateLimit(type: 'TEXT', content: content);
    if (rateLimitError != null) {
      debugPrint('[RateLimit] ⚠️ $rateLimitError');
      return rateLimitError;
    }
    _recordSendTimestamp(type: 'TEXT');

    final msg = NearbyMessage(
      senderId: nodeId,
      senderName: deviceName,
      content: content,
      timestamp: DateTime.now(),
      ttl: 3, // ข้อความทั่วไปรีเลย์ได้ 3 ทอด
    );

    _processedMessageIds.add(msg.id);
    messages.insert(0, msg);
    ChatDatabaseHelper.instance.insertMessage(
      msg,
      myNodeId: nodeId,
      myDeviceName: deviceName,
    );
    notifyListeners();

    final json = jsonEncode(msg.toJson());
    final bytes = utf8.encode(json);

    for (var endpointId in connectedDevices.keys.toList()) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('[BroadcastMsg] ⚠️ Error sending message to $endpointId: $e');
      }
    }
    return null;
  }

  /// 🔒 ส่งข้อความส่วนตัวเข้ารหัส (E2EE Private Direct Message) หาผู้รับปลายทางเฉพาะเจาะจง
  /// หาก Peer ไม่ได้อยู่ในเครือข่ายตอนนี้ จะฝากข้อความไว้ในคิว (Store-and-Forward) และส่งอัตโนมัติเมื่อเขากลับมา Online
  /// คืนค่า String? หากติด Rate Limit / ข้อความยาวเกิน หรือ null หากส่งสำเร็จ
  /// 🔍 ค้นหา Persistent Node ID (node_xxx) และดึง Public Key ของปลายทาง
  String _resolveTargetNodeId({
    required String recipientId,
    required String recipientName,
  }) {
    String targetNodeId = recipientId;
    if (!CryptoMeshService.hasPeerPublicKey(targetNodeId)) {
      for (var peer in discoveredMeshPeers.values) {
        if (peer.peerId == recipientId ||
            peer.peerName == recipientName ||
            peer.directEndpoint == recipientId) {
          if (CryptoMeshService.hasPeerPublicKey(peer.peerId)) {
            targetNodeId = peer.peerId;
            break;
          } else if (peer.publicKeyHex.isNotEmpty) {
            CryptoMeshService.registerPeerPublicKey(peer.peerId, peer.publicKeyHex);
            targetNodeId = peer.peerId;
            break;
          }
        }
      }
    }

    if (!CryptoMeshService.hasPeerPublicKey(targetNodeId) || !targetNodeId.startsWith('node_')) {
      for (var trust in IdentityService.instance.allTrustedPeers) {
        if (trust.peerId == recipientId ||
            trust.displayName == recipientName ||
            trust.displayName == recipientId) {
          if (trust.publicKeyHex.isNotEmpty) {
            CryptoMeshService.registerPeerPublicKey(trust.peerId, trust.publicKeyHex);
          }
          targetNodeId = trust.peerId;
          break;
        }
      }
    }

    return targetNodeId;
  }

  Future<String?> sendPrivateMessage({
    required String recipientId,
    required String recipientName,
    required String content,
  }) async {
    final rateLimitError = checkRateLimit(type: 'TEXT', content: content);
    if (rateLimitError != null) {
      debugPrint('[RateLimit] ⚠️ $rateLimitError');
      return rateLimitError;
    }
    _recordSendTimestamp(type: 'TEXT');

    try {
      // 0. Recipient Node ID Resolution Guard: แปลงและค้นหา Node ID ถาวรของปลายทาง
      final targetNodeId = _resolveTargetNodeId(
        recipientId: recipientId,
        recipientName: recipientName,
      );

      // 1. แพ็กรวมข้อมูลลับเฉพาะ (Inner Private Payload) ลง JSON
      final innerPayload = jsonEncode({
        "content": content,
        "senderName": deviceName,
        "senderId": nodeId,
      });

      // 2. เข้ารหัสข้อมูลทั้งหมดด้วย AES-256-GCM + X25519 ECDH
      final encryptedContent = CryptoMeshService.encryptPayload(
        plainText: innerPayload,
        recipientId: targetNodeId,
        senderId: nodeId,
      );

      final msg = NearbyMessage(
        senderId: nodeId,
        senderName: deviceName,
        recipientId: targetNodeId,
        recipientName: recipientName,
        content: encryptedContent,
        timestamp: DateTime.now(),
        isEncrypted: true,
        ttl: 5,
      );

      _processedMessageIds.add(msg.id);

      // บนหน้าจอผู้ส่ง ให้บันทึกแสดงผลด้วยข้อความปกติ (Plaintext) เพื่อให้อ่านในกล่องข้อความตนเองได้
      final localDisplayMsg = msg.copyWith(
        content: content,
        status: 'SENDING',
      );
      messages.insert(0, localDisplayMsg);
      ChatDatabaseHelper.instance.insertMessage(
        localDisplayMsg,
        myNodeId: nodeId,
        myDeviceName: deviceName,
      );
      notifyListeners();

      final jsonStr = jsonEncode(msg.toJson());
      final bytes = utf8.encode(jsonStr);

      // 3. ตรวจสอบว่ามีโหนดใดรู้จักเส้นทางไปหาผู้รับได้หรือไม่
      bool sent = false;
      final nextHop = _reversePathTable[targetNodeId];
      if (nextHop != null && connectedDevices.containsKey(nextHop)) {
        try {
          await Nearby().sendBytesPayload(nextHop, bytes);
          sent = true;
          debugPrint('[PrivateMsg] 🎯 Direct/Relay routed message ${msg.id} via next-hop $nextHop to $targetNodeId');
        } catch (e) {
          debugPrint('[PrivateMsg] ⚠️ Failed sending to nextHop $nextHop: $e');
        }
      }
      if (!sent) {
        for (var endpointId in connectedDevices.keys.toList()) {
          try {
            await Nearby().sendBytesPayload(endpointId, bytes);
            sent = true;
          } catch (_) {}
        }
      }


      if (!sent) {
        // ❌ Peer ไม่ได้อยู่ในเครือข่ายตอนนี้ — ฝากข้อความไว้ในคิว (Store-and-Forward)
        debugPrint('[PrivateMsg] 📤 No active route to $targetNodeId — queuing message ${msg.id} for later delivery.');
        await ChatDatabaseHelper.instance.insertPendingMessage(
          id: msg.id,
          recipientNodeId: targetNodeId,
          payload: jsonStr,
        );
        // อัปเดตสถานะบน UI เป็น PENDING
        final idx = messages.indexWhere((m) => m.id == localDisplayMsg.id);
        if (idx != -1) {
          messages[idx] = messages[idx].copyWith(status: 'PENDING');
          ChatDatabaseHelper.instance.updateMessageStatus(msg.id, 'PENDING');
          notifyListeners();
        }
      }
      return null;
    } catch (e) {
      // 🛑 Fail Closed Pattern: หยุดการส่งทันที + แจ้ง Error แสดงผลบน UI
      debugPrint('[E2EE Fail-Closed Guard] Encryption failed, aborting payload transmission: $e');
      final errorMsg = NearbyMessage(
        senderId: 'SYSTEM',
        senderName: 'ระบบความปลอดภัย (E2EE Guard)',
        recipientId: nodeId,
        recipientName: deviceName,
        content: '🚨 [Fail Closed] การเข้ารหัสขัดข้อง ระบบได้ยกเลิกการส่งข้อความส่วนตัวแล้ว ($e)',
        timestamp: DateTime.now(),
        status: 'FAILED',
      );
      messages.insert(0, errorMsg);
      notifyListeners();
      return 'การเข้ารหัสขัดข้อง: $e';
    }
  }

  // ===========================================================================
  // 📬 Store-and-Forward: ส่งข้อความที่ค้างอยู่ในคิวเมื่อ Peer กลับมา Online
  // ===========================================================================

  /// 📬 ดึงข้อความที่ค้างอยู่ในคิวแล้วส่งให้ Peer ที่เพิ่ง Connect เข้ามาทันที
  /// เรียกจาก onConnectionResult หลัง status == CONNECTED
  Future<void> _deliverPendingMessages(String connectedEndpointId, String peerNodeId) async {
    final pending = await ChatDatabaseHelper.instance.getPendingFor(peerNodeId);
    if (pending.isEmpty) return;

    debugPrint('[PendingQ] 📤 Found ${pending.length} pending message(s) for $peerNodeId. Delivering now...');

    for (final row in pending) {
      final String msgId = row['id'] as String;
      final String payload = row['payload'] as String;
      try {
        final bytes = utf8.encode(payload);
        await Nearby().sendBytesPayload(connectedEndpointId, bytes);

        // ลบออกจากคิวหลังส่งสำเร็จ
        await ChatDatabaseHelper.instance.deletePendingMessage(msgId);

        // อัปเดตสถานะใน UI จาก PENDING → SENDING (ACK จะเปลี่ยนเป็น DELIVERED ภายหลัง)
        final idx = messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          messages[idx] = messages[idx].copyWith(status: 'SENDING');
          ChatDatabaseHelper.instance.updateMessageStatus(msgId, 'SENDING');
        }
        debugPrint('[PendingQ] ✅ Delivered pending msg $msgId to $peerNodeId');
      } catch (e) {
        debugPrint('[PendingQ] ❌ Failed to deliver pending msg $msgId: $e');
      }
    }
    notifyListeners();
  }

  /// 📍 แชร์พิกัดละติจูด/ลองจิจูด ปัจจุบันเข้าสู่ห้องแชทสาธารณะ
  Future<void> sendLocation(double lat, double lng) async {
    final msg = NearbyMessage(
      senderId: nodeId,
      senderName: deviceName,
      content: "แชร์ตำแหน่งที่ตั้ง",
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
      isLocation: true,
      ttl: 3,
    );

    _processedMessageIds.add(msg.id);
    messages.insert(0, msg);
    ChatDatabaseHelper.instance.insertMessage(
      msg,
      myNodeId: nodeId,
      myDeviceName: deviceName,
    );
    notifyListeners();

    final json = jsonEncode(msg.toJson());
    final bytes = utf8.encode(json);

    for (var endpointId in connectedDevices.keys.toList()) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('[Location] ⚠️ Error sending location to $endpointId: $e');
      }
    }
  }

  /// 🔒📍 แชร์พิกัดส่วนตัวหาปลายทางเฉพาะเจาะจง (Private Encrypted Location Sharing)
  Future<void> sendPrivateLocation({
    required String recipientId,
    required String recipientName,
    required double lat,
    required double lng,
  }) async {
    try {
      final targetNodeId = _resolveTargetNodeId(
        recipientId: recipientId,
        recipientName: recipientName,
      );

      // 1. แพ็กรวมพิกัดลับและข้อมูลผู้ส่งลง Inner Private Payload
      final innerPayload = jsonEncode({
        "content": "แชร์ตำแหน่งที่ตั้งส่วนตัว",
        "senderName": deviceName,
        "senderId": nodeId,
        "latitude": lat,
        "longitude": lng,
      });

      // 2. เข้ารหัสเนื้อหาทั้งหมดด้วย AES-256-GCM + X25519 ECDH ก่อนส่งลงคลื่นวิทยุ
      final encryptedContent = CryptoMeshService.encryptPayload(
        plainText: innerPayload,
        recipientId: targetNodeId,
        senderId: nodeId,
      );

      // 3. กำหนดพิกัดบน Header แพ็กเก็ตที่จะส่งผ่าน Relay เป็น null (Zero-Knowledge Routing Header)
      final msg = NearbyMessage(
        senderId: nodeId,
        senderName: deviceName,
        recipientId: targetNodeId,
        recipientName: recipientName,
        content: encryptedContent,
        timestamp: DateTime.now(),
        latitude: null,  // 🔒 โหนดรีเลย์ตรงกลางจะเห็นพิกัดเป็น null 100%
        longitude: null, // 🔒 โหนดรีเลย์ตรงกลางจะเห็นพิกัดเป็น null 100%
        isLocation: true,
        isEncrypted: true,
        ttl: 5,
      );

      _processedMessageIds.add(msg.id);

      // บนเครื่องผู้ส่ง บันทึกแสดงผลพิกัดจริงเพื่อปักหมุดบน UI ตนเอง
      final localDisplayMsg = msg.copyWith(
        content: "แชร์ตำแหน่งที่ตั้งส่วนตัว",
        latitude: lat,
        longitude: lng,
      );
      messages.insert(0, localDisplayMsg);
      ChatDatabaseHelper.instance.insertMessage(
        localDisplayMsg,
        myNodeId: nodeId,
        myDeviceName: deviceName,
      );
      notifyListeners();

      final json = jsonEncode(msg.toJson());
      final bytes = utf8.encode(json);

      final nextHop = _reversePathTable[targetNodeId];
      if (nextHop != null && connectedDevices.containsKey(nextHop)) {
        try {
          await Nearby().sendBytesPayload(nextHop, bytes);
        } catch (_) {}
      } else {
        for (var endpointId in connectedDevices.keys.toList()) {
          try {
            await Nearby().sendBytesPayload(endpointId, bytes);
          } catch (_) {}
        }
      }
    } catch (e) {
      // 🛑 Fail Closed Pattern: หยุดการส่งทันที + แจ้ง Error แสดงผลบน UI
      debugPrint('[E2EE Fail-Closed Guard] Encryption failed, aborting private location transmission: $e');
      final errorMsg = NearbyMessage(
        senderId: 'SYSTEM',
        senderName: 'ระบบความปลอดภัย (E2EE Guard)',
        recipientId: nodeId,
        recipientName: deviceName,
        content: '🚨 [Fail Closed] การเข้ารหัสพิกัดขัดข้อง ระบบได้ยกเลิกการแชร์พิกัดส่วนตัวแล้ว ($e)',
        timestamp: DateTime.now(),
        status: 'FAILED',
      );
      messages.insert(0, errorMsg);
      notifyListeners();
    }
  }

  /// 🚨 ส่งสัญญาณขอความช่วยเหลือฉุกเฉินระดับสูงสุด (High Priority Local SOS Alert)
  /// มี Cooldown 3 วินาทีเพื่อป้องกันการส่งข้อความซ้ำโดยไม่ได้ตั้งใจ
  Future<String?> sendLocalSOS(String content) async {
    final rateLimitError = checkRateLimit(type: 'SOS');
    if (rateLimitError != null) {
      debugPrint('[RateLimit] ⚠️ $rateLimitError');
      return rateLimitError;
    }
    _recordSendTimestamp(type: 'SOS');

    final msg = NearbyMessage(
      senderId: nodeId,
      senderName: deviceName,
      content: content,
      timestamp: DateTime.now(),
      isSOS: true,
      ttl: 5, // SOS ได้รับสิทธิ์ในการรีเลย์ได้ไกลที่สุด (5 hops)
    );

    _processedMessageIds.add(msg.id);
    messages.insert(0, msg);
    ChatDatabaseHelper.instance.insertMessage(
      msg,
      myNodeId: nodeId,
      myDeviceName: deviceName,
    );
    notifyListeners();

    final json = jsonEncode(msg.toJson());
    final bytes = utf8.encode(json);

    for (var endpointId in connectedDevices.keys.toList()) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('[SOS] ⚠️ Error sending SOS to $endpointId: $e');
      }
    }
    return null;
  }

  /// 📷 ส่งรูปภาพถ่าย/จากคลังเข้าสู่ห้องแชท (รองรับทั้งแชทสาธารณะ และ E2EE ส่วนตัว)
  Future<String?> sendImageMessage({
    required String imagePath,
    String? recipientId,
    String? recipientName,
  }) async {
    final rateLimitError = checkRateLimit(type: 'MEDIA');
    if (rateLimitError != null) {
      debugPrint('[RateLimit] ⚠️ $rateLimitError');
      return rateLimitError;
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) return 'ไม่พบไฟล์รูปภาพ';
      final bytes = await file.readAsBytes();
      // 🛡️ ป้องกัน Payload Overrun บนคลื่น BLE (Nearby Connections BYTES payload จำกัดที่ 32KB)
      if (bytes.lengthInBytes > 22000) {
        return 'รูปภาพมีขนาดใหญ่เกินกว่าที่คลื่น BLE Mesh รองรับได้ (จำกัดไม่เกิน 22 KB)';
      }
      _recordSendTimestamp(type: 'MEDIA');
      final base64Str = base64Encode(bytes);

      if (recipientId != null && recipientId.isNotEmpty) {
        // แชทส่วนตัวเข้ารหัส E2EE Private
        final targetNodeId = _resolveTargetNodeId(
          recipientId: recipientId,
          recipientName: recipientName ?? recipientId,
        );

        final innerPayload = jsonEncode({
          "content": "[รูปภาพ]",
          "senderName": deviceName,
          "senderId": nodeId,
          "mediaType": "IMAGE",
          "base64Data": base64Str,
        });

        final encryptedContent = CryptoMeshService.encryptPayload(
          plainText: innerPayload,
          recipientId: targetNodeId,
          senderId: nodeId,
        );

        final msg = NearbyMessage(
          senderId: nodeId,
          senderName: deviceName,
          recipientId: targetNodeId,
          recipientName: recipientName,
          content: encryptedContent,
          timestamp: DateTime.now(),
          mediaType: "IMAGE",
          isEncrypted: true,
          ttl: 5,
        );

        _processedMessageIds.add(msg.id);

        final localDisplayMsg = msg.copyWith(
          content: "[รูปภาพ]",
          mediaPath: imagePath,
        );
        messages.insert(0, localDisplayMsg);
        ChatDatabaseHelper.instance.insertMessage(
          localDisplayMsg,
          myNodeId: nodeId,
          myDeviceName: deviceName,
        );
        notifyListeners();

        final json = jsonEncode(msg.toJson());
        final payloadBytes = utf8.encode(json);
        for (var endpointId in connectedDevices.keys.toList()) {
          await Nearby().sendBytesPayload(endpointId, payloadBytes);
        }
      } else {
        // แชทสาธารณะ Public Mesh
        final msg = NearbyMessage(
          senderId: nodeId,
          senderName: deviceName,
          content: "[รูปภาพ]",
          timestamp: DateTime.now(),
          mediaType: "IMAGE",
          base64Data: base64Str,
          ttl: 3,
        );

        _processedMessageIds.add(msg.id);

        final localDisplayMsg = msg.copyWith(mediaPath: imagePath, base64Data: null);
        messages.insert(0, localDisplayMsg);
        ChatDatabaseHelper.instance.insertMessage(
          localDisplayMsg,
          myNodeId: nodeId,
          myDeviceName: deviceName,
        );
        notifyListeners();

        final json = jsonEncode(msg.toJson());
        final payloadBytes = utf8.encode(json);
        for (var endpointId in connectedDevices.keys.toList()) {
          await Nearby().sendBytesPayload(endpointId, payloadBytes);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Send Image Error]: $e');
      return 'เกิดข้อผิดพลาดในการส่งรูปภาพ: $e';
    }
  }

  /// 🎙️ ส่งข้อความเสียง (Voice Message) เข้าสู่ห้องแชท (รองรับทั้งแชทสาธารณะ และ E2EE ส่วนตัว)
  Future<String?> sendVoiceMessage({
    required String audioPath,
    required int durationSeconds,
    String? recipientId,
    String? recipientName,
  }) async {
    final rateLimitError = checkRateLimit(type: 'MEDIA');
    if (rateLimitError != null) {
      debugPrint('[RateLimit] ⚠️ $rateLimitError');
      return rateLimitError;
    }

    try {
      final file = File(audioPath);
      if (!await file.exists()) return 'ไม่พบไฟล์ข้อความเสียง';
      final bytes = await file.readAsBytes();
      // 🛡️ ป้องกัน Payload Overrun บนคลื่น BLE (Nearby Connections BYTES payload จำกัดที่ 32KB)
      if (bytes.lengthInBytes > 22000) {
        return 'ข้อความเสียงมีขนาดยาวเกินกว่าที่คลื่น BLE Mesh รองรับได้ (จำกัดไม่เกิน 6 วินาที)';
      }
      _recordSendTimestamp(type: 'MEDIA');
      final base64Str = base64Encode(bytes);

      if (recipientId != null && recipientId.isNotEmpty) {
        // แชทส่วนตัวเข้ารหัส E2EE Private
        final targetNodeId = _resolveTargetNodeId(
          recipientId: recipientId,
          recipientName: recipientName ?? recipientId,
        );

        final innerPayload = jsonEncode({
          "content": "[ข้อความเสียง]",
          "senderName": deviceName,
          "senderId": nodeId,
          "mediaType": "AUDIO",
          "durationSeconds": durationSeconds,
          "base64Data": base64Str,
        });

        final encryptedContent = CryptoMeshService.encryptPayload(
          plainText: innerPayload,
          recipientId: targetNodeId,
          senderId: nodeId,
        );

        final msg = NearbyMessage(
          senderId: nodeId,
          senderName: deviceName,
          recipientId: targetNodeId,
          recipientName: recipientName,
          content: encryptedContent,
          timestamp: DateTime.now(),
          mediaType: "AUDIO",
          durationSeconds: durationSeconds,
          isEncrypted: true,
          ttl: 5,
        );

        _processedMessageIds.add(msg.id);

        final localDisplayMsg = msg.copyWith(
          content: "[ข้อความเสียง]",
          mediaPath: audioPath,
        );
        messages.insert(0, localDisplayMsg);
        ChatDatabaseHelper.instance.insertMessage(
          localDisplayMsg,
          myNodeId: nodeId,
          myDeviceName: deviceName,
        );
        notifyListeners();

        final json = jsonEncode(msg.toJson());
        final payloadBytes = utf8.encode(json);
        for (var endpointId in connectedDevices.keys.toList()) {
          await Nearby().sendBytesPayload(endpointId, payloadBytes);
        }
      } else {
        // แชทสาธารณะ Public Mesh
        final msg = NearbyMessage(
          senderId: nodeId,
          senderName: deviceName,
          content: "[ข้อความเสียง]",
          timestamp: DateTime.now(),
          mediaType: "AUDIO",
          durationSeconds: durationSeconds,
          base64Data: base64Str,
          ttl: 3,
        );

        _processedMessageIds.add(msg.id);

        final localDisplayMsg = msg.copyWith(mediaPath: audioPath, base64Data: null);
        messages.insert(0, localDisplayMsg);
        ChatDatabaseHelper.instance.insertMessage(
          localDisplayMsg,
          myNodeId: nodeId,
          myDeviceName: deviceName,
        );
        notifyListeners();

        final json = jsonEncode(msg.toJson());
        final payloadBytes = utf8.encode(json);
        for (var endpointId in connectedDevices.keys.toList()) {
          await Nearby().sendBytesPayload(endpointId, payloadBytes);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Send Voice Error]: $e');
      return 'เกิดข้อผิดพลาดในการส่งข้อความเสียง: $e';
    }
  }


  // --------------------------------------------------------------------------
  // 🔔 Local System Notifications (ระบบส่งการแจ้งเตือนเตือนภัยบนแถบสถานะ Android/iOS)
  // --------------------------------------------------------------------------

  Future<void> _showProximityAlert(String peerName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'proximity_channel',
          'Nearby Alerts',
          channelDescription:
              'Notifications when other emergency users are nearby',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      201,
      '🤝 พบผู้ใช้งานใกล้เคียง',
      'ตรวจพบ $peerName อยู่ในระยะบลูทูธ สามารถส่งข้อความขอความช่วยเหลือได้แม้ไม่มีเน็ต',
      details,
    );
  }

  Future<void> _showSOSAlert(String peerName, String content) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'sos_channel',
          'Immediate SOS Alerts',
          channelDescription: 'High priority SOS alerts from nearby users',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFE53935),
          enableLights: true,
          enableVibration: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      202,
      '🚨 SOS: $peerName ต้องการความช่วยเหลือ!',
      content,
      details,
    );
  }

  Future<void> _showPrivateMessageAlert(String peerName, String content) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'private_msg_channel',
          'Private Direct Messages',
          channelDescription: 'Encrypted private messages from peers',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF1E88E5),
          enableLights: true,
          enableVibration: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      203,
      '🔒 ข้อความส่วนตัวจาก $peerName',
      content,
      details,
    );
  }

  Future<void> _showPublicMessageAlert(String peerName, String content) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'public_msg_channel',
          'Public Mesh Messages',
          channelDescription: 'Broadcast messages from nearby mesh peers',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF00E676),
          enableLights: true,
          enableVibration: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      204,
      '💬 แชทออฟไลน์: $peerName',
      content,
      details,
    );
  }

  // --------------------------------------------------------------------------
  // 🗑️ Chat Clearing Operations (ระบบล้างประวัติแชททั้งใน RAM และ SQLite)
  // --------------------------------------------------------------------------

  /// 🗑️ ล้างประวัติข้อความแชทสาธารณะ
  Future<void> clearPublicChat() async {
    await ChatDatabaseHelper.instance.clearConversation('PUBLIC');
    messages.removeWhere(
      (m) =>
          m.recipientId == null ||
          m.recipientId == 'ALL' ||
          m.recipientId!.isEmpty,
    );
    notifyListeners();
  }

  /// 🗑️ ล้างประวัติข้อความแชทส่วนตัวกับคู่สนทนาที่ระบุ (รองรับทั้ง peerId และ peerName)
  Future<void> clearPrivateChat(String peerIdOrName) async {
    final convId = 'PEER_$peerIdOrName';
    await ChatDatabaseHelper.instance.clearConversation(convId);
    messages.removeWhere((m) {
      final isRecipientPeer =
          m.recipientId == peerIdOrName || m.recipientName == peerIdOrName;
      final isSenderPeer =
          m.senderId == peerIdOrName || m.senderName == peerIdOrName;
      return isRecipientPeer || isSenderPeer;
    });
    notifyListeners();
  }

  /// 🗑️ ลบโหนดเพื่อน (Peer) ออกจากระบบ พร้อมลบประวัติการสนทนาและกุญแจทั้งหมด
  Future<void> deletePeer(String peerId) async {
    // 1. ลบจากหน่วยความจำ RAM
    discoveredMeshPeers.remove(peerId);
    _reversePathTable.remove(peerId);
    messages.removeWhere((m) {
      final isRecipientPeer = m.recipientId == peerId;
      final isSenderPeer = m.senderId == peerId;
      return isRecipientPeer || isSenderPeer;
    });

    // 2. ลบออกจาก SQLite Database (ทั้ง messages และ pending queue)
    final convId = 'PEER_$peerId';
    await ChatDatabaseHelper.instance.clearConversation(convId);
    await ChatDatabaseHelper.instance.deletePendingMessagesFor(peerId);

    // 3. ลบออกจาก IdentityService Trust Store
    await IdentityService.instance.removeTrust(peerId);

    // 4. ลบ Public Key ออกจาก CryptoMeshService
    CryptoMeshService.removePeerPublicKey(peerId);

    debugPrint('[NearbyService] 🗑️ Peer $peerId completely deleted.');
    notifyListeners();
  }

  /// 🗑️ ล้างประวัติข้อความทั้งหมดในแอป
  Future<void> clearAllChatHistory() async {
    await ChatDatabaseHelper.instance.clearAllMessages();
    messages.clear();
    notifyListeners();
  }

  // ===========================================================================
  // 📌 Section: Offline Notice Board System (Epidemic Bulletin Board @ #mesh)
  // ===========================================================================

  /// 📖 โหลดประกาศที่ยังไม่หมดอายุจากฐานข้อมูล SQLite ขึ้น RAM
  Future<void> loadNotices() async {
    final active = await ChatDatabaseHelper.instance.getActiveNotices();
    notices = active;
    notifyListeners();
  }

  /// 📌 โพสต์ประกาศฉุกเฉินสาธารณะใหม่ขึ้นกระดานออฟไลน์
  Future<void> postNotice({
    required String content,
    required Duration expiresIn,
    bool isUrgent = false,
    double? latitude,
    double? longitude,
  }) async {
    final notice = MeshNotice(
      authorId: nodeId,
      authorName: deviceName,
      content: content,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(expiresIn),
      isUrgent: isUrgent,
      latitude: latitude,
      longitude: longitude,
      hopCount: 1,
    );

    // 1. บันทึกลง SQLite Database และอัปเดต RAM
    _processedMessageIds.add(notice.id);
    await ChatDatabaseHelper.instance.markPacketProcessed(notice.id);
    await ChatDatabaseHelper.instance.insertNotice(notice);

    notices.insert(0, notice);
    notices.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    notifyListeners();

    // 2. กระจายสัญญาณประกาศไปยังทุกโหนดที่เชื่อมต่ออยู่ (Epidemic Broadcast)
    final bytes = utf8.encode(jsonEncode(notice.toJson()));
    for (var endpointId in connectedDevices.keys.toList()) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (_) {}
    }
    debugPrint('[Notice Mesh] 📌 Posted and broadcast notice: ${notice.id}');
  }

  /// 📌 จัดการแพ็กเก็ตกระดานประกาศฉุกเฉินออฟไลน์ (Epidemic Notice Propagation)
  Future<void> _handleIncomingNotice(Map<String, dynamic> json, String fromEndpointId) async {
    try {
      final notice = MeshNotice.fromJson(json);

      // 1. ตรวจสอบว่าประกาศหมดอายุหรือยัง
      if (notice.isExpired) {
        debugPrint('[Notice Mesh] ⏱️ Dropped expired notice: ${notice.id}');
        return;
      }

      // 2. ป้องกันประมวลผลซ้ำ (Deduplication Check)
      if (_processedMessageIds.contains(notice.id) ||
          await ChatDatabaseHelper.instance.isPacketProcessed(notice.id)) {
        return;
      }
      _processedMessageIds.add(notice.id);
      await ChatDatabaseHelper.instance.markPacketProcessed(notice.id);

      // 3. บันทึกลง SQLite Database และอัปเดต RAM List
      await ChatDatabaseHelper.instance.insertNotice(notice);
      final existingIdx = notices.indexWhere((n) => n.id == notice.id);
      if (existingIdx != -1) {
        notices[existingIdx] = notice;
      } else {
        notices.insert(0, notice);
        notices.sort((a, b) {
          if (a.isUrgent && !b.isUrgent) return -1;
          if (!a.isUrgent && b.isUrgent) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
      }
      notifyListeners();

      // 4. แสดงการแจ้งเตือน หากเป็นประกาศด่วน (Urgent Notice Alert)
      if (notice.isUrgent) {
        _showNoticeAlert(notice.authorName, notice.content);
      }

      // 5. ส่งต่อแบบ Epidemic Gossip Relay ข้ามโหนดไปรอบตัว (Multi-hop Notice Forwarding)
      final relayedNotice = notice.copyWith(hopCount: notice.hopCount + 1);
      final relayBytes = utf8.encode(jsonEncode(relayedNotice.toJson()));

      for (var otherEndpointId in connectedDevices.keys.toList()) {
        if (otherEndpointId != fromEndpointId) {
          try {
            await Nearby().sendBytesPayload(otherEndpointId, relayBytes);
          } catch (_) {}
        }
      }
      debugPrint('[Notice Mesh] 📢 Received and gossiped notice from ${notice.authorName}: ${notice.content}');
    } catch (e) {
      debugPrint('[Notice Mesh Error] Failed to handle incoming notice: $e');
    }
  }

  /// 🚨 แจ้งเตือนเมื่อมีประกาศด่วนฉุกเฉินเข้ามาใหม่
  Future<void> _showNoticeAlert(String author, String content) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'urgent_notice_channel',
      'Urgent Mesh Notices',
      channelDescription: 'Emergency notices broadcast across the mesh',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF5252),
      enableLights: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      Random().nextInt(100000),
      '🚨 [ประกาศด่วน] $author',
      content,
      details,
    );
  }
  Future<void> deleteNotice(String noticeId) async {
    notices.removeWhere((n) => n.id == noticeId);
    await ChatDatabaseHelper.instance.deleteNotice(noticeId);
    notifyListeners();
  }
}
