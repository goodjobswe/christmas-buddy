import 'dart:math' as math;
import 'dart:ui';

import 'package:christmas_buddy/src/scene/scene_layout.dart';

/// Layers of the scene in drawing order. The elf is drawn right after the
/// layer named in his spot, so later layers can hide part of him.
enum SceneLayer { sky, mountains, ground, backVillage, village, tree, foreground }

enum SpotDifficulty { easy, medium, hard }

/// What Pip does when he is found in a spot.
enum ElfReaction {
  /// Waves from where he stands.
  wave,

  /// Rises out of the chimney, window or branches, then ducks back.
  popUp,

  /// Slides sideways out from behind whatever hides him, then back.
  peekOut,

  /// Wobbles as if about to slip off his perch.
  tumble,

  /// A little victory jump.
  jump,
}

/// One hiding place, resolved against the layout.
class ElfSpot {
  const ElfSpot({
    required this.feet,
    required this.height,
    required this.after,
    required this.difficulty,
    this.reaction = ElfReaction.wave,
    this.visible = 1.0,
    this.facingRight = true,
  });

  /// Where the elf's feet are.
  final Offset feet;
  final double height;
  final SceneLayer after;
  final SpotDifficulty difficulty;
  final ElfReaction reaction;

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

/// The 36 hiding places. Index 23 is the top of the tree, kept for
/// 24 December; the rest are shared out by [ElfSchedule].
class ElfSpots {
  static const count = 36;
  static const treeTop = 23;

  static const _difficulties = <SpotDifficulty>[
    SpotDifficulty.easy, // 0 house A roof
    SpotDifficulty.medium, // 1 beside the snowman
    SpotDifficulty.hard, // 2 house D window
    SpotDifficulty.medium, // 3 in the tree, right
    SpotDifficulty.easy, // 4 lamp top
    SpotDifficulty.medium, // 5 behind the left pine
    SpotDifficulty.medium, // 6 behind the fence
    SpotDifficulty.easy, // 7 on the sled
    SpotDifficulty.hard, // 8 house B chimney
    SpotDifficulty.easy, // 9 far ridge
    SpotDifficulty.easy, // 10 under the tree by the trunk
    SpotDifficulty.medium, // 11 by the presents
    SpotDifficulty.easy, // 12 house C roof
    SpotDifficulty.medium, // 13 in the drift
    SpotDifficulty.medium, // 14 right pine top
    SpotDifficulty.easy, // 15 house A doorway
    SpotDifficulty.hard, // 16 between houses C and D
    SpotDifficulty.medium, // 17 behind the right pine
    SpotDifficulty.easy, // 18 near ridge
    SpotDifficulty.easy, // 19 house D chimney
    SpotDifficulty.medium, // 20 lamp base
    SpotDifficulty.medium, // 21 in the tree, lower left
    SpotDifficulty.easy, // 22 fence top
    SpotDifficulty.hard, // 23 tree top (24 December)
    SpotDifficulty.hard, // 24 church bell tower
    SpotDifficulty.easy, // 25 house A chimney
    SpotDifficulty.hard, // 26 back house chimney
    SpotDifficulty.medium, // 27 back house roof
    SpotDifficulty.hard, // 28 in the tree, near the top
    SpotDifficulty.medium, // 29 behind the woodpile
    SpotDifficulty.medium, // 30 behind the postbox
    SpotDifficulty.easy, // 31 by the signpost
    SpotDifficulty.medium, // 32 behind the bench
    SpotDifficulty.hard, // 33 in the tree, mid left
    SpotDifficulty.hard, // 34 in the tree, low right
    SpotDifficulty.easy, // 35 far ridge, right
  ];

  static SpotDifficulty difficulty(int index) => _difficulties[index % count];

