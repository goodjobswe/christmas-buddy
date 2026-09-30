import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/scene/scene_events.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';
import 'package:christmas_buddy/src/scene/scene_painter.dart';
import 'package:christmas_buddy/src/scene/season.dart';
import 'package:christmas_buddy/src/scene/season_scenery.dart';
import 'package:christmas_buddy/src/scene/tree_decorations.dart';

/// A little puff of snow where a tap missed the elf.
class SnowPuff {
  const SnowPuff(this.position, this.start);

  final Offset position;
  final double start;

  static const duration = 0.6;
}

/// Everything that moves: northern lights, twinkling stars and lights,
/// shooting stars, chimney smoke, the star on top of the tree, Santa's
/// sleigh, snow puffs and the hint rings. Repaints every frame through the
/// [time] notifier.
class SceneFxPainter extends CustomPainter {
  SceneFxPainter({
    required this.layout,
    required this.decorations,
    required this.events,
    required this.time,
    required this.puffs,
    this.season = Season.winter,
    this.hintStart,
    this.hintCenter,
  }) : super(repaint: time);

  final SceneLayout layout;
  final Season season;
  final TreeDecorations decorations;
  final SceneEvents events;
  final ValueNotifier<double> time;
  final List<SnowPuff> puffs;
  final double? hintStart;
  final Offset? hintCenter;

  static const hintDuration = 2.4;

