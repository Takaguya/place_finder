import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:place_finder/app_router.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/ranked_place.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
import 'package:place_finder/features/places/domain/usecases/get_user_position.dart';
import 'package:place_finder/features/places/domain/usecases/get_walking_route.dart';
import 'package:place_finder/features/places/domain/usecases/open_in_maps_app.dart';
import 'package:place_finder/features/places/domain/usecases/search_places.dart';
import 'package:place_finder/features/places/presentation/bloc/place_search_bloc.dart';
import 'package:place_finder/features/places/presentation/pages/directions_page.dart';
import 'package:place_finder/features/places/presentation/pages/place_details_page.dart';
import 'package:place_finder/features/places/presentation/pages/search_page.dart';
import 'package:place_finder/features/places/presentation/place_routes.dart';
import 'package:place_finder/features/places/presentation/widgets/atoms/map_back_button.dart';

import 'helpers/fakes.dart';

void main() {
  final cafe = testPlace(name: 'Corner Cafe', location: northOfCentre(0.2));
  final args = PlaceRouteArgs(
    entry: RankedPlace(place: cafe, rank: 1, distanceKm: 0.2, isOpen: true),
    position: const UserPosition(
      point: testCentre,
      source: PositionSource.device,
      area: testArea,
    ),
  );

  /// The map's route never stops moving, so this pumps for a set time instead
  /// of pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Starts on the first route at a phone's size, using fake repositories.
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(
            value: GetWalkingRoute(FakeRouteRepository(Success(testRoute))),
          ),
          RepositoryProvider.value(
            value: OpenInMapsApp(FakeMapsAppRepository()),
          ),
        ],
        child: BlocProvider(
          create: (_) => PlaceSearchBloc(
            getUserPosition: GetUserPosition(
              FakeLocationRepository(Success(northOfCentre(0.1))),
              serviceArea: testArea,
            ),
            searchPlaces: SearchPlaces(
              FakePlaceRepository([cafe]),
              clock: () => testNoon,
            ),
          )..add(const PlaceSearchStarted()),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await settle(tester);
    return router;
  }

  String locationOf(GoRouter router) {
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  BuildContext searchContext(WidgetTester tester) {
    return tester.element(find.byType(SearchPage));
  }

  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('the first route is the search screen', (tester) async {
    final router = await pumpApp(tester);

    expect(find.byType(SearchPage), findsOneWidget);
    expect(locationOf(router), PlaceRoutes.search);
  });

  testWidgets('openDetails opens the place it was given', (tester) async {
    final router = await pumpApp(tester);

    PlaceRoutes.openDetails(searchContext(tester), args);
    await settle(tester);

    final page = tester.widget<PlaceDetailsPage>(find.byType(PlaceDetailsPage));
    expect(page.entry, args.entry);
    expect(page.position, args.position);
    expect(locationOf(router), PlaceRoutes.details);
  });

  testWidgets('openDirections opens the place it was given', (tester) async {
    final router = await pumpApp(tester);

    PlaceRoutes.openDirections(searchContext(tester), args);
    await settle(tester);

    final page = tester.widget<DirectionsPage>(find.byType(DirectionsPage));
    expect(page.entry, args.entry);
    expect(page.position, args.position);
    expect(locationOf(router), PlaceRoutes.directions);
  });

  group('an address that cannot open goes to the search screen', () {
    Future<void> goAndExpectSearch(
      WidgetTester tester,
      String location, {
      Object? extra,
    }) async {
      final router = await pumpApp(tester);

      router.go(location, extra: extra);
      await settle(tester);

      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byType(PlaceDetailsPage), findsNothing);
      expect(find.byType(DirectionsPage), findsNothing);
      expect(locationOf(router), PlaceRoutes.search);
    }

    testWidgets('when it matches no route', (tester) async {
      await goAndExpectSearch(tester, '/nowhere');
    });

    testWidgets('when details has no place', (tester) async {
      await goAndExpectSearch(tester, PlaceRoutes.details);
    });

    testWidgets('when directions has no place', (tester) async {
      await goAndExpectSearch(tester, PlaceRoutes.directions);
    });

    testWidgets('when directions has the wrong kind of data', (tester) async {
      await goAndExpectSearch(
        tester,
        PlaceRoutes.directions,
        extra: 'Corner Cafe',
      );
    });
  });

  testWidgets('the on-screen button goes back through the screens', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tapAndWait(tester, find.text('Corner Cafe'));
    expect(find.byType(PlaceDetailsPage), findsOneWidget);

    await tapAndWait(tester, find.text('Get directions'));
    expect(find.byType(DirectionsPage), findsOneWidget);
    expect(find.text('15 min walk'), findsOneWidget);
    expect(find.text('Head north on Norodom Blvd'), findsOneWidget);

    await tapAndWait(tester, find.byType(MapBackButton));
    expect(find.byType(DirectionsPage), findsNothing);
    expect(find.byType(PlaceDetailsPage), findsOneWidget);
    expect(locationOf(router), PlaceRoutes.details);

    await tapAndWait(tester, find.byType(MapBackButton));
    expect(find.byType(PlaceDetailsPage), findsNothing);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(locationOf(router), PlaceRoutes.search);
  });

  testWidgets('the Android Back key goes back through the screens', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    PlaceRoutes.openDirections(searchContext(tester), args);
    await settle(tester);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(PlaceDetailsPage), findsOneWidget);
    expect(locationOf(router), PlaceRoutes.details);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(SearchPage), findsOneWidget);
    expect(locationOf(router), PlaceRoutes.search);
  });
}
