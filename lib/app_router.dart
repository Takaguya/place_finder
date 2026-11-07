import 'package:go_router/go_router.dart';

import 'features/places/presentation/pages/directions_page.dart';
import 'features/places/presentation/pages/place_details_page.dart';
import 'features/places/presentation/pages/search_page.dart';
import 'features/places/presentation/place_routes.dart';

/// Builds the app's routes. This is the only file that knows which page belongs
/// to each route. The nesting sets what Back does: directions goes back to
/// details, and details goes back to search.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: PlaceRoutes.search,
    // An address that matches no route goes to the search screen.
    onException: (_, _, router) => router.go(PlaceRoutes.search),
    routes: [
      GoRoute(
        path: PlaceRoutes.search,
        builder: (_, _) => const SearchPage(),
        routes: [
          GoRoute(
            path: 'place',
            // Both screens from here on need a place, so without one, go to search.
            redirect: (_, state) =>
                state.extra is PlaceRouteArgs ? null : PlaceRoutes.search,
            builder: (_, state) {
              final args = state.extra! as PlaceRouteArgs;
              return PlaceDetailsPage(
                entry: args.entry,
                position: args.position,
              );
            },
            routes: [
              GoRoute(
                path: 'directions',
                builder: (_, state) {
                  final args = state.extra! as PlaceRouteArgs;
                  return DirectionsPage(
                    entry: args.entry,
                    position: args.position,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
