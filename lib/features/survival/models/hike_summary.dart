import 'package:latlong2/latlong.dart';

/// 📊 สรุปผลรายงานกิจกรรมการเดินป่า (Hike Summary)
class HikeSummary {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceKm;
  final int breadcrumbCount;
  final double? startAltitude;
  final double? maxAltitude;
  final List<LatLng> trail;

  const HikeSummary({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceKm,
    required this.breadcrumbCount,
    this.startAltitude,
    this.maxAltitude,
    required this.trail,
  });

  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} กม.';
}
