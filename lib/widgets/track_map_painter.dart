import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/track_point.dart';

class TrackMapWidget extends StatefulWidget {
  final List<TrackPoint> points;
  final bool colorByCurvature;

  const TrackMapWidget({
    super.key,
    required this.points,
    this.colorByCurvature = true,
  });

  @override
  State<TrackMapWidget> createState() => _TrackMapWidgetState();
}

class _TrackMapWidgetState extends State<TrackMapWidget> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastFocalPoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _lastFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (_lastFocalPoint != null) {
            _offset += details.focalPoint - _lastFocalPoint!;
          }
          _lastFocalPoint = details.focalPoint;
          _scale = (_scale * details.scale).clamp(0.1, 20.0);
        });
      },
      onDoubleTap: () {
        setState(() {
          _offset = Offset.zero;
          _scale = 1.0;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.terminalBackground,
          child: CustomPaint(
            painter: _TrackPainter(
              points: widget.points,
              offset: _offset,
              scale: _scale,
              colorByCurvature: widget.colorByCurvature,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final List<TrackPoint> points;
  final Offset offset;
  final double scale;
  final bool colorByCurvature;

  _TrackPainter({
    required this.points,
    required this.offset,
    required this.scale,
    required this.colorByCurvature,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      // Texto indicando que nao ha dados
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Sem dados de mapa',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    // Calcular bounds
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    double maxCurv = 0;

    for (final p in points) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
      maxCurv = max(maxCurv, p.curvatureDps.abs());
    }

    if (maxCurv == 0) maxCurv = 1;

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final range = max(rangeX, rangeY);
    if (range == 0) return;

    final margin = 30.0;
    final drawW = size.width - margin * 2;
    final drawH = size.height - margin * 2;
    final baseScale = min(drawW / range, drawH / range);

    Offset toScreen(double x, double y) {
      final sx = margin + (x - minX) * baseScale * scale +
          (drawW - rangeX * baseScale * scale) / 2 +
          offset.dx;
      final sy = margin + (maxY - y) * baseScale * scale +
          (drawH - rangeY * baseScale * scale) / 2 +
          offset.dy;
      return Offset(sx, sy);
    }

    // Desenhar grid
    final gridPaint = Paint()
      ..color = AppColors.surfaceLight.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      final y = size.height * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Desenhar track
    for (int i = 1; i < points.length; i++) {
      final p0 = toScreen(points[i - 1].x, points[i - 1].y);
      final p1 = toScreen(points[i].x, points[i].y);

      Color lineColor;
      if (colorByCurvature) {
        final t = (points[i].curvatureDps.abs() / maxCurv).clamp(0.0, 1.0);
        lineColor = Color.lerp(AppColors.success, AppColors.error, t)!;
      } else {
        lineColor = AppColors.primary;
      }

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p0, p1, paint);
    }

    // Ponto inicial (verde)
    if (points.isNotEmpty) {
      final start = toScreen(points.first.x, points.first.y);
      canvas.drawCircle(
          start, 6, Paint()..color = AppColors.success);
      canvas.drawCircle(
          start,
          6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // Ponto final (vermelho)
    if (points.length > 1) {
      final end = toScreen(points.last.x, points.last.y);
      canvas.drawCircle(end, 6, Paint()..color = AppColors.error);
      canvas.drawCircle(
          end,
          6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // Legenda
    final legendStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
    );
    final distText = TextPainter(
      text: TextSpan(
        text:
            'Dist: ${points.last.distanceM.toStringAsFixed(2)}m  |  ${points.length} pts',
        style: legendStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    distText.layout();
    distText.paint(canvas, Offset(8, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) =>
      old.points != points ||
      old.offset != offset ||
      old.scale != scale;
}
