import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/geo_point.dart';
import '../../../domain/entities/ranked_place.dart';
import '../../../sketch_map.dart';
import '../atoms/rank_pin.dart';
import '../atoms/user_marker.dart';

part 'place_map_painters.dart';

/// A hand-drawn map of central Phnom Penh with a numbered pin for each result.
///
/// The map glides to fit the top results whenever they change. It is drawn
/// rather than downloaded, so it needs no map service or API key. Using real
/// data outside Phnom Penh would mean replacing this widget with a map package.
class PlaceMap extends StatefulWidget {
  const PlaceMap({
    super.key,
    required this.results,
    this.userPoint,
    this.routeTarget,
    this.routePath,
    this.pinInsets = EdgeInsets.zero,
    this.onPinTap,
  });

  final List<RankedPlace> results;

  /// The point distances are measured from.
  final GeoPoint? userPoint;

  /// Draws a moving dashed line from [userPoint] to this point, as a hint of
  /// the direction. It doesn't follow the streets.
  final GeoPoint? routeTarget;

  /// Draws a solid line along these points, showing the way to walk.
  final List<GeoPoint>? routePath;

  /// The parts of the map hidden by other widgets. Pins are fitted inside.
  final EdgeInsets pinInsets;
  final ValueChanged<RankedPlace>? onPinTap;

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap>
    with SingleTickerProviderStateMixin {
  /// The map fits this many results. Lower ranks may fall out of view.
  static const int _resultsToFit = 10;

  /// Area names only appear at this zoom or closer, in pixels per degree.
  static const double _minZoomForLabels = 4000;

  late final AnimationController _routePhase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteAnimation();
  }

  @override
  void didUpdateWidget(PlaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRouteAnimation();
  }

  @override
  void dispose() {
    _routePhase.dispose();
    super.dispose();
  }

  void _syncRouteAnimation() {
    final shouldMove =
        widget.routeTarget != null && !MediaQuery.disableAnimationsOf(context);
    if (shouldMove && !_routePhase.isAnimating) {
      _routePhase.repeat();
    } else if (!shouldMove && _routePhase.isAnimating) {
      _routePhase.stop();
    }
  }

  List<GeoPoint> get _pointsToFit => [
    if (widget.userPoint != null) widget.userPoint!,
    for (final entry in widget.results.take(_resultsToFit))
      entry.place.location,
    ...?widget.routePath,
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = widget.pinInsets.deflateRect(
          Offset.zero & constraints.biggest,
        );
        final target = _Camera.fit(area.size, _pointsToFit);
        return TweenAnimationBuilder<_Camera>(
          tween: _CameraTween(begin: target, end: target),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          builder: (context, camera, _) =>
              _buildMap(context, camera, area, constraints.maxWidth),
        );
      },
    );
  }

  /// Leaves out a name that the screen edge would cut off or the header would
  /// cover. Names are drawn under the sheet, so they appear as it is dragged.
  bool _labelFits(SketchLabel label, Offset at, Rect area, double mapWidth) {
    const approximateLetterWidth = 7.5;
    const edgeMargin = 8.0;
    final right = at.dx + label.name.length * approximateLetterWidth;
    return at.dx >= edgeMargin &&
        right <= mapWidth - edgeMargin &&
        at.dy >= area.top - edgeMargin;
  }

  Widget _buildMap(
    BuildContext context,
    _Camera camera,
    Rect area,
    double mapWidth,
  ) {
    final centre = area.center;
    Offset project(GeoPoint point) => camera.project(point, centre);
    final user = widget.userPoint;
    final target = widget.routeTarget;
    final path = widget.routePath;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BaseMapPainter(camera, centre)),
          // Zoomed out too far, the names would run into each other.
          if (camera.pixelsPerDegree >= _minZoomForLabels)
            for (final label in sketchLabels)
              if (_labelFits(label, project(label.at), area, mapWidth))
                Positioned(
                  left: project(label.at).dx,
                  top: project(label.at).dy,
                  child: Text(label.name, style: labelStyle),
                ),
          if (path != null)
            CustomPaint(painter: _StreetRoutePainter(path.map(project).toList()))
          else if (user != null && target != null)
            CustomPaint(
              painter: _RoutePainter(
                from: project(user),
                to: project(target),
                phase: _routePhase,
              ),
            ),
          // Drawn in reverse so that better results sit on top.
          for (final entry in widget.results.skip(1).toList().reversed)
            _pin(entry, project(entry.place.location)),
          // The best results are usually nearest, so the marker goes above
          // their pins to stay visible. Taps pass through to the pins below.
          if (user != null)
            Positioned(
              left: project(user).dx - UserMarker.size / 2,
              top: project(user).dy - UserMarker.size / 2,
              child: const IgnorePointer(child: UserMarker()),
            ),
          if (widget.results.isNotEmpty)
            _pin(
              widget.results.first,
              project(widget.results.first.place.location),
            ),
        ],
      ),
    );
  }

  Widget _pin(RankedPlace entry, Offset position) {
    final size = RankPin.sizeFor(entry.rank);
    return Positioned(
      key: ValueKey(entry.place.id),
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: RankPin(
        rank: entry.rank,
        placeName: entry.place.name,
        onTap: widget.onPinTap == null ? null : () => widget.onPinTap!(entry),
      ),
    );
  }
}
