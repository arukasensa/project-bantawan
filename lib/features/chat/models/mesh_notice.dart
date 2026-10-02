// ============================================================================
// 📌 BANTAWAN Offline Mesh Notice Model: MeshNotice (Epidemic Bulletin Board)
// 
// โมเดลข้อมูลกระดานประกาศฉุกเฉินสาธารณะออฟไลน์ สไตล์ bitchat (@ #mesh)
// ส่งต่อจากมือถือสู่มือถือ (Store-and-Forward Gossip Protocol) แม้ไม่มีอินเทอร์เน็ต
// พร้อมระบบกำหนดวันหมดอายุอัตโนมัติ (TTL Expiry: 1 วัน, 3 วัน, 7 วัน)
// ============================================================================

import 'dart:math';

class MeshNotice {
  /// ไอดีประจำประกาศ (UUID v4)
  final String id;

  /// รหัสประจำโหนดผู้สร้างประกาศ (Node ID เช่น "node_a1b2c3d4e5f6")
  final String authorId;

  /// ชื่อเรียกของผู้สร้างประกาศ (Callsign เช่น "บ้านตะวัน", "Survivor_3f86")
  final String authorName;

  /// ข้อความประกาศ
  final String content;

  /// เวลาที่สร้างประกาศ
  final DateTime createdAt;

  /// เวลาที่ประกาศจะหมดอายุและลบตัวเองอัตโนมัติ
  final DateTime expiresAt;

  /// ธงระบุว่าเป็นประกาศด่วน/ฉุกเฉินวิกฤตหรือไม่
  final bool isUrgent;

  /// พิกัดละติจูด (ถ้ามีการแนบตำแหน่งจุดเกิดเหตุ/จุดแจกของ)
  final double? latitude;

  /// พิกัดลองจิจูด
  final double? longitude;

  /// จำนวนทอดที่ประกาศนี้ถูกส่งต่อมา (1 = ได้ยินจากผู้ประกาศโดยตรง)
  final int hopCount;

  MeshNotice({
    String? id,
    required this.authorId,
    required this.authorName,
    required this.content,
    DateTime? createdAt,
    required this.expiresAt,
    this.isUrgent = false,
    this.latitude,
    this.longitude,
    this.hopCount = 1,
  })  : id = id ?? _generateUuidV4(),
        createdAt = createdAt ?? DateTime.now();

  /// 🆔 สุ่มสร้าง UUID v4 สำหรับประจำประกาศ
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// ⏱️ ตรวจสอบว่าประกาศหมดอายุแล้วหรือยัง
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// ⏳ ระยะเวลาที่เหลืออยู่ก่อนหมดอายุ
  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 💬 ข้อความแสดงเวลาที่เหลือก่อนหมดอายุแบบเข้าใจง่าย
  String get remainingTimeFormatted {
    final rem = remainingTime;
    if (rem.inDays >= 1) {
      final days = rem.inDays;
      final hours = rem.inHours % 24;
      return hours > 0 ? 'หมดอายุในอีก $days วัน $hours ชม.' : 'หมดอายุในอีก $days วัน';
    } else if (rem.inHours >= 1) {
      final hours = rem.inHours;
      final mins = rem.inMinutes % 60;
      return mins > 0 ? 'หมดอายุในอีก $hours ชม. $mins นาที' : 'หมดอายุในอีก $hours ชม.';
    } else if (rem.inMinutes >= 1) {
      return 'หมดอายุในอีก ${rem.inMinutes} นาที';
    } else if (rem.inSeconds > 0) {
      return 'กำลังจะหมดอายุในไม่กี่วินาที';
    }
    return 'หมดอายุแล้ว';
  }

  /// แปลงเป็น JSON สำหรับกระจายสัญญาณผ่าน Nearby Mesh Payload
  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isUrgent': isUrgent,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'hopCount': hopCount,
        'isNotice': true,
      };

  /// แปลงข้อมูล JSON ที่ได้รับจากโครงข่ายไร้สายกลับเป็น MeshNotice
  factory MeshNotice.fromJson(Map<String, dynamic> json) => MeshNotice(
        id: json['id'] as String?,
        authorId: json['authorId'] as String? ?? 'unknown',
        authorName: json['authorName'] as String? ?? 'Survivor',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(days: 3)),
        isUrgent: json['isUrgent'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        hopCount: (json['hopCount'] as num?)?.toInt() ?? 1,
      );

  /// แปลงเป็น Map สำหรับบันทึกลงใน SQLite Database
  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isUrgent': isUrgent ? 1 : 0,
        'latitude': latitude,
        'longitude': longitude,
        'hopCount': hopCount,
      };

  /// แปลงข้อมูลจาก SQLite Map กลับเป็น MeshNotice
  factory MeshNotice.fromMap(Map<String, dynamic> map) => MeshNotice(
        id: map['id'] as String,
        authorId: map['authorId'] as String? ?? 'unknown',
        authorName: map['authorName'] as String? ?? 'Survivor',
        content: map['content'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        expiresAt: DateTime.parse(map['expiresAt'] as String),
        isUrgent: (map['isUrgent'] as int? ?? 0) == 1,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        hopCount: (map['hopCount'] as int? ?? 1),
      );

  /// สร้างสำเนาใหม่เพื่ออัปเดตฟิลด์บางส่วน (เช่น เพิ่ม hopCount ก่อนส่งต่อ)
  MeshNotice copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUrgent,
    double? latitude,
    double? longitude,
    int? hopCount,
  }) =>
      MeshNotice(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isUrgent: isUrgent ?? this.isUrgent,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        hopCount: hopCount ?? this.hopCount,
      );
}
