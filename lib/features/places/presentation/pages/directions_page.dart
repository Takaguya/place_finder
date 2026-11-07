import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ranked_place.dart';
import '../../domain/entities/user_position.dart';
import '../../domain/usecases/get_walking_route.dart';
import '../../domain/usecases/open_in_maps_app.dart';
import '../bloc/directions_bloc.dart';
import '../widgets/atoms/map_back_button.dart';
import '../widgets/organisms/directions_panel.dart';
import '../widgets/organisms/place_map.dart';
import '../widgets/templates/map_with_sheet_template.dart';

/// Shows how to walk to a place: the route along the streets, how far it is,
/// how long it takes, and each instruction along the way.
class DirectionsPage extends StatelessWidget {
  const DirectionsPage({
    super.key,
    required this.entry,
    required this.position,
  });

  final RankedPlace entry;
  final UserPosition position;

  static const double _headerHeight = 64;

  DirectionsRequested get _routeRequest =>
      DirectionsRequested(from: position.point, to: entry.place.location);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DirectionsBloc(
        getWalkingRoute: context.read<GetWalkingRoute>(),
        openInMapsApp: context.read<OpenInMapsApp>(),
      )..add(_routeRequest),
      child: BlocListener<DirectionsBloc, DirectionsState>(
        listenWhen: (_, current) => current.mapsAppError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.mapsAppError!)));
        },
        child: BlocBuilder<DirectionsBloc, DirectionsState>(
          builder: (context, state) {
            final bloc = context.read<DirectionsBloc>();
            return MapWithSheetTemplate(
              headerHeight: _headerHeight,
              mapBuilder: (context, visibleInsets) => PlaceMap(
                results: [entry],
                userPoint: position.point,
                routePath: state.route?.path,
                pinInsets: visibleInsets,
              ),
              header: const Align(
                alignment: Alignment.topLeft,
                child: MapBackButton(),
              ),
              sheetBuilder: (context, controller) => DirectionsPanel(
                scrollController: controller,
                placeName: entry.place.name,
                position: position,
                route: state.route,
                errorMessage: state.errorMessage,
                onRetry: () => bloc.add(_routeRequest),
                onOpenInMaps: () => bloc.add(
                  OpenInMapsAppRequested(to: entry.place.location),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
