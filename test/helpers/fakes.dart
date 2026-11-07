import 'dart:async';

import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/geo_point.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';
import 'package:place_finder/features/places/domain/repositories/location_repository.dart';
import 'package:place_finder/features/places/domain/repositories/maps_app_repository.dart';
import 'package:place_finder/features/places/domain/repositories/place_repository.dart';
import 'package:place_finder/features/places/domain/repositories/route_repository.dart';

const GeoPoint testCentre = GeoPoint(11.5564, 104.9282);

const ServiceArea testArea = ServiceArea(
  name: 'Phnom Penh',
  centre: testCentre,
  centreName: 'Independence Monument',
  radiusKm: 20,
);

/// Noon, when a place open from 9 to 21 is open.
final DateTime testNoon = DateTime(2026, 11, 6, 12);

Place testPlace({
  String id = 'place',
  String name = 'Test Place',
  PlaceCategory category = PlaceCategory.restaurant,
  double rating = 4.5,
  int reviewCount = 500,
  GeoPoint location = testCentre,
  int opensAtHour = 9,
  int closesAtHour = 21,
  String neighbourhood = 'BKK1',
  String summary = 'A place to visit.',
}) {
  return Place(
    id: id,
    name: name,
    category: category,
    rating: rating,
    reviewCount: reviewCount,
    priceLevel: 2,
    neighbourhood: neighbourhood,
    location: location,
    opensAtHour: opensAtHour,
    closesAtHour: closesAtHour,
    summary: summary,
  );
}

/// A point about [km] kilometres north of [testCentre].
GeoPoint northOfCentre(double km) {
  return GeoPoint(testCentre.latitude + km / 111.2, testCentre.longitude);
}

class FakePlaceRepository implements PlaceRepository {
  FakePlaceRepository(this.places, {this.failure});

  final List<Place> places;
  final Failure? failure;

  @override
  Future<Result<List<Place>>> getPlaces() async {
    final currentFailure = failure;
    return currentFailure != null ? Failed(currentFailure) : Success(places);
  }
}

/// Holds every request open until the test completes it, so a test can control
/// the order in which responses arrive.
class ManualPlaceRepository implements PlaceRepository {
  final List<Completer<Result<List<Place>>>> requests = [];

  @override
  Future<Result<List<Place>>> getPlaces() {
    final request = Completer<Result<List<Place>>>();
    requests.add(request);
    return request.future;
  }
}

class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository(this.result);

  /// Can be changed mid-test, as when someone turns on location in settings.
  Result<GeoPoint> result;

  @override
  Future<Result<GeoPoint>> getCurrentPoint() async => result;
}

/// A walk with a turn, for testing what the screens show.
final WalkingRoute testRoute = WalkingRoute(
  path: [testCentre, northOfCentre(0.4), northOfCentre(1)],
  distanceKm: 1.2,
  steps: const [
    RouteStep(
      maneuver: RouteManeuver.start,
      distanceKm: 0.4,
      streetName: 'Norodom Blvd',
      heading: CompassHeading.north,
    ),
    RouteStep(
      maneuver: RouteManeuver.turnLeft,
      distanceKm: 0.8,
      streetName: 'Sihanouk Blvd',
    ),
    RouteStep.arrive(),
  ],
);

class FakeRouteRepository implements RouteRepository {
  FakeRouteRepository(this.result);

  /// Can be changed mid-test, as when a request works on the second try.
  Result<WalkingRoute> result;

  @override
  Future<Result<WalkingRoute>> getWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  }) async => result;
}

class FakeMapsAppRepository implements MapsAppRepository {
  FakeMapsAppRepository({this.result = const Success<void>(null)});

  final Result<void> result;

  /// Each destination that was asked for, in order.
  final List<GeoPoint> opened = [];

  @override
  Future<Result<void>> openWalkingDirections({required GeoPoint to}) async {
    opened.add(to);
    return result;
  }
}

/// Holds the location request open until the test completes it.
class ManualLocationRepository implements LocationRepository {
  final Completer<Result<GeoPoint>> request = Completer();

  @override
  Future<Result<GeoPoint>> getCurrentPoint() => request.future;
}
