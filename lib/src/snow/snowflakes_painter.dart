import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/snow/snowflake_model.dart';

/// Paints the flakes. Far flakes are drawn first so near ones sit on top.
class SnowPainter extends CustomPainter {
  SnowPainter({required this.flakes, required Listenable repaint})
      : super(repaint: repaint);

  final List<Snowflake> flakes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final flake in flakes) {
      paint.color = Colors.white.withValues(alpha: flake.alpha);
      canvas.drawCircle(Offset(flake.x, flake.y), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => oldDelegate.flakes != flakes;
}
