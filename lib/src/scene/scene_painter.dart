import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/elf/elf_painter.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_events.dart';
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
  static const slopePine = Color(0xFF1C2B4E);
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
  static const churchWall = Color(0xFFF3EEE6);
  static const lampPost = Color(0xFF262626);
  static const lampLight = Color(0xFFFFE2A6);
  static const wood = Color(0xFF6B5240);
  static const woodDark = Color(0xFF4A3A2A);
  static const logEnd = Color(0xFFD9B48F);
  static const log = Color(0xFF8B5E3C);
  static const sled = Color(0xFF8B4A2A);
  static const runner = Color(0xFFB0B8C8);
  static const coal = Color(0xFF222222);
  static const carrot = Color(0xFFF08A24);
  static const twig = Color(0xFF5B3A1E);
  static const gold = Color(0xFFE9C46A);
  static const goldLight = Color(0xFFF6E3A1);
  static const starGold = Color(0xFFFFD75E);
  static const reindeer = Color(0xFF7A4B2A);
  static const reindeerDark = Color(0xFF4A2F1A);
  static const cream = Color(0xFFEFE6D8);
  static const shadow = Color(0x22000000);
}

/// The village, mountains, tree and its decorations, plus the hidden elf.
/// Everything here is static for a given day, so it sits in its own
/// repaint boundary and is only repainted while the elf reacts.
class ScenePainter extends CustomPainter {
  const ScenePainter({
    required this.layout,
    required this.decorations,
    required this.events,
    this.elfSpot,
    this.elfReacting = false,
    this.elfT = 0,
  });

