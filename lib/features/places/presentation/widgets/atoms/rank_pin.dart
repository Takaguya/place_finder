import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A map marker showing a place's rank. The top result is larger and yellow.
/// Results past [_lastNumberedRank] become small dots to keep the map readable.
class RankPin extends StatelessWidget {
  const RankPin({
    super.key,
    required this.rank,
    required this.placeName,
    this.onTap,
  });

  final int rank;
  final String placeName;
  final VoidCallback? onTap;

  static const int _lastNumberedRank = 10;

  /// The pin's width and height, so a map can centre it on a point.
  static double sizeFor(int rank) {
    if (rank == 1) return 40;
    return rank <= _lastNumberedRank ? 30 : 16;
  }

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    final textTheme = Theme.of(context).textTheme;
    final numberStyle = isTop
        ? textTheme.titleLarge?.copyWith(color: AppColors.ink)
        : textTheme.labelMedium?.copyWith(color: AppColors.white);

    return Semantics(
      button: true,
      label: 'Number $rank, $placeName',
      excludeSemantics: true,
      child: Material(
        color: isTop ? AppColors.yellow : AppColors.blue,
        elevation: isTop ? 6 : 2,
        shape: CircleBorder(
          side: BorderSide(
            color: isTop ? AppColors.ink : AppColors.white,
            width: 2,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: sizeFor(rank),
            child: rank <= _lastNumberedRank
                ? Center(child: Text('$rank', style: numberStyle))
                : null,
          ),
        ),
      ),
    );
  }
}
