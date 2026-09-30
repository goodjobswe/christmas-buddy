import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/elf/elf_painter.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';
import 'package:christmas_buddy/src/scene/tree_decorations.dart';

class SceneColors {
  static const skyTop = Color(0xFF070D26);
  static const skyMid = Color(0xFF141F4A);
  static const skyHorizon = Color(0xFF2E4078);
  static const farMountain = Color(0xFF3E5088);
  static const farCrest = Color(0xFF8E9FD0);
  static const nearMountain = Color(0xFF2C3D70);
  static const nearCrest = Color(0xFF6E80B3);
  static const snow = Color(0xFFE6EDF8);
  static const snowShade = Color(0xFFCBD8EC);
  static const snowBright = Color(0xFFF7FAFF);
  static const treeDark = Color(0xFF174D27);
  static const treeLight = Color(0xFF1F6B33);
  static const trunk = Color(0xFF4A3527);
  static const pine = Color(0xFF10361E);
  static const roof = Color(0xFF3B2A22);
  static const chimney = Color(0xFF4A3A33);
  static const window = Color(0xFFFFD27A);
  static const windowGlow = Color(0xFFFFC860);
  static const door = Color(0xFF3A2A22);
  static const cornerBoard = Color(0xFFF4F4F4);
  static const lampPost = Color(0xFF262626);
  static const lampLight = Color(0xFFFFE2A6);
  static const fence = Color(0xFF6B5240);
  static const sled = Color(0xFF8B4A2A);
  static const runner = Color(0xFFB0B8C8);
  static const coal = Color(0xFF222222);
  static const carrot = Color(0xFFF08A24);
  static const twig = Color(0xFF5B3A1E);
  static const gold = Color(0xFFE9C46A);
  static const goldLight = Color(0xFFF6E3A1);
  static const starGold = Color(0xFFFFD75E);
  static const shadow = Color(0x22000000);
}

/// The village, mountains, tree and its decorations, plus the hidden elf.
/// Everything here is static for a given day, so it sits in its own
/// repaint boundary and is only repainted when the elf animates.
class ScenePainter extends CustomPainter {
  const ScenePainter({
    required this.layout,
    required this.decorations,
    this.elfSpot,
    this.elfPose = ElfPose.idle,
    this.elfT = 0,
  });

  final SceneLayout layout;
  final TreeDecorations decorations;
  final ElfSpot? elfSpot;
  final ElfPose elfPose;
  final double elfT;

