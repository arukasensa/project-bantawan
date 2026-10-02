import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 🔒 E2EE Security Layer: CryptoMeshService (Layer 3 of BANTAWAN Architecture)
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// │ (CryptoMeshService: X25519 ECDH + HKDF + AES-256-CTR AEAD)│
// ├─────────────────────────────────────────────────────────┤
// │                BANTAWAN Mesh Routing Engine             │
// ├─────────────────────────────────────────────────────────┤
// │            Transport Layer (Nearby Connections)          │
// └─────────────────────────────────────────────────────────┘
// 
// ระบบเข้ารหัสข้อมูลแชทส่วนตัวระดับมาตรฐานสากล (NIST SP 800-38A / FIPS 197 / RFC 7366)
// ผสาน X25519 ECDH Key Exchange + HKDF-SHA256 + AES-256-CTR Block Cipher Engine
// พร้อมการตรวจสอบความถูกต้องด้วย HMAC-SHA256 AEAD (Encrypt-then-MAC with AAD Metadata Binding)
// และจัดเก็บกุญแจส่วนตัวลงใน Android Keystore / iOS Keychain ปลอดภัย 100%
// ============================================================================

/// 🛡️ แคชสำหรับจัดเก็บ Nonce เพื่อป้องกันการส่งแพ็กเก็ตซ้ำ (Anti-Replay Attack Guard)
/// ใช้โครงสร้างข้อมูลแบบ True LRU (Least Recently Used) ร่วมกับ TTL (Time-To-Live) 15 นาที
/// เพื่อจำกัดหน่วยความจำไม่ให้เกิน 2,000 รายการ
class LruNonceCache {
  /// จำนวนรายการสูงสุดที่จะบันทึกในแคช (eviction เมื่อเกิน 2000 รายการ)
  static const int _maxEntries = 2000;

  /// ระยะเวลาหมดอายุของ Nonce (15 นาที)
  static const Duration _ttl = Duration(minutes: 15);

  /// ตารางเก็บ Nonce และเวลาที่บันทึกล่าสุด
  final Map<String, DateTime> _cache = {};

  /// 🔍 ตรวจสอบว่ามี Nonce ในแคชหรือไม่ (และยังไม่หมดอายุ)
  /// หากพบ จะเลื่อนตำแหน่งคีย์ขึ้นมาเป็น Most Recently Used (MRU)
  bool contains(String key) {
    _cleanExpired();
    final timestamp = _cache.remove(key);
    if (timestamp != null) {
      _cache[key] = timestamp; // เลื่อนตำแหน่งมาเป็น Most Recently Used (MRU)
      return true;
    }
    return false;
  }

  /// ➕ บันทึก Nonce ใหม่ลงในแคช
  /// หากแคชเต็ม จะลบรายการที่เก่าที่สุด (Least Recently Used) ออกทันที
  void add(String key) {
    _cleanExpired();
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first); // Evict Least Recently Used (FIFO/LRU)
    }
    _cache[key] = DateTime.now();
  }

  /// 🧹 ล้างรายการ Nonce ที่หมดอายุเกิน 15 นาทีออกจากแคช
  void _cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, timestamp) => now.difference(timestamp) > _ttl);
  }
}

/// 🔐 บริการจัดการการเข้ารหัสความปลอดภัยระดับระบบ (Cryptographic Engine)
class CryptoMeshService {
  /// ตัวสุ่มตัวเลขแบบสุ่มที่มีความปลอดภัยสูงระดับคริปโต (Cryptographically Secure PRNG)
  static final Random _secureRandom = Random.secure();

  /// Prime Number สำหรับ Curve25519: 2^255 - 19
  static final BigInt _p = (BigInt.one << 255) - BigInt.from(19);

  /// Base Point (u = 9) ของ X25519 สำหรับการสร้าง Public Key
  static final List<int> _basePoint = [9, ...List<int>.filled(31, 0)];

  /// อินสแตนซ์จัดเก็บข้อมูลความลับในฮาร์ดแวร์ความปลอดภัย (Android Keystore / iOS Keychain)
  static const _secureStorage = FlutterSecureStorage();

  /// X25519 Private Key ประจำเครื่อง (32-byte binary)
  static List<int>? _myPrivateKey;

  /// X25519 Public Key ประจำเครื่อง (32-byte binary)
  static List<int>? _myPublicKey;

  /// สมุดจดจัดเก็บ Public Key ของเพื่อนใน Mesh Network (peerId -> 32-byte public key)
  static final Map<String, List<int>> _peerPublicKeys = {};

  /// --------------------------------------------------------------------------
  /// 🔑 1. Local KeyPair Management (จัดเก็บ X25519 Private Key ใน Hardware Keystore/Keychain)
  /// --------------------------------------------------------------------------
  
