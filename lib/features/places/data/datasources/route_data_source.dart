import '../../domain/entities/geo_point.dart';
import '../../domain/entities/walking_route.dart';

/// Supplies walking routes. Implement this with a routing service's API to
/// replace the test map's route finder.
abstract interface class RouteDataSource {
  Future<WalkingRoute> fetchWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  });
}

class RouteNotFoundException implements Exception {
  const RouteNotFoundException();

  @override
  String toString() => 'RouteNotFoundException: the points are not connected.';
}
