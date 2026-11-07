import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// The small bar that shows a bottom sheet can be dragged.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
