import 'package:flutter/material.dart';

import '../../../domain/entities/ranked_place.dart';
import '../../../domain/entities/user_position.dart';
import '../../formatters.dart';
import '../atoms/open_status.dart';
import '../atoms/rating_label.dart';

/// Everything known about one place, shown on its details screen.
class PlaceSummary extends StatelessWidget {
  const PlaceSummary({super.key, required this.entry, required this.position});

  final RankedPlace entry;
  final UserPosition position;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final place = entry.place;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${place.category.singular} in ${place.neighbourhood}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        OpenStatus(isOpen: entry.isOpen, text: formatOpenStatus(entry)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Fact(
              value: RatingLabel(rating: place.rating),
              label: '${formatCount(place.reviewCount)} reviews',
            ),
            _Fact(
              value: Text(
                formatDistance(entry.distanceKm),
                style: textTheme.titleMedium,
              ),
              label: distanceOrigin(position),
            ),
            _Fact(
              value: Text(
                formatPrice(place.priceLevel),
                style: textTheme.titleMedium,
              ),
              label: 'Price',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(place.summary, style: textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('Why it is number ${entry.rank}', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(rankingReason(entry, position), style: textTheme.bodyMedium),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          value,
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
