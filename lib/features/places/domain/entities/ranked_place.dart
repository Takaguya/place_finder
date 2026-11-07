import 'package:equatable/equatable.dart';

import 'place.dart';

/// A search result: a place plus everything worked out about it for this search.
class RankedPlace extends Equatable {
  const RankedPlace({
    required this.place,
    required this.rank,
    required this.distanceKm,
    required this.isOpen,
  });

  final Place place;

  /// Position in the results, starting at 1.
  final int rank;
  final double distanceKm;
  final bool isOpen;

  @override
  List<Object> get props => [place, rank, distanceKm, isOpen];
}
