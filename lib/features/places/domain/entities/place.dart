import 'package:equatable/equatable.dart';

import 'geo_point.dart';

enum PlaceCategory { mall, restaurant, cafe, market }

/// A place someone can visit.
class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.neighbourhood,
    required this.location,
    required this.opensAtHour,
    required this.closesAtHour,
    required this.summary,
  });

  final String id;
  final String name;
  final PlaceCategory category;

  /// Average review score from 0 to 5.
  final double rating;
  final int reviewCount;

  /// From 1 (cheapest) to 4 (most expensive).
  final int priceLevel;
  final String neighbourhood;
  final GeoPoint location;

  /// Opening hour on a 24-hour clock.
  final int opensAtHour;

  /// Closing hour on a 24-hour clock. A value at or below [opensAtHour] means
  /// the place closes after midnight.
  final int closesAtHour;
  final String summary;

  bool isOpenAt(DateTime time) {
    final hour = time.hour;
    if (closesAtHour > opensAtHour) {
      return hour >= opensAtHour && hour < closesAtHour;
    }
    return hour >= opensAtHour || hour < closesAtHour;
  }

  @override
  List<Object> get props => [id];
}
