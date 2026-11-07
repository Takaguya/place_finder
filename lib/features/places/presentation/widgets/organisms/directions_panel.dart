import 'package:flutter/material.dart';

import '../../../domain/entities/user_position.dart';
import '../../../domain/entities/walking_route.dart';
import '../../formatters.dart';
import '../atoms/sheet_handle.dart';
import '../molecules/panel_message.dart';
import '../molecules/route_step_row.dart';

/// The contents of the directions sheet: how long the walk takes, how far it
/// is, and each instruction along the way.
class DirectionsPanel extends StatelessWidget {
  const DirectionsPanel({
    super.key,
    required this.scrollController,
    required this.placeName,
    required this.position,
    required this.route,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenInMaps,
  });

  final ScrollController scrollController;
  final String placeName;
  final UserPosition position;
  final WalkingRoute? route;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenInMaps;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        ..._buildContent(context),
      ],
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final currentRoute = route;
    if (currentRoute != null) return _buildRoute(context, currentRoute);
    if (errorMessage != null) {
      return [
        PanelMessage(
          title: 'No route to show',
          body: errorMessage!,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ];
    }
    return const [
      PanelMessage(
        title: 'Finding a walking route',
        body: 'This only takes a moment.',
        showProgress: true,
      ),
    ];
  }

  List<Widget> _buildRoute(BuildContext context, WalkingRoute route) {
    final textTheme = Theme.of(context).textTheme;
    return [
      Text(
        '${formatWalkingTime(route.walkingTime)} walk',
        style: textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      Text(
        '${formatDistance(route.distanceKm)} to $placeName',
        style: textTheme.bodyMedium,
      ),
      Text(routeOrigin(position), style: textTheme.bodySmall),
      const SizedBox(height: 12),
      for (final step in route.steps)
        RouteStepRow(step: step, placeName: placeName),
      const SizedBox(height: 8),
      Text(
        'This is a test map, so streets and times are approximate.',
        style: textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onOpenInMaps,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Open in Google Maps'),
        ),
      ),
    ];
  }
}
