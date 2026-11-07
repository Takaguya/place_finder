import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/walking_route.dart';
import '../../formatters.dart';

/// One instruction in a walking route: an icon, what to do, and how far to go.
class RouteStepRow extends StatelessWidget {
  const RouteStepRow({super.key, required this.step, required this.placeName});

  final RouteStep step;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isArrival = step.maneuver == RouteManeuver.arrive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isArrival ? AppColors.yellow : AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: Icon(step.maneuver.icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatRouteStep(step, placeName),
              style: textTheme.bodyMedium,
            ),
          ),
          if (!isArrival) ...[
            const SizedBox(width: 12),
            Text(formatDistance(step.distanceKm), style: textTheme.labelMedium),
          ],
        ],
      ),
    );
  }
}