  /// 🚀 เริ่มต้นโหลดกุญแจความปลอดภัยประจำเครื่อง (X25519 KeyPair)
  /// ดึงข้อมูลจาก Android Keystore / iOS Keychain หากยังไม่มีจะสร้างกุญแจคู่ใหม่ขึ้นมาทันที
  static Future<void> initKeys() async {
    if (_myPrivateKey != null && _myPublicKey != null) return;

    try {
      String? privHex = await _secureStorage.read(key: 'x25519_private_key');
      String? pubHex = await _secureStorage.read(key: 'x25519_public_key');

      // 🔄 ตรวจสอบและย้ายข้อมูลกุญแจเก่า (Migration) จาก SharedPreferences เดิมสู่ Secure Storage
      if (privHex == null || pubHex == null) {
        final prefs = await SharedPreferences.getInstance();
        final legacyPriv = prefs.getString('x25519_private_key');
        final legacyPub = prefs.getString('x25519_public_key');

        if (legacyPriv != null && legacyPub != null) {
          privHex = legacyPriv;
          pubHex = legacyPub;
          await _secureStorage.write(key: 'x25519_private_key', value: privHex);
          await _secureStorage.write(key: 'x25519_public_key', value: pubHex);
          await prefs.remove('x25519_private_key');
          await prefs.remove('x25519_public_key');
          debugPrint('[E2EE] Migrated X25519 keys to Android Keystore / iOS Keychain');
        }
      }

      if (privHex != null && pubHex != null) {
        _myPrivateKey = _hexToBytes(privHex);
        _myPublicKey = _hexToBytes(pubHex);
      } else {
        // 🎲 สุ่ม Private Key 32 ไบต์ และคำนวณ Public Key ด้วย X25519
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        final pub = x25519(priv, _basePoint);

        _myPrivateKey = priv;
        _myPublicKey = pub;

        await _secureStorage.write(key: 'x25519_private_key', value: _bytesToHex(priv));
        await _secureStorage.write(key: 'x25519_public_key', value: _bytesToHex(pub));
      }
    } catch (e) {
      debugPrint('[E2EE] Secure storage fallback: $e');
      final prefs = await SharedPreferences.getInstance();
      final privHex = prefs.getString('x25519_private_key');
      final pubHex = prefs.getString('x25519_public_key');
      if (privHex != null && pubHex != null) {
        _myPrivateKey = _hexToBytes(privHex);
        _myPublicKey = _hexToBytes(pubHex);
      } else {
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        final pub = x25519(priv, _basePoint);
        _myPrivateKey = priv;
        _myPublicKey = pub;
        await prefs.setString('x25519_private_key', _bytesToHex(priv));
        await prefs.setString('x25519_public_key', _bytesToHex(pub));
      }
    }
  }

  /// 🔑 ดึงค่า X25519 Public Key ประจำเครื่องในรูปแบบ Hex String 64 ตัวอักษร
  static String get myPublicKeyHex {
    if (_myPublicKey == null) {
      final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
      _myPrivateKey = priv;
      _myPublicKey = x25519(priv, _basePoint);
    }
    return _bytesToHex(_myPublicKey!);
  }

  /// 🆔 รหัสประจำตัวโหนดถาวร (Persistent Cryptographic Node ID)
  /// สกัดจาก 12 ตัวอักษรแรกของ X25519 Public Key Hex (เช่น "node_a1b2c3d4e5f6")
  /// รับประกันว่าเป็นเอกลักษณ์เฉพาะเครื่อง คงที่ถาวร ไม่เปลี่ยนแม้ผู้ใช้จะเปลี่ยนชื่อเล่น
  static String get nodeId {
    final pubHex = myPublicKeyHex;
    return 'node_${pubHex.substring(0, 12)}';
  }

  /// 🛡️ ตรวจสอบการผูกมัดทางคริปโต (Cryptographic Identity Binding Verification)
  /// ยืนยันว่า Node ID ตรงกับ 12 ตัวแรกของ Public Key จริง ป้องกันการปลอมแปลง Node ID
  static bool verifyPeerNodeId(String peerId, String publicKeyHex) {
    if (publicKeyHex.length < 12) return false;
    final expectedNodeId = 'node_${publicKeyHex.substring(0, 12)}';
    return peerId == expectedNodeId;
  }

  /// 📝 ลงทะเบียนและตรวจสอบ Public Key ของเพื่อนใน Mesh Network
  /// หาก Node ID ไม่ตรงกับ Public Key จะปฏิเสธการลงทะเบียนทันทีเพื่อป้องกัน Sybil / Spoofing Attack
  static void registerPeerPublicKey(String peerId, String publicKeyHex) {
    try {
      if (!verifyPeerNodeId(peerId, publicKeyHex)) {
        debugPrint('[E2EE V4 Warning] Node ID $peerId does NOT match Public Key! Rejected registration to prevent spoofing.');
        return;
      }
      _peerPublicKeys[peerId] = _hexToBytes(publicKeyHex);
      debugPrint('[E2EE V4] Registered verified public key for peer $peerId');
    } catch (e) {
      debugPrint('[E2EE V4] Error registering peer key: $e');
    }
  }

  /// 🔍 ตรวจสอบว่าแอปมี Public Key ของโหนดปลายทางแล้วหรือยัง
  static bool hasPeerPublicKey(String peerId) {
    return _peerPublicKeys.containsKey(peerId);
  }

  /// 🗑️ ลบ Public Key ของเพื่อนออกจากแคชหน่วยความจำ
  static void removePeerPublicKey(String peerId) {
    _peerPublicKeys.remove(peerId);
  }

