// ============================================================================
// 🌐 BANTAWAN Mesh Peer Model: MeshPeer (Layer 4 of BANTAWAN Architecture)
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// ├─────────────────────────────────────────────────────────┤
// │                BANTAWAN Mesh Routing Engine             │
// │              (MeshPeer: Discovered Node State)          │
// ├─────────────────────────────────────────────────────────┤
// │            Transport Layer (Nearby Connections)          │
// └─────────────────────────────────────────────────────────┘
// 
// โครงสร้างข้อมูลสำหรับตัวแทนโหนดที่ค้นพบในเครือข่าย Multi-hop Mesh
// เก็บข้อมูลประจำโหนด, X25519 Public Key, สถานะการเชื่อมต่อ และโปรไฟล์ทางการแพทย์ฉุกเฉิน
// ============================================================================

/// 🌐 สถานะรูปแบบการเชื่อมต่อของโหนดในเครือข่าย Mesh
/// - [direct]: เชื่อมต่อบลูทูธโดยตรงในระยะ 1 hop (🟢)
/// - [relayed]: เชื่อมต่อผ่านโหนดกลางทางแบบ Multi-hop (🟣)
/// - [offline]: ไม่ได้ยินสัญญาณแอนเนาส์เกิน 3 นาที (⚪)
enum PeerConnectionStatus { direct, relayed, offline }

/// 👤 โมเดลข้อมูลโหนดเพื่อนบ้านในเครือข่ายไร้สาย (Mesh Peer Node)
class MeshPeer {
  /// รหัสประจำโหนดถาวร (Cryptographic Node ID สกัดจาก Public Key 12 ตัวแรก เช่น "node_a1b2c3d4e5f6")
  final String peerId;

  /// ชื่อแสดงผลประจำโหนด (Display Callsign เช่น "Survivor_1234")
  final String peerName;

  /// X25519 Public Key (Hex String 64 ตัวอักษร) สำหรับใช้เข้ารหัสข้อความแชทส่วนตัว (E2EE)
  final String publicKeyHex;

  /// จำนวนทอดระยะห่างจากโหนดต้นทาง (1 = Direct BLE Link, 2+ = Multi-hop Relayed Node)
  final int hopCount;

  /// endpointId ของ Nearby Connections กรณีที่เชื่อมต่อบลูทูธโดยตรง (Direct BLE Link)
  final String? directEndpoint;

  /// ประทับเวลาล่าสุดที่ได้รับสัญญาณประกาศตัวตน (Heartbeat Announcement)
  final DateTime lastSeen;

  /// 🏥 ข้อมูลโปรไฟล์ทางการแพทย์ฉุกเฉิน (In Case of Emergency - ICE Profile)
  final Map<String, String>? emergencyProfile;

  MeshPeer({
    required this.peerId,
    required this.peerName,
    required this.publicKeyHex,
    this.hopCount = 1,
    this.directEndpoint,
    DateTime? lastSeen,
    this.emergencyProfile,
  }) : lastSeen = lastSeen ?? DateTime.now();

  /// 📶 ตรวจสอบว่าเป็นการเชื่อมต่อบลูทูธโดยตรงระยะ 1 hop หรือไม่
  bool get isDirect => hopCount == 1;

  /// ⏱️ ตรวจสอบว่าโหนดนี้ยังออนไลน์อยู่หรือไม่ (ได้รับสัญญาณ Announce ล่าสุดภายใน 3 นาที)
  bool get isReachable {
    final diff = DateTime.now().difference(lastSeen);
    return diff.inMinutes < 3;
  }

  /// 🌐 ดึงสถานะการเชื่อมต่อปัจจุบันของโหนด (Direct BLE 🟢 / Relayed 🟣 / Offline ⚪)
  PeerConnectionStatus get connectionStatus {
    if (!isReachable) return PeerConnectionStatus.offline;
    if (hopCount == 1 || directEndpoint != null) return PeerConnectionStatus.direct;
    return PeerConnectionStatus.relayed;
  }

