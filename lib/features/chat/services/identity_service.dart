// ============================================================================
// 🆔 BANTAWAN Peer Identity Service: IdentityService
//
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │              Peer Identity Verification Layer           │
// │    (IdentityService: Fingerprint + Trust State Mgmt)    │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// │   (CryptoMeshService: X25519 KeyPair + SHA-256 Engine)  │
// ├─────────────────────────────────────────────────────────┤
// │            Transport Layer (Nearby Connections)          │
// └─────────────────────────────────────────────────────────┘
//
// บริการจัดการ Cryptographic Identity ของ Peer ในเครือข่าย Mesh
// ต่อยอดจาก CryptoMeshService (ไม่สร้าง KeyPair ใหม่ ใช้ key เดิม)
//
// หน้าที่หลัก:
// - คำนวณ Fingerprint ของตัวเองและ Peer (SHA-256 จาก Public Key)
// - บันทึกสถานะ Trust ของ Peer (UNKNOWN/UNVERIFIED/VERIFIED/CHANGED)
// - ตรวจสอบว่า Public Key ของ Peer เปลี่ยนหรือไม่เมื่อ reconnect
// - บันทึกและโหลด Trust Store จาก SharedPreferences (Local Storage)
//
// Security Principles:
// - Identity = Public Key (ไม่ใช่ displayName)
// - Private Key ไม่ถูกใช้/ส่งในบริการนี้
// - Fingerprint เป็น deterministic (เดิมเสมอสำหรับ Key เดิม)
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_mesh_service.dart';
import 'nearby_service.dart';
import '../models/peer_trust.dart';

/// 🆔 บริการจัดการ Cryptographic Identity และ Trust Store (IdentityService)
/// เป็น Singleton — ใช้ [instance] เพื่อเข้าถึงจากทุกที่ในแอป
class IdentityService extends ChangeNotifier {
  // --- Singleton ---
  static final IdentityService instance = IdentityService._();
  IdentityService._();

  /// SharedPreferences key สำหรับเก็บ Trust Store
  static const String _trustStoreKey = 'bantawan_peer_trust_store_v1';

  /// Trust Store: peerId → PeerTrust (เก็บใน RAM, sync กับ SharedPreferences)
  final Map<String, PeerTrust> _trustStore = {};

  /// ตรวจว่า init แล้วหรือยัง
  bool _initialized = false;

  // ============================================================================
  // 🚀 Section 1: Initialization
  // ============================================================================

  /// 🚀 เริ่มต้นโหลด Trust Store จาก SharedPreferences
  /// ต้องเรียกครั้งเดียวตอน App Start (หลัง CryptoMeshService.initKeys())
  Future<void> init() async {
    if (_initialized) return;
    await _loadTrustStore();
    _initialized = true;
    debugPrint('[Identity] Initialized. My fingerprint: ${myFingerprint.replaceAll('\n', ' | ')}');
  }

  // ============================================================================
  // 🆔 Section 2: My Identity (ต่อยอดจาก CryptoMeshService)
  // ============================================================================

  /// 🔑 Public Key ของเครื่องตัวเอง (Hex String) — มาจาก CryptoMeshService
  String get myPublicKeyHex => CryptoMeshService.myPublicKeyHex;

  /// 🔐 Fingerprint ของเครื่องตัวเอง (SHA-256 ของ Public Key, format 2 บรรทัด)
  String get myFingerprint => CryptoMeshService.myIdentityFingerprint;

  /// 🆔 Node ID ของเครื่องตัวเอง (เช่น "node_a1b2c3d4e5f6")
  String get myNodeId => CryptoMeshService.nodeId;

  // ============================================================================
  // 🔏 Section 3: Fingerprint Computation
  // ============================================================================

  /// 🔏 คำนวณ Fingerprint จาก Public Key ของ Peer
  /// Deterministic: Public Key เดิม → Fingerprint เดิมเสมอ
  String computeFingerprint(String publicKeyHex) {
    return CryptoMeshService.computeIdentityFingerprint(publicKeyHex);
  }

  // ============================================================================
  // 🛡️ Section 4: Trust State Management
  // ============================================================================

  /// 🔍 ดึงสถานะ Trust ของ Peer จาก Trust Store
  /// - ตรวจสอบว่า Public Key ปัจจุบันตรงกับที่เคยบันทึกไว้หรือไม่
  /// - ถ้า Key เปลี่ยน → CHANGED (ไม่ยอมรับ verified อัตโนมัติ)
  PeerTrustState getTrustState(String peerId, String currentPublicKeyHex) {
    final stored = _trustStore[peerId];
    if (stored == null) return PeerTrustState.unknown;

    // ตรวจสอบว่า Public Key ยังตรงกับที่บันทึกไว้หรือไม่
    if (stored.publicKeyHex != currentPublicKeyHex) {
      // Key เปลี่ยน → อัปเดตเป็น CHANGED และบันทึกทันที
      if (stored.trustState != PeerTrustState.changed) {
        _updateTrustToChanged(peerId, currentPublicKeyHex);
      }
      return PeerTrustState.changed;
    }

    return stored.trustState;
  }

  /// 📖 ดึงข้อมูล PeerTrust ทั้งหมดของ Peer (null ถ้าไม่เคยพบ)
  PeerTrust? getStoredTrust(String peerId) => _trustStore[peerId];

  String _sanitizeDisplayName(String peerId, String rawName) {
    final trimmed = rawName.trim();
    final lower = trimmed.toLowerCase();
    final isUgly = trimmed.isEmpty ||
        lower.startsWith('node_') ||
        lower == 'survivor' ||
        lower == 'unknown' ||
        lower.startsWith('survivor ');
    if (isUgly) {
      return NearbyService.generateTacticalCallsign(peerId);
    }
    return trimmed;
  }

