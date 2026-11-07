import 'package:flutter/material.dart';

import '../../../domain/entities/place_query.dart';
import '../../../domain/entities/ranked_place.dart';
import '../../../domain/entities/user_position.dart';
import '../../formatters.dart';
import '../atoms/sheet_handle.dart';
import '../molecules/panel_message.dart';
import '../molecules/place_row.dart';
import '../molecules/sort_selector.dart';

/// The contents of the bottom sheet: the sort choice and the ranked results,
/// or a message saying what to do when there are none.
class ResultsPanel extends StatelessWidget {
  const ResultsPanel({
    super.key,
    required this.scrollController,
    required this.results,
    required this.sortMode,
    required this.isLoading,
    required this.errorMessage,
    required this.position,
    required this.hasFilters,
    required this.onSortChanged,
    required this.onPlaceTap,
    required this.onRetry,
    required this.onClearFilters,
  });

  final ScrollController scrollController;
  final List<RankedPlace> results;
  final SortMode sortMode;
  final bool isLoading;
  final String? errorMessage;
  final UserPosition? position;
  final bool hasFilters;
  final ValueChanged<SortMode> onSortChanged;
  final ValueChanged<RankedPlace> onPlaceTap;
  final VoidCallback onRetry;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notice = positionNotice(position);

    return ListView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Keeps the last result clear of the phone's navigation bar.
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(sortMode.heading, style: textTheme.titleLarge),
              ),
              if (!isLoading && errorMessage == null)
                Text(_countLabel, style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SortSelector(selected: sortMode, onChanged: onSortChanged),
        ),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
            child: Text(notice, style: textTheme.bodySmall),
          ),
        if (position?.source == PositionSource.fallbackNoAccess)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use my location'),
            ),
          ),
        const SizedBox(height: 12),
        ..._buildResults(),
      ],
    );
  }

  String get _countLabel =>
      results.length == 1 ? '1 place' : '${results.length} places';

  List<Widget> _buildResults() {
    if (isLoading) {
      return const [
        PanelMessage(
          title: 'Finding your location',
          body: 'If your phone asks, allow location access.',
          showProgress: true,
        ),
      ];
    }
    if (errorMessage != null) {
      return [
        PanelMessage(
          title: 'Places could not be shown',
          body: errorMessage!,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ];
    }
    if (results.isEmpty) {
      return [
        PanelMessage(
          title: 'No places match',
          body: 'Try a different word, or clear the filters to see everything.',
          actionLabel: hasFilters ? 'Clear filters' : null,
          onAction: hasFilters ? onClearFilters : null,
        ),
      ];
    }
    final from = position;
    return [
      for (final entry in results)
        PlaceRow(
          key: ValueKey(entry.place.id),
          entry: entry,
          onTap: () => onPlaceTap(entry),
          topLabel: entry.rank == 1 ? sortMode.topResultLabel : null,
          reason: entry.rank == 1 && from != null
              ? rankingReason(entry, from)
              : null,
        ),
    ];
  }
}
