import 'package:flutter/material.dart';

import 'features/places/presentation/pages/directions_page.dart';
import 'features/places/presentation/pages/place_details_page.dart';
import 'features/places/presentation/pages/search_page.dart';
import 'features/places/presentation/place_routes.dart';

/// Turns a route name into a screen. This is the only file that knows which
/// page belongs to each route.
abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch ((settings.name, settings.arguments)) {
      (PlaceRoutes.details, final PlaceRouteArgs args) => PlaceDetailsPage(
        entry: args.entry,
        position: args.position,
      ),
      (PlaceRoutes.directions, final PlaceRouteArgs args) => DirectionsPage(
        entry: args.entry,
        position: args.position,
      ),
      // An unknown route, or one missing what it needs, goes to the search screen.
      _ => const SearchPage(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
