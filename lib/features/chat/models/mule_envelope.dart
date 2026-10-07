// ============================================================================
// 🎒 BANTAWAN Data Mule Envelope Model: MuleEnvelope
// 
// โมเดลซองจดหมายดิจิทัลสำหรับระบบ "คนเดินสาร" (Store-Carry-and-Forward Mesh Carrier)
// ข้อมูลภายในถูกเข้ารหัส Zero-Knowledge (AES-256-GCM) คนกลางไม่สามารถเปิดอ่านได้
// ใช้สำหรับฝากส่งข้ามระยะทางในพื้นที่ภัยพิบัติที่ไม่มีสัญญาณเชื่อมต่อโดยตรง
// ============================================================================

import 'dart:math';

class MuleEnvelope {
  /// รหัสประจำซองจดหมาย (UUID v4)
  final String envelopeId;

  /// รหัสประจำโหนดของผู้ส่งต้นทาง (Node ID เช่น "node_87a7a926578a")
  final String senderNodeId;

  /// ชื่อเรียกของผู้ส่ง (Callsign เช่น "สมชาย (ผู้ประสบภัย)")
  final String senderCallsign;

  /// รหัสประจำโหนดของผู้รับปลายทาง หรือกลุ่มฉุกเฉิน (เช่น "node_d9b231c" หรือ "@RESCUE_TEAM")
  final String recipientNodeId;

  /// ข้อมูลเนื้อหาที่เข้ารหัสแบบ E2EE (Base64 Ciphertext)
  final String encryptedPayload;

  /// เวกเตอร์กำหนดค่าเริ่มต้น (Initialization Vector - Base64) สำหรับ AES-GCM
  final String payloadIv;

  /// แท็กรับรองความถูกต้องของข้อมูล (Auth Tag - Base64) สำหรับ AES-GCM
  final String payloadAuthTag;

  /// ลายเซ็นดิจิทัลของผู้ส่งต้นทาง (Digital Signature - Base64) ป้องกันการปลอมแปลง
  final String senderSignature;

  /// ธงระบุว่าเป็นข้อความฉุกเฉินระดับวิกฤต (SOS) หรือไม่
  final bool isUrgentSOS;

  /// วันเวลาที่สร้างซองจดหมาย
  final DateTime createdAt;

  /// วันเวลาที่ซองจดหมายจะหมดอายุและลบทิ้งอัตโนมัติ
  final DateTime expiresAt;

  /// จำนวนครั้ง/จำนวนโหนดที่ช่วยแบกซองจดหมายนี้มา
  final int hopCarryCount;

  /// ขีดจำกัดสูงสุดของการส่งต่อระหว่างคนเดินสาร (Max Hops)
  final int maxHops;

  /// สถานะของซองจดหมาย: 'CARRIED' (กำลังช่วยแบก), 'DELIVERED' (ส่งถึงแล้ว), 'EXPIRED' (หมดอายุ)
  final String status;

  MuleEnvelope({
    String? envelopeId,
    required this.senderNodeId,
    required this.senderCallsign,
    required this.recipientNodeId,
    required this.encryptedPayload,
    required this.payloadIv,
    required this.payloadAuthTag,
    required this.senderSignature,
    this.isUrgentSOS = false,
    DateTime? createdAt,
    required this.expiresAt,
    this.hopCarryCount = 0,
    this.maxHops = 3,
    this.status = 'CARRIED',
  })  : envelopeId = envelopeId ?? _generateUuidV4(),
        createdAt = createdAt ?? DateTime.now();

