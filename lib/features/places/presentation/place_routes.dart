import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/ranked_place.dart';
import '../domain/entities/user_position.dart';

/// What the place details and directions screens need in order to open.
class PlaceRouteArgs {
  const PlaceRouteArgs({required this.entry, required this.position});

  final RankedPlace entry;
  final UserPosition position;
}

/// The screens in this feature, and how to open them. Pages use these instead
/// of importing each other, so no page knows how another one is built.
abstract final class PlaceRoutes {
  static const String search = '/';
  static const String details = '/place';
  static const String directions = '/place/directions';

  static void openDetails(BuildContext context, PlaceRouteArgs args) {
    context.go(details, extra: args);
  }

  static void openDirections(BuildContext context, PlaceRouteArgs args) {
    context.go(directions, extra: args);
  }
}
