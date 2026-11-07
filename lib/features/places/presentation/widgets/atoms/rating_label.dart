import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A star and a score, such as 4.7.
class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final score = rating.toStringAsFixed(1);
    return Semantics(
      label: 'Rated $score out of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppColors.ink),
          const SizedBox(width: 2),
          Text(score, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