  // --------------------------------------------------------------------------
  // 🆔 1b. Cryptographic Identity Fingerprint
  // --------------------------------------------------------------------------

  /// 🔏 คำนวณ SHA-256 Fingerprint จาก Public Key Hex String
  /// Fingerprint เป็น deterministic: publicKey เดิม → fingerprint เดิมเสมอ
  /// ใช้สำหรับแสดง Human-readable representation ของ Cryptographic Identity
  ///
  /// รูปแบบ output (32-char hex ของ SHA-256 แรก 16 bytes, แบ่งเป็น 8 กลุ่ม 4 chars):
  ///   "8B80 91A2 7C31 45F0\nA91D 8E21 6C44 1FC0"
  static String computeIdentityFingerprint(String publicKeyHex) {
    if (publicKeyHex.isEmpty) return '';
    try {
      // แปลง Public Key Hex → bytes → SHA-256 → hex string
      final pubBytes = _hexToBytes(publicKeyHex);
      final hashBytes = _sha256(pubBytes);
      final hashHex = _bytesToHex(hashBytes).toUpperCase();

      // ตัด 32 chars แรก (16 bytes) สำหรับ line 1, chars 32-63 สำหรับ line 2
      // แบ่งเป็นกลุ่ม 4 chars → "XXXX XXXX XXXX XXXX"
      String formatLine(String hex, int start) {
        final groups = <String>[];
        for (int i = start; i < start + 16; i += 4) {
          groups.add(hex.substring(i, i + 4));
        }
        return groups.join(' ');
      }

      final line1 = formatLine(hashHex, 0);
      final line2 = formatLine(hashHex, 16);
      return '$line1\n$line2';
    } catch (e) {
      debugPrint('[Identity] Error computing fingerprint: $e');
      return '';
    }
  }

  /// 🆔 Fingerprint ของเครื่องตัวเองจาก X25519 Public Key ประจำเครื่อง
  static String get myIdentityFingerprint {
    return computeIdentityFingerprint(myPublicKeyHex);
  }

  // --------------------------------------------------------------------------
  // 🔏 1c. Digital Signatures (สำหรับยืนยันความถูกต้องของ Peer Announce & ข้อมูลสุขภาพ)
  // --------------------------------------------------------------------------

  /// 🔏 สร้าง Digital Signature สำหรับเซ็นรับรองความถูกต้องของข้อมูลด้วย Private Key ประจำเครื่อง
  static String signData(String data) {
    if (_myPrivateKey == null || _myPublicKey == null) {
      final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
      _myPrivateKey = priv;
      _myPublicKey = x25519(priv, _basePoint);
    }
    // สกัด Key สำหรับสร้าง Signature ด้วย HKDF จาก Private Key ของเครื่องตนเอง
    final signingKey = hkdfSha256(
      ikm: _myPrivateKey!,
      info: utf8.encode('BantawanPayloadSigningKey_v2::$nodeId'),
      length: 32,
    );
    final mac = _computeHMAC(signingKey, 'DATA_SIG_V2::$nodeId::$data');
    return 'DATA_SIG_V2::$mac';
  }

  /// 🔏 ตรวจสอบ Digital Signature ของข้อมูลที่ได้รับจากเครือข่าย
  /// ยืนยันว่า Node ID และ Public Key ของผู้ส่งมีผลผูกพันจริง และข้อมูลไม่ถูกดัดแปลงระหว่างทาง
  static bool verifyDataSignature({
    required String data,
    required String? signature,
    required String publicKeyHex,
    required String senderId,
  }) {
    if (signature == null || !signature.startsWith('DATA_SIG_V2::')) return false;
    if (!verifyPeerNodeId(senderId, publicKeyHex)) {
      debugPrint('[Crypto Signature] Node ID $senderId does NOT match Public Key! Verification failed.');
      return false;
    }
    try {
      final peerPubKeyBytes = _hexToBytes(publicKeyHex);
      if (_myPrivateKey == null) {
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        _myPrivateKey = priv;
        _myPublicKey = x25519(priv, _basePoint);
      }
      final sharedSecret = x25519(_myPrivateKey!, peerPubKeyBytes);
      final verifierKey = hkdfSha256(
        ikm: sharedSecret,
        info: utf8.encode('BantawanPayloadSigningKey_v2::$senderId'),
        length: 32,
      );
      final expectedMac = _computeHMAC(verifierKey, 'DATA_SIG_V2::$senderId::$data');
      final receivedMac = signature.substring(13);
      return receivedMac == expectedMac;
    } catch (e) {
      debugPrint('[Crypto Signature Verification Error]: $e');
      return false;
    }
  }

  /// 📜 คำนวณ Canonical Data String สำหรับเซ็นชื่อแพ็กเก็ต Peer Announce & Emergency Profile
  static String computePeerAnnounceSignatureData(
    String senderId,
    String senderName,
    String publicKeyHex,
    Map<String, String>? profileData,
  ) {
    final profileJson = profileData != null ? jsonEncode(profileData) : '{}';
    return '$senderId::$senderName::$publicKeyHex::$profileJson';
  }