  /// ✅ ยืนยัน Fingerprint ของ Peer (ผู้ใช้กดปุ่มยืนยันหลังเปรียบเทียบ Fingerprint)
  /// บันทึก Trust State เป็น VERIFIED และ sync กับ SharedPreferences
  Future<void> verifyPeer({
    required String peerId,
    required String displayName,
    required String publicKeyHex,
  }) async {
    final cleanName = _sanitizeDisplayName(peerId, displayName);
    final fingerprint = computeFingerprint(publicKeyHex);
    final trust = PeerTrust(
      peerId: peerId,
      displayName: cleanName,
      publicKeyHex: publicKeyHex,
      fingerprint: fingerprint,
      verifiedAt: DateTime.now(),
      trustState: PeerTrustState.verified,
    );
    _trustStore[peerId] = trust;
    await _saveTrustStore();
    notifyListeners();
    debugPrint('[Identity] Peer verified: $peerId ($cleanName)');
  }

  /// 📝 ลงทะเบียน Peer ใหม่ที่พบในระบบ Mesh (UNVERIFIED)
  /// เรียกอัตโนมัติเมื่อรับ Peer Announce packet — ไม่ต้องรอให้ผู้ใช้ verify ก่อน
  Future<void> registerPeerIfNew({
    required String peerId,
    required String displayName,
    required String publicKeyHex,
  }) async {
    final currentState = getTrustState(peerId, publicKeyHex);
    final cleanName = _sanitizeDisplayName(peerId, displayName);

    // ถ้าเป็น UNKNOWN → สร้าง record ใหม่เป็น UNVERIFIED
    if (currentState == PeerTrustState.unknown) {
      final fingerprint = computeFingerprint(publicKeyHex);
      final trust = PeerTrust(
        peerId: peerId,
        displayName: cleanName,
        publicKeyHex: publicKeyHex,
        fingerprint: fingerprint,
        trustState: PeerTrustState.unverified,
      );
      _trustStore[peerId] = trust;
      await _saveTrustStore();
      notifyListeners();
      debugPrint('[Identity] New peer registered (unverified): $peerId ($cleanName)');
    } else if (currentState == PeerTrustState.changed) {
      // Key เปลี่ยน: อัปเดตชื่อใหม่ แต่คงสถานะ CHANGED
      notifyListeners();
    }
    // ถ้า VERIFIED/UNVERIFIED และ key ไม่เปลี่ยน → ไม่ต้องทำอะไร
  }

  /// ⚠️ อัปเดตสถานะเป็น CHANGED เมื่อ Peer ใช้ Public Key ใหม่
  void _updateTrustToChanged(String peerId, String newPublicKeyHex) {
    final existing = _trustStore[peerId];
    if (existing == null) return;

    final newFingerprint = computeFingerprint(newPublicKeyHex);
    _trustStore[peerId] = existing.copyWith(
      publicKeyHex: newPublicKeyHex,
      fingerprint: newFingerprint,
      trustState: PeerTrustState.changed,
    );
    // บันทึกแบบ async โดยไม่ await
    _saveTrustStore();
    notifyListeners();
    debugPrint('[Identity] ⚠️ Peer identity CHANGED: $peerId (key mismatch)');
  }

  /// 🔄 รีเซ็ต Trust State ของ Peer เป็น UNVERIFIED (ให้ผู้ใช้ verify ใหม่)
  Future<void> resetTrust(String peerId) async {
    final existing = _trustStore[peerId];
    if (existing == null) return;
    _trustStore[peerId] = existing.copyWith(trustState: PeerTrustState.unverified);
    await _saveTrustStore();
    notifyListeners();
  }

  /// 🗑️ ลบข้อมูล Trust ของ Peer ออกจาก Trust Store
  Future<void> removeTrust(String peerId) async {
    _trustStore.remove(peerId);
    await _saveTrustStore();
    notifyListeners();
  }

  /// 📋 ดึงรายการ Peer ทั้งหมดใน Trust Store (สำหรับแสดงในหน้า Settings)
  List<PeerTrust> get allTrustedPeers => _trustStore.values.toList();

  // ============================================================================
  // 💾 Section 5: Persistence (SharedPreferences)
  // ============================================================================

  /// 💾 บันทึก Trust Store ทั้งหมดลง SharedPreferences
  Future<void> _saveTrustStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _trustStore.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString(_trustStoreKey, encoded);
    } catch (e) {
      debugPrint('[Identity] Error saving trust store: $e');
    }
  }

  /// 📖 โหลด Trust Store จาก SharedPreferences เมื่อแอปเริ่มต้น
  Future<void> _loadTrustStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_trustStoreKey);
      if (encoded == null) return;

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      _trustStore.clear();
      for (final entry in decoded.entries) {
        final trust = PeerTrust.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        final cleanName = _sanitizeDisplayName(entry.key, trust.displayName);
        _trustStore[entry.key] = trust.copyWith(displayName: cleanName);
        // 🔑 ลงทะเบียน Public Key เข้า CryptoMeshService ทันที เพื่อให้พร้อมเข้ารหัสส่งข้อความออฟไลน์
        if (trust.publicKeyHex.isNotEmpty) {
          CryptoMeshService.registerPeerPublicKey(entry.key, trust.publicKeyHex);
        }
      }
      debugPrint('[Identity] Loaded ${_trustStore.length} trusted peer(s) from storage.');
    } catch (e) {
      debugPrint('[Identity] Error loading trust store: $e');
    }
  }
}
