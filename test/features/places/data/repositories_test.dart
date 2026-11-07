import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/data/datasources/location_data_source.dart';
import 'package:place_finder/features/places/data/datasources/place_data_source.dart';
import 'package:place_finder/features/places/data/datasources/route_data_source.dart';
import 'package:place_finder/features/places/data/models/place_model.dart';
import 'package:place_finder/features/places/data/repositories/location_repository_impl.dart';
import 'package:place_finder/features/places/data/repositories/place_repository_impl.dart';
import 'package:place_finder/features/places/data/repositories/route_repository_impl.dart';
import 'package:place_finder/features/places/domain/entities/geo_point.dart';
import 'package:place_finder/features/places/domain/entities/place.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';

import '../../../helpers/fakes.dart';

Map<String, dynamic> placeJson({String category = 'mall'}) => {
  'id': 'mall-1',
  'name': 'Test Mall',
  'category': category,
  'rating': 4.5,
  'reviews': 120,
  'price': 2,
  'area': 'BKK1',
  'lat': 11.55,
  'lng': 104.92,
  'opens': 9,
  'closes': 22,
  'summary': 'A mall.',
};

class FakePlaceSource implements PlaceDataSource {
  FakePlaceSource(this.fetch);

  final List<PlaceModel> Function() fetch;

  @override
  Future<List<PlaceModel>> fetchPlaces() async => fetch();
}

class FakeLocationSource implements LocationDataSource {
  FakeLocationSource(this.get);

  final GeoPoint Function() get;

  @override
  Future<GeoPoint> getCurrentPoint() async => get();
}

class FakeRouteSource implements RouteDataSource {
  FakeRouteSource(this.fetch);

  final WalkingRoute Function() fetch;

  @override
  Future<WalkingRoute> fetchWalkingRoute({
    required GeoPoint from,
    required GeoPoint to,
  }) async => fetch();
}

void main() {
  group('PlaceModel', () {
    test('turns its data into a place', () {
      final place = PlaceModel.fromJson(placeJson()).toEntity();

      expect(place.id, 'mall-1');
      expect(place.name, 'Test Mall');
      expect(place.category, PlaceCategory.mall);
      expect(place.rating, 4.5);
      expect(place.reviewCount, 120);
      expect(place.priceLevel, 2);
      expect(place.neighbourhood, 'BKK1');
      expect(place.location, const GeoPoint(11.55, 104.92));
      expect(place.opensAtHour, 9);
      expect(place.closesAtHour, 22);
      expect(place.summary, 'A mall.');
    });

    test('accepts a whole number for a rating', () {
      final json = placeJson()..['rating'] = 4;

      expect(PlaceModel.fromJson(json).toEntity().rating, 4.0);
    });

    test('rejects a category it does not know', () {
      final model = PlaceModel.fromJson(placeJson(category: 'zoo'));

      expect(model.toEntity, throwsFormatException);
    });
  });

  group('PlaceRepositoryImpl', () {
    test('returns the places it is given', () async {
      final repository = PlaceRepositoryImpl(
        FakePlaceSource(() => [PlaceModel.fromJson(placeJson())]),
      );

      final result = await repository.getPlaces();

      expect((result as Success<List<Place>>).value.single.name, 'Test Mall');
    });

    test('turns a source error into a failure', () async {
      final repository = PlaceRepositoryImpl(
        FakePlaceSource(() => throw Exception('Offline')),
      );

      expect(await repository.getPlaces(), isA<Failed<List<Place>>>());
    });

    test('turns bad data into a failure instead of crashing', () async {
      final repository = PlaceRepositoryImpl(
        FakePlaceSource(() => [PlaceModel.fromJson(placeJson(category: 'zoo'))]),
      );

      expect(await repository.getPlaces(), isA<Failed<List<Place>>>());
    });
  });

  group('LocationRepositoryImpl', () {
    test('returns the point it is given', () async {
      final repository = LocationRepositoryImpl(
        FakeLocationSource(() => testCentre),
      );

      final result = await repository.getCurrentPoint();

      expect((result as Success<GeoPoint>).value, testCentre);
    });

    test('gives a plain message, not technical details', () async {
      final repository = LocationRepositoryImpl(
        FakeLocationSource(() => throw Exception('PlatformException(ERROR_42)')),
      );

      final result = await repository.getCurrentPoint();

      expect(
        (result as Failed<GeoPoint>).failure.message,
        'Your location is unavailable.',
      );
    });
  });

  group('RouteRepositoryImpl', () {
    test('returns the route it is given', () async {
      final repository = RouteRepositoryImpl(FakeRouteSource(() => testRoute));

      final result = await repository.getWalkingRoute(
        from: testCentre,
        to: northOfCentre(1),
      );

      expect((result as Success<WalkingRoute>).value, testRoute);
    });

    test('turns a missing route into a failure', () async {
      final repository = RouteRepositoryImpl(
        FakeRouteSource(() => throw const RouteNotFoundException()),
      );

      final result = await repository.getWalkingRoute(
        from: testCentre,
        to: northOfCentre(1),
      );

      expect(result, isA<Failed<WalkingRoute>>());
    });
  });
}
