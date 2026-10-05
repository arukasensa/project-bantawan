import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// 📍 วิดเจ็ตแสดงพิกัด GPS ละติจูด-ลองจิจูดออฟไลน์ (Tactical Coordinates Badge)
/// ทำงานได้ 100% โดยไม่ต้องเชื่อมต่ออินเทอร์เน็ต ใช้แจ้งพิกัดกู้ภัย 1669 หรือนำทาง
class TacticalCoordinatesBadge extends StatefulWidget {
  final LatLng position;

  const TacticalCoordinatesBadge({
    super.key,
    required this.position,
  });

  @override
  State<TacticalCoordinatesBadge> createState() => _TacticalCoordinatesBadgeState();
}

class _TacticalCoordinatesBadgeState extends State<TacticalCoordinatesBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _copyCoordinates(BuildContext context) {
    HapticFeedback.mediumImpact();
    final lat = widget.position.latitude.toStringAsFixed(6);
    final lng = widget.position.longitude.toStringAsFixed(6);
    final coordStr = '$lat, $lng';

    Clipboard.setData(ClipboardData(text: coordStr));

    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'คัดลอกพิกัด GPS: $coordStr แล้ว (แจ้งกู้ภัย 1669)',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.position.latitude;
    final lng = widget.position.longitude;
    final latStr = '${lat.abs().toStringAsFixed(5)}° ${lat >= 0 ? "N" : "S"}';
    final lngStr = '${lng.abs().toStringAsFixed(5)}° ${lng >= 0 ? "E" : "W"}';

    return GestureDetector(
      onTap: () => _copyCoordinates(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // จุดเรดาร์สีเขียวกระพริบ (GPS Satellite Lock)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.4 + _pulseController.value * 0.5,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // ข้อความพิกัด Lat, Long
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "📍 พิกัด GPS: ",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "$latStr, $lngStr",
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // แท็ก "ออฟไลน์" และไอคอนคัดลอก
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "ออฟไลน์",
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                Icon(
                  _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                  color: _isCopied ? Colors.greenAccent : Colors.white54,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
