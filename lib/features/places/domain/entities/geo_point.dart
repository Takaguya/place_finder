import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A position on Earth.
class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static const double _earthRadiusKm = 6371;

  /// Straight-line distance over the Earth's surface (haversine formula).
  double distanceKmTo(GeoPoint other) {
    final latDelta = _radians(other.latitude - latitude);
    final lngDelta = _radians(other.longitude - longitude);
    final a =
        math.pow(math.sin(latDelta / 2), 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(other.latitude)) *
            math.pow(math.sin(lngDelta / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  @override
  List<Object> get props => [latitude, longitude];
}
