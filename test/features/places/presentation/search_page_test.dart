import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/app_router.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/repositories/location_repository.dart';
import 'package:place_finder/features/places/domain/repositories/place_repository.dart';
import 'package:place_finder/features/places/domain/usecases/get_user_position.dart';
import 'package:place_finder/features/places/domain/usecases/search_places.dart';
import 'package:place_finder/features/places/presentation/bloc/place_search_bloc.dart';

import '../../../helpers/fakes.dart';

void main() {
  final cafe = testPlace(
    id: 'cafe',
    name: 'Corner Cafe',
    category: PlaceCategory.cafe,
    rating: 4.7,
    reviewCount: 1000,
    location: northOfCentre(0.2),
  );
  final mall = testPlace(
    id: 'mall',
    name: 'Big Mall',
    category: PlaceCategory.mall,
    rating: 4.2,
    reviewCount: 800,
    location: northOfCentre(1),
  );

  /// Opens the search screen at a phone's size. The map's route never stops
  /// moving, so these tests pump for a set time instead of pumpAndSettle.
  Future<void> pumpSearchPage(
    WidgetTester tester, {
    PlaceRepository? placeRepository,
    LocationRepository? locationRepository,
  }) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => PlaceSearchBloc(
          getUserPosition: GetUserPosition(
            locationRepository ??
                FakeLocationRepository(Success(northOfCentre(0.1))),
            serviceArea: testArea,
          ),
          searchPlaces: SearchPlaces(
            placeRepository ?? FakePlaceRepository([cafe, mall]),
            clock: () => testNoon,
          ),
        )..add(const PlaceSearchStarted()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows ranked results with the first one as the top pick', (
    tester,
  ) async {
    await pumpSearchPage(tester);

    expect(find.text('Good and close'), findsOneWidget);
    expect(find.text('2 places'), findsOneWidget);
    expect(find.text('Top pick'), findsOneWidget);
    expect(find.text('Corner Cafe'), findsOneWidget);
    expect(find.text('Big Mall'), findsOneWidget);
    expect(find.bySemanticsLabel('Number 1, Corner Cafe'), findsOneWidget);
  });

  testWidgets('typing narrows the results', (tester) async {
    await pumpSearchPage(tester);

    await tester.enterText(find.byType(TextField), 'mall');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Big Mall'), findsOneWidget);
    expect(find.text('Corner Cafe'), findsNothing);
    expect(find.text('1 place'), findsOneWidget);
  });

  testWidgets('a category pill narrows the results', (tester) async {
    await pumpSearchPage(tester);

    await tapAndWait(tester, find.text('Malls'));

    expect(find.text('Big Mall'), findsOneWidget);
    expect(find.text('Corner Cafe'), findsNothing);
  });

  testWidgets('sorting changes the heading and the top result', (tester) async {
    await pumpSearchPage(tester);

    await tapAndWait(tester, find.text('Top rated'));

    expect(find.text('Highest rated first'), findsOneWidget);
    expect(find.text('Highest rated'), findsOneWidget);
  });

  testWidgets('no matches offers a way out that also clears the search box', (
    tester,
  ) async {
    await pumpSearchPage(tester);

    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No places match'), findsOneWidget);

    await tapAndWait(tester, find.text('Clear filters'));

    expect(find.text('Corner Cafe'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('a failure explains itself and offers to try again', (
    tester,
  ) async {
    await pumpSearchPage(
      tester,
      placeRepository: FakePlaceRepository(
        const [],
        failure: const Failure('Places could not be loaded.'),
      ),
    );

    expect(find.text('Places could not be loaded.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  group('when the keyboard opens and closes', () {
    Future<void> setKeyboardHeight(WidgetTester tester, double height) async {
      tester.view.viewInsets = FakeViewPadding(bottom: height);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('the sheet returns to where it was, with one result', (
      tester,
    ) async {
      await pumpSearchPage(tester);
      await tester.enterText(find.byType(TextField), 'mall');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1 place'), findsOneWidget);

      double sheetTop() => tester.getTopLeft(find.text('Good and close')).dy;
      final before = sheetTop();

      await setKeyboardHeight(tester, 340);
      expect(sheetTop(), lessThan(before));

      await setKeyboardHeight(tester, 0);
      expect(sheetTop(), before);
    });

    testWidgets('the map stays still', (tester) async {
      await pumpSearchPage(tester);
      final pin = find.bySemanticsLabel('Number 1, Corner Cafe');
      final before = tester.getCenter(pin);

      await setKeyboardHeight(tester, 340);

      expect(tester.getCenter(pin), before);
    });
  });

  testWidgets('refusing location can be undone without restarting the app', (
    tester,
  ) async {
    final location = FakeLocationRepository(const Failed(Failure('Refused.')));
    await pumpSearchPage(tester, locationRepository: location);

    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Top pick'), findsOneWidget);

    location.result = Success(northOfCentre(0.1));
    await tapAndWait(tester, find.text('Use my location'));

    expect(find.text('Use my location'), findsNothing);
    expect(find.text('Top pick'), findsOneWidget);
  });

  testWidgets('tapping a result opens its details', (tester) async {
    await pumpSearchPage(tester);

    await tapAndWait(tester, find.text('Big Mall'));

    expect(find.text('Get directions'), findsOneWidget);
    expect(find.text('Why it is number 2'), findsOneWidget);
    expect(find.text('800 reviews'), findsOneWidget);
  });

  testWidgets('tapping a pin opens its details', (tester) async {
    await pumpSearchPage(tester);

    await tapAndWait(tester, find.bySemanticsLabel('Number 2, Big Mall'));

    expect(find.text('Get directions'), findsOneWidget);
  });
}
