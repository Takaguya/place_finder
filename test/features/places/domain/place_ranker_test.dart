import 'package:flutter_test/flutter_test.dart';
import 'package:place_finder/features/places/domain/services/place_ranker.dart';

import '../../../helpers/fakes.dart';

void main() {
  const ranker = PlaceRanker();

  group('adjustedRating', () {
    test('trusts a slightly lower rating from many people over a high one '
        'from a few', () {
      final fewReviews = testPlace(rating: 4.9, reviewCount: 12);
      final manyReviews = testPlace(rating: 4.7, reviewCount: 1000);

      expect(
        ranker.adjustedRating(manyReviews),
        greaterThan(ranker.adjustedRating(fewReviews)),
      );
    });

    test('uses the typical rating when a place has no reviews', () {
      final noReviews = testPlace(rating: 5, reviewCount: 0);

      expect(ranker.adjustedRating(noReviews), ranker.typicalRating);
    });
  });

  group('closeness', () {
    test('is 1 at your door and halves at the half-score distance', () {
      expect(ranker.closeness(0), 1);
      expect(ranker.closeness(ranker.halfScoreKm), 0.5);
    });

    test('keeps falling with distance', () {
      expect(ranker.closeness(5), lessThan(ranker.closeness(1)));
    });
  });

  group('score', () {
    test('a good, close place beats a great far one and a poor near one', () {
      final goodAndClose = ranker.score(
        testPlace(rating: 4.6, reviewCount: 1000),
        0.5,
      );
      final greatButFar = ranker.score(
        testPlace(rating: 4.9, reviewCount: 1000),
        8,
      );
      final poorButNear = ranker.score(
        testPlace(rating: 3.5, reviewCount: 1000),
        0.2,
      );

      expect(goodAndClose, greaterThan(greatButFar));
      expect(goodAndClose, greaterThan(poorButNear));
    });

    test('gives no quality points to a very low rating', () {
      final score = ranker.score(testPlace(rating: 2, reviewCount: 1000), 0);

      expect(score, closeTo(ranker.closenessWeight, 0.0001));
    });
  });
}