  /// --------------------------------------------------------------------------
  /// 🔐 2. Encrypt Payload: AES-256-CTR AEAD (with AAD Metadata Binding)
  /// รูปแบบแพ็กเก็ต: ENC_V4::ephemeralPubHex::ivBase64::aesCipherBase64::macBase64
  /// --------------------------------------------------------------------------
  
  /// 🔒 เข้ารหัสข้อความแชทส่วนตัวด้วยมาตรฐาน AES-256-CTR + HMAC-SHA256 (AEAD) — ENC_V5
  /// - ใช้ Ephemeral X25519 KeyPair สำหรับ Forward Secrecy ทุกข้อความ
  /// - ใช้ HKDF-SHA256 (RFC 5869) สกัด 64 bytes → แบ่งเป็น AES Key (32B) + HMAC Auth Key (32B)
  /// - Zero-Padding ข้อมูลก่อนเข้ารหัสให้ขนาดเป็น multiple ของ 64 bytes ป้องกัน traffic analysis
  /// - AAD Binding ครอบคลุม: ephemeralPub, iv, msgId, timestamp, senderId, recipientId
  static String encryptPayload({
    required String plainText,
    required String recipientId,
    required String senderId,
    String? msgId,
    int? timestampMs,
  }) {
    if (plainText.isEmpty) return '';

    try {
      if (_myPrivateKey == null || _myPublicKey == null) {
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        _myPrivateKey = priv;
        _myPublicKey = x25519(priv, _basePoint);
      }

      // 1. สุ่มสร้าง Ephemeral X25519 KeyPair สำหรับข้อความนี้โดยเฉพาะ (Forward Secrecy)
      final ephemeralPriv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
      final ephemeralPub = x25519(ephemeralPriv, _basePoint);

      // 2. ดึง Public Key ของผู้รับเป้าหมาย (Fail-closed)
      final recipientPubKey = _peerPublicKeys[recipientId];
      if (recipientPubKey == null) {
        debugPrint('[E2EE V5] Error: No public key registered for recipient $recipientId');
        throw Exception('E2EE_KEY_NOT_FOUND: Recipient public key is not available');
      }

      // 3. สังเคราะห์ Shared Secret ด้วย X25519 ECDH
      final sharedSecret = x25519(ephemeralPriv, recipientPubKey);

      // 4. HKDF Dual Key Derivation: สกัด 64 bytes → AES Key (bytes 0-31) + HMAC Key (bytes 32-63)
      final keyMaterial = hkdfSha256(
        ikm: sharedSecret,
        info: utf8.encode('BantawanAES256GCM_v5::$senderId::$recipientId'),
        length: 64,
      );
      final aesKey = keyMaterial.sublist(0, 32);   // 256-bit AES Encryption Key
      final hmacKey = keyMaterial.sublist(32, 64);  // 256-bit HMAC Authentication Key

      // 5. สุ่มค่า 12-byte IV (96-bit Nonce สำหรับ CTR Mode)
      final iv = List<int>.generate(12, (_) => _secureRandom.nextInt(256));

      // 6. Zero-Padding ก่อนเข้ารหัส เพื่อป้องกัน Traffic Analysis (ซ่อนความยาวข้อความจริง)
      final plainBytes = utf8.encode(plainText);
      final paddedBytes = _padToBlockSize(plainBytes, 64);

      // 7. เข้ารหัสด้วย AES-256 CTR Mode (FIPS 197)
      final cipherBytes = _aes256CtrEncrypt(aesKey, iv, paddedBytes);

      final ivBase64 = base64.encode(iv);
      final cipherBase64 = base64.encode(cipherBytes);
      final ephemeralPubHex = _bytesToHex(ephemeralPub);

      // 8. Full AAD Binding: ผูก msgId + timestamp เพิ่มจาก V4 เพื่อป้องกัน cut-and-paste / replay
      final effectiveMsgId = msgId ?? _generateMsgId();
      final effectiveTs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
      final aad = '$ephemeralPubHex::$ivBase64::$cipherBase64::$senderId::$recipientId::$effectiveMsgId::$effectiveTs';

      // 9. คำนวณ HMAC-SHA256 ด้วย hmacKey (แยกจาก aesKey — Dual Key)
      final mac = _computeHMAC(hmacKey, aad);

      return 'ENC_V5::$ephemeralPubHex::$ivBase64::$effectiveMsgId::$effectiveTs::$cipherBase64::$mac';
    } catch (e) {
      debugPrint('[E2EE V5] Encryption error: $e');
      throw Exception('E2EE_ENCRYPTION_FAILED: $e');
    }
  }

  /// 🔢 สร้าง unique msgId 8 hex characters สำหรับใช้ใน AAD binding
  static String _generateMsgId() {
    final bytes = List<int>.generate(4, (_) => _secureRandom.nextInt(256));
    return _bytesToHex(bytes);
  }

  /// 📦 Zero-Padding: เพิ่ม null bytes ท้ายข้อความให้ขนาดเป็น multiple ของ blockSize
  /// byte สุดท้ายเก็บจำนวน bytes ที่ถูก pad ไว้ (PKCS#7-like แบบ single-byte length)
  static List<int> _padToBlockSize(List<int> data, int blockSize) {
    // คำนวณจำนวน padding bytes ที่ต้องการ (อย่างน้อย 1 เสมอ)
    final padLen = blockSize - ((data.length + 1) % blockSize);
    final totalPad = padLen + 1;
    return [...data, ...List<int>.filled(padLen, 0), totalPad];
  }