  double get u => layout.unit;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (events.aurora) _paintAurora(canvas, t);
    _paintStars(canvas, t);
    _paintShootingStar(canvas, t);
    if (events.sleigh) _paintSleigh(canvas, t);
    if (season == Season.winter || season == Season.autumn) _paintSmoke(canvas, t);
    SeasonScenery(layout, season).breeze(canvas, t);
    _paintLampFlicker(canvas, t);
    _paintLights(canvas, t);
    if (decorations.star) _paintStar(canvas, t);
    _paintPuffs(canvas, t);
    _paintHint(canvas, t);
  }

  void _paintAurora(Canvas c, double t) {
    final w = layout.w;
    final h = layout.h;
    const colors = [Color(0xFF7CF7B0), Color(0xFF6FE3E8), Color(0xFFB08CFF)];
    for (var b = 0; b < 3; b++) {
      final baseY = h * (0.05 + 0.075 * b);
      final amp = h * 0.035;
      final band = h * 0.11;
      final path = Path();
      final bottom = <Offset>[];
      const n = 16;
      for (var i = 0; i <= n; i++) {
        final x = w * i / n;
        final y = baseY +
            amp * math.sin(x / w * math.pi * 2 * 1.3 + t * 0.18 + b * 1.7) +
            amp * 0.4 * math.sin(x / w * math.pi * 2 * 3.1 - t * 0.11 + b);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        bottom.add(Offset(x, y + band * (0.8 + 0.2 * math.sin(x / w * 5 + t * 0.2 + b))));
      }
      for (final p in bottom.reversed) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      final rect = Rect.fromLTWH(0, baseY - amp, w, band + 2 * amp);
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors[b].withValues(alpha: 0),
              colors[b].withValues(alpha: 0.30 - b * 0.06),
              colors[b].withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 1],
          ).createShader(rect),
      );
    }
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

  void _paintShootingStar(Canvas c, double t) {
    const period = 23.0;
    final cycle = (t / period).floor();
    final p = (t - cycle * period) / 1.1;
    if (p >= 1) return;
    final random = math.Random(cycle * 31 + 7);
    final start = Offset(layout.w * (0.1 + 0.7 * random.nextDouble()), layout.h * (0.04 + 0.2 * random.nextDouble()));
    const dir = Offset(0.912, 0.410);
    final head = start + dir * (u * 0.55 * p);
    final tail = head - dir * (u * 0.2 * (1 - p * 0.3));
    c.drawLine(
      tail,
      head,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9 * (1 - p))],
        ).createShader(Rect.fromPoints(tail, head)..inflate(1))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(head, 2.2, Paint()..color = Colors.white.withValues(alpha: 1 - p));
  }

  void _paintSleigh(Canvas c, double t) {
    const period = 40.0;
    final p = (t % period) / 13.0;
    if (p >= 1) return;
    final moon = layout.moon;
    final x = -layout.w * 0.2 + layout.w * 1.4 * p;
    final y = moon.dy - layout.moonRadius * 0.3 + math.sin(p * math.pi * 2) * layout.h * 0.012;
    final s = u * 0.045;
    final dark = Paint()..color = const Color(0xFF15102B);

    // Golden dust trailing behind the sleigh.
    for (var i = 1; i <= 9; i++) {
      final f = i / 9;
      final pos = Offset(x - s * 1.2 - i * s * 0.7, y + s * 0.2 + math.sin(t * 6 + i) * s * 0.25);
      c.drawCircle(pos, s * 0.12 * (1 - f * 0.6), Paint()..color = SceneColors.starGold.withValues(alpha: 0.7 * (1 - f)));
    }

    // Sleigh with Santa.
    final sleigh = Path()
      ..moveTo(x - s * 1.1, y + s * 0.5)
      ..quadraticBezierTo(x - s * 1.4, y + s * 0.5, x - s * 1.3, y - s * 0.2)
      ..lineTo(x - s * 0.9, y - s * 0.2)
      ..lineTo(x - s * 0.9, y - s * 0.5)
      ..lineTo(x + s * 0.6, y - s * 0.5)
      ..lineTo(x + s * 0.9, y + s * 0.5)
      ..close();
    c.drawPath(sleigh, dark);
    c.drawLine(
      Offset(x - s * 1.4, y + s * 0.65),
      Offset(x + s * 1.1, y + s * 0.65),
      Paint()
        ..color = dark.color
        ..strokeWidth = s * 0.12
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(Offset(x - s * 0.15, y - s * 0.75), s * 0.28, dark);
    c.drawPath(
      Path()
        ..moveTo(x - s * 0.4, y - s * 0.9)
        ..lineTo(x - s * 0.1, y - s * 1.35)
        ..lineTo(x + s * 0.15, y - s * 0.95)
        ..close(),
      dark,
    );

    // Two reindeer up front, legs mid gallop.
    for (var k = 0; k < 2; k++) {
      final bx = x + s * (2.3 + k * 1.7);
      final gallop = math.sin(t * 10 + k) * s * 0.15;
      c.drawOval(Rect.fromCenter(center: Offset(bx, y - s * 0.1), width: s * 1.2, height: s * 0.5), dark);
      c.drawOval(Rect.fromCenter(center: Offset(bx + s * 0.65, y - s * 0.55), width: s * 0.45, height: s * 0.3), dark);
      final leg = Paint()
        ..color = dark.color
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(bx - s * 0.4, y + s * 0.05), Offset(bx - s * 0.6 - gallop, y + s * 0.5), leg);
      c.drawLine(Offset(bx + s * 0.35, y + s * 0.05), Offset(bx + s * 0.6 + gallop, y + s * 0.45), leg);
      final antler = Paint()
        ..color = dark.color
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(bx + s * 0.6, y - s * 0.65), Offset(bx + s * 0.45, y - s * 1.05), antler);
      c.drawLine(Offset(bx + s * 0.7, y - s * 0.65), Offset(bx + s * 0.75, y - s * 1.05), antler);
      c.drawLine(Offset(bx + s * 0.1, y - s * 0.3), Offset(bx + s * 0.4, y - s * 0.5), leg);
      if (k == 1) {
        final nose = Offset(bx + s * 0.9, y - s * 0.55);
        c.drawCircle(nose, s * 0.18, Paint()..color = ElfNoseGlow.color);
        c.drawCircle(nose, s * 0.08, Paint()..color = const Color(0xFFFF2A2A));
      }
    }
    // Reins.
    c.drawLine(
      Offset(x + s * 0.6, y - s * 0.4),
      Offset(x + s * 4.4, y - s * 0.45),
      Paint()
        ..color = dark.color
        ..strokeWidth = math.max(1, s * 0.05),
    );
  }

  void _paintSmoke(Canvas c, double t) {
    final paint = Paint();
    final chimneys = [
      for (final house in layout.houses) house.chimney,
      for (final house in layout.backHouses) house.chimney,
    ];
    for (var h = 0; h < chimneys.length; h++) {
      final chimney = chimneys[h];
      for (var j = 0; j < 3; j++) {
        final p = (t * 0.22 + j / 3 + h * 0.17) % 1.0;
        final rise = layout.h * 0.11 * p;
        final drift = math.sin(p * math.pi * 2 + j) * u * 0.02 + p * u * 0.03;
        final radius = u * (0.008 + 0.022 * p) * (h >= 4 ? 0.6 : 1);
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
        paint.color = season.accent.withValues(alpha: 0.6 * (1 - p));
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

/// The soft red halo around the lead reindeer's nose.
class ElfNoseGlow {
  static const color = Color(0x66FF2A2A);
}
