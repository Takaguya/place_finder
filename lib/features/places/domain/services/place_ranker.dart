import '../entities/place.dart';

/// Decides how "good and close" a place is.
///
/// This is the app's main business rule. It lives here so it can be tested and
/// changed without touching any UI.
class PlaceRanker {
  const PlaceRanker({
    this.qualityWeight = 0.5,
    this.closenessWeight = 0.5,
    this.halfScoreKm = 2,
    this.typicalRating = 4,
    this.reviewsToTrust = 50,
    this.lowestRating = 3,
    this.highestRating = 5,
  });

  /// How much the rating counts towards the score.
  final double qualityWeight;

  /// How much the distance counts towards the score.
  final double closenessWeight;

  /// The distance at which a place earns half of the closeness points.
  final double halfScoreKm;

  /// The rating assumed for a place until it has enough reviews of its own.
  final double typicalRating;

  /// The number of reviews at which a place's own rating counts for half.
  final int reviewsToTrust;

  /// Ratings at or below this earn no quality points.
  final double lowestRating;

  /// Ratings at this level earn all of the quality points.
  final double highestRating;

  /// The rating adjusted for how many people left one (a Bayesian average).
  ///
  /// A 4.9 from 12 reviews is less certain than a 4.7 from 1,000, so a small
  /// number of reviews is pulled towards [typicalRating].
  double adjustedRating(Place place) {
    final reviews = place.reviewCount;
    return (reviews * place.rating + reviewsToTrust * typicalRating) /
        (reviews + reviewsToTrust);
  }

  /// From 1 at your door, falling to 0.5 at [halfScoreKm] and towards 0 beyond.
  double closeness(double distanceKm) => 1 / (1 + distanceKm / halfScoreKm);

  /// From 0 to 1, where higher is better.
  double score(Place place, double distanceKm) {
    final quality =
        ((adjustedRating(place) - lowestRating) /
                (highestRating - lowestRating))
            .clamp(0.0, 1.0);
    return qualityWeight * quality + closenessWeight * closeness(distanceKm);
  }
}
