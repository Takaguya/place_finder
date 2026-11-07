import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/entities/place_query.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
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
    location: northOfCentre(0.2),
  );
  final mall = testPlace(
    id: 'mall',
    name: 'Big Mall',
    category: PlaceCategory.mall,
    location: northOfCentre(1),
  );
  final nightSpot = testPlace(
    id: 'night',
    name: 'Night Spot',
    opensAtHour: 17,
    closesAtHour: 2,
    location: northOfCentre(2),
  );
  final places = [cafe, mall, nightSpot];

  PlaceSearchBloc buildBloc({
    PlaceRepository? placeRepository,
    LocationRepository? locationRepository,
  }) {
    return PlaceSearchBloc(
      getUserPosition: GetUserPosition(
        locationRepository ??
            FakeLocationRepository(Success(northOfCentre(0.1))),
        serviceArea: testArea,
      ),
      searchPlaces: SearchPlaces(
        placeRepository ?? FakePlaceRepository(places),
        clock: () => testNoon,
      ),
    );
  }

  /// Lets everything already scheduled finish, including async event handlers.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<String> idsOf(PlaceSearchState state) => [
    for (final entry in state.results) entry.place.id,
  ];

  group('starting', () {
    test('begins in the locating state with nothing to show', () {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state.status, PlaceSearchStatus.locating);
      expect(bloc.state.isLoading, isTrue);
    });

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'finds the user, then publishes ranked results',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlaceSearchStarted()),
      verify: (bloc) {
        expect(bloc.state.status, PlaceSearchStatus.ready);
        expect(bloc.state.position?.source, PositionSource.device);
        expect(idsOf(bloc.state), hasLength(places.length));
        expect(bloc.state.isLoading, isFalse);
      },
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'still shows results when location access is refused',
      build: () => buildBloc(
        locationRepository: FakeLocationRepository(
          const Failed(Failure('Refused.')),
        ),
      ),
      act: (bloc) => bloc.add(const PlaceSearchStarted()),
      verify: (bloc) {
        expect(bloc.state.status, PlaceSearchStatus.ready);
        expect(bloc.state.position?.isFallback, isTrue);
        expect(idsOf(bloc.state), isNotEmpty);
      },
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'publishes the failure message when places cannot be loaded',
      build: () => buildBloc(
        placeRepository: FakePlaceRepository(
          const [],
          failure: const Failure('Places could not be loaded.'),
        ),
      ),
      act: (bloc) => bloc.add(const PlaceSearchStarted()),
      verify: (bloc) {
        expect(bloc.state.status, PlaceSearchStatus.failure);
        expect(bloc.state.errorMessage, 'Places could not be loaded.');
        expect(bloc.state.results, isEmpty);
      },
    );

    test('keeps text typed while the location is still being found', () async {
      final location = ManualLocationRepository();
      final bloc = buildBloc(locationRepository: location);
      addTearDown(bloc.close);

      bloc.add(const PlaceSearchStarted());
      await settle();
      bloc.add(const SearchTextChanged('mall'));
      await settle();
      location.request.complete(Success(northOfCentre(0.1)));
      await settle();

      expect(bloc.state.query.text, 'mall');
      expect(idsOf(bloc.state), ['mall']);
    });
  });

  group('changing the search', () {
    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'filters by text',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PlaceSearchStarted());
        await settle();
        bloc.add(const SearchTextChanged('corner'));
      },
      verify: (bloc) => expect(idsOf(bloc.state), ['cafe']),
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'filters by category, and null brings every category back',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PlaceSearchStarted());
        await settle();
        bloc.add(const CategorySelected(PlaceCategory.mall));
        await settle();
        expect(idsOf(bloc.state), ['mall']);
        bloc.add(const CategorySelected(null));
      },
      verify: (bloc) => expect(idsOf(bloc.state), hasLength(places.length)),
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'open now switches on and off',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PlaceSearchStarted());
        await settle();
        bloc.add(const OpenNowToggled());
        await settle();
        expect(idsOf(bloc.state), isNot(contains('night')));
        bloc.add(const OpenNowToggled());
      },
      verify: (bloc) => expect(idsOf(bloc.state), contains('night')),
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'changing the sort order re-ranks the results',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PlaceSearchStarted());
        await settle();
        bloc.add(const SortModeChanged(SortMode.closest));
      },
      verify: (bloc) {
        expect(bloc.state.query.sortMode, SortMode.closest);
        expect(idsOf(bloc.state), ['cafe', 'mall', 'night']);
      },
    );

    blocTest<PlaceSearchBloc, PlaceSearchState>(
      'clearing filters keeps the sort order',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const PlaceSearchStarted());
        await settle();
        bloc.add(const SortModeChanged(SortMode.topRated));
        bloc.add(const SearchTextChanged('nothing matches this'));
        await settle();
        expect(bloc.state.results, isEmpty);
        bloc.add(const FiltersCleared());
      },
      verify: (bloc) {
        expect(bloc.state.query.text, isEmpty);
        expect(bloc.state.query.sortMode, SortMode.topRated);
        expect(idsOf(bloc.state), hasLength(places.length));
      },
    );

    test('a slow older search cannot overwrite a newer one', () async {
      final repository = ManualPlaceRepository();
      final bloc = buildBloc(placeRepository: repository);
      addTearDown(bloc.close);

      bloc.add(const PlaceSearchStarted());
      await settle();
      repository.requests[0].complete(Success(places));
      await settle();

      bloc.add(const SearchTextChanged('corner'));
      await settle();
      bloc.add(const SearchTextChanged('mall'));
      await settle();

      // The newer search answers first, then the older one arrives late.
      repository.requests[2].complete(Success(places));
      await settle();
      repository.requests[1].complete(Success(places));
      await settle();

      expect(bloc.state.query.text, 'mall');
      expect(idsOf(bloc.state), ['mall']);
    });

    test('keeps old results on screen while a new search runs', () async {
      final repository = ManualPlaceRepository();
      final bloc = buildBloc(placeRepository: repository);
      addTearDown(bloc.close);

      bloc.add(const PlaceSearchStarted());
      await settle();
      repository.requests[0].complete(Success(places));
      await settle();

      bloc.add(const SearchTextChanged('mall'));
      await settle();

      expect(bloc.state.status, PlaceSearchStatus.searching);
      expect(bloc.state.isLoading, isFalse);
      expect(idsOf(bloc.state), hasLength(places.length));
    });
  });
}
