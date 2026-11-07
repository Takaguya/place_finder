import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/ranked_place.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';
import 'package:place_finder/features/places/domain/usecases/get_walking_route.dart';
import 'package:place_finder/features/places/domain/usecases/open_in_maps_app.dart';
import 'package:place_finder/features/places/presentation/pages/directions_page.dart';

import '../../../helpers/fakes.dart';

void main() {
  final entry = RankedPlace(
    place: testPlace(name: 'Corner Cafe', location: northOfCentre(1)),
    rank: 1,
    distanceKm: 1,
    isOpen: true,
  );
  const fromDevice = UserPosition(
    point: testCentre,
    source: PositionSource.device,
    area: testArea,
  );

  /// Opens [page] at a phone's size, using the given fake repositories.
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    required FakeRouteRepository routes,
    FakeMapsAppRepository? mapsApp,
  }) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: GetWalkingRoute(routes)),
          RepositoryProvider.value(
            value: OpenInMapsApp(mapsApp ?? FakeMapsAppRepository()),
          ),
        ],
        child: MaterialApp(home: page),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapAndWait(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows how long the walk takes and how far it is', (tester) async {
    await pumpPage(
      tester,
      DirectionsPage(entry: entry, position: fromDevice),
      routes: FakeRouteRepository(Success(testRoute)),
    );

    expect(find.text('15 min walk'), findsOneWidget);
    expect(find.text('1.2 km to Corner Cafe'), findsOneWidget);
    expect(find.text('Starting from your location'), findsOneWidget);
  });

  testWidgets('lists each instruction with the distance to walk', (tester) async {
    await pumpPage(
      tester,
      DirectionsPage(entry: entry, position: fromDevice),
      routes: FakeRouteRepository(Success(testRoute)),
    );

    expect(find.text('Head north on Norodom Blvd'), findsOneWidget);
    expect(find.text('400 m'), findsOneWidget);
    expect(find.text('Turn left onto Sihanouk Blvd'), findsOneWidget);
    expect(find.text('800 m'), findsOneWidget);
    expect(find.text('Arrive at Corner Cafe'), findsOneWidget);
  });

  testWidgets('says so when the route does not start from the user', (
    tester,
  ) async {
    const fallback = UserPosition(
      point: testCentre,
      source: PositionSource.fallbackNoAccess,
      area: testArea,
    );

    await pumpPage(
      tester,
      DirectionsPage(entry: entry, position: fallback),
      routes: FakeRouteRepository(Success(testRoute)),
    );

    expect(find.text('Starting from Independence Monument'), findsOneWidget);
  });

  testWidgets('a failure explains itself, and trying again can work', (
    tester,
  ) async {
    final routes = FakeRouteRepository(
      const Failed<WalkingRoute>(Failure('No route today.')),
    );
    await pumpPage(
      tester,
      DirectionsPage(entry: entry, position: fromDevice),
      routes: routes,
    );

    expect(find.text('No route today.'), findsOneWidget);

    routes.result = Success(testRoute);
    await tapAndWait(tester, 'Try again');

    expect(find.text('15 min walk'), findsOneWidget);
    expect(find.text('No route today.'), findsNothing);
  });

  group('open in Google Maps', () {
    testWidgets('asks for the place the page is showing', (tester) async {
      final mapsApp = FakeMapsAppRepository();
      await pumpPage(
        tester,
        DirectionsPage(entry: entry, position: fromDevice),
        routes: FakeRouteRepository(Success(testRoute)),
        mapsApp: mapsApp,
      );

      await tapAndWait(tester, 'Open in Google Maps');

      expect(mapsApp.opened, [entry.place.location]);
    });

    testWidgets('a failure shows a message and keeps the route', (tester) async {
      await pumpPage(
        tester,
        DirectionsPage(entry: entry, position: fromDevice),
        routes: FakeRouteRepository(Success(testRoute)),
        mapsApp: FakeMapsAppRepository(
          result: const Failed<void>(Failure('No maps app.')),
        ),
      );

      await tapAndWait(tester, 'Open in Google Maps');

      expect(find.text('No maps app.'), findsOneWidget);
      expect(find.text('15 min walk'), findsOneWidget);
    });
  });
}
