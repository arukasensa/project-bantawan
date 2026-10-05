import 'dart:convert';
import 'package:flutter/material.dart';

/// 🔔 ประเภทของการแจ้งเตือนในระบบ BANTAWAN
enum NotificationCategory {
  /// 🚨 สัญญาณขอความช่วยเหลือฉุกเฉินระดับวิกฤต
  sos,

  /// 🌧️ การเตือนภัยธรรมชาติ สภาพอากาศ น้ำท่วม พายุ
  weather,

  /// 🎒 การส่งสารออฟไลน์เมช / คนเดินสาร (Data Mule)
  mule,

  /// ⛺ ศูนย์พักพิง จุดแจกจ่ายถุงยังชีพ หรือสถานพยาบาล
  shelter,

  /// ⚙️ สถานะระบบ แบตเตอรี่ หรือความปลอดภัยอุปกรณ์
  system,
}

/// 📦 โมเดลข้อมูลการแจ้งเตือน
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'actionRoute': actionRoute,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    NotificationCategory cat = NotificationCategory.system;
    try {
      cat = NotificationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => NotificationCategory.system,
      );
    } catch (_) {}

    Map<String, dynamic>? meta;
    if (map['metadata'] != null) {
      try {
        meta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      category: cat,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] is int ? map['isRead'] == 1 : map['isRead'] == true),
      actionRoute: map['actionRoute'] as String?,
      metadata: meta,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// ข้อความระบุเวลาที่ผ่านไปในรูปแบบภาษาไทย
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// ไอคอนประจำหมวดหมู่
  IconData get categoryIcon {
    switch (category) {
      case NotificationCategory.sos:
        return Icons.emergency_rounded;
      case NotificationCategory.weather:
        return Icons.thunderstorm_rounded;
      case NotificationCategory.mule:
        return Icons.backpack_rounded;
      case NotificationCategory.shelter:
        return Icons.night_shelter_rounded;
      case NotificationCategory.system:
        return Icons.shield_rounded;
    }
  }

  /// สีประจำหมวดหมู่
  Color get categoryColor {
    switch (category) {
      case NotificationCategory.sos:
        return Colors.redAccent;
      case NotificationCategory.weather:
        return Colors.amberAccent;
      case NotificationCategory.mule:
        return Colors.purpleAccent;
      case NotificationCategory.shelter:
        return const Color(0xFF10B981); // Emerald
      case NotificationCategory.system:
        return Colors.cyanAccent;
    }
  }

  /// ป้ายชื่อหมวดหมู่ภาษาไทย
  String get categoryLabel {
    switch (category) {
      case NotificationCategory.sos:
        return 'ฉุกเฉิน SOS';
      case NotificationCategory.weather:
        return 'เตือนภัยอากาศ';
      case NotificationCategory.mule:
        return 'คนเดินสาร';
      case NotificationCategory.shelter:
        return 'ศูนย์ช่วยเหลือ';
      case NotificationCategory.system:
        return 'ระบบ / อุปกรณ์';
    }
  }
}
