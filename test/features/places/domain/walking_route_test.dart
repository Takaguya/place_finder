import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';

void main() {
  WalkingRoute routeOf(double km) =>
      WalkingRoute(path: const [], distanceKm: km, steps: const []);

  group('walkingTime', () {
    test('uses a normal walking pace of 4.8 km an hour', () {
      expect(routeOf(4.8).walkingTime, const Duration(hours: 1));
      expect(routeOf(2.4).walkingTime, const Duration(minutes: 30));
    });

    test('rounds up, so the time shown is enough to get there', () {
      // 1 km takes 12.5 minutes.
      expect(routeOf(1).walkingTime, const Duration(minutes: 13));
    });

    test('is never less than a minute', () {
      expect(routeOf(0.01).walkingTime, const Duration(minutes: 1));
      expect(routeOf(0).walkingTime, const Duration(minutes: 1));
    });
  });
}
