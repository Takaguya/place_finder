import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'geo_point.dart';

enum RouteManeuver { start, continueStraight, turnLeft, turnRight, arrive }

enum CompassHeading {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

/// One instruction in a walking route.
class RouteStep extends Equatable {
  const RouteStep({
    required this.maneuver,
    required this.distanceKm,
    this.streetName,
    this.heading,
  });

  /// The final step, on reaching the destination.
  const RouteStep.arrive()
    : maneuver = RouteManeuver.arrive,
      distanceKm = 0,
      streetName = null,
      heading = null;

  final RouteManeuver maneuver;

  /// How far to walk after this instruction.
  final double distanceKm;

  /// The street to walk along. Null when arriving.
  final String? streetName;

  /// The direction to set off in. Only the first step has one.
  final CompassHeading? heading;

  @override
  List<Object?> get props => [maneuver, distanceKm, streetName, heading];
}

/// How to walk from one point to another.
class WalkingRoute extends Equatable {
  const WalkingRoute({
    required this.path,
    required this.distanceKm,
    required this.steps,
  });

  /// A normal walking pace.
  static const double walkingSpeedKmh = 4.8;

  /// The line to follow, from the start to the destination.
  final List<GeoPoint> path;
  final double distanceKm;
  final List<RouteStep> steps;

  /// How long the walk takes, rounded up to a whole minute.
  Duration get walkingTime {
    final minutes = (distanceKm / walkingSpeedKmh * 60).ceil();
    return Duration(minutes: math.max(minutes, 1));
  }

  @override
  List<Object> get props => [path, distanceKm, steps];
}
