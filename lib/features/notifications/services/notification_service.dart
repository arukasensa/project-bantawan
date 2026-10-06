import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/app_notification.dart';

/// 🔔 ตัวจัดการระบบการแจ้งเตือนส่วนกลางของ BANTAWAN (NotificationService)
/// รองรับการทำงานแบบ Offline-First บันทึกลง SQLite
class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  Database? _db;
  List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// จำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// มีการแจ้งเตือนระดับ SOS ฉุกเฉินที่ยังไม่ได้อ่านหรือไม่ (ใช้สำหรับกระพริบไอคอนกระดิ่ง)
  bool get hasCriticalSos => _notifications.any(
        (n) => !n.isRead && n.category == NotificationCategory.sos,
      );

  /// เริ่มต้นระบบฐานข้อมูลการแจ้งเตือน
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'bantawan_notifications.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE notifications (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              category TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              isRead INTEGER NOT NULL DEFAULT 0,
              actionRoute TEXT,
              metadata TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_notif_time ON notifications (timestamp DESC)',
          );
        },
      );

      await loadNotifications();

      // หากเป็นการเปิดใช้งานครั้งแรกและไม่มีแจ้งเตือนเลย ให้ใส่การแจ้งเตือนเริ่มต้นที่เป็นประโยชน์
      if (_notifications.isEmpty) {
        await _seedInitialNotifications();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// โหลดการแจ้งเตือนทั้งหมดจาก SQLite
  Future<void> loadNotifications() async {
    if (_db == null) return;
    try {
      final maps = await _db!.query(
        'notifications',
        orderBy: 'timestamp DESC',
        limit: 50,
      );

      _notifications = maps.map((m) => AppNotification.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Load error: $e');
    }
  }

  /// เพิ่มการแจ้งเตือนใหม่
  Future<void> addNotification(AppNotification notif) async {
    if (_db == null) await init();

    try {
      await _db!.insert(
        'notifications',
        notif.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // แทรกไว้บนสุดของลิสต์ในเมมโมรี
      _notifications.removeWhere((n) => n.id == notif.id);
      _notifications.insert(0, notif);

      // จำกัดสูงสุด 50 รายการ
      if (_notifications.length > 50) {
        _notifications.removeLast();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Add error: $e');
    }
  }

  /// สร้างและส่งการแจ้งเตือน SOS ฉุกเฉินอย่างรวดเร็ว
  Future<void> notifySosAlert({
    required String senderName,
    required String distanceText,
    required String details,
    double? latitude,
    double? longitude,
  }) async {
    final notif = AppNotification(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 พบสัญญาณขอความช่วยเหลือ SOS',
      body: 'คุณ $senderName อยู่ห่างจากคุณ $distanceText: "$details"',
      category: NotificationCategory.sos,
      timestamp: DateTime.now(),
      actionRoute: 'map_sos',
      metadata: {
        'sender': senderName,
        'distance': distanceText,
        'lat': latitude,
        'lng': longitude,
      },
    );
    await addNotification(notif);
  }

  /// สร้างและส่งการแจ้งเตือนสถานะคนเดินสาร (Data Mule)
  Future<void> notifyMuleUpdate({
    required String title,
    required String message,
  }) async {
    final notif = AppNotification(
      id: 'mule_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: message,
      category: NotificationCategory.mule,
      timestamp: DateTime.now(),
      actionRoute: 'data_mule',
    );
    await addNotification(notif);
  }

  /// ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(String id) async {
    if (_db == null) return;
    try {
      await _db!.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] Mark read error: $e');
    }
  }

  /// ทำเครื่องหมายว่าอ่านแล้วทั้งหมด
  Future<void> markAllAsRead() async {
    if (_db == null) return;
    try {
      await _db!.update('notifications', {'isRead': 1});
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Mark all read error: $e');
    }
  }

  /// ลบการแจ้งเตือนทีละรายการ
  Future<void> deleteNotification(String id) async {
    if (_db == null) return;
    try {
      await _db!.delete('notifications', where: 'id = ?', whereArgs: [id]);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Delete error: $e');
    }
  }

  /// ลบการแจ้งเตือนทั้งหมด
  Future<void> clearAll() async {
    if (_db == null) return;
    try {
      await _db!.delete('notifications');
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Clear all error: $e');
    }
  }

  /// ข้อมูลตั้งต้นเพื่อสาธิตและแนะนำระบบในสถานการณ์จริง
  Future<void> _seedInitialNotifications() async {
    final now = DateTime.now();
    final seeds = [
      AppNotification(
        id: 'seed_sos_1',
        title: '🚨 ซ้อมสัญญาณเตือนภัย SOS ฉุกเฉิน',
        body: 'ระบบเครือข่ายกู้ภัยออฟไลน์พร้อมทำงาน หากพบผู้ประสบภัยใกล้เคียง สัญญาณจะแจ้งเตือนทันที',
        category: NotificationCategory.sos,
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        actionRoute: 'map_sos',
      ),
      AppNotification(
        id: 'seed_weather_1',
        title: '🌧️ เฝ้าระวังฝนตกสะสมและน้ำท่วมฉับพลัน',
        body: 'ศูนย์เตือนภัยรายงานกลุ่มฝนหนักในพื้นที่ภาคใต้ตอนล่าง แนะนำตรวจเช็คระดับน้ำใกล้บ้าน',
        category: NotificationCategory.weather,
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
        actionRoute: 'weather',
      ),
      AppNotification(
        id: 'seed_shelter_1',
        title: '⛺ จุดพักพิงและศูนย์อพยพพร้อมรองรับ',
        body: 'เปิดศูนย์อพยพชั่วคราว ณ โรงเรียนเทศบาล 1 มีสิ่งอำนวยความสะดวกและจุดปฐมพยาบาล',
        category: NotificationCategory.shelter,
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionRoute: 'map_shelter',
      ),
    ];

    for (final notif in seeds) {
      await addNotification(notif);
    }
  }
}