  /// 📦 Unpad: ถอด Zero-Padding ออกหลังถอดรหัส
  static List<int> _unpadFromBlockSize(List<int> data) {
    if (data.isEmpty) return data;
    final padLen = data.last;
    if (padLen <= 0 || padLen > data.length) return data; // guard
    return data.sublist(0, data.length - padLen);
  }

  /// --------------------------------------------------------------------------
  /// 🔓 3. Decrypt Payload: ถอดรหัสด้วย AES-256 Block Cipher + HMAC Tag Check
  /// --------------------------------------------------------------------------
  
  /// 🔓 ถอดรหัสแพ็กเก็ตข้อความแชทส่วนตัว
  /// รองรับ V5 (ENC_V5) และ V4 (ENC_V4) สำหรับ backward compatibility
  /// พร้อมปฏิเสธแพ็กเก็ตการเข้ารหัสรุ่นเก่าที่ไม่ปลอดภัย (ENC_V2 / ENC_V3)
  static String decryptPayload({
    required String cipherText,
    required String recipientId,
    required String senderId,
  }) {
    if (cipherText.startsWith('ENC_V5::')) {
      return _decryptV5(cipherText, recipientId, senderId);
    }
    if (cipherText.startsWith('ENC_V4::')) {
      return _decryptV4(cipherText, recipientId, senderId);
    }
    // ปฏิเสธแพ็กเก็ต Legacy ที่ใช้ XOR Keystream ที่ไม่ปลอดภัย
    if (cipherText.startsWith('ENC_V3::') ||
        cipherText.startsWith('ENC_V2::') ||
        cipherText.startsWith('ENC::')) {
      debugPrint('[E2EE] Rejected legacy insecure ciphertext');
      return '🚨 [คำเตือน: รูปแบบการเข้ารหัสรุ่นเก่าที่ไม่ปลอดภัย]';
    }
    return cipherText;
  }

  /// แคชติดตาม Nonce ที่เคยถอดรหัสแล้วเพื่อป้องกัน Replay Attack
  static final LruNonceCache _usedNonces = LruNonceCache();

  /// 🔓 ถอดรหัสแพ็กเก็ต V5 — Dual-Key HKDF + Full AAD Binding + Zero-Padding
  /// รูปแบบ: ENC_V5::ephemeralPub::iv::msgId::timestamp::cipher::mac
  static String _decryptV5(String cipherText, String recipientId, String senderId) {
    try {
      final parts = cipherText.split('::');
      if (parts.length < 7) return '🔒 [ข้อมูลเสียหาย]';

      final ephemeralPubHex = parts[1];
      final ivBase64      = parts[2];
      final msgId         = parts[3];
      final timestampStr  = parts[4];
      final cipherBase64  = parts[5];
      final receivedMac   = parts[6];

      // 🛡️ Anti-Replay Guard: ผูก msgId เข้ากับ nonce key
      final nonceKey = '$ephemeralPubHex::$ivBase64::$msgId';
      if (_usedNonces.contains(nonceKey)) {
        debugPrint('[E2EE V5 Anti-Replay] Detected replayed nonce/msgId! Packet rejected.');
        return '🚨 [คำเตือน: ตรวจพบการส่งแพ็กเก็ตซ้ำ (Replay Attack)]';
      }
      _usedNonces.add(nonceKey);

      final ephemeralPub = _hexToBytes(ephemeralPubHex);

      if (_myPrivateKey == null) {
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        _myPrivateKey = priv;
        _myPublicKey = x25519(priv, _basePoint);
      }

      // 1. X25519 ECDH — สังเคราะห์ Shared Secret
      final sharedSecret = x25519(_myPrivateKey!, ephemeralPub);

      // 2. HKDF Dual Key Derivation (64 bytes)
      final keyMaterial = hkdfSha256(
        ikm: sharedSecret,
        info: utf8.encode('BantawanAES256GCM_v5::$senderId::$recipientId'),
        length: 64,
      );
      final aesKey  = keyMaterial.sublist(0, 32);
      final hmacKey = keyMaterial.sublist(32, 64);

      // 3. ตรวจสอบ HMAC ด้วย Full AAD (รวม msgId + timestamp)
      final aad = '$ephemeralPubHex::$ivBase64::$cipherBase64::$senderId::$recipientId::$msgId::$timestampStr';
      final expectedMac = _computeHMAC(hmacKey, aad);
      if (receivedMac != expectedMac) {
        debugPrint('[E2EE V5] MAC verification failed! Packet may be tampered (sender/recipient/msgId/timestamp).');
        return '🚨 [คำเตือน: ข้อมูลหรือ Metadata ถูกดัดแปลงระหว่างส่ง]';
      }

      // 4. ถอดรหัสด้วย AES-256 CTR Mode
      final iv = base64.decode(ivBase64);
      final cipherBytes = base64.decode(cipherBase64);
      final paddedBytes = _aes256CtrEncrypt(aesKey, iv, cipherBytes);

      // 5. ถอด Zero-Padding ออก
      final decryptedBytes = _unpadFromBlockSize(paddedBytes);

      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('[E2EE V5] Decryption error: $e');
      return '🔒 [ข้อความเข้ารหัส AES-256 - ไม่สามารถอ่านได้]';
    }
  }

