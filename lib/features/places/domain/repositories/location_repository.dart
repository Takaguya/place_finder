import '../../../../core/result.dart';
import '../entities/geo_point.dart';

/// Where the device is right now.
abstract interface class LocationRepository {
  Future<Result<GeoPoint>> getCurrentPoint();
}
