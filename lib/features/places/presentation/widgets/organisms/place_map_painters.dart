part of 'place_map.dart';

/// Which part of the world the map shows, and how zoomed in it is.
class _Camera extends Equatable {
  const _Camera({
    required this.latitude,
    required this.longitude,
    required this.pixelsPerDegree,
  });

  /// Shows [points] as large as possible inside [area].
  factory _Camera.fit(Size area, List<GeoPoint> points) {
    final fitted = points.isEmpty
        ? const [
            GeoPoint(SketchMap.north, SketchMap.west),
            GeoPoint(SketchMap.south, SketchMap.east),
          ]
        : points;
    final latitudes = fitted.map((point) => point.latitude);
    final longitudes = fitted.map((point) => point.longitude);
    final north = latitudes.reduce(math.max);
    final south = latitudes.reduce(math.min);
    final east = longitudes.reduce(math.max);
    final west = longitudes.reduce(math.min);
    return _Camera(
      latitude: (north + south) / 2,
      longitude: (east + west) / 2,
      pixelsPerDegree: math.min(
        math.max(area.width, 1) / math.max(east - west, _smallestSpanDegrees),
        math.max(area.height, 1) / math.max(north - south, _smallestSpanDegrees),
      ),
    );
  }

  /// Stops the map zooming in too far on results that are close together.
  static const double _smallestSpanDegrees = 0.012;

  final double latitude;
  final double longitude;
  final double pixelsPerDegree;

  Offset project(GeoPoint point, Offset centre) {
    return Offset(
      centre.dx + (point.longitude - longitude) * pixelsPerDegree,
      centre.dy - (point.latitude - latitude) * pixelsPerDegree,
    );
  }

  @override
  List<Object> get props => [latitude, longitude, pixelsPerDegree];
}

class _CameraTween extends Tween<_Camera> {
  _CameraTween({super.begin, super.end});

  @override
  _Camera lerp(double t) {
    final from = begin!;
    final to = end!;
    return _Camera(
      latitude: from.latitude + (to.latitude - from.latitude) * t,
      longitude: from.longitude + (to.longitude - from.longitude) * t,
      pixelsPerDegree:
          from.pixelsPerDegree +
          (to.pixelsPerDegree - from.pixelsPerDegree) * t,
    );
  }
}

Paint _stroke(Color color, double width) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

Path _lineThrough(Iterable<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path;
}

/// The land, parks, water and streets. Everything under the pins.
class _BaseMapPainter extends CustomPainter {
  const _BaseMapPainter(this.camera, this.centre);

  final _Camera camera;
  final Offset centre;

  Offset _project(GeoPoint point) => camera.project(point, centre);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.land);

    for (final area in sketchAreas.where((a) => a.kind != SketchAreaKind.land)) {
      _drawArea(canvas, area);
    }
    for (final river in sketchRivers) {
      final width =
          river.width *
          (SketchMap.east - SketchMap.west) *
          camera.pixelsPerDegree;
      _drawLine(canvas, river.path, width, AppColors.water);
    }
    // Land goes on top of the rivers, which is what makes an island.
    for (final area in sketchAreas.where((a) => a.kind == SketchAreaKind.land)) {
      _drawArea(canvas, area);
    }

    for (final street in sketchStreets.where((street) => !street.isMain)) {
      _drawLine(canvas, street.path, 4, AppColors.white);
    }
    for (final street in sketchStreets.where((street) => street.isMain)) {
      _drawLine(canvas, street.path, 7, AppColors.majorRoad);
    }
  }

  void _drawArea(Canvas canvas, SketchArea area) {
    final color = switch (area.kind) {
      SketchAreaKind.park => AppColors.park,
      SketchAreaKind.water => AppColors.water,
      SketchAreaKind.land => AppColors.land,
    };
    canvas.drawOval(
      Rect.fromPoints(_project(area.northWest), _project(area.southEast)),
      Paint()..color = color,
    );
  }

  void _drawLine(
    Canvas canvas,
    List<GeoPoint> path,
    double width,
    Color color,
  ) {
    canvas.drawPath(_lineThrough(path.map(_project)), _stroke(color, width));
  }

  @override
  bool shouldRepaint(_BaseMapPainter oldDelegate) =>
      oldDelegate.camera != camera || oldDelegate.centre != centre;
}

/// The way to walk: a solid line along the streets, with a white edge so it
/// stands out from the road beneath it.
class _StreetRoutePainter extends CustomPainter {
  const _StreetRoutePainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = _lineThrough(points);
    canvas.drawPath(path, _stroke(AppColors.white, 9));
    canvas.drawPath(path, _stroke(AppColors.blue, 5));
  }

  @override
  bool shouldRepaint(_StreetRoutePainter oldDelegate) =>
      oldDelegate.points != points;
}

/// The dashed line from the user to the top result. Its dashes move towards
/// the destination.
class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.from,
    required this.to,
    required Animation<double> phase,
  }) : _phase = phase,
       super(repaint: phase);

  final Offset from;
  final Offset to;
  final Animation<double> _phase;

  static const double _dash = 11;
  static const double _gap = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = (from + to) / 2;
    final bend = Offset(from.dy - to.dy, to.dx - from.dx) * 0.16;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(
        middle.dx + bend.dx,
        middle.dy + bend.dy,
        to.dx,
        to.dy,
      );
    final paint = _stroke(AppColors.blue, 4);

    const period = _dash + _gap;
    for (final metric in path.computeMetrics()) {
      var start = _phase.value * period - period;
      while (start < metric.length) {
        final dashStart = math.max(start, 0.0);
        final dashEnd = math.min(start + _dash, metric.length);
        if (dashEnd > dashStart) {
          canvas.drawPath(metric.extractPath(dashStart, dashEnd), paint);
        }
        start += period;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
