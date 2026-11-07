import '../../../../core/result.dart';
import '../entities/geo_point.dart';
import '../repositories/maps_app_repository.dart';

/// Opens walking directions to a point in a maps app outside this one.
class OpenInMapsApp {
  const OpenInMapsApp(this._mapsApp);

  final MapsAppRepository _mapsApp;

  Future<Result<void>> call({required GeoPoint to}) {
    return _mapsApp.openWalkingDirections(to: to);
  }
}
