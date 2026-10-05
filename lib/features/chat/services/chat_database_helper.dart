import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'nearby_service.dart';
import '../models/mesh_notice.dart';
import '../models/mule_envelope.dart';

// ============================================================================
// 📦 BANTAWAN SQLite Chat Database Helper: ChatDatabaseHelper (Layer 4)
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// ├─────────────────────────────────────────────────────────┤
// │                   E2EE Security Layer                   │
// ├─────────────────────────────────────────────────────────┤
// │                BANTAWAN Mesh Routing Engine             │
// ├─────────────────────────────────────────────────────────┤
// │   SQLite Local Store (ChatDatabaseHelper: Persistence)   │
// └─────────────────────────────────────────────────────────┘
// 
// ตัวจัดการฐานข้อมูล SQLite ท้องถิ่นสำหรับจัดเก็บข้อความแชทถาวร (Persistent Offline Storage)
// รองรับการแยกห้องแชทด้วย Node ID ถาวร, การอัปเดตสถานะ ACK (SENDING/DELIVERED/READ)
// และระบบ Auto-Purge ป้องกันขนาดฐานข้อมูลบวมเกินขนาดที่กำหนด
// ============================================================================

class ChatDatabaseHelper {
  /// Singleton Instance ให้เรียกใช้งานออบเจกต์ตัวเดียวตรงกันทั่วทั้งแอปพลิเคชัน
  static final ChatDatabaseHelper instance = ChatDatabaseHelper._internal();
  static Database? _database;

  ChatDatabaseHelper._internal();

  /// ชื่อไฟล์ฐานข้อมูล SQLite และเวอร์ชัน Schema (V6: เพิ่มระบบคนเดินสาร Data Mule)
  static const String _dbName = 'bantawan_chat.db';
  static const int _dbVersion = 6;

  /// ชื่อตารางจัดเก็บข้อความ
  static const String tableMessages = 'messages';

  /// ชื่อตารางฝากข้อความรอส่ง (Offline Store-and-Forward)
  static const String tablePending = 'pending_messages';

  /// 🛡️ ชื่อตารางบันทึกประวัติ Packet ID เพื่อป้องกัน Replay Attack ข้ามการเปิด-ปิดแอป
  static const String tableProcessedPackets = 'processed_packets';

  /// 📌 ชื่อตารางกระดานประกาศฉุกเฉินออฟไลน์ (Offline Bulletin Board)
  static const String tableNotices = 'mesh_notices';

  /// 🎒 ชื่อตารางซองจดหมายคนเดินสาร (Data Mule Envelopes Store-Carry-and-Forward)
  static const String tableMuleEnvelopes = 'mule_envelopes';

  // --- ชื่อคอลัมน์ในตาราง SQLite ---
  static const String colId = 'id';
  static const String colSenderId = 'senderId';
  static const String colSenderName = 'senderName';
  static const String colRecipientId = 'recipientId';
  static const String colRecipientName = 'recipientName';
  static const String colContent = 'content';
  static const String colTimestamp = 'timestamp';
  static const String colLatitude = 'latitude';
  static const String colLongitude = 'longitude';
  static const String colIsLocation = 'isLocation';
  static const String colIsSOS = 'isSOS';
  static const String colIsEncrypted = 'isEncrypted';
  static const String colTtl = 'ttl';
  static const String colIsRelayed = 'isRelayed';
  static const String colStatus = 'status';
  static const String colConversationId = 'conversationId';
  static const String colMediaPath = 'mediaPath';
  static const String colMediaType = 'mediaType';
  static const String colDurationSeconds = 'durationSeconds';

