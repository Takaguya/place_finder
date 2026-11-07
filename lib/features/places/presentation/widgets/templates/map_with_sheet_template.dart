import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// The layout of the map screens: a full-screen map, a floating header and a
/// draggable bottom sheet. It knows where things go, not what they are.
class MapWithSheetTemplate extends StatelessWidget {
  const MapWithSheetTemplate({
    super.key,
    required this.mapBuilder,
    required this.header,
    required this.sheetBuilder,
    this.headerHeight = 122,
  });

  /// Builds the map. `visibleInsets` covers what the header and the sheet hide.
  final Widget Function(BuildContext context, EdgeInsets visibleInsets)
  mapBuilder;
  final Widget header;
  final Widget Function(BuildContext context, ScrollController controller)
  sheetBuilder;

  /// How much of the top of the map the header covers.
  final double headerHeight;

  static const double _sheetStart = 0.5;
  static const double _sheetSmallest = 0.16;
  static const double _sheetLargest = 0.94;
  static const double _pinMargin = 30;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    // Read here because the Scaffold hides the keyboard's height from its body.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.land,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The map keeps its size when the keyboard opens, so it doesn't zoom
          // out to fit the smaller space. The sheet rises over it instead.
          final mapHeight = constraints.maxHeight + keyboardHeight;
          final visibleInsets = EdgeInsets.only(
            left: _pinMargin,
            right: _pinMargin,
            top: topInset + headerHeight + _pinMargin,
            bottom: mapHeight * _sheetStart + _pinMargin,
          );
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight,
                child: mapBuilder(context, visibleInsets),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(bottom: false, child: header),
              ),
              DraggableScrollableSheet(
                initialChildSize: _sheetStart,
                minChildSize: _sheetSmallest,
                maxChildSize: _sheetLargest,
                builder: (context, controller) => Material(
                  color: AppColors.white,
                  elevation: 16,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: sheetBuilder(context, controller),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
