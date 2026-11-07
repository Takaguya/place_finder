part of 'place_search_bloc.dart';

enum PlaceSearchStatus { locating, searching, ready, failure }

/// Everything the search screen needs to draw itself.
final class PlaceSearchState extends Equatable {
  const PlaceSearchState({
    this.status = PlaceSearchStatus.locating,
    this.query = const PlaceQuery(),
    this.position,
    this.results = const [],
    this.errorMessage,
  });

  final PlaceSearchStatus status;
  final PlaceQuery query;

  /// The point distances are measured from. Null until it has been worked out.
  final UserPosition? position;
  final List<RankedPlace> results;
  final String? errorMessage;

  /// True when there is nothing to show yet. A new search keeps the previous
  /// results on screen until the new ones arrive, so the list doesn't flicker.
  bool get isLoading =>
      status == PlaceSearchStatus.locating ||
      (status == PlaceSearchStatus.searching && results.isEmpty);

  /// Copies this state. [errorMessage] is cleared unless a new one is given.
  PlaceSearchState copyWith({
    PlaceSearchStatus? status,
    PlaceQuery? query,
    UserPosition? position,
    List<RankedPlace>? results,
    String? errorMessage,
  }) {
    return PlaceSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      position: position ?? this.position,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, query, position, results, errorMessage];
}
