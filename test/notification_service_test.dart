import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/features/notifications/models/app_notification.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final notif = AppNotification(
        id: 'test_notif_1',
        title: '🚨 ทดสอบ SOS',
        body: 'ต้องการความช่วยเหลือด่วน',
        category: NotificationCategory.sos,
        timestamp: now,
        isRead: false,
        actionRoute: 'map_sos',
        metadata: {'lat': 6.867, 'lng': 101.250},
      );

      final map = notif.toMap();
      expect(map['id'], 'test_notif_1');
      expect(map['category'], 'sos');
      expect(map['isRead'], 0);
      expect(map['actionRoute'], 'map_sos');

      final fromMap = AppNotification.fromMap(map);
      expect(fromMap.id, notif.id);
      expect(fromMap.title, notif.title);
      expect(fromMap.body, notif.body);
      expect(fromMap.category, NotificationCategory.sos);
      expect(fromMap.isRead, false);
      expect(fromMap.metadata?['lat'], 6.867);
    });

    test('timeAgo returns appropriate Thai string', () {
      final now = DateTime.now();

      final justNow = AppNotification(
        id: '1',
        title: 't',
        body: 'b',
        category: NotificationCategory.system,
        timestamp: now.subtract(const Duration(seconds: 20)),
      );
      expect(justNow.timeAgo, 'เมื่อสักครู่');

      final minutesAgo = AppNotification(
        id: '2',
        title: 't',
        body: 'b',
        category: NotificationCategory.weather,
        timestamp: now.subtract(const Duration(minutes: 5)),
      );
      expect(minutesAgo.timeAgo, '5 นาทีที่แล้ว');

      final hoursAgo = AppNotification(
        id: '3',
        title: 't',
        body: 'b',
        category: NotificationCategory.mule,
        timestamp: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgo, '3 ชั่วโมงที่แล้ว');
    });

    test('category properties match expectations', () {
      final sos = AppNotification(
        id: 'sos_1',
        title: 'SOS',
        body: 'Help',
        category: NotificationCategory.sos,
        timestamp: DateTime.now(),
      );
      expect(sos.categoryLabel, 'ฉุกเฉิน SOS');

      final weather = AppNotification(
        id: 'w_1',
        title: 'Rain',
        body: 'Flood',
        category: NotificationCategory.weather,
        timestamp: DateTime.now(),
      );
      expect(weather.categoryLabel, 'เตือนภัยอากาศ');

      final mule = AppNotification(
        id: 'm_1',
        title: 'Mule',
        body: 'Carried',
        category: NotificationCategory.mule,
        timestamp: DateTime.now(),
      );
      expect(mule.categoryLabel, 'คนเดินสาร');
    });

    test('copyWith updates fields correctly', () {
      final original = AppNotification(
        id: 'test_copy',
        title: 'Title',
        body: 'Body',
        category: NotificationCategory.system,
        timestamp: DateTime.now(),
        isRead: false,
      );

      final updated = original.copyWith(isRead: true, title: 'New Title');
      expect(updated.id, original.id);
      expect(updated.title, 'New Title');
      expect(updated.isRead, true);
    });
  });
}
