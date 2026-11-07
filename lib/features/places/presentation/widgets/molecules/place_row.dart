import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/ranked_place.dart';
import '../../formatters.dart';
import '../atoms/open_status.dart';
import '../atoms/rating_label.dart';

/// One search result. Giving it a [topLabel] turns it into the yellow top
/// result, whose number matches the yellow pin on the map.
class PlaceRow extends StatelessWidget {
  const PlaceRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.topLabel,
    this.reason,
  });

  final RankedPlace entry;
  final VoidCallback onTap;
  final String? topLabel;

  /// One sentence explaining the ranking, shown under the row.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = topLabel != null;
    final textTheme = Theme.of(context).textTheme;
    final place = entry.place;
    final secondaryStyle = textTheme.bodySmall?.copyWith(
      color: isHighlighted ? AppColors.ink : AppColors.slate,
    );

    return Material(
      color: isHighlighted ? AppColors.yellow : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topLabel != null) ...[
                Text(topLabel!, style: textTheme.labelMedium),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Text('${entry.rank}', style: textTheme.titleLarge),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${place.category.singular} in ${place.neighbourhood}',
                          style: secondaryStyle,
                        ),
                        const SizedBox(height: 4),
                        OpenStatus(
                          isOpen: entry.isOpen,
                          text: formatOpenStatus(entry),
                          textColor: isHighlighted ? AppColors.ink : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RatingLabel(rating: place.rating),
                      const SizedBox(height: 2),
                      Text(
                        formatDistance(entry.distanceKm),
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
              if (reason != null) ...[
                const SizedBox(height: 10),
                Text(
                  reason!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.ink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
