import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A pill-shaped choice that floats over the map.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.white : AppColors.ink;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.ink : AppColors.white,
        elevation: 2,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
