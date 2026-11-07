import 'package:equatable/equatable.dart';

import 'place.dart';

enum SortMode {
  /// Good and close: a blend of rating and distance.
  bestMatch,
  closest,
  topRated,
}

/// What the user is looking for.
class PlaceQuery extends Equatable {
  const PlaceQuery({
    this.text = '',
    this.category,
    this.openNowOnly = false,
    this.sortMode = SortMode.bestMatch,
  });

  final String text;

  /// The category to show, or null for every category.
  final PlaceCategory? category;
  final bool openNowOnly;
  final SortMode sortMode;

  bool get hasFilters =>
      text.trim().isNotEmpty || category != null || openNowOnly;

  PlaceQuery copyWith({
    String? text,
    PlaceCategory? Function()? category,
    bool? openNowOnly,
    SortMode? sortMode,
  }) {
    return PlaceQuery(
      text: text ?? this.text,
      category: category != null ? category() : this.category,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      sortMode: sortMode ?? this.sortMode,
    );
  }

  /// The same sort order with every filter removed.
  PlaceQuery withoutFilters() => PlaceQuery(sortMode: sortMode);

  @override
  List<Object?> get props => [text, category, openNowOnly, sortMode];
}
