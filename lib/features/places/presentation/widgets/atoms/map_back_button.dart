import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A round back button that floats over a map.
class MapBackButton extends StatelessWidget {
  const MapBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Material(
        color: AppColors.white,
        shape: CircleBorder(),
        elevation: 3,
        child: BackButton(color: AppColors.ink),
      ),
    );
  }
}
