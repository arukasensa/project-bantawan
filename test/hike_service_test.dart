import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter1/features/survival/services/hike_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HikeService Tests', () {
    late HikeService service;

    setUp(() {
      service = HikeService();
    });

    test('initial state is inactive and empty', () {
      expect(service.isHikeActive, false);
      expect(service.breadcrumbs.isEmpty, true);
      expect(service.isBacktrackActive, false);
      expect(service.totalDistanceKm, 0.0);
    });

    test('startHike activates tracking and sets basecamp point', () {
      const start = LatLng(6.867, 101.250);
      service.startHike(start);

      expect(service.isHikeActive, true);
      expect(service.breadcrumbs.length, 1);
      expect(service.breadcrumbs.first, start);
      expect(service.hikeStartTime, isNotNull);
    });

    test('toggleBacktrack toggles state properly', () {
      service.toggleBacktrack();
      expect(service.isBacktrackActive, true);

      service.toggleBacktrack(false);
      expect(service.isBacktrackActive, false);
    });

    test('calculates distance and bearing to start correctly', () {
      const basecamp = LatLng(6.8670, 101.2500);
      const current = LatLng(6.8770, 101.2500); // 1 km or so north

      service.startHike(basecamp);
      service.updateCurrentPosition(current, altitude: 320.0);

      final dist = service.getDistanceToStartMeters();
      expect(dist, isNotNull);
      expect(dist! > 1000, true); // Approximately 1.1 km

      final bearing = service.getBearingToStartDegrees();
      expect(bearing, isNotNull);
      expect(bearing! >= 0 && bearing <= 360, true);
      // Bearing from north to south should be near 180 degrees
      expect(bearing, closeTo(180, 5));
    });

    test('endHike generates complete summary and stops tracking', () {
      const basecamp = LatLng(6.8670, 101.2500);
      service.startHike(basecamp);
      service.updateCurrentPosition(const LatLng(6.8700, 101.2500), altitude: 280.0);

      final summary = service.endHike();
      expect(summary, isNotNull);
      expect(summary!.breadcrumbCount, 1);
      expect(summary.trail.length, 1);
      expect(service.isHikeActive, false);
      expect(service.isBacktrackActive, false);
    });
  });
}
