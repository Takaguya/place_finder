part of 'place_search_bloc.dart';

/// Things the user did, or that happened to the screen.
sealed class PlaceSearchEvent extends Equatable {
  const PlaceSearchEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened, or the user asked to try again.
final class PlaceSearchStarted extends PlaceSearchEvent {
  const PlaceSearchStarted();
}

final class SearchTextChanged extends PlaceSearchEvent {
  const SearchTextChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// A null [category] means every category.
final class CategorySelected extends PlaceSearchEvent {
  const CategorySelected(this.category);

  final PlaceCategory? category;

  @override
  List<Object?> get props => [category];
}

final class OpenNowToggled extends PlaceSearchEvent {
  const OpenNowToggled();
}

final class SortModeChanged extends PlaceSearchEvent {
  const SortModeChanged(this.sortMode);

  final SortMode sortMode;

  @override
  List<Object?> get props => [sortMode];
}

final class FiltersCleared extends PlaceSearchEvent {
  const FiltersCleared();
}
