import '../../../../core/result.dart';
import '../entities/geo_point.dart';
import '../entities/user_position.dart';
import '../repositories/location_repository.dart';

/// Works out the point to measure distances from.
///
/// This never fails. If the device position is unavailable, or too far away for
/// the distances to mean anything, it falls back to the centre of the service
/// area and says why.
class GetUserPosition {
  const GetUserPosition(this._locations, {required this.serviceArea});

  final LocationRepository _locations;
  final ServiceArea serviceArea;

  Future<UserPosition> call() async {
    final result = await _locations.getCurrentPoint();
    return switch (result) {
      Failed<GeoPoint>() => _fallback(PositionSource.fallbackNoAccess),
      Success<GeoPoint>(:final value) => _fromDevice(value),
    };
  }

  UserPosition _fromDevice(GeoPoint point) {
    final isInsideArea =
        point.distanceKmTo(serviceArea.centre) <= serviceArea.radiusKm;
    if (!isInsideArea) return _fallback(PositionSource.fallbackOutsideArea);
    return UserPosition(
      point: point,
      source: PositionSource.device,
      area: serviceArea,
    );
  }

  UserPosition _fallback(PositionSource source) {
    return UserPosition(
      point: serviceArea.centre,
      source: source,
      area: serviceArea,
    );
  }
}
