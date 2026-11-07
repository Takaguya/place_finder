import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ranked_place.dart';
import '../bloc/place_search_bloc.dart';
import '../place_routes.dart';
import '../widgets/organisms/place_map.dart';
import '../widgets/organisms/results_panel.dart';
import '../widgets/organisms/search_header.dart';
import '../widgets/templates/map_with_sheet_template.dart';

/// The search screen. This is where the UI meets the BLoC: it passes state down
/// to widgets as plain values and turns their callbacks into events.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaceSearchBloc, PlaceSearchState>(
      builder: (context, state) {
        final bloc = context.read<PlaceSearchBloc>();

        void openPlace(RankedPlace entry) {
          // Results only exist once the position is known.
          final position = state.position;
          if (position == null) return;
          PlaceRoutes.openDetails(
            context,
            PlaceRouteArgs(entry: entry, position: position),
          );
        }

        return MapWithSheetTemplate(
          mapBuilder: (context, visibleInsets) => PlaceMap(
            results: state.results,
            userPoint: state.position?.point,
            routeTarget: state.results.isEmpty
                ? null
                : state.results.first.place.location,
            pinInsets: visibleInsets,
            onPinTap: openPlace,
          ),
          header: SearchHeader(
            query: state.query,
            onTextChanged: (text) => bloc.add(SearchTextChanged(text)),
            onCategorySelected: (category) =>
                bloc.add(CategorySelected(category)),
            onOpenNowToggled: () => bloc.add(const OpenNowToggled()),
          ),
          sheetBuilder: (context, controller) => ResultsPanel(
            scrollController: controller,
            results: state.results,
            sortMode: state.query.sortMode,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            position: state.position,
            hasFilters: state.query.hasFilters,
            onSortChanged: (mode) => bloc.add(SortModeChanged(mode)),
            onPlaceTap: openPlace,
            onRetry: () => bloc.add(const PlaceSearchStarted()),
            onClearFilters: () => bloc.add(const FiltersCleared()),
          ),
        );
      },
    );
  }
}
