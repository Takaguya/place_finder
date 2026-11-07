import '../../../../core/result.dart';
import '../entities/geo_point.dart';
import '../entities/walking_route.dart';
import '../repositories/route_repository.dart';

/// Finds the way to walk from one point to another.
class GetWalkingRoute {
  const GetWalkingRoute(this._routes);

  final RouteRepository _routes;

  Future<Result<WalkingRoute>> call({
    required GeoPoint from,
    required GeoPoint to,
  }) {
    return _routes.getWalkingRoute(from: from, to: to);
  }
}