  final SceneLayout layout;
  final TreeDecorations decorations;
  final SceneEvents events;
  final ElfSpot? elfSpot;
  final bool elfReacting;
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
    _paintBackVillage(canvas);
    _elfAfter(canvas, SceneLayer.backVillage);
    _paintVillage(canvas);
    _elfAfter(canvas, SceneLayer.village);
    _paintTree(canvas);
    _elfAfter(canvas, SceneLayer.tree);
    _paintForeground(canvas);
    _elfAfter(canvas, SceneLayer.foreground);
  }

  // The elf ---------------------------------------------------------------

  void _elfAfter(Canvas canvas, SceneLayer layer) {
    final spot = elfSpot;
    if (spot == null || spot.after != layer) return;

    var rect = spot.rect;
    var clip = spot.visibleRect;
    var pose = ElfPose.idle;
    var t = 0.0;
    var rotation = 0.0;

    if (elfReacting) {
      t = elfT;
      final swell = math.sin(math.pi * t);
      switch (spot.reaction) {
        case ElfReaction.wave:
          pose = ElfPose.wave;
        case ElfReaction.popUp:
          pose = ElfPose.wave;
          final lift = ((1 - spot.visible) * spot.height + spot.height * 0.15) * swell;
          rect = rect.shift(Offset(0, -lift));
          clip = Rect.fromLTRB(clip.left, clip.top - lift - spot.height * 0.2, clip.right, clip.bottom);
        case ElfReaction.peekOut:
          pose = ElfPose.wave;
          final dx = spot.width * 0.7 * swell * (spot.facingRight ? 1 : -1);
          rect = rect.shift(Offset(dx, 0));
          clip = clip.shift(Offset(dx, 0));
        case ElfReaction.tumble:
          pose = ElfPose.wave;
          rotation = math.sin(t * math.pi * 4) * 0.35 * (1 - t);
          clip = clip.inflate(spot.height * 0.4);
        case ElfReaction.jump:
          pose = ElfPose.jump;
          clip = Rect.fromLTRB(clip.left, clip.top - spot.height * 0.25, clip.right, clip.bottom);
      }
    }

    canvas.save();
    canvas.clipRect(clip);
    if (rotation != 0) {
      canvas.translate(spot.feet.dx, spot.feet.dy);
      canvas.rotate(rotation);
      canvas.translate(-spot.feet.dx, -spot.feet.dy);
    }
    ElfPainter(pose: pose, t: t, facingRight: spot.facingRight).paintInto(canvas, rect);
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
    for (final pine in layout.slopePines) {
      _paintPine(c, pine, color: SceneColors.slopePine, snow: false, trunk: false);
    }
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

    for (final pine in l.hillPines) {
      _paintPine(c, pine, trunk: false);
    }
  }

  // Village --------------------------------------------------------------

  void _paintBackVillage(Canvas c) {
    for (final house in layout.backHouses) {
      _paintHouse(c, house);
    }
    _paintChurch(c, layout.church);
  }

  void _paintVillage(Canvas c) {
    for (final house in layout.houses) {
      _paintHouse(c, house);
    }
    _paintPostbox(c, layout.postbox);
    _paintWoodpile(c, layout.woodpile);
    for (var i = 0; i < layout.giftStack.length; i++) {
      _paintGift(c, layout.giftStack[i], i + 1);
    }
    for (final bird in layout.birds) {
      _paintBird(c, bird);
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

  void _paintWindow(Canvas c, Rect win, {bool arched = false}) {
    final glowRect = Rect.fromCenter(center: win.center, width: win.width * 3.6, height: win.width * 3.6);
    c.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [SceneColors.windowGlow.withValues(alpha: 0.5), SceneColors.windowGlow.withValues(alpha: 0)],
        ).createShader(glowRect),
    );
    final paint = Paint()..color = SceneColors.window;
    if (arched) {
      c.drawRRect(
        RRect.fromRectAndCorners(
          win,
          topLeft: Radius.circular(win.width / 2),
          topRight: Radius.circular(win.width / 2),
        ),
        paint,
      );
      return;
    }
    c.drawRect(win, paint);
    final bar = Paint()
      ..color = const Color(0xFF6B4F2A)
      ..strokeWidth = math.max(1, win.width * 0.08);
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), bar);
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
  }

  void _paintChurch(Canvas c, Church church) {
    final body = church.body;
    final tower = church.tower;
    final o = body.width * 0.08;

    c.drawRect(body, Paint()..color = SceneColors.churchWall);
    final roofH = body.width * 0.32;
    final roof = Path()
      ..moveTo(body.left - o, body.top + o * 0.5)
      ..lineTo(body.center.dx, body.top - roofH)
      ..lineTo(body.right + o, body.top + o * 0.5)
      ..close();
    c.drawPath(roof, Paint()..color = SceneColors.roof);
    c.drawPath(
      Path()
        ..moveTo(body.left - o * 0.3, body.top - roofH * 0.2)
        ..lineTo(body.center.dx, body.top - roofH * 0.95)
        ..lineTo(body.right + o * 0.3, body.top - roofH * 0.2)
        ..close(),
      Paint()..color = SceneColors.snowBright,
    );
    for (final win in church.windows) {
      _paintWindow(c, win, arched: true);
    }

    c.drawRect(tower, Paint()..color = SceneColors.churchWall);
    c.drawRect(
      Rect.fromLTRB(tower.right - tower.width * 0.25, tower.top, tower.right, tower.bottom),
      Paint()..color = const Color(0x1A000000),
    );
    final bell = church.bell;
    c.drawRRect(
      RRect.fromRectAndCorners(
        bell,
        topLeft: Radius.circular(bell.width / 2),
        topRight: Radius.circular(bell.width / 2),
      ),
      Paint()..color = const Color(0xFF2A1E18),
    );
    c.drawCircle(bell.center + Offset(0, bell.height * 0.1), bell.width * 0.26, Paint()..color = SceneColors.gold);

    final spire = Path()
      ..moveTo(tower.left - u * 0.004, tower.top)
      ..lineTo(church.spireTip.dx, church.spireTip.dy)
      ..lineTo(tower.right + u * 0.004, tower.top)
      ..close();
    c.drawPath(spire, Paint()..color = SceneColors.roof);
    c.drawLine(
      Offset(tower.left - u * 0.004, tower.top),
      church.spireTip,
      Paint()
        ..color = SceneColors.snowBright
        ..strokeWidth = u * 0.006
        ..strokeCap = StrokeCap.round,
    );
    final cross = Paint()
      ..color = SceneColors.gold
      ..strokeWidth = u * 0.004
      ..strokeCap = StrokeCap.round;
    final tip = church.spireTip;
    c.drawLine(tip, tip - Offset(0, u * 0.016), cross);
    c.drawLine(tip - Offset(u * 0.005, u * 0.011), tip - Offset(-u * 0.005, u * 0.011), cross);
  }

  void _paintPostbox(Canvas c, Rect box) {
    c.drawRect(
      Rect.fromLTRB(box.center.dx - u * 0.003, box.bottom, box.center.dx + u * 0.003, layout.villageBase),
      Paint()..color = SceneColors.woodDark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(box.width * 0.2)),
      Paint()..color = ElfColors.red,
    );
    c.drawRect(
      Rect.fromLTWH(box.left + box.width * 0.2, box.top + box.height * 0.3, box.width * 0.6, box.height * 0.1),
      Paint()..color = Colors.white,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(box.left - box.width * 0.08, box.top - box.height * 0.12, box.width * 1.16, box.height * 0.22),
        Radius.circular(box.width * 0.1),
      ),
      Paint()..color = SceneColors.snowBright,
    );
  }

  void _paintWoodpile(Canvas c, Rect pile) {
    final r = pile.height / 5.2;
    final logPaint = Paint()..color = SceneColors.log;
    final endPaint = Paint()..color = SceneColors.logEnd;
    final rows = [4, 3, 2];
    for (var row = 0; row < rows.length; row++) {
      final count = rows[row];
      final y = pile.bottom - r - row * r * 1.75;
      final startX = pile.center.dx - (count - 1) * r;
      for (var i = 0; i < count; i++) {
        final center = Offset(startX + i * r * 2, y);
        c.drawCircle(center, r, logPaint);
        c.drawCircle(center, r * 0.6, endPaint);
      }
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pile.center.dx, pile.top + r * 0.2), width: r * 4.4, height: r * 0.9),
        Radius.circular(r * 0.4),
      ),
      Paint()..color = SceneColors.snowBright,
    );
  }

  void _paintBird(Canvas c, Offset perch) {
    final r = u * 0.0065;
    c.drawCircle(perch + Offset(0, -r), r, Paint()..color = ElfColors.red);
    c.drawCircle(perch + Offset(r * 0.9, -r * 1.9), r * 0.7, Paint()..color = SceneColors.coal);
    c.drawPath(
      Path()
        ..moveTo(perch.dx - r * 0.6, perch.dy - r * 1.2)
        ..lineTo(perch.dx - r * 2.2, perch.dy - r * 1.6)
        ..lineTo(perch.dx - r * 2.0, perch.dy - r * 0.6)
        ..close(),
      Paint()..color = SceneColors.coal,
    );
    c.drawCircle(perch + Offset(r * 1.7, -r * 1.9), r * 0.25, Paint()..color = SceneColors.gold);
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
    const colors = [ElfColors.red, Color(0xFF3F7FD6), SceneColors.gold, ElfColors.green];
    const ribbons = [SceneColors.goldLight, Colors.white, ElfColors.red, SceneColors.goldLight];
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
    final station = events.reindeerStation;
    if (station != null && station == 1) {
      _paintReindeer(c, l.reindeerStations[1]);
    }
    _paintBench(c, l.bench);
    _paintSled(c, l.sled);
    _paintLamp(c, l.lamp);
    if (station != null && station == 0) {
      _paintReindeer(c, l.reindeerStations[0]);
    }
    _paintFence(c, l.fence);
    _paintSnowman(c, l.snowman);
    _paintDrift(c, l.drift);
    for (final v in l.villagers) {
      _paintVillager(c, v);
    }
    _paintPine(c, l.rightPine);
    _paintSignpost(c, l.signpost);
  }

  void _paintPine(Canvas c, Pine pine, {Color color = SceneColors.pine, bool snow = true, bool trunk = true}) {
    final snowPaint = Paint()
      ..color = SceneColors.snowShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, pine.height * 0.035)
      ..strokeCap = StrokeCap.round;
    if (trunk) {
      c.drawRect(
        Rect.fromCenter(
          center: Offset(pine.tip.dx, pine.bottom + u * 0.015),
          width: u * 0.03,
          height: u * 0.05,
        ),
        Paint()..color = SceneColors.trunk,
      );
    }
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
        Paint()..color = color,
      );
      if (snow) {
        c.drawLine(left, Offset.lerp(left, apex, 0.25)!, snowPaint);
        c.drawLine(right, Offset.lerp(right, apex, 0.25)!, snowPaint);
      }
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

  void _paintBench(Canvas c, Bench bench) {
    final seat = bench.seat;
    final wood = Paint()..color = SceneColors.wood;
    final dark = Paint()..color = SceneColors.woodDark;
    final legW = seat.width * 0.06;
    c.drawRect(Rect.fromLTRB(seat.left + legW, seat.bottom, seat.left + legW * 2, bench.legBottom), dark);
    c.drawRect(Rect.fromLTRB(seat.right - legW * 2, seat.bottom, seat.right - legW, bench.legBottom), dark);
    c.drawRect(Rect.fromLTRB(seat.left + legW, bench.backTop, seat.left + legW * 2, seat.top), dark);
    c.drawRect(Rect.fromLTRB(seat.right - legW * 2, bench.backTop, seat.right - legW, seat.top), dark);
    final slatH = (seat.top - bench.backTop) * 0.3;
    c.drawRect(Rect.fromLTWH(seat.left, bench.backTop, seat.width, slatH), wood);
    c.drawRect(Rect.fromLTWH(seat.left, bench.backTop + slatH * 1.7, seat.width, slatH), wood);
    c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(seat.height * 0.3)), wood);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(seat.left - u * 0.002, seat.top - seat.height * 0.5, seat.width + u * 0.004, seat.height * 0.7),
        Radius.circular(seat.height * 0.3),
      ),
      Paint()..color = SceneColors.snowBright,
    );
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
    final wood = Paint()..color = SceneColors.wood;
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

  void _paintSignpost(Canvas c, Signpost sign) {
    final top = sign.top;
    final base = sign.base;
    final poleW = u * 0.012;
    final pole = Rect.fromLTRB(base.dx - poleW / 2, top.dy, base.dx + poleW / 2, base.dy);
    c.drawRect(pole, Paint()..color = Colors.white);
    final stripe = Paint()..color = ElfColors.red;
    for (var y = top.dy + u * 0.01; y < base.dy; y += u * 0.024) {
      c.drawRect(Rect.fromLTWH(pole.left, y, poleW, u * 0.012), stripe);
    }
    c.drawCircle(top, poleW * 0.9, stripe);

    final boardH = u * 0.03;
    final boardW = u * 0.08;
    final boardTop = top.dy + u * 0.028;
    final board = Path()
      ..moveTo(base.dx + poleW * 0.4, boardTop)
      ..lineTo(base.dx + poleW * 0.4 - boardW + boardH * 0.6, boardTop)
      ..lineTo(base.dx + poleW * 0.4 - boardW, boardTop + boardH / 2)
      ..lineTo(base.dx + poleW * 0.4 - boardW + boardH * 0.6, boardTop + boardH)
      ..lineTo(base.dx + poleW * 0.4, boardTop + boardH)
      ..close();
    c.drawPath(board, Paint()..color = SceneColors.cream);
    c.drawPath(
      board,
      Paint()
        ..color = SceneColors.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, u * 0.003),
    );
    final text = Paint()
      ..color = SceneColors.woodDark
      ..strokeWidth = math.max(1, u * 0.004)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = boardTop + boardH * (0.3 + 0.2 * i);
      final x0 = base.dx + poleW * 0.4 - boardW * (0.72 - 0.06 * i);
      c.drawLine(Offset(x0, y), Offset(x0 + boardW * (0.5 - 0.08 * i), y), text);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + poleW * 0.4 - boardW * 0.9, boardTop - u * 0.005, boardW * 0.85, u * 0.008),
        Radius.circular(u * 0.003),
      ),
      Paint()..color = SceneColors.snowBright,
    );
  }

  void _paintVillager(Canvas c, Villager v) {
    final hgt = v.height;
    final x = v.feet.dx;
    final y0 = v.feet.dy;
    final dir = v.facingRight ? 1.0 : -1.0;

    c.drawOval(
      Rect.fromCenter(center: Offset(x, y0), width: hgt * 0.5, height: hgt * 0.1),
      Paint()..color = SceneColors.shadow,
    );
    final legs = Paint()..color = const Color(0xFF2B3A5C);
    for (final side in const [-1.0, 1.0]) {
      c.drawRect(Rect.fromLTWH(x + side * hgt * 0.09 - hgt * 0.055, y0 - hgt * 0.30, hgt * 0.11, hgt * 0.30), legs);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + side * hgt * 0.09 - hgt * 0.07, y0 - hgt * 0.07, hgt * 0.14, hgt * 0.07),
          Radius.circular(hgt * 0.03),
        ),
        Paint()..color = SceneColors.woodDark,
      );
    }
    final jacket = Paint()..color = v.jacket;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - hgt * 0.21, y0 - hgt * 0.68, hgt * 0.42, hgt * 0.42),
        Radius.circular(hgt * 0.08),
      ),
      jacket,
    );
    c.drawLine(
      Offset(x, y0 - hgt * 0.64),
      Offset(x, y0 - hgt * 0.30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = math.max(1, hgt * 0.025),
    );
    final arm = Paint()
      ..color = v.jacket
      ..strokeWidth = hgt * 0.09
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x - hgt * 0.18, y0 - hgt * 0.60), Offset(x - hgt * 0.27, y0 - hgt * 0.38), arm);
    c.drawLine(Offset(x + hgt * 0.18, y0 - hgt * 0.60), Offset(x + hgt * 0.27, y0 - hgt * 0.38), arm);
    final mitten = Paint()..color = v.hat;
    c.drawCircle(Offset(x - hgt * 0.27, y0 - hgt * 0.37), hgt * 0.055, mitten);
    c.drawCircle(Offset(x + hgt * 0.27, y0 - hgt * 0.37), hgt * 0.055, mitten);
    c.drawRect(
      Rect.fromLTWH(x - hgt * 0.23, y0 - hgt * 0.70, hgt * 0.46, hgt * 0.07),
      Paint()..color = SceneColors.goldLight,
    );

    final headC = Offset(x, y0 - hgt * 0.84);
    final hr = hgt * 0.16;
    c.drawCircle(headC, hr, Paint()..color = ElfColors.skin);
    final eye = Paint()..color = ElfColors.eye;
    c.drawCircle(headC + Offset(dir * hr * 0.15, -hr * 0.05), hr * 0.12, eye);
    c.drawCircle(headC + Offset(dir * hr * 0.55, -hr * 0.05), hr * 0.12, eye);
    c.drawCircle(headC + Offset(dir * hr * 0.3, hr * 0.35), hr * 0.2, Paint()..color = ElfColors.cheek);

    final hat = Paint()..color = v.hat;
    c.drawArc(
      Rect.fromCircle(center: headC + Offset(0, -hr * 0.05), radius: hr * 1.08),
      math.pi,
      math.pi,
      true,
      hat,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(headC.dx - hr * 1.1, headC.dy - hr * 0.3, hr * 2.2, hr * 0.32),
        Radius.circular(hr * 0.1),
      ),
      Paint()..color = Color.lerp(v.hat, Colors.black, 0.25)!,
    );
    c.drawCircle(headC + Offset(0, -hr * 1.15), hr * 0.28, Paint()..color = Colors.white);
  }

  void _paintReindeer(Canvas c, Reindeer r) {
    final hgt = r.height;
    final dir = r.facingRight ? 1.0 : -1.0;
    final fx = r.feet.dx;
    final fy = r.feet.dy;
    final body = Paint()..color = SceneColors.reindeer;
    final dark = Paint()..color = SceneColors.reindeerDark;

    c.drawOval(
      Rect.fromCenter(center: Offset(fx, fy), width: hgt * 1.0, height: hgt * 0.12),
      Paint()..color = SceneColors.shadow,
    );
    final leg = Paint()
      ..color = SceneColors.reindeer
      ..strokeWidth = hgt * 0.07
      ..strokeCap = StrokeCap.round;
    for (final off in const [-0.30, -0.16, 0.16, 0.30]) {
      c.drawLine(Offset(fx + off * hgt, fy - hgt * 0.45), Offset(fx + off * hgt * 1.1, fy - hgt * 0.02), leg);
      c.drawCircle(Offset(fx + off * hgt * 1.1, fy - hgt * 0.02), hgt * 0.04, dark);
    }
    c.drawOval(Rect.fromCenter(center: Offset(fx, fy - hgt * 0.52), width: hgt * 0.9, height: hgt * 0.38), body);
    c.drawOval(
      Rect.fromCenter(center: Offset(fx, fy - hgt * 0.45), width: hgt * 0.6, height: hgt * 0.16),
      Paint()..color = SceneColors.cream.withValues(alpha: 0.8),
    );
    c.drawCircle(Offset(fx - dir * hgt * 0.46, fy - hgt * 0.58), hgt * 0.06, dark);
    c.drawLine(
      Offset(fx + dir * hgt * 0.35, fy - hgt * 0.62),
      Offset(fx + dir * hgt * 0.55, fy - hgt * 0.92),
      Paint()
        ..color = SceneColors.reindeer
        ..strokeWidth = hgt * 0.17
        ..strokeCap = StrokeCap.round,
    );
    final headC = Offset(fx + dir * hgt * 0.62, fy - hgt * 0.97);
    c.drawOval(Rect.fromCenter(center: headC, width: hgt * 0.32, height: hgt * 0.2), body);
    c.drawPath(
      Path()
        ..moveTo(headC.dx - dir * hgt * 0.06, headC.dy - hgt * 0.08)
        ..lineTo(headC.dx - dir * hgt * 0.16, headC.dy - hgt * 0.2)
        ..lineTo(headC.dx - dir * hgt * 0.00, headC.dy - hgt * 0.12)
        ..close(),
      body,
    );
    c.drawCircle(headC + Offset(dir * hgt * 0.06, -hgt * 0.03), hgt * 0.022, Paint()..color = ElfColors.eye);
    final nose = Offset(headC.dx + dir * hgt * 0.16, headC.dy);
    if (events.sleigh) {
      c.drawCircle(nose, hgt * 0.09, Paint()..color = ElfColors.red.withValues(alpha: 0.35));
      c.drawCircle(nose, hgt * 0.045, Paint()..color = ElfColors.red);
    } else {
      c.drawCircle(nose, hgt * 0.035, dark);
    }
    final antler = Paint()
      ..color = SceneColors.reindeerDark
      ..strokeWidth = math.max(1, hgt * 0.035)
      ..strokeCap = StrokeCap.round;
    for (final side in const [-0.08, 0.02]) {
      final root = Offset(headC.dx - dir * hgt * side, headC.dy - hgt * 0.08);
      final tip = root + Offset(-dir * hgt * 0.06, -hgt * 0.26);
      c.drawLine(root, tip, antler);
      c.drawLine(Offset.lerp(root, tip, 0.5)!, Offset.lerp(root, tip, 0.5)! + Offset(-dir * hgt * 0.09, -hgt * 0.06), antler);
      c.drawLine(tip, tip + Offset(dir * hgt * 0.07, -hgt * 0.06), antler);
    }
    c.drawArc(
      Rect.fromCenter(center: Offset(fx + dir * hgt * 0.42, fy - hgt * 0.74), width: hgt * 0.2, height: hgt * 0.16),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = ElfColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = hgt * 0.04,
    );
    c.drawCircle(Offset(fx + dir * hgt * 0.42, fy - hgt * 0.65), hgt * 0.03, Paint()..color = SceneColors.gold);
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.layout != layout ||
      old.decorations != decorations ||
      old.events != events ||
      old.elfSpot != elfSpot ||
      old.elfReacting != elfReacting ||
      old.elfT != elfT;
}
