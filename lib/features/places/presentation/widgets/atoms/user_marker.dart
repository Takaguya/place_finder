import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Shows the point distances are measured from.
class UserMarker extends StatelessWidget {
  const UserMarker({super.key});

  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Distances are measured from here',
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: AppColors.white,
          shape: const CircleBorder(),
          elevation: 4,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 15,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
