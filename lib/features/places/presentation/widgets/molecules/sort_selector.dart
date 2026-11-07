import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/place_query.dart';
import '../../formatters.dart';

/// Chooses the order of the results.
class SortSelector extends StatelessWidget {
  const SortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SortMode selected;
  final ValueChanged<SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final mode in SortMode.values)
            Expanded(
              child: _SortOption(
                label: mode.label,
                isSelected: mode == selected,
                onTap: () => onChanged(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? AppColors.white : AppColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
