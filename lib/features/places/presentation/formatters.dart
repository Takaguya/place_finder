import 'package:flutter/material.dart';

import '../domain/entities/place.dart';
import '../domain/entities/place_query.dart';
import '../domain/entities/ranked_place.dart';
import '../domain/entities/user_position.dart';
import '../domain/entities/walking_route.dart';

/// How domain values are worded and shown. The domain stays free of UI text.
extension PlaceCategoryDisplay on PlaceCategory {
  String get singular => switch (this) {
    PlaceCategory.mall => 'Mall',
    PlaceCategory.restaurant => 'Restaurant',
    PlaceCategory.cafe => 'Cafe',
    PlaceCategory.market => 'Market',
  };

  String get plural => switch (this) {
    PlaceCategory.mall => 'Malls',
    PlaceCategory.restaurant => 'Restaurants',
    PlaceCategory.cafe => 'Cafes',
    PlaceCategory.market => 'Markets',
  };

  IconData get icon => switch (this) {
    PlaceCategory.mall => Icons.local_mall_outlined,
    PlaceCategory.restaurant => Icons.restaurant,
    PlaceCategory.cafe => Icons.local_cafe_outlined,
    PlaceCategory.market => Icons.storefront_outlined,
  };
}

extension SortModeDisplay on SortMode {
  String get label => switch (this) {
    SortMode.bestMatch => 'Best match',
    SortMode.closest => 'Closest',
    SortMode.topRated => 'Top rated',
  };

  String get heading => switch (this) {
    SortMode.bestMatch => 'Good and close',
    SortMode.closest => 'Closest first',
    SortMode.topRated => 'Highest rated first',
  };

  /// The tag on the first result.
  String get topResultLabel => switch (this) {
    SortMode.bestMatch => 'Top pick',
    SortMode.closest => 'Closest to you',
    SortMode.topRated => 'Highest rated',
  };
}

String formatDistance(double km) {
  final metres = (km * 100).round() * 10;
  if (metres < 1000) return '$metres m';
  return '${km.toStringAsFixed(1)} km';
}

/// 1280 becomes 1,280.
String formatCount(int count) {
  final digits = count.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 22 becomes 10 PM.
String formatHour(int hour) {
  final normalised = hour % 24;
  final suffix = normalised < 12 ? 'AM' : 'PM';
  final twelveHour = normalised % 12 == 0 ? 12 : normalised % 12;
  return '$twelveHour $suffix';
}

String formatOpenStatus(RankedPlace entry) {
  final place = entry.place;
  return entry.isOpen
      ? 'Open until ${formatHour(place.closesAtHour)}'
      : 'Closed, opens ${formatHour(place.opensAtHour)}';
}

String formatPrice(int priceLevel) => r'$' * priceLevel;

extension RouteManeuverDisplay on RouteManeuver {
  IconData get icon => switch (this) {
    RouteManeuver.start => Icons.directions_walk,
    RouteManeuver.continueStraight => Icons.straight,
    RouteManeuver.turnLeft => Icons.turn_left,
    RouteManeuver.turnRight => Icons.turn_right,
    RouteManeuver.arrive => Icons.flag,
  };
}

/// 13 minutes becomes "13 min", and 75 minutes becomes "1 hr 15 min".
String formatWalkingTime(Duration time) {
  final hours = time.inHours;
  final minutes = time.inMinutes % 60;
  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
}

String formatRouteStep(RouteStep step, String placeName) {
  final street = step.streetName;
  return switch (step.maneuver) {
    RouteManeuver.start => 'Head ${_headingName(step.heading!)} on $street',
    RouteManeuver.continueStraight => 'Continue onto $street',
    RouteManeuver.turnLeft => 'Turn left onto $street',
    RouteManeuver.turnRight => 'Turn right onto $street',
    RouteManeuver.arrive => 'Arrive at $placeName',
  };
}

String _headingName(CompassHeading heading) => switch (heading) {
  CompassHeading.north => 'north',
  CompassHeading.northEast => 'north-east',
  CompassHeading.east => 'east',
  CompassHeading.southEast => 'south-east',
  CompassHeading.south => 'south',
  CompassHeading.southWest => 'south-west',
  CompassHeading.west => 'west',
  CompassHeading.northWest => 'north-west',
};

/// Says where a route begins, which isn't the user if their position is unknown.
String routeOrigin(UserPosition position) {
  return position.isFallback
      ? 'Starting from ${position.area.centreName}'
      : 'Starting from your location';
}

/// Where a distance is measured from, worded to follow the distance.
String distanceOrigin(UserPosition position) {
  return position.isFallback ? 'from ${position.area.centreName}' : 'from you';
}

/// Explains in plain words why a place ranks where it does.
String rankingReason(RankedPlace entry, UserPosition position) {
  final place = entry.place;
  final distance = formatDistance(entry.distanceKm);
  return 'Rated ${place.rating.toStringAsFixed(1)} by '
      '${formatCount(place.reviewCount)} people, $distance '
      '${distanceOrigin(position)}.';
}

/// Explains why distances aren't from the device position, when they aren't.
String? positionNotice(UserPosition? position) {
  if (position == null) return null;
  final centre = position.area.centreName;
  return switch (position.source) {
    PositionSource.device => null,
    PositionSource.fallbackNoAccess =>
      'Your location is unavailable, so distances start from $centre. Check '
          'that location is on for this app, then tap Use my location.',
    PositionSource.fallbackOutsideArea =>
      'You are outside ${position.area.name}, the only area with places so '
          'far. Distances start from $centre.',
  };
}
