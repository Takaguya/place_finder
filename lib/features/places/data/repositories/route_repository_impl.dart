import '../../../../core/result.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/walking_route.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_data_source.dart';

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._source);

  final RouteDataSource _source;

  @override
  Future<Result<WalkingRoute>> getWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    try {
      return Success(await _source.fetchWalkingRoute(from: from, to: to));
    } on Exception {
      return const Failed(
        Failure('A walking route could not be found. Try again in a moment.'),
      );
    }
  }
}
