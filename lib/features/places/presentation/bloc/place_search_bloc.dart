import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_query.dart';
import '../../domain/entities/ranked_place.dart';
import '../../domain/entities/user_position.dart';
import '../../domain/usecases/get_user_position.dart';
import '../../domain/usecases/search_places.dart';

part 'place_search_event.dart';
part 'place_search_state.dart';

/// Turns user actions into search states.
///
/// This class contains no widgets and no ranking rules: it asks the use cases
/// for answers and publishes the result for the UI to draw.
class PlaceSearchBloc extends Bloc<PlaceSearchEvent, PlaceSearchState> {
  PlaceSearchBloc({
    required this._getUserPosition,
    required this._searchPlaces,
  }) : super(const PlaceSearchState()) {
    on<PlaceSearchStarted>(_onStarted);
    on<SearchTextChanged>(
      (event, emit) => _search(state.query.copyWith(text: event.text), emit),
    );
    on<CategorySelected>(
      (event, emit) =>
          _search(state.query.copyWith(category: () => event.category), emit),
    );
    on<OpenNowToggled>(
      (event, emit) => _search(
        state.query.copyWith(openNowOnly: !state.query.openNowOnly),
        emit,
      ),
    );
    on<SortModeChanged>(
      (event, emit) =>
          _search(state.query.copyWith(sortMode: event.sortMode), emit),
    );
    on<FiltersCleared>(
      (event, emit) => _search(state.query.withoutFilters(), emit),
    );
  }

  final GetUserPosition _getUserPosition;
  final SearchPlaces _searchPlaces;

  /// Identifies the newest search, so a slow older one can't overwrite it.
  int _latestRequestId = 0;

  Future<void> _onStarted(
    PlaceSearchStarted event,
    Emitter<PlaceSearchState> emit,
  ) async {
    emit(state.copyWith(status: PlaceSearchStatus.locating));
    final position = await _getUserPosition();
    emit(state.copyWith(position: position));
    await _search(state.query, emit);
  }

  Future<void> _search(PlaceQuery query, Emitter<PlaceSearchState> emit) async {
    final position = state.position;
    if (position == null) {
      // Still locating. Keep the query, and _onStarted will search with it.
      emit(state.copyWith(query: query));
      return;
    }

    final requestId = ++_latestRequestId;
    emit(state.copyWith(status: PlaceSearchStatus.searching, query: query));
    final result = await _searchPlaces(query: query, from: position.point);
    if (requestId != _latestRequestId) return;

    switch (result) {
      case Success<List<RankedPlace>>(:final value):
        emit(state.copyWith(status: PlaceSearchStatus.ready, results: value));
      case Failed<List<RankedPlace>>(:final failure):
        emit(
          state.copyWith(
            status: PlaceSearchStatus.failure,
            results: const [],
            errorMessage: failure.message,
          ),
        );
    }
  }
}
