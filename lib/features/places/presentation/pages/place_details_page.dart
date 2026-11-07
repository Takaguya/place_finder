import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ranked_place.dart';
import '../../domain/entities/user_position.dart';
import '../place_routes.dart';
import '../widgets/atoms/map_back_button.dart';
import '../widgets/organisms/place_map.dart';
import '../widgets/organisms/place_summary.dart';

/// The details screen for one place. It only displays what it is given, so it
/// doesn't need the BLoC.
class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage({
    super.key,
    required this.entry,
    required this.position,
  });

  final RankedPlace entry;
  final UserPosition position;

  static const double _mapHeight = 300;

  void _getDirections(BuildContext context) {
    PlaceRoutes.openDirections(
      context,
      PlaceRouteArgs(entry: entry, position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _mapHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlaceMap(
                  results: [entry],
                  userPoint: position.point,
                  routeTarget: entry.place.location,
                  pinInsets: const EdgeInsets.fromLTRB(50, 80, 50, 50),
                ),
                const SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: MapBackButton(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: PlaceSummary(entry: entry, position: position),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton.icon(
                onPressed: () => _getDirections(context),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Get directions'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