  static ElfSpot resolve(int index, SceneLayout l) {
    final u = l.unit;
    final tree = l.tree;
    final a = l.houses[0];
    final b = l.houses[1];
    final c = l.houses[2];
    final d = l.houses[3];
    final sm = l.snowman;
    final i = index % count;
    final difficulty = _difficulties[i];
    const headFraction = 58 / 160;

    switch (i) {
      case 0:
        return ElfSpot(
          feet: Offset(a.roofPeak.dx - u * 0.035, a.roofPeak.dy + u * 0.012),
          height: u * 0.055,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
        );
      case 1:
        return ElfSpot(
          feet: Offset(sm.centerX - sm.bottomRadius - u * 0.010, sm.groundY),
          height: u * 0.06,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
        );
      case 2:
        final win = d.windows.last;
        final height = u * 0.05;
        return ElfSpot(
          feet: Offset(win.center.dx, win.center.dy + (1 - headFraction) * height),
          height: height,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.45,
        );
      case 3:
        return ElfSpot(
          feet: Offset(tree.centerX + u * 0.12, tree.tip.dy + tree.height * 0.56),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.6,
          facingRight: false,
        );
      case 4:
        return ElfSpot(
          feet: Offset(l.lamp.top.dx, l.lamp.top.dy - u * 0.004),
          height: u * 0.05,
          after: SceneLayer.foreground,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
        );
      case 5:
        final y = l.h * 0.78;
        return ElfSpot(
          feet: Offset(l.leftPine.tip.dx + l.leftPine.halfWidthAt(y) + u * 0.004, y),
          height: u * 0.055,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
        );
      case 6:
        return ElfSpot(
          feet: Offset(l.fence.rect.center.dx, l.fence.rect.bottom + u * 0.002),
          height: u * 0.06,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
        );
      case 7:
        return ElfSpot(
          feet: Offset(l.sled.center.dx, l.sled.top + u * 0.004),
          height: u * 0.05,
          after: SceneLayer.foreground,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
          facingRight: false,
        );
      case 8:
        final height = u * 0.06;
        return ElfSpot(
          feet: Offset(b.chimney.center.dx, b.chimney.top + u * 0.006 - 0.4 * height + height),
          height: height,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.4,
        );
      case 9:
        final x = l.w * 0.33;
        return ElfSpot(
          feet: Offset(x, SceneLayout.ridgeYAt(l.farRidge, x) + u * 0.002),
          height: u * 0.035,
          after: SceneLayer.mountains,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
        );
      case 10:
        return ElfSpot(
          feet: Offset(tree.centerX + tree.trunkHalf + u * 0.014, tree.trunkBottom),
          height: u * 0.05,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
        );
      case 11:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.047, tree.baseY + l.h * 0.022),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
        );
      case 12:
        return ElfSpot(
          feet: Offset(c.roofPeak.dx - u * 0.02, c.roofPeak.dy + u * 0.012),
          height: u * 0.055,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
          facingRight: false,
        );
      case 13:
        return ElfSpot(
          feet: Offset(l.drift.left + l.drift.width * 0.25, l.drift.bottom - u * 0.006),
          height: u * 0.055,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
        );
      case 14:
        return ElfSpot(
          feet: Offset(l.rightPine.tip.dx, l.rightPine.tip.dy + u * 0.006),
          height: u * 0.045,
          after: SceneLayer.foreground,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
          facingRight: false,
        );
      case 15:
        final door = a.door!;
        return ElfSpot(
          feet: Offset(door.center.dx, door.bottom),
          height: door.height * 0.88,
          after: SceneLayer.village,
          difficulty: difficulty,
        );
      case 16:
        return ElfSpot(
          feet: Offset((c.walls.right + d.walls.left) / 2, l.villageBase),
          height: u * 0.05,
          after: SceneLayer.backVillage,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
        );
      case 17:
        final y = l.h * 0.83;
        return ElfSpot(
          feet: Offset(l.rightPine.tip.dx - l.rightPine.halfWidthAt(y) - u * 0.004, y),
          height: u * 0.055,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
          facingRight: false,
        );
      case 18:
        final x = l.w * 0.62;
        return ElfSpot(
          feet: Offset(x, SceneLayout.ridgeYAt(l.nearRidge, x) + u * 0.002),
          height: u * 0.038,
          after: SceneLayer.mountains,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
          facingRight: false,
        );
      case 19:
        return ElfSpot(
          feet: Offset(d.chimney.center.dx, d.chimney.top + u * 0.002),
          height: u * 0.05,
          after: SceneLayer.village,
          difficulty: difficulty,
          facingRight: false,
        );
      case 20:
        return ElfSpot(
          feet: Offset(l.lamp.base.dx + u * 0.012, l.lamp.base.dy),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
          facingRight: false,
        );
      case 21:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.20, tree.tip.dy + tree.height * 0.80),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.55,
        );
      case 22:
        return ElfSpot(
          feet: Offset(l.fence.rect.right - u * 0.02, l.fence.rect.top + u * 0.002),
          height: u * 0.045,
          after: SceneLayer.foreground,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
          facingRight: false,
        );
      case 23:
        return ElfSpot(
          feet: Offset(tree.centerX, tree.tip.dy + tree.height * 0.11),
          height: u * 0.045,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.75,
        );
      case 24:
        final bell = l.church.bell;
        final height = u * 0.05;
        return ElfSpot(
          feet: Offset(bell.center.dx, bell.center.dy + (1 - headFraction) * height),
          height: height,
          after: SceneLayer.backVillage,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.5,
        );
      case 25:
        return ElfSpot(
          feet: Offset(a.chimney.center.dx, a.chimney.top + u * 0.002),
          height: u * 0.05,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
        );
      case 26:
        final back = l.backHouses[0];
        final height = u * 0.055;
        return ElfSpot(
          feet: Offset(back.chimney.center.dx, back.chimney.top + u * 0.004 - 0.45 * height + height),
          height: height,
          after: SceneLayer.backVillage,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.45,
        );
      case 27:
        final back = l.backHouses[1];
        return ElfSpot(
          feet: Offset(back.chimney.center.dx, back.chimney.top + u * 0.002),
          height: u * 0.04,
          after: SceneLayer.village,
          difficulty: difficulty,
          reaction: ElfReaction.tumble,
        );
      case 28:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.05, tree.tip.dy + tree.height * 0.22),
          height: u * 0.045,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.5,
        );
      case 29:
        return ElfSpot(
          feet: Offset(l.woodpile.center.dx, l.woodpile.bottom - u * 0.002),
          height: u * 0.055,
          after: SceneLayer.backVillage,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
        );
      case 30:
        return ElfSpot(
          feet: Offset(l.postbox.center.dx + u * 0.007, l.villageBase),
          height: u * 0.05,
          after: SceneLayer.backVillage,
          difficulty: difficulty,
          reaction: ElfReaction.peekOut,
        );
      case 31:
        return ElfSpot(
          feet: Offset(l.signpost.base.dx - u * 0.016, l.signpost.base.dy),
          height: u * 0.045,
          after: SceneLayer.foreground,
          difficulty: difficulty,
          facingRight: false,
        );
      case 32:
        return ElfSpot(
          feet: Offset(l.bench.seat.left + l.bench.seat.width * 0.32, l.bench.seat.bottom + u * 0.014),
          height: u * 0.055,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
        );
      case 33:
        return ElfSpot(
          feet: Offset(tree.centerX - u * 0.16, tree.tip.dy + tree.height * 0.64),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.5,
        );
      case 34:
        return ElfSpot(
          feet: Offset(tree.centerX + u * 0.24, tree.tip.dy + tree.height * 0.92),
          height: u * 0.05,
          after: SceneLayer.tree,
          difficulty: difficulty,
          reaction: ElfReaction.popUp,
          visible: 0.45,
          facingRight: false,
        );
      case 35:
      default:
        final x = l.w * 0.68;
        return ElfSpot(
          feet: Offset(x, SceneLayout.ridgeYAt(l.farRidge, x) + u * 0.002),
          height: u * 0.035,
          after: SceneLayer.mountains,
          difficulty: difficulty,
          reaction: ElfReaction.jump,
          facingRight: false,
        );
    }
  }
}
