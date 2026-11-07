import '../../../../core/result.dart';
import '../entities/geo_point.dart';

/// Hands a journey over to a maps app outside this one.
abstract interface class MapsAppRepository {
  Future<Result<void>> openWalkingDirections({required GeoPoint to});
}