  // --- 🏥 Getters สะดวกใช้งานสำหรับข้อมูลโปรไฟล์ทางการแพทย์ฉุกเฉิน (ICE Profile) ---

  /// กรุ๊ปเลือด (เช่น "A+", "O-")
  String get bloodType => emergencyProfile?['bloodType'] ?? '';

  /// ประวัติการแพ้ยาและอาหาร (เช่น "เพนิซิลลิน, ถั่ว")
  String get allergies => emergencyProfile?['allergies'] ?? '';

  /// โรคประจำตัว (เช่น "ความดันโลหิตสูง, เบาหวาน")
  String get conditions => emergencyProfile?['conditions'] ?? '';

  /// อายุผู้ใช้งาน
  String get age => emergencyProfile?['age'] ?? '';

  /// โรงพยาบาลที่ต้องการส่งตัวเป็นพิเศษ
  String get hospitalPref => emergencyProfile?['hospitalPref'] ?? '';

  /// ประสงค์บริจาคอวัยวะหรือไม่
  bool get isOrganDonor => emergencyProfile?['organDonor'] == 'true';

  /// 🛡️ ผู้ใช้ตั้งค่าปิดการแชร์ข้อมูลการแพทย์ฉุกเฉิน (Private Mode)
  bool get isPrivacyProtected => emergencyProfile?['isPrivacyProtected'] == 'true';

  /// 🛡️ ผู้ใช้แชร์เฉพาะข้อมูลปฐมพยาบาลวิกฤต (Minimal First-Aid Only)
  bool get isMinimalShared => emergencyProfile?['isMinimalShared'] == 'true';

  /// 🏥 ตรวจสอบว่ามีข้อมูลทางการแพทย์อย่างน้อย 1 รายการหรือไม่
  bool get hasMedicalData =>
      !isPrivacyProtected &&
      (bloodType.isNotEmpty ||
          allergies.isNotEmpty ||
          conditions.isNotEmpty ||
          hospitalPref.isNotEmpty);

  /// 🔄 คัดลอกและสร้างอินสแตนซ์ใหม่พร้อมอัปเดตฟิลด์บางส่วน (Immutable State Pattern)
  MeshPeer copyWith({
    String? peerId,
    String? peerName,
    String? publicKeyHex,
    int? hopCount,
    String? directEndpoint,
    DateTime? lastSeen,
    Map<String, String>? emergencyProfile,
  }) {
    return MeshPeer(
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      hopCount: hopCount ?? this.hopCount,
      directEndpoint: directEndpoint ?? this.directEndpoint,
      lastSeen: lastSeen ?? this.lastSeen,
      emergencyProfile: emergencyProfile ?? this.emergencyProfile,
    );
  }

  /// 📦 แปลงออบเจกต์ MeshPeer ให้เป็น Map (JSON Object) สำหรับซีเรียลไลซ์ส่งผ่านแชนเนล
  Map<String, dynamic> toJson() => {
    'peerId': peerId,
    'peerName': peerName,
    'publicKeyHex': publicKeyHex,
    'hopCount': hopCount,
    'directEndpoint': directEndpoint,
    'lastSeen': lastSeen.toIso8601String(),
    if (emergencyProfile != null) 'emergencyProfile': emergencyProfile,
  };

  /// 📦 แปลงข้อมูล Map (JSON Object) กลับเป็นออบเจกต์ MeshPeer
  factory MeshPeer.fromJson(Map<String, dynamic> json) => MeshPeer(
    peerId: json['peerId'] ?? '',
    peerName: json['peerName'] ?? '',
    publicKeyHex: json['publicKeyHex'] ?? '',
    hopCount: json['hopCount'] ?? 1,
    directEndpoint: json['directEndpoint'],
    lastSeen: json['lastSeen'] != null
        ? DateTime.parse(json['lastSeen'])
        : DateTime.now(),
    emergencyProfile: json['emergencyProfile'] != null
        ? Map<String, String>.from(json['emergencyProfile'])
        : null,
  );
}
