import '../../domain/entities/geo_point.dart';

/// Supplies the device's current position.
abstract interface class LocationDataSource {
  Future<GeoPoint> getCurrentPoint();
}
