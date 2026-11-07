import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/walking_route.dart';
import '../../domain/usecases/get_walking_route.dart';
import '../../domain/usecases/open_in_maps_app.dart';

part 'directions_event.dart';
part 'directions_state.dart';

/// Asks for a walking route and publishes the result for the UI to draw.
class DirectionsBloc extends Bloc<DirectionsEvent, DirectionsState> {
  DirectionsBloc({required this._getWalkingRoute, required this._openInMapsApp})
    : super(const DirectionsState()) {
    on<DirectionsRequested>(_onRequested);
    on<OpenInMapsAppRequested>(_onOpenInMapsApp);
  }

  final GetWalkingRoute _getWalkingRoute;
  final OpenInMapsApp _openInMapsApp;

  Future<void> _onRequested(
    DirectionsRequested event,
    Emitter<DirectionsState> emit,
  ) async {
    emit(const DirectionsState());
    final result = await _getWalkingRoute(from: event.from, to: event.to);
    switch (result) {
      case Success<WalkingRoute>(:final value):
        emit(DirectionsState(status: DirectionsStatus.ready, route: value));
      case Failed<WalkingRoute>(:final failure):
        emit(
          DirectionsState(
            status: DirectionsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onOpenInMapsApp(
    OpenInMapsAppRequested event,
    Emitter<DirectionsState> emit,
  ) async {
    final result = await _openInMapsApp(to: event.to);
    if (result case Failed<void>(:final failure)) {
      emit(_withMapsAppError(failure.message));
      emit(_withMapsAppError(null));
    }
  }

  DirectionsState _withMapsAppError(String? message) {
    return DirectionsState(
      status: state.status,
      route: state.route,
      errorMessage: state.errorMessage,
      mapsAppError: message,
    );
  }
}
