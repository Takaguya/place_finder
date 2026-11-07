import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/core/result.dart';
import 'package:place_finder/features/places/domain/entities/geo_point.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
import 'package:place_finder/features/places/domain/usecases/get_user_position.dart';

import '../../../helpers/fakes.dart';

void main() {
  Future<UserPosition> positionFor(Result<GeoPoint> deviceResult) {
    final useCase = GetUserPosition(
      FakeLocationRepository(deviceResult),
      serviceArea: testArea,
    );
    return useCase();
  }

  test('uses the device position inside the service area', () async {
    final nearby = northOfCentre(5);

    final position = await positionFor(Success(nearby));

    expect(position.point, nearby);
    expect(position.source, PositionSource.device);
    expect(position.isFallback, isFalse);
  });

  test('falls back to the area centre when the device is far away', () async {
    final position = await positionFor(
      const Success(GeoPoint(51.5074, -0.1278)),
    );

    expect(position.point, testCentre);
    expect(position.source, PositionSource.fallbackOutsideArea);
    expect(position.isFallback, isTrue);
  });

  test('falls back to the area centre when location is refused', () async {
    final position = await positionFor(const Failed(Failure('Refused.')));

    expect(position.point, testCentre);
    expect(position.source, PositionSource.fallbackNoAccess);
    expect(position.isFallback, isTrue);
  });
}
