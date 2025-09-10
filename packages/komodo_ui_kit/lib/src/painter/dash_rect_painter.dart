import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashRectPainter extends CustomPainter {
  DashRectPainter({
    this.strokeWidth = 5.0,
    this.color = Colors.red,
    this.gap = 5.0,
  });

  double strokeWidth;
  Color color;
  double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final x = size.width;
    final y = size.height;

    final topPath = getDashedPath(
      const math.Point(0, 0),
      math.Point(x, 0),
      gap,
    );

    final rightPath = getDashedPath(math.Point(x, 0), math.Point(x, y), gap);

    final bottomPath = getDashedPath(math.Point(0, y), math.Point(x, y), gap);

    final leftPath = getDashedPath(
      const math.Point(0, 0),
      math.Point(0.001, y),
      gap,
    );

    canvas
      ..drawPath(topPath, dashedPaint)
      ..drawPath(rightPath, dashedPaint)
      ..drawPath(bottomPath, dashedPaint)
      ..drawPath(leftPath, dashedPaint);
  }

  Path getDashedPath(math.Point<double> a, math.Point<double> b, double gap) {
    final size = Size(b.x - a.x, b.y - a.y);
    final path = Path()..moveTo(a.x, a.y);
    var shouldDraw = true;
    var currentPoint = math.Point(a.x, a.y);

    final radians = math.atan(size.height / size.width);

    final dx = math.cos(radians) * gap < 0
        ? math.cos(radians) * gap * -1
        : math.cos(radians) * gap;

    final dy = math.sin(radians) * gap < 0
        ? math.sin(radians) * gap * -1
        : math.sin(radians) * gap;

    while (currentPoint.x <= b.x && currentPoint.y <= b.y) {
      shouldDraw
          ? path.lineTo(currentPoint.x, currentPoint.y)
          : path.moveTo(currentPoint.x, currentPoint.y);
      shouldDraw = !shouldDraw;
      currentPoint = math.Point(currentPoint.x + dx, currentPoint.y + dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
