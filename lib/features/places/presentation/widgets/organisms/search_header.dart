import 'package:flutter/material.dart';

import '../../../domain/entities/place.dart';
import '../../../domain/entities/place_query.dart';
import '../../formatters.dart';
import '../atoms/filter_pill.dart';
import '../molecules/search_field.dart';

/// The search box and filter pills that float at the top of the map.
class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.query,
    required this.onTextChanged,
    required this.onCategorySelected,
    required this.onOpenNowToggled,
  });

  final PlaceQuery query;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<PlaceCategory?> onCategorySelected;
  final VoidCallback onOpenNowToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SearchField(text: query.text, onChanged: onTextChanged),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            spacing: 8,
            children: [
              FilterPill(
                label: 'All',
                isSelected: query.category == null,
                onTap: () => onCategorySelected(null),
              ),
              for (final category in PlaceCategory.values)
                FilterPill(
                  label: category.plural,
                  icon: category.icon,
                  isSelected: query.category == category,
                  onTap: () => onCategorySelected(category),
                ),
              FilterPill(
                label: 'Open now',
                isSelected: query.openNowOnly,
                onTap: onOpenNowToggled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
