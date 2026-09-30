import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';
import 'package:christmas_buddy/src/scene/season.dart';

/// Seasonal plants use the winter props' footprints, keeping Pip's cover intact.
class SeasonScenery {
  const SeasonScenery(this.layout, this.season);
  final SceneLayout layout;
  final Season season;
  double get u => layout.unit;

  void flower(Canvas c, Offset center, double r, Color color) {
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      c.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * r * 0.75,
        r * 0.55,
        Paint()..color = color,
      );
    }
    c.drawCircle(center, r * 0.4, Paint()..color = const Color(0xFFFFD979));
  }

  void leaf(Canvas c, Offset center, double r, Color color, double angle) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.drawPath(
      Path()
        ..moveTo(-r, 0)
        ..quadraticBezierTo(0, -r, r, 0)
        ..quadraticBezierTo(0, r, -r, 0)
        ..close(),
      Paint()..color = color,
    );
    c.drawLine(
      Offset(-r * 0.7, 0),
      Offset(r * 0.7, 0),
      Paint()
        ..color = const Color(0x66523E25)
        ..strokeWidth = math.max(0.5, r * 0.1),
    );
    c.restore();
  }

  void ground(Canvas c) {
    if (season == Season.winter) return;
    final random = math.Random(712);
    for (var i = 0; i < 85; i++) {
      final p = Offset(
        random.nextDouble() * layout.w,
        layout.h * (0.605 + random.nextDouble() * 0.35),
      );
      if (season == Season.autumn) {
        leaf(
          c,
          p,
          u * (0.003 + random.nextDouble() * 0.004),
          i.isEven ? season.accent : const Color(0xFFB25238),
          random.nextDouble() * math.pi,
        );
      } else {
        final stem =
            Paint()
              ..color = season.groundShade
              ..strokeWidth = 1;
        c.drawLine(p, p - Offset(u * 0.002, u * 0.007), stem);
        c.drawLine(p, p + Offset(u * 0.004, -u * 0.005), stem);
        if (i % 3 == 0) {
          flower(
            c,
            p - Offset(0, u * 0.008),
            u * 0.003,
            i.isEven ? season.accent : const Color(0xFFFFF0D8),
          );
        }
      }
    }
    // Round-canopied trees distinguish the seasons from the evergreen centrepiece.
    for (final x in const [0.13, 0.26, 0.73, 0.89]) {
      final base = Offset(layout.w * x, layout.h * 0.575);
      final height = u * (x < 0.5 ? 0.13 : 0.16);
      c.drawLine(
        base,
        base - Offset(0, height * 0.78),
        Paint()
          ..color = const Color(0xFF625040)
          ..strokeWidth = u * 0.009,
      );
      final crown = base - Offset(0, height * 0.7);
      final color = switch (season) {
        Season.spring => const Color(0xFFDDA6BE),
        Season.summer => const Color(0xFF477950),
        _ => x < 0.5 ? const Color(0xFFB9663D) : const Color(0xFFD6A04B),
      };
      for (final offset in const [
        Offset(-0.22, 0),
        Offset(0.22, 0),
        Offset(0, -0.2),
      ]) {
        c.drawCircle(
          crown + offset * height,
          height * 0.32,
          Paint()..color = color,
        );
      }
      if (season == Season.spring) {
        for (var j = 0; j < 8; j++) {
          flower(
            c,
            crown +
                Offset(
                  (random.nextDouble() - 0.5) * height * 0.7,
                  (random.nextDouble() - 0.5) * height * 0.6,
                ),
            u * 0.003,
            const Color(0xFFFFD7E2),
          );
        }
      }
    }
  }

  void garden(Canvas c, Snowman spot) {
    final autumn = season == Season.autumn;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(spot.centerX, spot.groundY),
        width: spot.bottomRadius * 2.6,
        height: spot.bottomRadius * 0.5,
      ),
      Paint()..color = const Color(0x22000000),
    );
    for (final (center, radius) in [
      (spot.bottom, spot.bottomRadius),
      (spot.middle, spot.middleRadius),
      (spot.head, spot.headRadius),
    ]) {
      if (autumn) {
        c.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2,
            height: radius * 1.6,
          ),
          Paint()..color = const Color(0xFFCC7236),
        );
        for (final dx in const [-0.45, 0.0, 0.45]) {
          c.drawOval(
            Rect.fromCenter(
              center: center + Offset(dx * radius, 0),
              width: radius * 0.8,
              height: radius * 1.55,
            ),
            Paint()
              ..color = const Color(0xFFEA9749)
              ..style = PaintingStyle.stroke
              ..strokeWidth = u * 0.002,
          );
        }
        c.drawLine(
          center - Offset(0, radius * 0.72),
          center + Offset(radius * 0.12, -radius),
          Paint()
            ..color = const Color(0xFF536339)
            ..strokeWidth = u * 0.004
            ..strokeCap = StrokeCap.round,
        );
      } else {
        c.drawCircle(center, radius, Paint()..color = season.groundShade);
        c.drawCircle(
          center - Offset(radius * 0.1, radius * 0.15),
          radius * 0.85,
          Paint()..color = const Color(0xFF55854C),
        );
        for (var i = 0; i < 5; i++) {
          final angle = i * math.pi * 2 / 5;
          flower(
            c,
            center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.62,
            radius * (season == Season.summer ? 0.24 : 0.18),
            season.accent,
          );
        }
      }
    }
  }

  void planter(Canvas c, Rect box) {
    c.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(u * 0.003)),
      Paint()..color = const Color(0xFF936044),
    );
    final rail =
        Paint()
          ..color = const Color(0xFFC08A60)
          ..strokeWidth = u * 0.003;
    c.drawLine(box.topLeft, box.topRight, rail);
    c.drawLine(box.centerLeft, box.centerRight, rail);
    for (var i = 0; i < 5; i++) {
      final p = Offset(box.left + box.width * (i + 0.5) / 5, box.top);
      c.drawLine(
        p,
        p - Offset(0, u * 0.015),
        Paint()
          ..color = const Color(0xFF426D3D)
          ..strokeWidth = u * 0.002,
      );
      if (season == Season.autumn) {
        leaf(
          c,
          p - Offset(0, u * 0.012),
          u * 0.009,
          season.accent,
          -0.5 + i * 0.4,
        );
      } else {
        flower(
          c,
          p - Offset(0, u * 0.015),
          u * 0.006,
          i.isEven ? season.accent : const Color(0xFFFFF0D8),
        );
      }
    }
  }

  void drift(Canvas c, Rect area) {
    for (var i = 0; i < 12; i++) {
      final p = Offset(
        area.left + area.width * (i + 0.5) / 12,
        area.center.dy + math.sin(i * 2.7) * area.height * 0.18,
      );
      if (season == Season.autumn) {
        leaf(
          c,
          p,
          u * 0.007,
          i.isEven ? season.accent : const Color(0xFFB25238),
          i * 1.3,
        );
      } else {
        flower(c, p, u * 0.004, season.accent);
      }
    }
  }

  void breeze(Canvas c, double t) {
    if (season == Season.winter) return;
    for (var i = 0; i < 18; i++) {
      final phase = i * 2.399;
      final x =
          layout.w * ((i * 0.173 + t * 0.012) % 1) +
          math.sin(t * 0.7 + phase) * u * 0.03;
      if (season == Season.summer) {
        final p = Offset(
          x,
          layout.h * (0.58 + (i % 6) * 0.055) +
              math.sin(t * 0.6 + phase) * u * 0.025,
        );
        final alpha = 0.2 + 0.65 * (0.5 + 0.5 * math.sin(t * 1.2 + phase));
        c.drawCircle(
          p,
          u * 0.009,
          Paint()..color = season.accent.withValues(alpha: alpha * 0.18),
        );
        c.drawCircle(
          p,
          u * 0.0025,
          Paint()..color = season.accent.withValues(alpha: alpha),
        );
      } else {
        final p = Offset(
          x,
          layout.h * (0.43 + ((i * 0.137 + t * 0.018) % 0.52)),
        );
        if (season == Season.autumn) {
          leaf(
            c,
            p,
            u * 0.005,
            i.isEven ? season.accent : const Color(0xFFC25E3D),
            t * 0.6 + phase,
          );
        } else {
          c.save();
          c.translate(p.dx, p.dy);
          c.rotate(t * 0.5 + phase);
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: u * 0.007,
              height: u * 0.012,
            ),
            Paint()..color = season.accent.withValues(alpha: 0.8),
          );
          c.restore();
        }
      }
    }
  }
}
