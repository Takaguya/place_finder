part of 'directions_bloc.dart';

sealed class DirectionsEvent extends Equatable {
  const DirectionsEvent();

  @override
  List<Object?> get props => const [];
}

/// The directions screen opened, or the user asked to try again.
final class DirectionsRequested extends DirectionsEvent {
  const DirectionsRequested({required this.from, required this.to});

  final GeoPoint from;
  final GeoPoint to;

  @override
  List<Object?> get props => [from, to];
}

/// The user asked to continue in a maps app outside this one.
final class OpenInMapsAppRequested extends DirectionsEvent {
  const OpenInMapsAppRequested({required this.to});

  final GeoPoint to;

  @override
  List<Object?> get props => [to];
}
