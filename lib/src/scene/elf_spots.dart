import 'dart:math' as math;
import 'dart:ui';

import 'package:christmas_buddy/src/scene/scene_layout.dart';

/// Layers of the scene in drawing order. The elf is drawn right after the
/// layer named in its spot, so later layers can hide part of him.
enum SceneLayer { sky, mountains, ground, village, tree, foreground }

/// One hiding place, resolved against the layout.
class ElfSpot {
  const ElfSpot({
    required this.feet,
    required this.height,
    required this.after,
    this.visible = 1.0,
    this.facingRight = true,
  });

  /// Where the elf's feet are.
  final Offset feet;
  final double height;
  final SceneLayer after;

  /// Fraction of the elf, from the top, that is drawn. Below 1 he is
  /// peeking out from behind something.
  final double visible;
  final bool facingRight;

  double get width => height * 100 / 160;

  Rect get rect => Rect.fromLTWH(feet.dx - width / 2, feet.dy - height, width, height);

  Rect get visibleRect => Rect.fromLTWH(rect.left, rect.top, width, height * visible);

  /// Generous tap target: at least 48 logical pixels each way.
  Rect get hitRect {
    final v = visibleRect;
    return Rect.fromCenter(
      center: v.center,
      width: math.max(v.width, 48),
      height: math.max(v.height, 48),
    );
  }
}

/// The 24 hiding places. The order matters: index 23 (24 December) is the
/// top of the tree next to the star.
class ElfSpots {
  static const count = 24;

  static ElfSpot resolve(int index, SceneLayout l) {
    final u = l.unit;
    final tree = l.tree;
    final a = l.houses[0];
    final b = l.houses[1];
    final c = l.houses[2];
    final d = l.houses[3];
    final sm = l.snowman;

    switch (index % count) {
      case 0:
        return ElfSpot(
          feet: Offset(a.roofPeak.dx + u * 0.035, a.roofPeak.dy + u * 0.012),
          height: u * 0.055,
          after: SceneLayer.village,
        );
      case 1:
        return ElfSpot(
          feet: Offset(sm.centerX - sm.bottomRadius - u * 0.010, sm.groundY),
          height: u * 0.06,
          after: SceneLayer.tree,
        );
      case 2:
        final win = d.windows.last;
        const headFraction = 58 / 160;
        final height = u * 0.05;
        return ElfSpot(
          feet: Offset(win.center.dx, win.center.dy + (1 - headFraction) * height),
          height: height,
          after: SceneLayer.village,
          visible: 0.45,
        );
      case 3:
        return ElfSpot(
          feet: Offset(tree.centerX + u * 0.12, tree.tip.dy + tree.height * 0.56),
          height: u * 0.05,
          after: SceneLayer.tree,
          visible: 0.6,
          facingRight: false,
        );
      case 4:
        return ElfSpot(
          feet: Offset(l.lamp.top.dx, l.lamp.top.dy - u * 0.004),
          height: u * 0.05,
          after: SceneLayer.foreground,
        );
      case 5:
        final y = l.h * 0.78;
        return ElfSpot(
          feet: Offset(l.leftPine.tip.dx + l.leftPine.halfWidthAt(y) + u * 0.004, y),
          height: u * 0.055,
          after: SceneLayer.tree,
        );
      case 6:
        return ElfSpot(
          feet: Offset(l.fence.rect.center.dx, l.fence.rect.bottom + u * 0.002),
          height: u * 0.06,
          after: SceneLayer.tree,
        );
      case 7:
        return ElfSpot(
          feet: Offset(l.sled.center.dx, l.sled.top + u * 0.004),
          height: u * 0.05,
          after: SceneLayer.foreground,
          facingRight: false,
        );
      case 8:
        final height = u * 0.06;
        return ElfSpot(
          feet: Offset(b.chimney.center.dx, b.chimney.top + u * 0.006 - 0.4 * height + height),
          height: height,
          after: SceneLayer.village,
          visible: 0.4,
        );
      case 9:
        final x = l.w * 0.33;
        return ElfSpot(
          feet: Offset(x, SceneLayout.ridgeYAt(l.farRidge, x) + u * 0.002),
          height: u * 0.035,
          after: SceneLayer.mountains,
        );
      case 10:
        return ElfSpot(
          feet: Offset(tree.centerX + tree.trunkHalf + u * 0.014, tree.trunkBottom),
          height: u * 0.05,
          after: SceneLayer.village,
        );
      case 11:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.10, tree.baseY + l.h * 0.022),
          height: u * 0.05,
          after: SceneLayer.tree,
        );
      case 12:
        return ElfSpot(
          feet: Offset(c.roofPeak.dx - u * 0.035, c.roofPeak.dy + u * 0.012),
          height: u * 0.055,
          after: SceneLayer.village,
          facingRight: false,
        );
      case 13:
        return ElfSpot(
          feet: Offset(l.drift.center.dx, l.drift.bottom - u * 0.006),
          height: u * 0.055,
          after: SceneLayer.tree,
        );
      case 14:
        return ElfSpot(
          feet: Offset(l.rightPine.tip.dx, l.rightPine.tip.dy + u * 0.006),
          height: u * 0.045,
          after: SceneLayer.foreground,
          facingRight: false,
        );
      case 15:
        final door = a.door!;
        return ElfSpot(
          feet: Offset(door.center.dx, door.bottom),
          height: door.height * 0.88,
          after: SceneLayer.village,
        );
      case 16:
        return ElfSpot(
          feet: Offset((c.walls.right + d.walls.left) / 2, l.villageBase),
          height: u * 0.05,
          after: SceneLayer.ground,
        );
      case 17:
        final y = l.h * 0.83;
        return ElfSpot(
          feet: Offset(l.rightPine.tip.dx - l.rightPine.halfWidthAt(y) - u * 0.004, y),
          height: u * 0.055,
          after: SceneLayer.tree,
          facingRight: false,
        );
      case 18:
        final x = l.w * 0.62;
        return ElfSpot(
          feet: Offset(x, SceneLayout.ridgeYAt(l.nearRidge, x) + u * 0.002),
          height: u * 0.038,
          after: SceneLayer.mountains,
          facingRight: false,
        );
      case 19:
        return ElfSpot(
          feet: Offset(d.chimney.center.dx, d.chimney.top + u * 0.002),
          height: u * 0.05,
          after: SceneLayer.village,
          facingRight: false,
        );
      case 20:
        return ElfSpot(
          feet: Offset(l.lamp.base.dx + u * 0.012, l.lamp.base.dy),
          height: u * 0.05,
          after: SceneLayer.tree,
          facingRight: false,
        );
      case 21:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.20, tree.tip.dy + tree.height * 0.80),
          height: u * 0.05,
          after: SceneLayer.tree,
          visible: 0.55,
        );
      case 22:
        return ElfSpot(
          feet: Offset(l.fence.rect.right - u * 0.02, l.fence.rect.top + u * 0.002),
          height: u * 0.045,
          after: SceneLayer.foreground,
          facingRight: false,
        );
      case 23:
      default:
        return ElfSpot(
          feet: Offset(tree.centerX, tree.tip.dy + tree.height * 0.11),
          height: u * 0.045,
          after: SceneLayer.tree,
          visible: 0.75,
        );
    }
  }
}
