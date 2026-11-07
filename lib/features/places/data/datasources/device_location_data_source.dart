import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import 'location_data_source.dart';

class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'LocationUnavailableException: $reason';
}

/// Reads the device position, asking for permission if needed.
class DeviceLocationDataSource implements LocationDataSource {
  const DeviceLocationDataSource();

  /// How long to wait for a position. Time spent on the permission prompt isn't
  /// counted, so someone can take as long as they like to answer it.
  static const Duration _positionTimeLimit = Duration(seconds: 10);

  @override
  Future<GeoPoint> getCurrentPoint() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException('Location services are off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException('Permission was refused.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        // Medium accuracy doesn't use GPS on Android, so it finds nothing where
        // Wi-Fi and cell location are weak. High uses every source available,
        // and Android still limits the result if the user chose Approximate.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _positionTimeLimit,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      // A new position can be slow indoors. A recent one is better than none.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) rethrow;
      return GeoPoint(lastKnown.latitude, lastKnown.longitude);
    }
  }
}
