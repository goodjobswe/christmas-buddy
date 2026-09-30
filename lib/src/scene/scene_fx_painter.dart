import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/scene/scene_layout.dart';
import 'package:christmas_buddy/src/scene/scene_painter.dart';
import 'package:christmas_buddy/src/scene/tree_decorations.dart';

/// A little puff of snow where a tap missed the elf.
class SnowPuff {
  const SnowPuff(this.position, this.start);

  final Offset position;
  final double start;

  static const duration = 0.6;
}

/// Everything that moves: twinkling stars and lights, chimney smoke, the
/// star on top of the tree, snow puffs and the hint rings. Repaints every
/// frame through the [time] notifier.
class SceneFxPainter extends CustomPainter {
  SceneFxPainter({
    required this.layout,
    required this.decorations,
    required this.time,
    required this.puffs,
    this.hintStart,
    this.hintCenter,
  }) : super(repaint: time);

  final SceneLayout layout;
  final TreeDecorations decorations;
  final ValueNotifier<double> time;
  final List<SnowPuff> puffs;
  final double? hintStart;
  final Offset? hintCenter;

  static const hintDuration = 2.4;

  double get u => layout.unit;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    _paintStars(canvas, t);
    _paintSmoke(canvas, t);
    _paintLampFlicker(canvas, t);
    _paintLights(canvas, t);
    if (decorations.star) _paintStar(canvas, t);
    _paintPuffs(canvas, t);
    _paintHint(canvas, t);
  }

  void _paintStars(Canvas c, double t) {
    final paint = Paint();
    final stars = layout.stars;
    for (var i = 0; i < stars.length; i += 4) {
      final a = 0.5 + 0.5 * math.sin(t * 1.6 + i * 1.3);
      paint.color = Colors.white.withValues(alpha: 0.6 * a);
      c.drawCircle(stars[i], 1.2 + a * 1.2, paint);
    }
  }

  void _paintSmoke(Canvas c, double t) {
    final paint = Paint();
    for (var h = 0; h < layout.houses.length; h++) {
      final chimney = layout.houses[h].chimney;
      for (var j = 0; j < 3; j++) {
        final p = (t * 0.22 + j / 3 + h * 0.17) % 1.0;
        final rise = layout.h * 0.11 * p;
        final drift = math.sin(p * math.pi * 2 + j) * u * 0.02 + p * u * 0.03;
        final radius = u * (0.008 + 0.022 * p);
        paint.color = Colors.white.withValues(alpha: 0.32 * (1 - p) * math.min(1, p * 6));
        c.drawCircle(Offset(chimney.center.dx + drift, chimney.top - rise), radius, paint);
      }
    }
  }

  void _paintLampFlicker(Canvas c, double t) {
    final head = layout.lamp.head;
    final flicker = 0.5 + 0.5 * math.sin(t * 7.3) * math.sin(t * 2.1);
    final rect = Rect.fromCircle(center: head.center, radius: u * 0.12);
    c.drawCircle(
      head.center,
      u * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SceneColors.lampLight.withValues(alpha: 0.10 + 0.10 * flicker),
            SceneColors.lampLight.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _paintLights(Canvas c, double t) {
    final glow = Paint();
    final core = Paint();
    final r = u * 0.0065;
    for (final light in decorations.lights) {
      final b = 0.55 + 0.45 * math.sin(2 * math.pi * (t * 0.35 + light.phase));
      glow.color = light.color.withValues(alpha: 0.28 * b);
      c.drawCircle(light.position, r * 3.2, glow);
      core.color = Color.lerp(light.color, Colors.white, 0.35 * b)!.withValues(alpha: 0.7 + 0.3 * b);
      c.drawCircle(light.position, r, core);
    }
  }

  void _paintStar(Canvas c, double t) {
    final tree = layout.tree;
    final center = Offset(tree.centerX, tree.tip.dy - u * 0.012);
    final pulse = 1 + 0.08 * math.sin(t * 2 * math.pi / 2.5);
    final glowR = u * 0.13 * pulse;
    c.drawCircle(
      center,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SceneColors.starGold.withValues(alpha: 0.75),
            SceneColors.starGold.withValues(alpha: 0.25),
            SceneColors.starGold.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: center, radius: glowR)),
    );
    final path = _starPath(center, u * 0.05, u * 0.021, -math.pi / 2);
    c.drawPath(path, Paint()..color = SceneColors.starGold);
    c.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.004
        ..strokeJoin = StrokeJoin.round,
    );
    // Sparkles drifting around the star.
    final sparkle = Paint()..color = Colors.white;
    for (var i = 0; i < 6; i++) {
      final a = t * 0.8 + i * math.pi / 3;
      final d = u * (0.07 + 0.02 * math.sin(t * 3 + i));
      final p = center + Offset(math.cos(a) * d, math.sin(a) * d * 0.7);
      final s = 0.5 + 0.5 * math.sin(t * 5 + i * 2);
      sparkle.color = Colors.white.withValues(alpha: 0.8 * s);
      c.drawPath(_starPath(p, u * 0.009 * s, u * 0.003 * s, 0), sparkle);
    }
  }

  Path _starPath(Offset center, double outer, double inner, double rotation) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = rotation + i * math.pi / 5;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _paintPuffs(Canvas c, double t) {
    final paint = Paint();
    for (final puff in puffs) {
      final p = ((t - puff.start) / SnowPuff.duration).clamp(0.0, 1.0);
      if (p >= 1) continue;
      final ease = 1 - (1 - p) * (1 - p);
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 + puff.start;
        final d = u * 0.05 * ease;
        final pos = puff.position + Offset(math.cos(a) * d, math.sin(a) * d - u * 0.02 * ease);
        paint.color = Colors.white.withValues(alpha: 0.6 * (1 - p));
        c.drawCircle(pos, u * (0.006 + 0.012 * ease), paint);
      }
    }
  }

  void _paintHint(Canvas c, double t) {
    final start = hintStart;
    final center = hintCenter;
    if (start == null || center == null) return;
    final elapsed = t - start;
    if (elapsed < 0 || elapsed > hintDuration) return;
    final p = (elapsed / 1.2) % 1.0;
    final radius = u * 0.05 + u * 0.14 * p;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = SceneColors.starGold.withValues(alpha: 0.9 * (1 - p))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawCircle(
      center,
      u * 0.06,
      Paint()..color = SceneColors.starGold.withValues(alpha: 0.18 * (1 - elapsed / hintDuration)),
    );
  }

  @override
  bool shouldRepaint(SceneFxPainter old) => true;
}
