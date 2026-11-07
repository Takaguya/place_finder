import 'package:equatable/equatable.dart';

import 'geo_point.dart';

/// Where the app's place data applies.
class ServiceArea extends Equatable {
  const ServiceArea({
    required this.name,
    required this.centre,
    required this.centreName,
    required this.radiusKm,
  });

  final String name;
  final GeoPoint centre;
  final String centreName;
  final double radiusKm;

  @override
  List<Object> get props => [name, centre, centreName, radiusKm];
}

/// Why the app is measuring distances from a particular point.
enum PositionSource {
  /// The device's real position.
  device,

  /// The device position is unavailable, so the area's centre is used.
  fallbackNoAccess,

  /// The device is too far from the area, so the area's centre is used.
  fallbackOutsideArea,
}

/// The point distances are measured from.
class UserPosition extends Equatable {
  const UserPosition({
    required this.point,
    required this.source,
    required this.area,
  });

  final GeoPoint point;
  final PositionSource source;
  final ServiceArea area;

  bool get isFallback => source != PositionSource.device;

  @override
  List<Object> get props => [point, source, area];
}
