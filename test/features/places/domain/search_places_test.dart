import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/entities/place_query.dart';
import 'package:place_finder/features/places/domain/entities/ranked_place.dart';
import 'package:place_finder/features/places/domain/usecases/search_places.dart';

import '../../../helpers/fakes.dart';

void main() {
  final nearCafe = testPlace(
    id: 'near-cafe',
    name: 'Near Cafe',
    category: PlaceCategory.cafe,
    summary: 'A small roastery.',
    rating: 4,
    reviewCount: 1000,
    location: northOfCentre(0.2),
  );
  final goodRestaurant = testPlace(
    id: 'good-restaurant',
    name: 'Good Noodles',
    neighbourhood: 'BKK1',
    rating: 4.7,
    reviewCount: 1000,
    location: northOfCentre(1),
  );
  final farMall = testPlace(
    id: 'far-mall',
    name: 'Far Mall',
    category: PlaceCategory.mall,
    neighbourhood: 'Sen Sok',
    rating: 4.9,
    reviewCount: 1000,
    location: northOfCentre(12),
  );
  final nightPlace = testPlace(
    id: 'night-place',
    name: 'Night Place',
    opensAtHour: 17,
    closesAtHour: 2,
    location: northOfCentre(3),
  );
  final places = [nearCafe, goodRestaurant, farMall, nightPlace];

  Future<List<RankedPlace>> search(PlaceQuery query, {DateTime? at}) async {
    final useCase = SearchPlaces(
      FakePlaceRepository(places),
      clock: () => at ?? testNoon,
    );
    final result = await useCase(query: query, from: testCentre);
    return (result as Success<List<RankedPlace>>).value;
  }

  List<String> idsOf(List<RankedPlace> results) => [
    for (final entry in results) entry.place.id,
  ];

  group('filtering', () {
    test('returns everything for an empty query', () async {
      final results = await search(const PlaceQuery());

      expect(results, hasLength(places.length));
    });

    test('keeps only the selected category', () async {
      final results = await search(
        const PlaceQuery(category: PlaceCategory.mall),
      );

      expect(idsOf(results), ['far-mall']);
    });

    test('matches every word, in any order and any case', () async {
      final results = await search(const PlaceQuery(text: 'bkk1 NOODLES'));

      expect(idsOf(results), ['good-restaurant']);
    });

    test('finds a category by its name, not inside another word', () async {
      final results = await search(const PlaceQuery(text: 'mall'));

      // Near Cafe's summary says "small", which must not count as "mall".
      expect(idsOf(results), ['far-mall']);
    });

    test('finds a category by the plural the search hint suggests', () async {
      final results = await search(const PlaceQuery(text: 'malls'));

      expect(idsOf(results), ['far-mall']);
    });

    test('finds a category by an everyday word', () async {
      final food = await search(const PlaceQuery(text: 'food'));
      final coffee = await search(const PlaceQuery(text: 'coffee'));

      expect(idsOf(food), unorderedEquals(['good-restaurant', 'night-place']));
      expect(idsOf(coffee), ['near-cafe']);
    });

    test('matches the start of a word while it is still being typed', () async {
      final results = await search(const PlaceQuery(text: 'nood'));

      expect(idsOf(results), ['good-restaurant']);
    });

    test('finds nothing when one word has no match', () async {
      final results = await search(const PlaceQuery(text: 'noodles pizza'));

      expect(results, isEmpty);
    });

    test('open now leaves out places that are closed', () async {
      final results = await search(const PlaceQuery(openNowOnly: true));

      expect(idsOf(results), isNot(contains('night-place')));
      expect(results, hasLength(places.length - 1));
    });
  });

  group('opening hours', () {
    test('a place closing after midnight is open late and shut at noon', () {
      expect(nightPlace.isOpenAt(DateTime(2026, 11, 6, 23)), isTrue);
      expect(nightPlace.isOpenAt(DateTime(2026, 11, 7, 1)), isTrue);
      expect(nightPlace.isOpenAt(DateTime(2026, 11, 7, 2)), isFalse);
      expect(nightPlace.isOpenAt(testNoon), isFalse);
    });

    test('each result says whether it is open at the time of the search', () async {
      final atNoon = await search(const PlaceQuery(text: 'night'));
      final atNight = await search(
        const PlaceQuery(text: 'night'),
        at: DateTime(2026, 11, 6, 23),
      );

      expect(atNoon.single.isOpen, isFalse);
      expect(atNight.single.isOpen, isTrue);
    });
  });

  group('ordering', () {
    test('ranks start at 1 and follow the order of the results', () async {
      final results = await search(const PlaceQuery());

      expect([for (final entry in results) entry.rank], [1, 2, 3, 4]);
    });

    test('best match puts a good, close place first', () async {
      final results = await search(const PlaceQuery());

      expect(results.first.place.id, 'good-restaurant');
    });

    test('closest sorts by distance alone', () async {
      final results = await search(
        const PlaceQuery(sortMode: SortMode.closest),
      );

      expect(idsOf(results), [
        'near-cafe',
        'good-restaurant',
        'night-place',
        'far-mall',
      ]);
    });

    test('top rated sorts by rating alone', () async {
      final results = await search(
        const PlaceQuery(sortMode: SortMode.topRated),
      );

      expect(results.first.place.id, 'far-mall');
      expect(results.last.place.id, 'near-cafe');
    });

    test('reports the distance from the given point', () async {
      final results = await search(const PlaceQuery(text: 'noodles'));

      expect(results.single.distanceKm, closeTo(1, 0.01));
    });
  });

  test('passes a repository failure through to the caller', () async {
    final useCase = SearchPlaces(
      FakePlaceRepository(const [], failure: const Failure('Offline.')),
    );

    final result = await useCase(query: const PlaceQuery(), from: testCentre);

    expect(result, isA<Failed<List<RankedPlace>>>());
    expect((result as Failed<List<RankedPlace>>).failure.message, 'Offline.');
  });
}