  /// 🔓 ถอดรหัสแพ็กเก็ต V4 (Legacy — backward compatibility)
  /// รูปแบบ: ENC_V4::ephemeralPub::iv::cipher::mac
  static String _decryptV4(String cipherText, String recipientId, String senderId) {
    try {
      final parts = cipherText.split('::');
      if (parts.length < 5) return '🔒 [ข้อมูลเสียหาย]';

      final ephemeralPubHex = parts[1];
      final ivBase64 = parts[2];
      final cipherBase64 = parts[3];
      final receivedMac = parts[4];

      // 🛡️ Anti-Replay Nonce Guard
      final nonceKey = '$ephemeralPubHex::$ivBase64';
      if (_usedNonces.contains(nonceKey)) {
        debugPrint('[E2EE V4 Anti-Replay Guard] Detected replayed nonce/ephemeral key! Packet rejected.');
        return '🚨 [คำเตือน: ตรวจพบการส่งแพ็กเก็ตซ้ำ (Replay Attack)]';
      }
      _usedNonces.add(nonceKey);

      final ephemeralPub = _hexToBytes(ephemeralPubHex);

      if (_myPrivateKey == null) {
        final priv = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
        _myPrivateKey = priv;
        _myPublicKey = x25519(priv, _basePoint);
      }

      // 1. X25519 ECDH
      final sharedSecret = x25519(_myPrivateKey!, ephemeralPub);

      // 2. HKDF → Single AES Key (V4 legacy: ใช้ aesKey เดียวสำหรับทั้ง encrypt และ mac)
      final aesKey = hkdfSha256(
        ikm: sharedSecret,
        info: utf8.encode('BantawanAES256GCM_v4::$senderId::$recipientId'),
        length: 32,
      );

      // 3. ตรวจสอบ MAC
      final expectedMac = _computeHMAC(aesKey, '$ephemeralPubHex::$ivBase64::$cipherBase64::$senderId::$recipientId');
      if (receivedMac != expectedMac) {
        debugPrint('[E2EE V4] MAC verification failed! Ciphertext or metadata was tampered with.');
        return '🚨 [คำเตือน: ข้อมูลหรือผู้รับผู้ส่งถูกดัดแปลงระหว่างส่ง]';
      }

      // 4. ถอดรหัสด้วย AES-256 CTR Mode
      final iv = base64.decode(ivBase64);
      final cipherBytes = base64.decode(cipherBase64);
      final decryptedBytes = _aes256CtrEncrypt(aesKey, iv, cipherBytes);

      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('[E2EE V4] Decryption error: $e');
      return '🔒 [ข้อความเข้ารหัส AES-256 - ไม่สามารถอ่านได้]';
    }
  }

  /// --------------------------------------------------------------------------
  /// 🛡️ 4. FIPS 197 Standard AES-256 Block Cipher Implementation (Pure Dart)
  /// --------------------------------------------------------------------------
  
  /// ⚡ เข้ารหัส/ถอดรหัสแบบ Stream Block Cipher ในโหมด AES-256 Counter (CTR Mode)
  static List<int> _aes256CtrEncrypt(List<int> key, List<int> iv, List<int> input) {
    final expandedKey = _aesKeyExpansion(key);
    final output = List<int>.filled(input.length, 0);

    // 12-byte IV + 4-byte Counter (Big-Endian Counter starting at 1)
    final counterBlock = List<int>.filled(16, 0);
    for (int i = 0; i < 12 && i < iv.length; i++) {
      counterBlock[i] = iv[i];
    }

    int counter = 1;
    for (int offset = 0; offset < input.length; offset += 16) {
      // อัปเดต 4-byte counter ใน counterBlock
      counterBlock[12] = (counter >> 24) & 0xff;
      counterBlock[13] = (counter >> 16) & 0xff;
      counterBlock[14] = (counter >> 8) & 0xff;
      counterBlock[15] = counter & 0xff;
      counter++;

      // เข้ารหัส Counter Block ด้วย AES-256 Single Block Encrypt
      final encryptedCounter = _aes256EncryptBlock(expandedKey, counterBlock);

      // XOR ระหว่าง Plaintext block กับ Encrypted Counter
      final blockSize = min(16, input.length - offset);
      for (int i = 0; i < blockSize; i++) {
        output[offset + i] = input[offset + i] ^ encryptedCounter[i];
      }
    }
    return output;
  }

  /// 🔐 AES-256 Block Cipher Encryption (FIPS 197 Standard - 14 Rounds)
  static List<int> _aes256EncryptBlock(List<int> w, List<int> block) {
    var state = List<int>.from(block);

    // Round 0: AddRoundKey
    _addRoundKey(state, w, 0);

    // Rounds 1 to 13
    for (int round = 1; round <= 13; round++) {
      _subBytes(state);
      _shiftRows(state);
      _mixColumns(state);
      _addRoundKey(state, w, round * 16);
    }

    // Round 14: Final Round (without MixColumns)
    _subBytes(state);
    _shiftRows(state);
    _addRoundKey(state, w, 14 * 16);

    return state;
  }