  /// 🗄️ ดึงอินสแตนซ์ฐานข้อมูล SQLite (หากยังไม่ได้เปิด จะทำการ Init ฐานข้อมูลก่อน)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 🚀 เริ่มต้นเปิดไฟล์ฐานข้อมูล SQLite
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 🛠️ สร้างโครงสร้างตารางข้อความและ Index สำหรับค้นหาเมื่อแอปถูกติดตั้งครั้งแรก
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMessages (
        $colId TEXT PRIMARY KEY,
        $colSenderId TEXT NOT NULL,
        $colSenderName TEXT NOT NULL,
        $colRecipientId TEXT,
        $colRecipientName TEXT,
        $colContent TEXT NOT NULL,
        $colTimestamp TEXT NOT NULL,
        $colLatitude REAL,
        $colLongitude REAL,
        $colIsLocation INTEGER NOT NULL DEFAULT 0,
        $colIsSOS INTEGER NOT NULL DEFAULT 0,
        $colIsEncrypted INTEGER NOT NULL DEFAULT 0,
        $colTtl INTEGER NOT NULL DEFAULT 3,
        $colIsRelayed INTEGER NOT NULL DEFAULT 0,
        $colStatus TEXT NOT NULL DEFAULT 'SENDING',
        $colConversationId TEXT NOT NULL,
        $colMediaPath TEXT,
        $colMediaType TEXT,
        $colDurationSeconds INTEGER
      )
    ''');

    // Index สำหรับค้นหาตามห้องและเรียงเวลาเพื่อความรวดเร็วในการแสดงผล
    await db.execute('''
      CREATE INDEX idx_conversation_timestamp 
      ON $tableMessages ($colConversationId, $colTimestamp DESC)
    ''');

    // Index สำหรับค้นหาสถานะข้อความ (เช่น หาข้อความที่ยังไม่ READ หรือ DELIVERED)
    await db.execute('''
      CREATE INDEX idx_message_status 
      ON $tableMessages ($colStatus)
    ''');

    // 📬 ตาราง Pending Messages สำหรับระบบฝากข้อความออฟไลน์
    await db.execute('''
      CREATE TABLE $tablePending (
        id TEXT PRIMARY KEY,
        recipientNodeId TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expireAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_pending_recipient
      ON $tablePending (recipientNodeId)
    ''');

    // 🛡️ ตาราง Processed Packets ป้องกัน Replay Attack ข้ามเซสชัน
    await db.execute('''
      CREATE TABLE $tableProcessedPackets (
        id TEXT PRIMARY KEY,
        receivedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_processed_packets_received
      ON $tableProcessedPackets (receivedAt)
    ''');

    // 📌 ตาราง Mesh Notices สำหรับกระดานประกาศฉุกเฉินออฟไลน์
    await db.execute('''
      CREATE TABLE $tableNotices (
        id TEXT PRIMARY KEY,
        authorId TEXT NOT NULL,
        authorName TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        isUrgent INTEGER NOT NULL DEFAULT 0,
        latitude REAL,
        longitude REAL,
        hopCount INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notices_expires
      ON $tableNotices (expiresAt)
    ''');

    // 🎒 ตาราง Mule Envelopes สำหรับระบบคนเดินสาร (Store-Carry-and-Forward Mesh Carrier)
    await db.execute('''
      CREATE TABLE $tableMuleEnvelopes (
        envelopeId TEXT PRIMARY KEY,
        senderNodeId TEXT NOT NULL,
        senderCallsign TEXT NOT NULL,
        recipientNodeId TEXT NOT NULL,
        encryptedPayload TEXT NOT NULL,
        payloadIv TEXT NOT NULL,
        payloadAuthTag TEXT NOT NULL,
        senderSignature TEXT NOT NULL,
        isUrgentSOS INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        hopCarryCount INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'CARRIED'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_mule_recipient
      ON $tableMuleEnvelopes (recipientNodeId)
    ''');

    await db.execute('''
      CREATE INDEX idx_mule_expires
      ON $tableMuleEnvelopes (expiresAt)
    ''');
  }

  /// 🔄 ปรับปรุง Schema ของตารางสำหรับเวอร์ชันที่อัปเดตใหม่ (Database Migration)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE $tableMessages ADD COLUMN $colMediaPath TEXT;');
        await db.execute('ALTER TABLE $tableMessages ADD COLUMN $colMediaType TEXT;');
        await db.execute('ALTER TABLE $tableMessages ADD COLUMN $colDurationSeconds INTEGER;');
      } catch (e) {
        debugPrint('[SQLITE MIGRATION] Column addition error: $e');
      }
    }
    if (oldVersion < 3) {
      // 📬 เพิ่มตาราง Pending Messages สำหรับระบบฝากข้อความออฟไลน์
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tablePending (
          id TEXT PRIMARY KEY,
          recipientNodeId TEXT NOT NULL,
          payload TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          expireAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_pending_recipient
        ON $tablePending (recipientNodeId)
      ''');
    }
    if (oldVersion < 4) {
      // 🛡️ เพิ่มตาราง Processed Packets ป้องกัน Replay Attack ข้ามเซสชัน
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableProcessedPackets (
          id TEXT PRIMARY KEY,
          receivedAt INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_processed_packets_received
        ON $tableProcessedPackets (receivedAt)
      ''');
    }
    if (oldVersion < 5) {
      // 📌 เพิ่มตาราง Mesh Notices สำหรับกระดานประกาศฉุกเฉินออฟไลน์
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableNotices (
          id TEXT PRIMARY KEY,
          authorId TEXT NOT NULL,
          authorName TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          expiresAt TEXT NOT NULL,
          isUrgent INTEGER NOT NULL DEFAULT 0,
          latitude REAL,
          longitude REAL,
          hopCount INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_notices_expires
        ON $tableNotices (expiresAt)
      ''');
    }
    if (oldVersion < 6) {
      // 🎒 เพิ่มตาราง Mule Envelopes สำหรับระบบคนเดินสาร (Store-Carry-and-Forward Mesh Carrier)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableMuleEnvelopes (
          envelopeId TEXT PRIMARY KEY,
          senderNodeId TEXT NOT NULL,
          senderCallsign TEXT NOT NULL,
          recipientNodeId TEXT NOT NULL,
          encryptedPayload TEXT NOT NULL,
          payloadIv TEXT NOT NULL,
          payloadAuthTag TEXT NOT NULL,
          senderSignature TEXT NOT NULL,
          isUrgentSOS INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          expiresAt TEXT NOT NULL,
          hopCarryCount INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'CARRIED'
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_mule_recipient
        ON $tableMuleEnvelopes (recipientNodeId)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_mule_expires
        ON $tableMuleEnvelopes (expiresAt)
      ''');
    }
  }

  /// 🔑 คำนวณ Conversation ID สำหรับจัดกลุ่มห้องแชทแยกอิสระ
  /// - แชทสาธารณะ: `'PUBLIC'`
  /// - แชทส่วนตัว: `'PEER_[peerNodeId]'` (ใช้ Node ID ถาวร ป้องกันแชทแตกห้องเมื่อผู้ใช้เปลี่ยนชื่อเล่น)
  static String getConversationId(
    NearbyMessage msg, {
    String? myNodeId,
    String? myDeviceName,
  }) {
    final bool isPublic =
        msg.recipientId == null ||
        msg.recipientId == 'ALL' ||
        msg.recipientId!.isEmpty;

    if (isPublic) {
      return 'PUBLIC';
    }

    final myId = myNodeId ?? myDeviceName;

    // แชทส่วนตัว: ถ้าเราเป็นคนส่ง ให้ผูกกับ recipientId (ที่เป็น nodeId ถาวร)
    // ถ้าเราเป็นคนรับ ให้ผูกกับ senderId (ที่เป็น nodeId ถาวร)
    if (myId != null && msg.senderId == myId) {
      final peer = msg.recipientId ?? msg.recipientName ?? 'Unknown';
      return 'PEER_$peer';
    } else {
      final peer = msg.senderId.isNotEmpty ? msg.senderId : msg.senderName;
      return 'PEER_$peer';
    }
  }

  /// 💾 บันทึกหรืออัปเดตข้อความใหม่ลงในฐานข้อมูล SQLite
  Future<void> insertMessage(
    NearbyMessage msg, {
    String? conversationId,
    String? myNodeId,
    String? myDeviceName,
  }) async {
    try {
      final db = await database;
      final convId = conversationId ??
          getConversationId(msg, myNodeId: myNodeId, myDeviceName: myDeviceName);

      final row = {
        colId: msg.id,
        colSenderId: msg.senderId,
        colSenderName: msg.senderName,
        colRecipientId: msg.recipientId,
        colRecipientName: msg.recipientName,
        colContent: msg.content,
        colTimestamp: msg.timestamp.toIso8601String(),
        colLatitude: msg.latitude,
        colLongitude: msg.longitude,
        colIsLocation: msg.isLocation ? 1 : 0,
        colIsSOS: msg.isSOS ? 1 : 0,
        colIsEncrypted: msg.isEncrypted ? 1 : 0,
        colTtl: msg.ttl,
        colIsRelayed: msg.isRelayed ? 1 : 0,
        colStatus: msg.status,
        colConversationId: convId,
        colMediaPath: msg.mediaPath,
        colMediaType: msg.mediaType,
        colDurationSeconds: msg.durationSeconds,
      };

      await db.insert(
        tableMessages,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // รัน auto-purge เคลียร์ความจุฐานข้อมูลเบื้องหลัง
      if (convId == 'PUBLIC') {
        autoPurgeOldPublicMessages();
      } else {
        autoPurgeOldPrivateMessages(convId);
      }
    } catch (e) {
      debugPrint('[SQLITE ERROR] insertMessage failed: $e');
    }
  }

  /// 🔄 อัปเดตสถานะการส่งข้อความ (เช่น เปลี่ยนเป็น 'DELIVERED' หรือ 'READ')
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      final db = await database;
      await db.update(
        tableMessages,
        {colStatus: status},
        where: '$colId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('[SQLITE ERROR] updateMessageStatus failed: $e');
    }
  }

  /// 📖 โหลดข้อความทั้งหมดเรียงลำดับเวลาใหม่สุดขึ้นก่อน (สำหรับ NearbyService.messages)
  Future<List<NearbyMessage>> getAllMessages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        orderBy: '$colTimestamp DESC',
      );

      return maps.map(_fromMap).toList();
    } catch (e) {
      debugPrint('[SQLITE ERROR] getAllMessages failed: $e');
      return [];
    }
  }

  /// 📖 โหลดข้อความเฉพาะห้องแชทที่ระบุ (จำกัดจำนวนล่าสุดเพื่อประหยัด RAM)
  Future<List<NearbyMessage>> getMessagesByConversation(
    String conversationId, {
    int limit = 100,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        where: '$colConversationId = ?',
        whereArgs: [conversationId],
        orderBy: '$colTimestamp DESC',
        limit: limit,
      );

      return maps.map(_fromMap).toList();
    } catch (e) {
      debugPrint('[SQLITE ERROR] getMessagesByConversation failed: $e');
      return [];
    }
  }

  /// 📖 โหลดเฉพาะข้อความในห้องแชทสาธารณะ
  Future<List<NearbyMessage>> getPublicMessages({int limit = 100}) async {
    return getMessagesByConversation('PUBLIC', limit: limit);
  }

  /// 🗑️ ลบประวัติข้อความในห้องที่เลือก (เช่น ล้างแชทส่วนตัวกับ peerId หรือล้างแชทสาธารณะ)
  Future<int> clearConversation(String conversationId) async {
    try {
      final db = await database;
      return await db.delete(
        tableMessages,
        where: '$colConversationId = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      debugPrint('[SQLITE ERROR] clearConversation failed: $e');
      return 0;
    }
  }

  /// 🧹 ล้างข้อความสาธารณะที่เก่าเกิน maxAge (Default 24 ชั่วโมง) อัตโนมัติ ป้องกันข้อมูลค้างสะสม
  Future<int> purgeExpiredPublicMessages({Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final db = await database;
      final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
      final count = await db.delete(
        tableMessages,
        where: '$colConversationId = ? AND $colTimestamp < ?',
        whereArgs: ['PUBLIC', cutoff],
      );
      if (count > 0) {
        debugPrint('[ChatDatabase] 🧹 Purged $count expired public messages (> ${maxAge.inHours}h).');
      }
      return count;
    } catch (e) {
      debugPrint('[SQLITE ERROR] purgeExpiredPublicMessages failed: $e');
      return 0;
    }
  }

  /// 🗑️ ล้างประวัติข้อความทั้งหมดในฐานข้อมูล SQLite
  Future<int> clearAllMessages() async {
    try {
      final db = await database;
      return await db.delete(tableMessages);
    } catch (e) {
      debugPrint('[SQLITE ERROR] clearAllMessages failed: $e');
      return 0;
    }
  }

  /// 🛡️ Auto-Purge: ควบคุมขนาดฐานข้อมูลห้องแชทสาธารณะไม่ให้เกิน keepCount (ยกเว้นข้อความ SOS)
  Future<void> autoPurgeOldPublicMessages({int keepCount = 300}) async {
    try {
      final db = await database;
      await db.execute('''
        DELETE FROM $tableMessages
        WHERE $colConversationId = 'PUBLIC'
          AND $colIsSOS = 0
          AND $colId NOT IN (
            SELECT $colId FROM $tableMessages
            WHERE $colConversationId = 'PUBLIC'
            ORDER BY $colTimestamp DESC
            LIMIT $keepCount
          )
      ''');
    } catch (e) {
      debugPrint('[SQLITE ERROR] autoPurgeOldPublicMessages failed: $e');
    }
  }

  /// 🛡️ Auto-Purge: ควบคุมขนาดข้อความแชทส่วนตัวต่อห้อง ไม่ให้เกิน keepCount
  Future<void> autoPurgeOldPrivateMessages(String conversationId, {int keepCount = 500}) async {
    try {
      final db = await database;
      await db.execute('''
        DELETE FROM $tableMessages
        WHERE $colConversationId = ?
          AND $colIsSOS = 0
          AND $colId NOT IN (
            SELECT $colId FROM $tableMessages
            WHERE $colConversationId = ?
            ORDER BY $colTimestamp DESC
            LIMIT $keepCount
          )
      ''', [conversationId, conversationId]);
    } catch (e) {
      debugPrint('[SQLITE ERROR] autoPurgeOldPrivateMessages failed: $e');
    }
  }

  /// 🔄 แปลง Map Record จาก SQLite กลับเป็นออบเจกต์ NearbyMessage
  NearbyMessage _fromMap(Map<String, dynamic> map) {
    return NearbyMessage(
      id: map[colId] as String,
      senderId: map[colSenderId] as String,
      senderName: map[colSenderName] as String,
      recipientId: map[colRecipientId] as String?,
      recipientName: map[colRecipientName] as String?,
      content: map[colContent] as String,
      timestamp: DateTime.tryParse(map[colTimestamp] as String? ?? '') ?? DateTime.now(),
      latitude: (map[colLatitude] as num?)?.toDouble(),
      longitude: (map[colLongitude] as num?)?.toDouble(),
      isLocation: (map[colIsLocation] as int? ?? 0) == 1,
      isSOS: (map[colIsSOS] as int? ?? 0) == 1,
      isEncrypted: (map[colIsEncrypted] as int? ?? 0) == 1,
      ttl: map[colTtl] as int? ?? 3,
      isRelayed: (map[colIsRelayed] as int? ?? 0) == 1,
      status: map[colStatus] as String? ?? 'SENDING',
      mediaPath: map[colMediaPath] as String?,
      mediaType: map[colMediaType] as String?,
      durationSeconds: map[colDurationSeconds] as int?,
    );
  }

  // ===========================================================================
  // 📬 PENDING MESSAGES — Offline Store-and-Forward
  // ===========================================================================

  /// ⏳ อายุสูงสุดของข้อความที่ฝากไว้ (72 ชั่วโมง หลังจากนั้นถือว่าหมดอายุ)
  static const Duration pendingTtl = Duration(hours: 72);
  static const int maxPendingPerPeer = 30;
  static const int maxTotalPending = 200;

  /// 💾 บันทึกข้อความที่ยังส่งไม่ได้ลงตาราง pending_messages
  /// [recipientNodeId] = Node ID ของผู้รับ (ใช้จับคู่เมื่อ Peer กลับมา Online)
  /// [payload] = JSON String ของ NearbyMessage ที่เข้ารหัสแล้ว
  Future<void> insertPendingMessage({
    required String id,
    required String recipientNodeId,
    required String payload,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();

      // 1. ล้างข้อความที่หมดอายุก่อน
      await purgeExpiredPending();

      // 2. ตรวจสอบโควตารวมทั้งหมด (Global Cap: 200 ข้อความ) - ลบข้อความที่เก่าสุดออกถ้าเกิน (FIFO)
      final totalCountResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tablePending');
      final int totalCount = (totalCountResult.first['cnt'] as int? ?? 0);
      if (totalCount >= maxTotalPending) {
        final int toEvict = totalCount - maxTotalPending + 1;
        await db.execute('''
          DELETE FROM $tablePending 
          WHERE id IN (
            SELECT id FROM $tablePending 
            ORDER BY createdAt ASC 
            LIMIT $toEvict
          )
        ''');
        debugPrint('[PendingQ] ⚠️ Global cap reached. Evicted $toEvict oldest pending message(s).');
      }

      // 3. ตรวจสอบโควตารายบุคคล (Per-Peer Cap: 30 ข้อความ) - ลบข้อความที่เก่าสุดของ Peer นี้ถ้าเกิน (FIFO)
      final peerCountResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $tablePending WHERE recipientNodeId = ?',
        [recipientNodeId],
      );
      final int peerCount = (peerCountResult.first['cnt'] as int? ?? 0);
      if (peerCount >= maxPendingPerPeer) {
        final int toEvict = peerCount - maxPendingPerPeer + 1;
        await db.execute('''
          DELETE FROM $tablePending 
          WHERE id IN (
            SELECT id FROM $tablePending 
            WHERE recipientNodeId = ? 
            ORDER BY createdAt ASC 
            LIMIT $toEvict
          )
        ''', [recipientNodeId]);
        debugPrint('[PendingQ] ⚠️ Peer cap reached for $recipientNodeId. Evicted $toEvict oldest pending message(s).');
      }

      // 4. เพิ่มข้อความใหม่ลงในคิว
      await db.insert(
        tablePending,
        {
          'id': id,
          'recipientNodeId': recipientNodeId,
          'payload': payload,
          'createdAt': now.toIso8601String(),
          'expireAt': now.add(pendingTtl).toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[PendingQ] ✉️ Queued msg $id for $recipientNodeId (expires in 72h)');
    } catch (e) {
      debugPrint('[PendingQ] insertPendingMessage error: $e');
    }
  }

  /// 📬 ดึง payload ทั้งหมดที่รอส่งให้ recipientNodeId
  Future<List<Map<String, dynamic>>> getPendingFor(String recipientNodeId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      return await db.query(
        tablePending,
        where: 'recipientNodeId = ? AND expireAt > ?',
        whereArgs: [recipientNodeId, now],
        orderBy: 'createdAt ASC',
      );
    } catch (e) {
      debugPrint('[PendingQ] getPendingFor error: $e');
      return [];
    }
  }

  /// 🗑️ ลบข้อความออกจากคิวหลังส่งสำเร็จแล้ว
  Future<void> deletePendingMessage(String id) async {
    try {
      final db = await database;
      await db.delete(tablePending, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[PendingQ] deletePendingMessage error: $e');
    }
  }

  /// 🗑️ ลบข้อความที่รอส่งทั้งหมดของ recipientNodeId เมื่อลบผู้ติดต่อ
  Future<void> deletePendingMessagesFor(String recipientNodeId) async {
    try {
      final db = await database;
      await db.delete(tablePending, where: 'recipientNodeId = ?', whereArgs: [recipientNodeId]);
    } catch (e) {
      debugPrint('[PendingQ] deletePendingMessagesFor error: $e');
    }
  }

  /// 🧹 ลบข้อความหมดอายุทั้งหมดออกจากคิว (เรียกตอนเริ่มแอป)
  Future<void> purgeExpiredPending() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final count = await db.delete(
        tablePending,
        where: 'expireAt <= ?',
        whereArgs: [now],
      );
      if (count > 0) {
        debugPrint('[PendingQ] 🧹 Purged $count expired pending messages.');
      }
    } catch (e) {
      debugPrint('[PendingQ] purgeExpiredPending error: $e');
    }
  }

  /// 📊 นับจำนวนข้อความที่รอส่งในคิว (ใช้แสดง badge บน UI)
  Future<int> countPendingFor(String recipientNodeId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $tablePending WHERE recipientNodeId = ? AND expireAt > ?',
        [recipientNodeId, now],
      );
      return (result.first['cnt'] as int? ?? 0);
    } catch (e) {
      debugPrint('[PendingQ] countPendingFor error: $e');
      return 0;
    }
  }

  // ============================================================================
  // 🛡️ Section: Persistent Anti-Replay Guard
  // ============================================================================

  /// 🔍 ตรวจสอบว่า Packet ID นี้เคยได้รับและประมวลผลแล้วหรือยัง (Persistent Anti-Replay)
  Future<bool> isPacketProcessed(String packetId) async {
    try {
      final db = await database;
      final result = await db.query(
        tableProcessedPackets,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [packetId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[SQLITE ERROR] isPacketProcessed failed: $e');
      return false;
    }
  }

  /// 📝 บันทึก Packet ID ที่ประมวลผลแล้วลงใน SQLite เพื่อป้องกัน Replay Attack หลังเปิด-ปิดแอปใหม่
  Future<void> markPacketProcessed(String packetId) async {
    try {
      final db = await database;
      await db.insert(
        tableProcessedPackets,
        {
          'id': packetId,
          'receivedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('[SQLITE ERROR] markPacketProcessed failed: $e');
    }
  }

  /// 🧹 ล้างประวัติ Packet ID ที่อายุเกินกำหนด (เช่น เกิน 72 ชั่วโมง) เพื่อประหยัดพื้นที่
  Future<void> purgeExpiredProcessedPackets({Duration maxAge = const Duration(hours: 72)}) async {
    try {
      final db = await database;
      final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      final count = await db.delete(
        tableProcessedPackets,
        where: 'receivedAt < ?',
        whereArgs: [cutoff],
      );
      if (count > 0) {
        debugPrint('[Anti-Replay] 🧹 Purged $count expired packet IDs from database.');
      }
    } catch (e) {
      debugPrint('[SQLITE ERROR] purgeExpiredProcessedPackets failed: $e');
    }
  }

  // ============================================================================
  // 📌 Section: Offline Mesh Notices (Epidemic Bulletin Board)
  // ============================================================================

  /// 📝 บันทึกประกาศใหม่ลง SQLite
  Future<void> insertNotice(MeshNotice notice) async {
    try {
      final db = await database;
      await db.insert(
        tableNotices,
        notice.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[NoticeDB] 📌 Saved notice: ${notice.id} (${notice.content})');
    } catch (e) {
      debugPrint('[NoticeDB Error] insertNotice failed: $e');
    }
  }

  /// 📖 ดึงประกาศทั้งหมดที่ยังไม่หมดอายุ (เรียง ด่วนขึ้นก่อน -> เวลาสร้างล่าสุด)
  Future<List<MeshNotice>> getActiveNotices() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final maps = await db.query(
        tableNotices,
        where: 'expiresAt > ?',
        whereArgs: [now],
        orderBy: 'isUrgent DESC, createdAt DESC',
      );
      return maps.map(MeshNotice.fromMap).toList();
    } catch (e) {
      debugPrint('[NoticeDB Error] getActiveNotices failed: $e');
      return [];
    }
  }

  /// 🧹 ลบประกาศที่หมดอายุแล้วออกจากฐานข้อมูล
  Future<int> purgeExpiredNotices() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final count = await db.delete(
        tableNotices,
        where: 'expiresAt <= ?',
        whereArgs: [now],
      );
      if (count > 0) {
        debugPrint('[NoticeDB] 🧹 Purged $count expired notices.');
      }
      return count;
    } catch (e) {
      debugPrint('[NoticeDB Error] purgeExpiredNotices failed: $e');
      return 0;
    }
  }

  /// 🗑️ ลบประกาศเฉพาะรายการ
  Future<void> deleteNotice(String noticeId) async {
    try {
      final db = await database;
      await db.delete(
        tableNotices,
        where: 'id = ?',
        whereArgs: [noticeId],
      );
      debugPrint('[NoticeDB] 🗑️ Deleted notice $noticeId');
    } catch (e) {
      debugPrint('[NoticeDB Error] deleteNotice failed: $e');
    }
  }

  // ==========================================================================
  // 🎒 ระบบคนเดินสาร (Data Mule: Store-Carry-and-Forward Mesh Carrier)
  // ==========================================================================

  /// 📥 บันทึกซองจดหมายเข้ารหัสที่รับฝากมา (พร้อมระบบคุมโควต้า Quota Guard)
  Future<bool> insertMuleEnvelope(
    MuleEnvelope envelope, {
    int maxStorageEnvelopes = 50,
  }) async {
    try {
      if (envelope.isExpired) {
        debugPrint('[MuleDB] ⚠️ ซองจดหมายหมดอายุแล้ว ไม่รับฝาก: ${envelope.envelopeId}');
        return false;
      }

      final db = await database;

      // ตรวจสอบว่ามีซองนี้ในเครื่องอยู่แล้วหรือไม่
      final existing = await db.query(
        tableMuleEnvelopes,
        where: 'envelopeId = ?',
        whereArgs: [envelope.envelopeId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        debugPrint('[MuleDB] ℹ️ มีซองจดหมาย ${envelope.envelopeId} อยู่แล้ว');
        return false;
      }

      // ตรวจสอบจำนวนซองจดหมายที่มีอยู่
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableMuleEnvelopes WHERE status = ?',
        ['CARRIED'],
      );
      int currentCount = Sqflite.firstIntValue(countResult) ?? 0;

      // ถ้าความจุเต็ม ให้ล้างซองที่หมดอายุออกก่อน
      if (currentCount >= maxStorageEnvelopes) {
        await purgeExpiredMuleEnvelopes();
        final countAfterPurge = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableMuleEnvelopes WHERE status = ?',
          ['CARRIED'],
        );
        currentCount = Sqflite.firstIntValue(countAfterPurge) ?? 0;
      }

      // หากยังเต็มอยู่ และซองใหม่ไม่ใช่ SOS ฉุกเฉิน ให้ปฏิเสธการรับฝากเพื่อป้องกันเมมเต็ม
      if (currentCount >= maxStorageEnvelopes && !envelope.isUrgentSOS) {
        debugPrint('[MuleDB] ❌ Quota เต็ม ($currentCount/$maxStorageEnvelopes) ปฏิเสธซองธรรมดา');
        return false;
      }

      await db.insert(
        tableMuleEnvelopes,
        envelope.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[MuleDB] 🎒 รับฝากซองจดหมายสำเร็จ: ${envelope.envelopeId} -> ${envelope.recipientNodeId} (ฉุกเฉิน: ${envelope.isUrgentSOS})');
      return true;
    } catch (e) {
      debugPrint('[MuleDB Error] insertMuleEnvelope failed: $e');
      return false;
    }
  }

  /// 🔍 ค้นหาซองจดหมายที่ต้องส่งมอบให้โหนดผู้รับที่เพิ่งค้นพบ
  /// รองรับทั้งรหัสโหนดเฉพาะบุคคล หรือข้อความขอความช่วยเหลือฉุกเฉิน (isUrgentSOS)
  Future<List<MuleEnvelope>> getEnvelopesForRecipient(String recipientNodeId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final maps = await db.query(
        tableMuleEnvelopes,
        where: 'status = ? AND expiresAt > ? AND (recipientNodeId = ? OR isUrgentSOS = 1 OR recipientNodeId = ? OR recipientNodeId = ?)',
        whereArgs: ['CARRIED', now, recipientNodeId, '@RESCUE_TEAM', '@PUBLIC_SOS'],
        orderBy: 'isUrgentSOS DESC, createdAt ASC',
      );

      return maps.map(MuleEnvelope.fromMap).toList();
    } catch (e) {
      debugPrint('[MuleDB Error] getEnvelopesForRecipient failed: $e');
      return [];
    }
  }

  /// 🔄 ค้นหาซองจดหมายที่สามารถส่งต่อให้คนเดินสารคนอื่น (Mule Relay) ช่วยแบกต่อได้
  /// ต้องยังไม่หมดอายุ และยังส่งต่อไม่เกินขีดจำกัด (hopCarryCount < maxHops)
  Future<List<MuleEnvelope>> getEnvelopesForRelay({
    required String peerNodeId,
    int maxHops = 3,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      // ไม่ส่งซองที่ส่งมาจาก peer นั้น หรือมีเป้าหมายคือ peer นั้น (เพราะ peer นั้นจะได้รับทาง Handover ปกติอยู่แล้ว)
      final maps = await db.query(
        tableMuleEnvelopes,
        where: 'status = ? AND expiresAt > ? AND hopCarryCount < ? AND senderNodeId != ? AND recipientNodeId != ?',
        whereArgs: ['CARRIED', now, maxHops, peerNodeId, peerNodeId],
        orderBy: 'isUrgentSOS DESC, createdAt ASC',
        limit: 20,
      );

      return maps.map(MuleEnvelope.fromMap).toList();
    } catch (e) {
      debugPrint('[MuleDB Error] getEnvelopesForRelay failed: $e');
      return [];
    }
  }

  /// 📋 ดึงรายการซองจดหมายที่กำลังช่วยแบกอยู่ทั้งหมดในเครื่อง
  Future<List<MuleEnvelope>> getAllCarriedEnvelopes() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final maps = await db.query(
        tableMuleEnvelopes,
        where: 'status = ? AND expiresAt > ?',
        whereArgs: ['CARRIED', now],
        orderBy: 'isUrgentSOS DESC, createdAt DESC',
      );

      return maps.map(MuleEnvelope.fromMap).toList();
    } catch (e) {
      debugPrint('[MuleDB Error] getAllCarriedEnvelopes failed: $e');
      return [];
    }
  }

  /// ✅ อัปเดตสถานะเป็นส่งมอบสำเร็จแล้ว (Delivered)
  Future<void> markMuleEnvelopeDelivered(String envelopeId) async {
    try {
      final db = await database;
      await db.update(
        tableMuleEnvelopes,
        {'status': 'DELIVERED'},
        where: 'envelopeId = ?',
        whereArgs: [envelopeId],
      );
      debugPrint('[MuleDB]  ทำเครื่องหมายส่งมอบสำเร็จ: $envelopeId');
    } catch (e) {
      debugPrint('[MuleDB Error] markMuleEnvelopeDelivered failed: $e');
    }
  }

  /// 🗑️ ลบซองจดหมายออกจากเครื่องทันทีเมื่อได้รับใบเสร็จการส่งมอบ (Delivery Receipt)
  Future<void> deleteMuleEnvelope(String envelopeId) async {
    try {
      final db = await database;
      await db.delete(
        tableMuleEnvelopes,
        where: 'envelopeId = ?',
        whereArgs: [envelopeId],
      );
      debugPrint('[MuleDB] 🗑️ ลบซองจดหมาย $envelopeId คืนพื้นที่ความจำแล้ว');
    } catch (e) {
      debugPrint('[MuleDB Error] deleteMuleEnvelope failed: $e');
    }
  }

  /// 🧹 ลบซองจดหมายที่หมดอายุ หรือที่ส่งมอบสำเร็จแล้วออกจากเครื่อง
  Future<int> purgeExpiredMuleEnvelopes() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final count = await db.delete(
        tableMuleEnvelopes,
        where: 'expiresAt <= ? OR status = ?',
        whereArgs: [now, 'DELIVERED'],
      );
      if (count > 0) {
        debugPrint('[MuleDB] 🧹 ล้างซองจดหมายหมดอายุ/ส่งแล้ว $count รายการ');
      }
      return count;
    } catch (e) {
      debugPrint('[MuleDB Error] purgeExpiredMuleEnvelopes failed: $e');
      return 0;
    }
  }

  /// 📊 คำนวณสถิติพื้นที่จัดเก็บของระบบคนเดินสาร
  Future<Map<String, int>> getMuleStorageStats() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final list = await db.query(
        tableMuleEnvelopes,
        where: 'status = ? AND expiresAt > ?',
        whereArgs: ['CARRIED', now],
      );

      int totalBytes = 0;
      int urgentCount = 0;

      for (var map in list) {
        final env = MuleEnvelope.fromMap(map);
        totalBytes += env.estimatedSizeBytes;
        if (env.isUrgentSOS) urgentCount++;
      }

      return {
        'count': list.length,
        'urgentCount': urgentCount,
        'totalSizeBytes': totalBytes,
      };
    } catch (e) {
      debugPrint('[MuleDB Error] getMuleStorageStats failed: $e');
      return {
        'count': 0,
        'urgentCount': 0,
        'totalSizeBytes': 0,
      };
    }
  }
}
