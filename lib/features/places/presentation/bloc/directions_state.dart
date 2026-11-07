part of 'directions_bloc.dart';

enum DirectionsStatus { loading, ready, failure }

/// Everything the directions screen needs to draw itself.
final class DirectionsState extends Equatable {
  const DirectionsState({
    this.status = DirectionsStatus.loading,
    this.route,
    this.errorMessage,
    this.mapsAppError,
  });

  final DirectionsStatus status;

  /// Null until a route has been found.
  final WalkingRoute? route;
  final String? errorMessage;

  /// Why a maps app could not be opened. This is set just long enough for the
  /// screen to show the message once, so the same failure can show it again.
  final String? mapsAppError;

  @override
  List<Object?> get props => [status, route, errorMessage, mapsAppError];
}
