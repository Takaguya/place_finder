import '../../../../core/result.dart';
import '../entities/geo_point.dart';
import '../entities/walking_route.dart';

/// Where walking routes come from. The domain only knows this contract, so the
/// test map's route finder can be replaced by a real routing service.
abstract interface class RouteRepository {
  Future<Result<WalkingRoute>> getWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  });
}