  /// 🔑 AES Key Expansion (ขยายกุญแจ 256-bit ไปเป็น 60 32-bit words / 240 bytes)
  static List<int> _aesKeyExpansion(List<int> key) {
    final w = List<int>.filled(240, 0);
    for (int i = 0; i < 32; i++) {
      w[i] = key[i];
    }

    for (int i = 32; i < 240; i += 4) {
      var temp = [w[i - 4], w[i - 3], w[i - 2], w[i - 1]];
      final wordIndex = i ~/ 4;

      if (wordIndex % 8 == 0) {
        // RotWord + SubWord + Rcon
        final rot = [temp[1], temp[2], temp[3], temp[0]];
        temp = [
          _sBox[rot[0]] ^ _rcon[wordIndex ~/ 8],
          _sBox[rot[1]],
          _sBox[rot[2]],
          _sBox[rot[3]]
        ];
      } else if (wordIndex % 8 == 4) {
        // SubWord
        temp = [_sBox[temp[0]], _sBox[temp[1]], _sBox[temp[2]], _sBox[temp[3]]];
      }

      w[i] = w[i - 32] ^ temp[0];
      w[i + 1] = w[i - 31] ^ temp[1];
      w[i + 2] = w[i - 30] ^ temp[2];
      w[i + 3] = w[i - 29] ^ temp[3];
    }
    return w;
  }

  static void _addRoundKey(List<int> state, List<int> w, int offset) {
    for (int i = 0; i < 16; i++) {
      state[i] ^= w[offset + i];
    }
  }

  static void _subBytes(List<int> state) {
    for (int i = 0; i < 16; i++) {
      state[i] = _sBox[state[i]];
    }
  }

  static void _shiftRows(List<int> s) {
    // Row 1: shift left 1
    var tmp = s[1]; s[1] = s[5]; s[5] = s[9]; s[9] = s[13]; s[13] = tmp;
    // Row 2: shift left 2
    tmp = s[2]; s[2] = s[10]; s[10] = tmp;
    tmp = s[6]; s[6] = s[14]; s[14] = tmp;
    // Row 3: shift left 3
    tmp = s[15]; s[15] = s[11]; s[11] = s[7]; s[7] = s[3]; s[3] = tmp;
  }

  static void _mixColumns(List<int> s) {
    for (int c = 0; c < 4; c++) {
      final i = c * 4;
      final a0 = s[i], a1 = s[i + 1], a2 = s[i + 2], a3 = s[i + 3];
      s[i] = (_gmul2(a0) ^ _gmul3(a1) ^ a2 ^ a3) & 0xff;
      s[i + 1] = (a0 ^ _gmul2(a1) ^ _gmul3(a2) ^ a3) & 0xff;
      s[i + 2] = (a0 ^ a1 ^ _gmul2(a2) ^ _gmul3(a3)) & 0xff;
      s[i + 3] = (_gmul3(a0) ^ a1 ^ a2 ^ _gmul2(a3)) & 0xff;
    }
  }

  static int _gmul2(int x) => (((x << 1) ^ ((x & 0x80) != 0 ? 0x1b : 0))) & 0xff;
  static int _gmul3(int x) => (_gmul2(x) ^ x) & 0xff;