  double get u => layout.unit;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas);
    _elfAfter(canvas, SceneLayer.sky);
    _paintMountains(canvas);
    _elfAfter(canvas, SceneLayer.mountains);
    _paintGround(canvas);
    _elfAfter(canvas, SceneLayer.ground);
    _paintVillage(canvas);
    _elfAfter(canvas, SceneLayer.village);
    _paintTree(canvas);
    _elfAfter(canvas, SceneLayer.tree);
    _paintForeground(canvas);
    _elfAfter(canvas, SceneLayer.foreground);
  }

  void _elfAfter(Canvas canvas, SceneLayer layer) {
    final spot = elfSpot;
    if (spot == null || spot.after != layer) return;
    canvas.save();
    canvas.clipRect(spot.visibleRect);
    ElfPainter(pose: elfPose, t: elfT, facingRight: spot.facingRight)
        .paintInto(canvas, spot.rect);
    canvas.restore();
  }

  // Sky ------------------------------------------------------------------

  void _paintSky(Canvas c) {
    final l = layout;
    final rect = Offset.zero & l.size;
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SceneColors.skyTop, SceneColors.skyMid, SceneColors.skyHorizon],
          stops: [0, 0.45, 0.68],
        ).createShader(rect),
    );

    final star = Paint();
    for (var i = 0; i < l.stars.length; i++) {
      star.color = Colors.white.withValues(alpha: 0.4 + (i % 5) * 0.12);
      c.drawCircle(l.stars[i], 0.7 + (i % 3) * 0.45, star);
    }

    final glowRect = Rect.fromCircle(center: l.moon, radius: l.moonRadius * 3.6);
    c.drawCircle(
      l.moon,
      l.moonRadius * 3.6,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55FFF1C0), Color(0x00FFF1C0)],
        ).createShader(glowRect),
    );
    c.drawCircle(l.moon, l.moonRadius, Paint()..color = const Color(0xFFFFF4D6));
    final crater = Paint()..color = const Color(0xFFEFE2BC);
    final r = l.moonRadius;
    c.drawCircle(l.moon + Offset(-r * 0.32, -r * 0.18), r * 0.22, crater);
    c.drawCircle(l.moon + Offset(r * 0.34, r * 0.28), r * 0.15, crater);
    c.drawCircle(l.moon + Offset(r * 0.02, r * 0.5), r * 0.1, crater);
  }

  // Mountains ------------------------------------------------------------

  void _paintMountains(Canvas c) {
    _paintRange(c, layout.farRidge, layout.h * 0.64, SceneColors.farMountain, SceneColors.farCrest);
    _paintRange(c, layout.nearRidge, layout.h * 0.66, SceneColors.nearMountain, SceneColors.nearCrest);
  }

  void _paintRange(Canvas c, List<Offset> ridge, double baseY, Color fill, Color crest) {
    final path = Path()..moveTo(ridge.first.dx - 1, baseY);
    for (final p in ridge) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(ridge.last.dx + 1, baseY)
      ..close();
    c.drawPath(path, Paint()..color = fill);

    final crestPaint = Paint()
      ..color = crest
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.014
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 1; i < ridge.length - 1; i++) {
      final p = ridge[i];
      if (p.dy < ridge[i - 1].dy && p.dy < ridge[i + 1].dy) {
        final left = Offset.lerp(p, ridge[i - 1], 0.32)!;
        final right = Offset.lerp(p, ridge[i + 1], 0.32)!;
        c.drawPath(
          Path()
            ..moveTo(left.dx, left.dy)
            ..lineTo(p.dx, p.dy)
            ..lineTo(right.dx, right.dy),
          crestPaint,
        );
      }
    }
  }

  // Ground ---------------------------------------------------------------

  void _paintGround(Canvas c) {
    final l = layout;
    final w = l.w;
    final h = l.h;
    c.drawPath(l.ground, Paint()..color = SceneColors.snow);

    final shade = Paint()..color = SceneColors.snowShade.withValues(alpha: 0.75);
    c.drawPath(
      Path()
        ..moveTo(-1, h * 0.705)
        ..quadraticBezierTo(w * 0.30, h * 0.665, w * 0.60, h * 0.715)
        ..quadraticBezierTo(w * 0.85, h * 0.755, w + 1, h * 0.725)
        ..lineTo(w + 1, h * 0.765)
        ..quadraticBezierTo(w * 0.60, h * 0.785, w * 0.30, h * 0.745)
        ..quadraticBezierTo(w * 0.10, h * 0.725, -1, h * 0.745)
        ..close(),
      shade,
    );
    c.drawPath(
      Path()
        ..moveTo(-1, h * 0.90)
        ..quadraticBezierTo(w * 0.35, h * 0.86, w * 0.7, h * 0.905)
        ..quadraticBezierTo(w * 0.9, h * 0.93, w + 1, h * 0.915)
        ..lineTo(w + 1, h * 0.95)
        ..quadraticBezierTo(w * 0.6, h * 0.965, w * 0.3, h * 0.935)
        ..quadraticBezierTo(w * 0.1, h * 0.915, -1, h * 0.93)
        ..close(),
      shade,
    );

    final edge = Path()
      ..moveTo(-1, h * 0.58)
      ..quadraticBezierTo(w * 0.15, h * 0.545, w * 0.32, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.575, w * 0.66, h * 0.565)
      ..quadraticBezierTo(w * 0.85, h * 0.55, w + 1, h * 0.57);
    c.drawPath(
      edge,
      Paint()
        ..color = SceneColors.snowBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.008,
    );
  }

  // Village --------------------------------------------------------------

  void _paintVillage(Canvas c) {
    for (final house in layout.houses) {
      _paintHouse(c, house);
    }
  }

  void _paintHouse(Canvas c, House hs) {
    final walls = hs.walls;
    final o = hs.overhang;

    c.drawOval(
      Rect.fromCenter(
        center: Offset(walls.center.dx, walls.bottom),
        width: walls.width * 1.4,
        height: walls.width * 0.16,
      ),
      Paint()..color = SceneColors.shadow,
    );

    c.drawRect(walls, Paint()..color = hs.color);
    c.drawRect(
      Rect.fromLTRB(walls.right - walls.width * 0.22, walls.top, walls.right, walls.bottom),
      Paint()..color = const Color(0x22000000),
    );
    final board = walls.width * 0.05;
    final boardPaint = Paint()..color = SceneColors.cornerBoard;
    c.drawRect(Rect.fromLTWH(walls.left, walls.top, board, walls.height), boardPaint);
    c.drawRect(Rect.fromLTWH(walls.right - board, walls.top, board, walls.height), boardPaint);

    for (final win in hs.windows) {
      _paintWindow(c, win);
    }

    final door = hs.door;
    if (door != null) {
      c.drawRRect(
        RRect.fromRectAndCorners(
          door,
          topLeft: Radius.circular(door.width / 2),
          topRight: Radius.circular(door.width / 2),
        ),
        Paint()..color = SceneColors.door,
      );
      c.drawCircle(
        Offset(door.right - door.width * 0.25, door.center.dy + door.height * 0.05),
        door.width * 0.07,
        Paint()..color = SceneColors.gold,
      );
    }

    final roof = Path()
      ..moveTo(walls.left - o, walls.top + o * 0.6)
      ..lineTo(hs.roofPeak.dx, hs.roofPeak.dy)
      ..lineTo(walls.right + o, walls.top + o * 0.6)
      ..close();
    c.drawPath(roof, Paint()..color = SceneColors.roof);
    final roofH = walls.top - hs.roofPeak.dy;
    final snowRoof = Path()
      ..moveTo(walls.left - o * 0.4, walls.top - roofH * 0.22)
      ..lineTo(hs.roofPeak.dx, hs.roofPeak.dy + roofH * 0.04)
      ..lineTo(walls.right + o * 0.4, walls.top - roofH * 0.22)
      ..close();
    c.drawPath(snowRoof, Paint()..color = SceneColors.snowBright);

    final ch = hs.chimney;
    c.drawRect(ch, Paint()..color = SceneColors.chimney);
    final cap = ch.height * 0.28;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ch.left - ch.width * 0.12, ch.top - cap * 0.5, ch.width * 1.24, cap),
        Radius.circular(cap * 0.4),
      ),
      Paint()..color = SceneColors.snowBright,
    );
  }

  void _paintWindow(Canvas c, Rect win) {
    final glowRect = Rect.fromCenter(center: win.center, width: win.width * 3.6, height: win.width * 3.6);
    c.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [SceneColors.windowGlow.withValues(alpha: 0.5), SceneColors.windowGlow.withValues(alpha: 0)],
        ).createShader(glowRect),
    );
    c.drawRect(win, Paint()..color = SceneColors.window);
    final bar = Paint()
      ..color = const Color(0xFF6B4F2A)
      ..strokeWidth = math.max(1, win.width * 0.08);
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), bar);
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
  }

  // Tree -----------------------------------------------------------------

  void _paintTree(Canvas c) {
    final tree = layout.tree;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(tree.centerX, tree.baseY + u * 0.01),
        width: tree.halfBase * 2.1,
        height: u * 0.07,
      ),
      Paint()..color = SceneColors.shadow,
    );
    c.drawRect(
      Rect.fromLTRB(
        tree.centerX - tree.trunkHalf,
        tree.baseY - u * 0.02,
        tree.centerX + tree.trunkHalf,
        tree.trunkBottom,
      ),
      Paint()..color = SceneColors.trunk,
    );

    final snowPaint = Paint()
      ..color = SceneColors.snowBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var k = SceneTree.tierCount - 1; k >= 0; k--) {
      final t = tree.tier(k);
      final full = Path()
        ..moveTo(t.apex.dx, t.apex.dy)
        ..lineTo(t.right.dx, t.right.dy)
        ..lineTo(t.left.dx, t.left.dy)
        ..close();
      c.drawPath(full, Paint()..color = SceneColors.treeDark);
      final lit = Path()
        ..moveTo(t.apex.dx, t.apex.dy)
        ..lineTo(t.left.dx, t.left.dy)
        ..lineTo(t.apex.dx + (t.right.dx - t.apex.dx) * 0.12, t.left.dy)
        ..close();
      c.drawPath(lit, Paint()..color = SceneColors.treeLight);

      c.drawPath(_scallop(t.left, t.right, u * 0.007, u * 0.045), snowPaint);
      c.drawLine(t.left, Offset.lerp(t.left, t.apex, 0.28)!, snowPaint);
      c.drawLine(t.right, Offset.lerp(t.right, t.apex, 0.28)!, snowPaint);
    }

    _paintDecorations(c);
  }

  Path _scallop(Offset from, Offset to, double amp, double wave) {
    final path = Path()..moveTo(from.dx, from.dy);
    final n = math.max(2, ((to - from).distance / wave).round());
    for (var i = 0; i < n; i++) {
      final a = Offset.lerp(from, to, i / n)!;
      final b = Offset.lerp(from, to, (i + 1) / n)!;
      path.quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + amp, b.dx, b.dy);
    }
    return path;
  }

  void _paintDecorations(Canvas c) {
    final d = decorations;

    final garland = Paint()
      ..color = SceneColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.012
      ..strokeCap = StrokeCap.round;
    final garlandInner = Paint()
      ..color = SceneColors.goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.004
      ..strokeCap = StrokeCap.round;
    for (final g in d.garlands) {
      c.drawPath(g, garland);
      c.drawPath(g, garlandInner);
    }

    for (final b in d.baubles) {
      final cap = Paint()..color = const Color(0xFF9AA0AA);
      c.drawRect(
        Rect.fromCenter(center: b.position - Offset(0, b.radius), width: b.radius * 0.5, height: b.radius * 0.35),
        cap,
      );
      c.drawCircle(b.position, b.radius, Paint()..color = b.color);
      c.drawCircle(
        b.position + Offset(-b.radius * 0.3, -b.radius * 0.3),
        b.radius * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }

    for (final p in d.candyCanes) {
      _paintCandyCane(c, p, u * 0.07);
    }

    for (var i = 0; i < d.giftCount && i < layout.gifts.length; i++) {
      _paintGift(c, layout.gifts[i], i);
    }
  }

  void _paintCandyCane(Canvas c, Offset base, double length) {
    final r = length * 0.26;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx, base.dy - length + r)
      ..arcToPoint(Offset(base.dx + 2 * r, base.dy - length + r), radius: Radius.circular(r));
    c.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.014
        ..strokeCap = StrokeCap.round,
    );
    final stripe = Paint()
      ..color = ElfColors.red
      ..strokeWidth = u * 0.014
      ..strokeCap = StrokeCap.butt;
    for (var y = base.dy - length * 0.08; y > base.dy - length + r; y -= length * 0.18) {
      c.drawLine(Offset(base.dx, y), Offset(base.dx, y - length * 0.08), stripe);
    }
  }

  void _paintGift(Canvas c, Rect box, int index) {
    const colors = [ElfColors.red, Color(0xFF3F7FD6), SceneColors.gold];
    const ribbons = [SceneColors.goldLight, Colors.white, ElfColors.red];
    c.drawRect(box, Paint()..color = colors[index % colors.length]);
    final ribbon = Paint()..color = ribbons[index % ribbons.length];
    c.drawRect(
      Rect.fromLTWH(box.center.dx - box.width * 0.09, box.top, box.width * 0.18, box.height),
      ribbon,
    );
    c.drawRect(
      Rect.fromLTWH(box.left, box.center.dy - box.height * 0.09, box.width, box.height * 0.18),
      ribbon,
    );
    c.drawCircle(Offset(box.center.dx - box.width * 0.13, box.top), box.width * 0.11, ribbon);
    c.drawCircle(Offset(box.center.dx + box.width * 0.13, box.top), box.width * 0.11, ribbon);
  }

  // Foreground -----------------------------------------------------------

  void _paintForeground(Canvas c) {
    final l = layout;
    _paintLampGlow(c, l.lamp);
    _paintPine(c, l.leftPine);
    _paintSled(c, l.sled);
    _paintLamp(c, l.lamp);
    _paintFence(c, l.fence);
    _paintSnowman(c, l.snowman);
    _paintDrift(c, l.drift);
    _paintPine(c, l.rightPine);
  }

  void _paintPine(Canvas c, Pine pine) {
    final snowPaint = Paint()
      ..color = SceneColors.snowShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.01
      ..strokeCap = StrokeCap.round;
    c.drawRect(
      Rect.fromCenter(
        center: Offset(pine.tip.dx, pine.bottom + u * 0.015),
        width: u * 0.03,
        height: u * 0.05,
      ),
      Paint()..color = SceneColors.trunk,
    );
    for (var j = 2; j >= 0; j--) {
      final apex = Offset(pine.tip.dx, pine.tip.dy + pine.height * 0.22 * j);
      final baseY = pine.tip.dy + pine.height * (0.45 + 0.275 * j);
      final half = pine.halfWidth * (0.45 + 0.275 * j);
      final left = Offset(pine.tip.dx - half, baseY);
      final right = Offset(pine.tip.dx + half, baseY);
      c.drawPath(
        Path()
          ..moveTo(apex.dx, apex.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(left.dx, left.dy)
          ..close(),
        Paint()..color = SceneColors.pine,
      );
      c.drawLine(left, Offset.lerp(left, apex, 0.25)!, snowPaint);
      c.drawLine(right, Offset.lerp(right, apex, 0.25)!, snowPaint);
    }
  }

  void _paintSled(Canvas c, Rect sled) {
    final runner = Paint()
      ..color = SceneColors.runner
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.008
      ..strokeCap = StrokeCap.round;
    final runnerY = sled.bottom + sled.height * 0.55;
    c.drawPath(
      Path()
        ..moveTo(sled.right, runnerY)
        ..lineTo(sled.left + sled.width * 0.05, runnerY)
        ..quadraticBezierTo(sled.left - sled.width * 0.12, runnerY, sled.left - sled.width * 0.08, sled.top - sled.height * 0.4),
      runner,
    );
    c.drawLine(Offset(sled.left + sled.width * 0.25, sled.bottom), Offset(sled.left + sled.width * 0.25, runnerY), runner);
    c.drawLine(Offset(sled.right - sled.width * 0.2, sled.bottom), Offset(sled.right - sled.width * 0.2, runnerY), runner);
    c.drawRRect(
      RRect.fromRectAndRadius(sled, Radius.circular(sled.height * 0.3)),
      Paint()..color = SceneColors.sled,
    );
    final slat = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = math.max(1, u * 0.003);
    c.drawLine(Offset(sled.left, sled.center.dy), Offset(sled.right, sled.center.dy), slat);
  }

  void _paintLampGlow(Canvas c, Lamp lamp) {
    final center = lamp.head.center;
    final rect = Rect.fromCircle(center: center, radius: u * 0.22);
    c.drawCircle(
      center,
      u * 0.22,
      Paint()
        ..shader = RadialGradient(
          colors: [SceneColors.lampLight.withValues(alpha: 0.5), SceneColors.lampLight.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  void _paintLamp(Canvas c, Lamp lamp) {
    final post = Paint()..color = SceneColors.lampPost;
    final head = lamp.head;
    c.drawRect(
      Rect.fromLTRB(lamp.top.dx - u * 0.006, head.bottom, lamp.top.dx + u * 0.006, lamp.base.dy),
      post,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: lamp.base, width: u * 0.04, height: u * 0.02),
        Radius.circular(u * 0.005),
      ),
      post,
    );
    final hw = lamp.headWidth;
    final lantern = Path()
      ..moveTo(head.center.dx - hw * 0.32, head.top)
      ..lineTo(head.center.dx + hw * 0.32, head.top)
      ..lineTo(head.right, head.bottom)
      ..lineTo(head.left, head.bottom)
      ..close();
    c.drawPath(lantern, Paint()..color = SceneColors.lampLight);
    c.drawPath(
      lantern,
      Paint()
        ..color = SceneColors.lampPost
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.004,
    );
    c.drawPath(
      Path()
        ..moveTo(head.center.dx - hw * 0.5, head.top)
        ..lineTo(head.center.dx, head.top - lamp.headHeight * 0.35)
        ..lineTo(head.center.dx + hw * 0.5, head.top)
        ..close(),
      post,
    );
    c.drawCircle(Offset(head.center.dx, head.top - lamp.headHeight * 0.3), u * 0.006, Paint()..color = SceneColors.snowBright);
    c.drawRect(
      Rect.fromCenter(center: Offset(head.center.dx, head.bottom), width: hw * 0.6, height: lamp.headHeight * 0.12),
      post,
    );
  }

  void _paintFence(Canvas c, Fence fence) {
    final r = fence.rect;
    final wood = Paint()..color = SceneColors.fence;
    final railH = r.height * 0.14;
    c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.28, r.width, railH), wood);
    c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.64, r.width, railH), wood);
    final snowDab = Paint()..color = SceneColors.snowBright;
    for (var x = r.left; x <= r.right + 0.1; x += fence.postSpacing) {
      final post = Rect.fromLTWH(x - u * 0.006, r.top, u * 0.012, r.height);
      c.drawPath(
        Path()
          ..moveTo(post.left, post.top + u * 0.008)
          ..lineTo(post.center.dx, post.top)
          ..lineTo(post.right, post.top + u * 0.008)
          ..lineTo(post.right, post.bottom)
          ..lineTo(post.left, post.bottom)
          ..close(),
        wood,
      );
      c.drawCircle(Offset(post.center.dx, post.top + u * 0.004), u * 0.006, snowDab);
    }
  }

  void _paintSnowman(Canvas c, Snowman sm) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(sm.centerX, sm.groundY),
        width: sm.bottomRadius * 2.6,
        height: sm.bottomRadius * 0.5,
      ),
      Paint()..color = SceneColors.shadow,
    );
    final white = Paint()..color = SceneColors.snowBright;
    final shade = Paint()..color = SceneColors.snowShade;
    void ball(Offset center, double r) {
      c.drawCircle(center, r, shade);
      c.drawCircle(center + Offset(-r * 0.14, -r * 0.14), r * 0.94, white);
    }

    ball(sm.bottom, sm.bottomRadius);
    ball(sm.middle, sm.middleRadius);

    // Twig arms.
    final twig = Paint()
      ..color = SceneColors.twig
      ..strokeWidth = u * 0.006
      ..strokeCap = StrokeCap.round;
    final mr = sm.middleRadius;
    final leftArm = sm.middle + Offset(-mr * 1.7, -mr * 0.9);
    final rightArm = sm.middle + Offset(mr * 1.7, -mr * 0.9);
    c.drawLine(sm.middle + Offset(-mr * 0.8, -mr * 0.2), leftArm, twig);
    c.drawLine(leftArm, leftArm + Offset(-mr * 0.25, -mr * 0.3), twig);
    c.drawLine(sm.middle + Offset(mr * 0.8, -mr * 0.2), rightArm, twig);
    c.drawLine(rightArm, rightArm + Offset(mr * 0.3, -mr * 0.25), twig);

    final coal = Paint()..color = SceneColors.coal;
    for (var i = -1; i <= 1; i++) {
      c.drawCircle(sm.middle + Offset(0, mr * 0.45 * i), mr * 0.11, coal);
    }

    ball(sm.head, sm.headRadius);
    final hr = sm.headRadius;
    // Scarf around the neck with a tail.
    final scarf = Paint()
      ..color = ElfColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = hr * 0.42
      ..strokeCap = StrokeCap.round;
    final neck = Rect.fromCircle(center: sm.head + Offset(0, hr * 0.85), radius: hr * 0.95);
    c.drawArc(neck, math.pi * 0.05, math.pi * 0.9, false, scarf);
    c.drawLine(
      sm.head + Offset(-hr * 0.8, hr * 1.25),
      sm.head + Offset(-hr * 1.35, hr * 2.1),
      scarf,
    );
    // Face: eyes, carrot pointing at the tree, a smile of coal.
    c.drawCircle(sm.head + Offset(-hr * 0.35, -hr * 0.2), hr * 0.12, coal);
    c.drawCircle(sm.head + Offset(hr * 0.05, -hr * 0.22), hr * 0.12, coal);
    c.drawPath(
      Path()
        ..moveTo(sm.head.dx - hr * 0.2, sm.head.dy - hr * 0.02)
        ..lineTo(sm.head.dx - hr * 1.3, sm.head.dy + hr * 0.12)
        ..lineTo(sm.head.dx - hr * 0.2, sm.head.dy + hr * 0.2)
        ..close(),
      Paint()..color = SceneColors.carrot,
    );
    for (var i = 0; i < 3; i++) {
      c.drawCircle(sm.head + Offset(-hr * 0.45 + hr * 0.3 * i, hr * 0.45 + (i == 1 ? hr * 0.08 : 0)), hr * 0.07, coal);
    }
    // Top hat with a red band.
    final brim = Rect.fromCenter(center: sm.head + Offset(0, -hr * 0.78), width: hr * 2.3, height: hr * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(brim, Radius.circular(hr * 0.06)), coal);
    final crown = Rect.fromLTWH(sm.head.dx - hr * 0.75, brim.top - hr * 1.15, hr * 1.5, hr * 1.2);
    c.drawRRect(RRect.fromRectAndRadius(crown, Radius.circular(hr * 0.08)), coal);
    c.drawRect(Rect.fromLTWH(crown.left, crown.bottom - hr * 0.3, crown.width, hr * 0.2), Paint()..color = ElfColors.red);
  }

  void _paintDrift(Canvas c, Rect drift) {
    c.drawOval(drift.shift(Offset(u * 0.01, u * 0.006)), Paint()..color = SceneColors.snowShade);
    c.drawOval(drift, Paint()..color = SceneColors.snowBright);
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.layout != layout ||
      old.decorations != decorations ||
      old.elfSpot != elfSpot ||
      old.elfPose != elfPose ||
      old.elfT != elfT;
}
