import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/features/places/data/datasources/route_data_source.dart';
import 'package:place_finder/features/places/data/datasources/sample_place_data_source.dart';
import 'package:place_finder/features/places/data/datasources/sketch_route_data_source.dart';
import 'package:place_finder/features/places/domain/entities/geo_point.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';
import 'package:place_finder/features/places/sketch_map.dart';

void main() {
  const centre = GeoPoint(11.5564, 104.9282);

  group('the test map', () {
    final source = SketchRouteDataSource();
    late List<Place> places;

    setUpAll(() async {
      final models = await const SamplePlaceDataSource().fetchPlaces();
      places = [for (final model in models) model.toEntity()];
    });

    Future<WalkingRoute> routeTo(String name) {
      final place = places.firstWhere((place) => place.name == name);
      return source.fetchWalkingRoute(from: centre, to: place.location);
    }

    test('every sample place can be reached from the city centre', () async {
      for (final place in places) {
        final route = await source.fetchWalkingRoute(
          from: centre,
          to: place.location,
        );

        expect(route.path.first, centre, reason: place.name);
        expect(route.path.last, place.location, reason: place.name);
        expect(route.steps.first.maneuver, RouteManeuver.start);
        expect(route.steps.last.maneuver, RouteManeuver.arrive);
      }
    });

    test('every sample place can be reached from every other', () async {
      for (final from in places) {
        for (final to in places) {
          await expectLater(
            source.fetchWalkingRoute(from: from.location, to: to.location),
            completes,
            reason: '${from.name} to ${to.name}',
          );
        }
      }
    });

    test('a walk is never shorter than the straight line', () async {
      for (final place in places) {
        final route = await source.fetchWalkingRoute(
          from: centre,
          to: place.location,
        );

        expect(
          route.distanceKm,
          greaterThanOrEqualTo(centre.distanceKmTo(place.location) - 0.001),
          reason: place.name,
        );
      }
    });

    test('the steps add up to the whole distance', () async {
      for (final place in places) {
        final route = await source.fetchWalkingRoute(
          from: centre,
          to: place.location,
        );
        final stepsTotal = route.steps.fold<double>(
          0,
          (total, step) => total + step.distanceKm,
        );

        expect(stepsTotal, closeTo(route.distanceKm, 0.0001), reason: place.name);
      }
    });

    test('the line on the map is as long as the stated distance', () async {
      final route = await routeTo('Sen Sok Central');
      var lineKm = 0.0;
      for (var i = 0; i < route.path.length - 1; i++) {
        lineKm += route.path[i].distanceKmTo(route.path[i + 1]);
      }

      expect(lineKm, closeTo(route.distanceKm, 0.0001));
    });

    test('a walk is the same length in both directions', () async {
      final place = places.firstWhere((p) => p.name == 'Sen Sok Central');
      final there = await source.fetchWalkingRoute(
        from: centre,
        to: place.location,
      );
      final back = await source.fetchWalkingRoute(
        from: place.location,
        to: centre,
      );

      expect(back.distanceKm, closeTo(there.distanceKm, 0.0001));
    });

    test('places across the river are reached over a bridge', () async {
      List<String?> streetsOn(WalkingRoute route) => [
        for (final step in route.steps) step.streetName,
      ];

      expect(
        streetsOn(await routeTo('Diamond Point Mall')),
        contains('Koh Pich Bridge'),
      );
      expect(
        streetsOn(await routeTo('Chroy Changvar Seafood')),
        contains('Chroy Changvar Bridge'),
      );
    });
  });

  group('instructions', () {
    // Long Road runs north to south, and Cross Road runs west to east.
    final corner = SketchRouteDataSource(
      streets: [
        SketchStreet('Long Road', [(0.2, 0.8), (0.2, 0.2)]),
        SketchStreet('Cross Road', [(0.1, 0.25), (0.8, 0.25)]),
      ],
    );

    List<RouteManeuver> maneuversOf(WalkingRoute route) => [
      for (final step in route.steps) step.maneuver,
    ];

    test('walking north then east is a right turn', () async {
      final route = await corner.fetchWalkingRoute(
        from: SketchMap.toGeo(0.2, 0.7),
        to: SketchMap.toGeo(0.6, 0.25),
      );

      expect(route.steps.first.heading, CompassHeading.north);
      expect(route.steps.first.streetName, 'Long Road');
      expect(maneuversOf(route), [
        RouteManeuver.start,
        RouteManeuver.turnRight,
        RouteManeuver.arrive,
      ]);
      expect(route.steps[1].streetName, 'Cross Road');
    });

    test('walking north then west is a left turn', () async {
      final route = await corner.fetchWalkingRoute(
        from: SketchMap.toGeo(0.2, 0.7),
        to: SketchMap.toGeo(0.12, 0.25),
      );

      expect(maneuversOf(route), [
        RouteManeuver.start,
        RouteManeuver.turnLeft,
        RouteManeuver.arrive,
      ]);
    });

    test('staying on one street is a single instruction', () async {
      final route = await corner.fetchWalkingRoute(
        from: SketchMap.toGeo(0.2, 0.7),
        to: SketchMap.toGeo(0.2, 0.4),
      );

      expect(maneuversOf(route), [RouteManeuver.start, RouteManeuver.arrive]);
    });

    test('a slight bend onto another street says to continue', () async {
      final bend = SketchRouteDataSource(
        streets: [
          SketchStreet('First Road', [(0.1, 0.5), (0.7, 0.5)]),
          SketchStreet('Next Road', [(0.45, 0.49), (0.9, 0.52)]),
        ],
      );

      final route = await bend.fetchWalkingRoute(
        from: SketchMap.toGeo(0.2, 0.5),
        to: SketchMap.toGeo(0.85, 0.517),
      );

      expect(route.steps[1].maneuver, RouteManeuver.continueStraight);
      expect(route.steps[1].streetName, 'Next Road');
    });

    test('a street used for only a few metres gets no instruction', () async {
      final shortLink = SketchRouteDataSource(
        streets: [
          SketchStreet('First Road', [(0.1, 0.5), (0.5, 0.5)]),
          SketchStreet('Tiny Link', [(0.499, 0.4995), (0.499, 0.5015)]),
          SketchStreet('Second Road', [(0.4, 0.501), (0.9, 0.501)]),
        ],
      );

      final route = await shortLink.fetchWalkingRoute(
        from: SketchMap.toGeo(0.2, 0.5),
        to: SketchMap.toGeo(0.8, 0.501),
      );

      final streets = [for (final step in route.steps) step.streetName];
      expect(streets, ['First Road', 'Second Road', null]);
    });
  });

  test('streets that never meet have no route between them', () async {
    final apart = SketchRouteDataSource(
      streets: [
        SketchStreet('West Road', [(0.1, 0.1), (0.1, 0.9)]),
        SketchStreet('East Road', [(0.9, 0.1), (0.9, 0.9)]),
      ],
    );

    await expectLater(
      apart.fetchWalkingRoute(
        from: SketchMap.toGeo(0.1, 0.5),
        to: SketchMap.toGeo(0.9, 0.5),
      ),
      throwsA(isA<RouteNotFoundException>()),
    );
  });
}
