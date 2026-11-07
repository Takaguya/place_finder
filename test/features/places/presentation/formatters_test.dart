import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/features/places/domain/entities/ranked_place.dart';
import 'package:place_finder/features/places/domain/entities/user_position.dart';
import 'package:place_finder/features/places/domain/entities/walking_route.dart';
import 'package:place_finder/features/places/presentation/formatters.dart';

import '../../../helpers/fakes.dart';

void main() {
  const fromDevice = UserPosition(
    point: testCentre,
    source: PositionSource.device,
    area: testArea,
  );
  const noAccess = UserPosition(
    point: testCentre,
    source: PositionSource.fallbackNoAccess,
    area: testArea,
  );
  const outsideArea = UserPosition(
    point: testCentre,
    source: PositionSource.fallbackOutsideArea,
    area: testArea,
  );

  RankedPlace entryOf({bool isOpen = true}) => RankedPlace(
    place: testPlace(rating: 4.7, reviewCount: 1280),
    rank: 1,
    distanceKm: 0.65,
    isOpen: isOpen,
  );

  group('formatDistance', () {
    test('uses metres under a kilometre, rounded to 10', () {
      expect(formatDistance(0.65), '650 m');
      expect(formatDistance(0.123), '120 m');
    });

    test('uses kilometres from a kilometre up', () {
      expect(formatDistance(1.26), '1.3 km');
    });

    test('never shows 1000 m', () {
      expect(formatDistance(0.996), '1.0 km');
    });
  });

  test('formatCount adds thousands separators', () {
    expect(formatCount(7), '7');
    expect(formatCount(999), '999');
    expect(formatCount(1280), '1,280');
    expect(formatCount(1000000), '1,000,000');
  });

  test('formatHour uses a 12-hour clock', () {
    expect(formatHour(0), '12 AM');
    expect(formatHour(9), '9 AM');
    expect(formatHour(12), '12 PM');
    expect(formatHour(22), '10 PM');
    expect(formatHour(24), '12 AM');
  });

  test('formatPrice shows one symbol per level', () {
    expect(formatPrice(1), r'$');
    expect(formatPrice(3), r'$$$');
  });

  test('formatOpenStatus says what happens next', () {
    expect(formatOpenStatus(entryOf()), 'Open until 9 PM');
    expect(formatOpenStatus(entryOf(isOpen: false)), 'Closed, opens 9 AM');
  });

  test('formatWalkingTime switches to hours at 60 minutes', () {
    expect(formatWalkingTime(const Duration(minutes: 13)), '13 min');
    expect(formatWalkingTime(const Duration(minutes: 60)), '1 hr');
    expect(formatWalkingTime(const Duration(minutes: 89)), '1 hr 29 min');
  });

  group('formatRouteStep', () {
    RouteStep stepOf(RouteManeuver maneuver) => RouteStep(
      maneuver: maneuver,
      distanceKm: 0.2,
      streetName: 'Street 51',
    );

    test('words each kind of instruction', () {
      expect(
        formatRouteStep(stepOf(RouteManeuver.turnLeft), 'Cafe'),
        'Turn left onto Street 51',
      );
      expect(
        formatRouteStep(stepOf(RouteManeuver.turnRight), 'Cafe'),
        'Turn right onto Street 51',
      );
      expect(
        formatRouteStep(stepOf(RouteManeuver.continueStraight), 'Cafe'),
        'Continue onto Street 51',
      );
      expect(
        formatRouteStep(const RouteStep.arrive(), 'Cafe'),
        'Arrive at Cafe',
      );
    });

    test('words every compass heading', () {
      const expected = {
        CompassHeading.north: 'north',
        CompassHeading.northEast: 'north-east',
        CompassHeading.east: 'east',
        CompassHeading.southEast: 'south-east',
        CompassHeading.south: 'south',
        CompassHeading.southWest: 'south-west',
        CompassHeading.west: 'west',
        CompassHeading.northWest: 'north-west',
      };
      for (final MapEntry(key: heading, value: word) in expected.entries) {
        final step = RouteStep(
          maneuver: RouteManeuver.start,
          distanceKm: 0.2,
          streetName: 'Street 51',
          heading: heading,
        );

        expect(formatRouteStep(step, 'Cafe'), 'Head $word on Street 51');
      }
    });
  });

  group('wording about the starting point', () {
    test('says "you" only when the position is really the user', () {
      expect(distanceOrigin(fromDevice), 'from you');
      expect(distanceOrigin(noAccess), 'from Independence Monument');
      expect(routeOrigin(fromDevice), 'Starting from your location');
      expect(routeOrigin(noAccess), 'Starting from Independence Monument');
    });

    test('rankingReason uses the same wording', () {
      expect(
        rankingReason(entryOf(), fromDevice),
        'Rated 4.7 by 1,280 people, 650 m from you.',
      );
      expect(
        rankingReason(entryOf(), noAccess),
        'Rated 4.7 by 1,280 people, 650 m from Independence Monument.',
      );
    });

    test('positionNotice only appears when something needs explaining', () {
      expect(positionNotice(null), isNull);
      expect(positionNotice(fromDevice), isNull);
      expect(positionNotice(noAccess), contains('Use my location'));
      expect(positionNotice(outsideArea), contains('outside Phnom Penh'));
    });
  });
}
