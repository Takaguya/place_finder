import '../../../../core/result.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._source);

  final LocationDataSource _source;

  @override
  Future<Result<GeoPoint>> getCurrentPoint() async {
    try {
      return Success(await _source.getCurrentPoint());
    } on Exception {
      return const Failed(Failure('Your location is unavailable.'));
    }
  }
}
