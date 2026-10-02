// ============================================================================
// 🔐 BANTAWAN Peer Identity Trust Model: PeerTrust
//
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │              Peer Identity Verification Layer           │
// │         (PeerTrust: Cryptographic Trust State)          │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// │           (CryptoMeshService: X25519 ECDH)              │
// └─────────────────────────────────────────────────────────┘
//
// โมเดลข้อมูลสถานะความน่าเชื่อถือของ Peer ที่ผู้ใช้เคยสื่อสารด้วย
// ใช้ Cryptographic Fingerprint (SHA-256 ของ Public Key) เป็น Identity
// ไม่ใช้ displayName เป็น Identity (displayName เปลี่ยนได้ตลอด)
// ============================================================================

/// 🔐 สถานะความน่าเชื่อถือของ Peer แต่ละราย
enum PeerTrustState {
  /// ยังไม่เคยพบ Peer นี้ในระบบ Trust Store
  unknown,

  /// พบ Peer แต่ยังไม่ได้ยืนยัน Fingerprint ด้วยมือ (สื่อสารได้แต่ยังไม่ verified)
  unverified,

  /// ผู้ใช้เคยยืนยัน Fingerprint ของ Peer นี้แล้ว และ Public Key ยังตรงกับที่บันทึกไว้
  verified,

  /// Peer ใช้ Public Key ใหม่หลังจากเคยถูก verify แล้ว → อาจถูก MITM หรือ re-install
  changed,
}

/// 👤 โมเดลข้อมูลสถานะความน่าเชื่อถือของ Peer (Cryptographic Trust Record)
/// บันทึกลง Local Storage เพื่อคงสถานะระหว่าง session
class PeerTrust {
  /// รหัสประจำโหนดถาวร (Cryptographic Node ID เช่น "node_a1b2c3d4e5f6")
  final String peerId;

  /// ชื่อแสดงผลที่ Peer ใช้ตอน verify (Human-readable เท่านั้น ไม่ใช้เป็น identity)
  final String displayName;

  /// X25519 Public Key ที่บันทึกไว้ตอน verify (Hex String 64 chars)
  final String publicKeyHex;

  /// SHA-256 Fingerprint ของ publicKeyHex (format: "XXXX XXXX XXXX XXXX\nXXXX XXXX XXXX XXXX")
  final String fingerprint;

  /// เวลาที่ผู้ใช้กดยืนยัน fingerprint ครั้งล่าสุด
  final DateTime? verifiedAt;

  /// สถานะความน่าเชื่อถือปัจจุบัน
  final PeerTrustState trustState;

  const PeerTrust({
    required this.peerId,
    required this.displayName,
    required this.publicKeyHex,
    required this.fingerprint,
    this.verifiedAt,
    required this.trustState,
  });

  /// 🔄 คัดลอกและสร้างอินสแตนซ์ใหม่พร้อมอัปเดตบางฟิลด์
  PeerTrust copyWith({
    String? peerId,
    String? displayName,
    String? publicKeyHex,
    String? fingerprint,
    DateTime? verifiedAt,
    PeerTrustState? trustState,
  }) {
    return PeerTrust(
      peerId: peerId ?? this.peerId,
      displayName: displayName ?? this.displayName,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      fingerprint: fingerprint ?? this.fingerprint,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      trustState: trustState ?? this.trustState,
    );
  }

  /// 📦 แปลงเป็น Map สำหรับ JSON serialization (SharedPreferences)
  Map<String, dynamic> toJson() => {
    'peerId': peerId,
    'displayName': displayName,
    'publicKeyHex': publicKeyHex,
    'fingerprint': fingerprint,
    'verifiedAt': verifiedAt?.toIso8601String(),
    'trustState': trustState.name,
  };

  /// 📦 สร้างออบเจกต์จาก JSON Map (SharedPreferences)
  factory PeerTrust.fromJson(Map<String, dynamic> json) {
    return PeerTrust(
      peerId: json['peerId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      publicKeyHex: json['publicKeyHex'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      trustState: PeerTrustState.values.firstWhere(
        (s) => s.name == (json['trustState'] as String? ?? 'unknown'),
        orElse: () => PeerTrustState.unknown,
      ),
    );
  }

  @override
  String toString() =>
      'PeerTrust(peerId: $peerId, displayName: $displayName, trustState: ${trustState.name})';
}
