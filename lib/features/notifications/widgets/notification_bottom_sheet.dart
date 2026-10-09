import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'package:flutter1/core/navigation/main_navigation.dart';
import 'package:flutter1/features/chat/screens/nearby_chat_screen.dart';
import 'package:flutter1/features/weather/screens/weather_detail_screen.dart';
import 'package:flutter1/features/weather/services/weather_service.dart';
import 'package:flutter1/core/utils/l10n_extensions.dart';

/// 🔔 หน้าต่างแสดงรายการแจ้งเตือนสไตล์ Glassmorphism Tactical HUD
class NotificationBottomSheet extends StatefulWidget {
  final WeatherData? currentWeather;

  const NotificationBottomSheet({super.key, this.currentWeather});

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  NotificationCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notifService, child) {
        final allNotifs = notifService.notifications;
        final filteredNotifs = _selectedCategory == null
            ? allNotifs
            : allNotifs.where((n) => n.category == _selectedCategory).toList();

        final unreadCount = notifService.unreadCount;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // แถบลากด้านบน (Drag Handle)
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header: หัวข้อ, จำนวนที่ยังไม่ได้อ่าน, และปุ่มล้าง/อ่านทั้งหมด
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.isThai ? 'การแจ้งเตือน' : 'Notifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.isThai ? '$unreadCount ใหม่' : '$unreadCount New',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (unreadCount > 0)
                          IconButton(
                            icon: const Icon(
                              Icons.done_all_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: context.isThai ? 'อ่านทั้งหมด' : 'Mark all read',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              notifService.markAllAsRead();
                            },
                          ),
                        if (allNotifs.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            tooltip: context.isThai ? 'ล้างทั้งหมด' : 'Clear all',
                            onPressed: () => _confirmClearAll(context, notifService),
                          ),
                      ],
                    ),
                  ),

                  // Category Filter Chips
                  _buildCategoryFilters(allNotifs),

                  const SizedBox(height: 8),

                  // รายการการแจ้งเตือน
                  Expanded(
                    child: filteredNotifs.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filteredNotifs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notif = filteredNotifs[index];
                              return _buildNotificationCard(
                                context,
                                notif,
                                notifService,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// แถบตัวกรองหมวดหมู่แบบเลื่อนได้ในแนวนอน
  Widget _buildCategoryFilters(List<AppNotification> all) {
    final categories = <NotificationCategory?>[
      null, // ทั้งหมด
      NotificationCategory.sos,
      NotificationCategory.weather,
      NotificationCategory.mule,
      NotificationCategory.shelter,
      NotificationCategory.system,
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          String label;
          int count;
          IconData icon;
          Color color;

          if (cat == null) {
            label = context.isThai ? 'ทั้งหมด' : 'All';
            count = all.length;
            icon = Icons.all_inbox_rounded;
            color = Colors.white;
          } else {
            label = _getCategoryTitle(cat);
            count = all.where((n) => n.category == cat).length;
            icon = _getCategoryIcon(cat);
            color = _getCategoryColor(cat);
          }

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? color : Colors.white60,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(
                        color: isSelected ? color : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// การ์ดการแจ้งเตือนแต่ละรายการ (รองรับการปัดเพื่อลบ Dismissible)
  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notif,
    NotificationService service,
  ) {
    final catColor = notif.categoryColor;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text(
              'ลบ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        service.deleteNotification(notif.id);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          service.markAsRead(notif.id);
          _handleAction(context, notif);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : const Color(0xFF1E293B).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? Colors.white.withValues(alpha: 0.08)
                  : catColor.withValues(alpha: 0.4),
              width: notif.isRead ? 1 : 1.4,
            ),
            boxShadow: notif.isRead
                ? null
                : [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวการ์ด: ไอคอนหมวดหมู่, หมวดหมู่, เวลา และจุดยังไม่ได้อ่าน
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(notif.categoryIcon, color: catColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notif.categoryLabel,
                    style: TextStyle(
                      color: catColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    notif.timeAgo,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  if (!notif.isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: catColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // ชื่อเรื่อง (Title)
              Text(
                notif.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // รายละเอียด (Body)
              Text(
                notif.body,
                style: TextStyle(
                  color: notif.isRead ? Colors.white60 : Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),

              // ปุ่มลิงก์การทำงาน (Action Button) ถ้ามี route
              if (notif.actionRoute != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        service.markAsRead(notif.id);
                        _handleAction(context, notif);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getActionLabel(notif.actionRoute!),
                              style: TextStyle(
                                color: catColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: catColor,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// การทำงานเมื่อแตะที่การ์ดแจ้งเตือน
  void _handleAction(BuildContext context, AppNotification notif) {
    final route = notif.actionRoute;
    if (route == null) return;

    Navigator.pop(context); // ปิด BottomSheet ก่อนไปหน้าอื่น

    if (route == 'map_sos' || route == 'map_shelter') {
      // สลับไปแท็บแผนที่ (Index 3)
      final mainNav = context.findAncestorStateOfType<MainNavigationState>();
      mainNav?.changeTab(3);
    } else if (route == 'weather') {
      // นำทางไปหน้าข้อมูลสภาพอากาศ
      if (widget.currentWeather != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailScreen(
              weatherData: widget.currentWeather!,
            ),
          ),
        );
      }
    } else if (route == 'data_mule' || route == 'chat') {
      // ไปหน้าห้องแชทออฟไลน์เมช
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NearbyChatScreen(),
        ),
      );
    }
  }

  String _getActionLabel(String route) {
    switch (route) {
      case 'map_sos':
        return context.isThai ? 'ดูพิกัดบนแผนที่' : 'View on Map';
      case 'map_shelter':
        return context.isThai ? 'ดูศูนย์พักพิงบนแผนที่' : 'View Shelters on Map';
      case 'weather':
        return context.isThai ? 'ตรวจเช็คสภาพอากาศ' : 'Check Weather';
      case 'data_mule':
        return context.isThai ? 'เปิดคลังคนเดินสาร' : 'Open Data Mule';
      case 'chat':
        return context.isThai ? 'เปิดห้องแชทเมช' : 'Open Mesh Chat';
      default:
        return context.isThai ? 'ดูรายละเอียด' : 'View Details';
    }
  }

  String _getCategoryTitle(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.sos:
        return context.isThai ? 'ฉุกเฉิน SOS' : 'Emergency SOS';
      case NotificationCategory.weather:
        return context.isThai ? 'สภาพอากาศ' : 'Weather';
      case NotificationCategory.mule:
        return context.isThai ? 'คนเดินสาร' : 'Data Mule';
      case NotificationCategory.shelter:
        return context.isThai ? 'ศูนย์ช่วยเหลือ' : 'Relief Centers';
      case NotificationCategory.system:
        return context.isThai ? 'ระบบ' : 'System';
    }
  }

  IconData _getCategoryIcon(NotificationCategory cat) {
    switch (cat) {
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

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.sos:
        return Colors.redAccent;
      case NotificationCategory.weather:
        return Colors.amberAccent;
      case NotificationCategory.mule:
        return Colors.purpleAccent;
      case NotificationCategory.shelter:
        return const Color(0xFF10B981);
      case NotificationCategory.system:
        return Colors.cyanAccent;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.isThai ? 'ไม่มีการแจ้งเตือนในขณะนี้' : 'No notifications right now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.isThai
                ? 'ข้อมูลการเตือนภัยฉุกเฉินล่าสุดจะปรากฏที่นี่'
                : 'Latest emergency alerts will appear here',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, NotificationService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              context.isThai ? 'ล้างการแจ้งเตือนทั้งหมด' : 'Clear All Notifications',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          context.isThai
              ? 'คุณแน่ใจหรือไม่ว่าต้องการล้างประวัติการแจ้งเตือนทั้งหมด?'
              : 'Are you sure you want to clear all notification history?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.isThai ? 'ยกเลิก' : 'Cancel',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              service.clearAll();
              Navigator.pop(ctx);
            },
            child: Text(
              context.isThai ? 'ล้างทั้งหมด' : 'Clear All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