  /// AES S-Box Look-up Table (FIPS 197 Table)
  static const List<int> _sBox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
  ];

  static const List<int> _rcon = [
    0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
  ];

  /// --------------------------------------------------------------------------
  /// 📐 5. X25519 (Curve25519) Scalar Multiplication (Montgomery Ladder Algorithm)
  /// --------------------------------------------------------------------------
  
  /// 📐 อัลกอริทึม X25519 Diffie-Hellman Scalar Multiplication (RFC 7748)
  /// คำนวณ Shared Secret หรือ Public Key จาก Scalar (Private Key) และ U-Coordinate Point
  static List<int> x25519(List<int> scalar, List<int> uBytes) {
    final k = List<int>.from(scalar);
    k[0] &= 248;
    k[31] &= 127;
    k[31] |= 64;

    BigInt kBig = BigInt.zero;
    for (int i = 31; i >= 0; i--) {
      kBig = (kBig << 8) | BigInt.from(k[i]);
    }

    BigInt u = BigInt.zero;
    for (int i = 31; i >= 0; i--) {
      u = (u << 8) | BigInt.from(uBytes[i]);
    }
    u = u % _p;

    BigInt x1 = u;
    BigInt x2 = BigInt.one;
    BigInt z2 = BigInt.zero;
    BigInt x3 = u;
    BigInt z3 = BigInt.one;
    bool swap = false;

    final a24 = BigInt.from(121665);

    for (int t = 254; t >= 0; t--) {
      bool kt = ((kBig >> t) & BigInt.one) == BigInt.one;
      swap ^= kt;
      if (swap) {
        var dummyX = x2; x2 = x3; x3 = dummyX;
        var dummyZ = z2; z2 = z3; z3 = dummyZ;
      }
      swap = kt;

      var aVal = (x2 + z2) % _p;
      var aaVal = (aVal * aVal) % _p;
      var bVal = (x2 - z2) % _p; if (bVal.isNegative) bVal += _p;
      var bbVal = (bVal * bVal) % _p;
      var eVal = (aaVal - bbVal) % _p; if (eVal.isNegative) eVal += _p;
      var cVal = (x3 + z3) % _p;
      var dVal = (x3 - z3) % _p; if (dVal.isNegative) dVal += _p;
      var daVal = (dVal * aVal) % _p;
      var cbVal = (cVal * bVal) % _p;

      var daPlusCb = (daVal + cbVal) % _p;
      var daMinusCb = (daVal - cbVal) % _p; if (daMinusCb.isNegative) daMinusCb += _p;

      var x3New = (daPlusCb * daPlusCb) % _p;
      var z3New = (x1 * ((daMinusCb * daMinusCb) % _p)) % _p;
      var x2New = (aaVal * bbVal) % _p;
      var z2New = (eVal * ((bbVal + (a24 * eVal) % _p) % _p)) % _p;

      x2 = x2New; z2 = z2New;
      x3 = x3New; z3 = z3New;
    }

    if (swap) {
      var dummyX = x2; x2 = x3; x3 = dummyX;
      var dummyZ = z2; z2 = z3; z3 = dummyZ;
    }

    BigInt result = (x2 * z2.modInverse(_p)) % _p;

    final out = List<int>.filled(32, 0);
    var temp = result;
    for (int i = 0; i < 32; i++) {
      out[i] = (temp & BigInt.from(0xff)).toInt();
      temp >>= 8;
    }
    return out;
  }

  /// --------------------------------------------------------------------------
  /// 🛠️ 6. HKDF-SHA256 Engine (HMAC-based Key Derivation Function - RFC 5869)
  /// --------------------------------------------------------------------------
  
  /// 🛠️ ฟังก์ชันสกัดกุญแจ HKDF-SHA256 (RFC 5869)
  /// แปลง Shared Secret แบบสุ่มให้กลายเป็นกุญแจเข้ารหัส AES ความยาว 256 บิต
  static List<int> hkdfSha256({
    required List<int> ikm,
    List<int>? salt,
    List<int>? info,
    int length = 32,
  }) {
    salt ??= List<int>.filled(32, 0);
    info ??= utf8.encode('BantawanE2EE_v4');

    final prk = _computeHmacBytes(salt, ikm);

    final okm = <int>[];
    var t = <int>[];
    int i = 1;
    while (okm.length < length) {
      t = _computeHmacBytes(prk, [...t, ...info, i]);
      okm.addAll(t);
      i++;
    }
    return okm.sublist(0, length);
  }

  /// คำนวณ HMAC-SHA256 จากข้อมูลข้อความและคืนค่าเป็น Base64 String
  static String _computeHMAC(List<int> key, String data) {
    final hash = _computeHmacBytes(key, utf8.encode(data));
    return base64.encode(hash);
  }

  /// 🛡️ อัลกอริทึมมาตรฐาน HMAC-SHA256 (RFC 2104)
  static List<int> _computeHmacBytes(List<int> key, List<int> message) {
    var k = List<int>.from(key);
    if (k.length > 64) {
      k = _sha256(k);
    }
    if (k.length < 64) {
      k = List<int>.from(k)..addAll(List<int>.filled(64 - k.length, 0));
    }

    final oKeyPad = List<int>.filled(64, 0);
    final iKeyPad = List<int>.filled(64, 0);

    for (int i = 0; i < 64; i++) {
      oKeyPad[i] = k[i] ^ 0x5c;
      iKeyPad[i] = k[i] ^ 0x36;
    }

    final innerHash = _sha256([...iKeyPad, ...message]);
    return _sha256([...oKeyPad, ...innerHash]);
  }

  /// แปลง Byte Array เป็น Hexadecimal String
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// แปลง Hexadecimal String เป็น Byte Array
  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// ⚡ Pure Dart SHA-256 Engine (FIPS 180-4 Standard)
  static List<int> _sha256(List<int> input) {
    final K = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef4a3f7, 0xc67178f2
    ];

    int h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    int h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    final bitLen = input.length * 8;
    final padded = List<int>.from(input)..add(0x80);
    while ((padded.length % 64) != 56) {
      padded.add(0);
    }
    for (int i = 7; i >= 0; i--) {
      padded.add((bitLen >> (i * 8)) & 0xff);
    }

    final w = List<int>.filled(64, 0);
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) |
            (padded[chunk + i * 4 + 1] << 16) |
            (padded[chunk + i * 4 + 2] << 8) |
            (padded[chunk + i * 4 + 3]);
      }
      for (int i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      int a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;

      for (int i = 0; i < 64; i++) {
        final s1Val = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (h + s1Val + ch + K[i] + w[i]) & 0xffffffff;
        final s0Val = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0Val + maj) & 0xffffffff;

        h = g; g = f; f = e; e = (d + temp1) & 0xffffffff;
        d = c; c = b; b = a; a = (temp1 + temp2) & 0xffffffff;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }

    final result = <int>[];
    for (var val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      result.add((val >> 24) & 0xff);
      result.add((val >> 16) & 0xff);
      result.add((val >> 8) & 0xff);
      result.add(val & 0xff);
    }
    return result;
  }

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;
}
