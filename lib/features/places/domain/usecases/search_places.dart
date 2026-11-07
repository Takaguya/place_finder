import '../../../../core/result.dart';
import '../entities/geo_point.dart';
import '../entities/place.dart';
import '../entities/place_query.dart';
import '../entities/ranked_place.dart';
import '../repositories/place_repository.dart';
import '../services/place_ranker.dart';

/// Filters places to what the user asked for, then puts them in order.
class SearchPlaces {
  SearchPlaces(
    this._places, {
    this._ranker = const PlaceRanker(),
    this._clock = DateTime.now,
  });

  final PlaceRepository _places;
  final PlaceRanker _ranker;
  final DateTime Function() _clock;

  /// The everyday words people use to look for each category.
  static const Map<PlaceCategory, String> _categoryWords = {
    PlaceCategory.mall: 'mall malls shopping',
    PlaceCategory.restaurant: 'restaurant restaurants food eat',
    PlaceCategory.cafe: 'cafe cafes coffee tea',
    PlaceCategory.market: 'market markets',
  };

  static final RegExp _wordSeparator = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  Future<Result<List<RankedPlace>>> call({
    required PlaceQuery query,
    required GeoPoint from,
  }) async {
    final result = await _places.getPlaces();
    return switch (result) {
      Failed<List<Place>>(:final failure) => Failed(failure),
      Success<List<Place>>(:final value) => Success(
        _rank(value, query: query, from: from),
      ),
    };
  }

  List<RankedPlace> _rank(
    List<Place> places, {
    required PlaceQuery query,
    required GeoPoint from,
  }) {
    final now = _clock();
    final matches = [
      for (final place in places)
        if (_matches(place, query, now)) _candidateFor(place, from),
    ];
    matches.sort(_comparatorFor(query.sortMode));

    return [
      for (final (index, candidate) in matches.indexed)
        RankedPlace(
          place: candidate.place,
          rank: index + 1,
          distanceKm: candidate.distanceKm,
          isOpen: candidate.place.isOpenAt(now),
        ),
    ];
  }

  _Candidate _candidateFor(Place place, GeoPoint from) {
    final distanceKm = from.distanceKmTo(place.location);
    return _Candidate(
      place: place,
      distanceKm: distanceKm,
      adjustedRating: _ranker.adjustedRating(place),
      score: _ranker.score(place, distanceKm),
    );
  }

  bool _matches(Place place, PlaceQuery query, DateTime now) {
    if (query.category != null && place.category != query.category) {
      return false;
    }
    if (query.openNowOnly && !place.isOpenAt(now)) return false;
    return _matchesText(place, query.text);
  }

  /// Every word the user typed must start a word in the place's text, in any
  /// order. So "mall" finds malls, but not a cafe described as "small".
  bool _matchesText(Place place, String text) {
    final placeWords = _wordsIn(
      [
        place.name,
        place.neighbourhood,
        place.summary,
        _categoryWords[place.category]!,
      ].join(' '),
    ).toList();
    return _wordsIn(text).every(
      (typed) => placeWords.any((word) => word.startsWith(typed)),
    );
  }

  Iterable<String> _wordsIn(String text) {
    return text
        .toLowerCase()
        .split(_wordSeparator)
        .where((word) => word.isNotEmpty);
  }

  int Function(_Candidate, _Candidate) _comparatorFor(SortMode mode) {
    return switch (mode) {
      SortMode.bestMatch => (a, b) => _firstDifference([
        b.score.compareTo(a.score),
        a.distanceKm.compareTo(b.distanceKm),
        a.place.name.compareTo(b.place.name),
      ]),
      SortMode.closest => (a, b) => _firstDifference([
        a.distanceKm.compareTo(b.distanceKm),
        b.adjustedRating.compareTo(a.adjustedRating),
        a.place.name.compareTo(b.place.name),
      ]),
      SortMode.topRated => (a, b) => _firstDifference([
        b.adjustedRating.compareTo(a.adjustedRating),
        a.distanceKm.compareTo(b.distanceKm),
        a.place.name.compareTo(b.place.name),
      ]),
    };
  }

  int _firstDifference(List<int> comparisons) {
    return comparisons.firstWhere((result) => result != 0, orElse: () => 0);
  }
}

class _Candidate {
  const _Candidate({
    required this.place,
    required this.distanceKm,
    required this.adjustedRating,
    required this.score,
  });

  final Place place;
  final double distanceKm;
  final double adjustedRating;
  final double score;
}