  /// 🆔 สุ่มสร้าง UUID v4 สำหรับประจำซองจดหมาย
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10
    final hexChars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'env_${hexChars.substring(0, 16)}';
  }

  /// ⏳ ตรวจสอบว่าซองจดหมายหมดอายุแล้วหรือไม่
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 🔄 ตรวจสอบว่าซองจดหมายนี้สามารถส่งต่อให้คนเดินสารคนอื่นช่วยแบกต่อได้หรือไม่
  bool get canRelay => !isExpired && hopCarryCount < maxHops;

  /// ➕ เพิ่มจำนวนรอบการแบกต่อขึ้น 1 ทอด
  MuleEnvelope incrementHop() => copyWith(hopCarryCount: hopCarryCount + 1);

  /// 📊 คำนวณขนาดโดยประมาณของซองจดหมายในหน่วยไบต์ (Bytes) สำหรับคุม Quota
  int get estimatedSizeBytes {
    return envelopeId.length +
        senderNodeId.length +
        senderCallsign.length +
        recipientNodeId.length +
        encryptedPayload.length +
        payloadIv.length +
        payloadAuthTag.length +
        senderSignature.length +
        128; // ค่าเผื่อ Header & Overhead
  }

  /// 💾 แปลงเป็น Map สำหรับบันทึกลง SQLite
  Map<String, dynamic> toMap() {
    return {
      'envelopeId': envelopeId,
      'senderNodeId': senderNodeId,
      'senderCallsign': senderCallsign,
      'recipientNodeId': recipientNodeId,
      'encryptedPayload': encryptedPayload,
      'payloadIv': payloadIv,
      'payloadAuthTag': payloadAuthTag,
      'senderSignature': senderSignature,
      'isUrgentSOS': isUrgentSOS ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'hopCarryCount': hopCarryCount,
      'maxHops': maxHops,
      'status': status,
    };
  }

  /// 📥 สร้างออบเจกต์จากข้อมูล SQLite Row
  factory MuleEnvelope.fromMap(Map<String, dynamic> map) {
    return MuleEnvelope(
      envelopeId: map['envelopeId'] as String,
      senderNodeId: map['senderNodeId'] as String,
      senderCallsign: map['senderCallsign'] as String,
      recipientNodeId: map['recipientNodeId'] as String,
      encryptedPayload: map['encryptedPayload'] as String,
      payloadIv: map['payloadIv'] as String,
      payloadAuthTag: map['payloadAuthTag'] as String,
      senderSignature: map['senderSignature'] as String,
      isUrgentSOS: (map['isUrgentSOS'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      hopCarryCount: map['hopCarryCount'] as int? ?? 0,
      maxHops: map['maxHops'] as int? ?? 3,
      status: map['status'] as String? ?? 'CARRIED',
    );
  }

  /// 🌐 แปลงเป็น JSON Map สำหรับส่งต่อผ่านเครือข่าย BLE / Wi-Fi Mesh
  Map<String, dynamic> toJson() {
    return {
      'envelopeId': envelopeId,
      'senderNodeId': senderNodeId,
      'senderCallsign': senderCallsign,
      'recipientNodeId': recipientNodeId,
      'encryptedPayload': encryptedPayload,
      'payloadIv': payloadIv,
      'payloadAuthTag': payloadAuthTag,
      'senderSignature': senderSignature,
      'isUrgentSOS': isUrgentSOS,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'hopCarryCount': hopCarryCount,
      'maxHops': maxHops,
      'status': status,
    };
  }

  /// 🌐 สร้างออบเจกต์จาก JSON Map ที่ได้รับจากเครือข่าย
  factory MuleEnvelope.fromJson(Map<String, dynamic> json) {
    return MuleEnvelope(
      envelopeId: json['envelopeId'] as String,
      senderNodeId: json['senderNodeId'] as String,
      senderCallsign: json['senderCallsign'] as String,
      recipientNodeId: json['recipientNodeId'] as String,
      encryptedPayload: json['encryptedPayload'] as String,
      payloadIv: json['payloadIv'] as String,
      payloadAuthTag: json['payloadAuthTag'] as String,
      senderSignature: json['senderSignature'] as String,
      isUrgentSOS: json['isUrgentSOS'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      hopCarryCount: json['hopCarryCount'] as int? ?? 0,
      maxHops: json['maxHops'] as int? ?? 3,
      status: json['status'] as String? ?? 'CARRIED',
    );
  }

  /// 🔄 คัดลอกพร้อมอัปเดตฟิลด์ (Immutable Copy)
  MuleEnvelope copyWith({
    String? envelopeId,
    String? senderNodeId,
    String? senderCallsign,
    String? recipientNodeId,
    String? encryptedPayload,
    String? payloadIv,
    String? payloadAuthTag,
    String? senderSignature,
    bool? isUrgentSOS,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? hopCarryCount,
    int? maxHops,
    String? status,
  }) {
    return MuleEnvelope(
      envelopeId: envelopeId ?? this.envelopeId,
      senderNodeId: senderNodeId ?? this.senderNodeId,
      senderCallsign: senderCallsign ?? this.senderCallsign,
      recipientNodeId: recipientNodeId ?? this.recipientNodeId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      payloadIv: payloadIv ?? this.payloadIv,
      payloadAuthTag: payloadAuthTag ?? this.payloadAuthTag,
      senderSignature: senderSignature ?? this.senderSignature,
      isUrgentSOS: isUrgentSOS ?? this.isUrgentSOS,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hopCarryCount: hopCarryCount ?? this.hopCarryCount,
      maxHops: maxHops ?? this.maxHops,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'MuleEnvelope(id: $envelopeId, from: $senderCallsign, to: $recipientNodeId, urgent: $isUrgentSOS, hop: $hopCarryCount/$maxHops, status: $status)';
  }
}
