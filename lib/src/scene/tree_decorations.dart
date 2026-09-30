import 'dart:math' as math;
import 'dart:ui';

import 'package:christmas_buddy/src/scene/scene_layout.dart';

/// One fairy light on the tree, with its own twinkle phase.
class TreeLight {
  const TreeLight(this.position, this.color, this.phase);

  final Offset position;
  final Color color;
  final double phase;
}

class Bauble {
  const Bauble(this.position, this.radius, this.color);

  final Offset position;
  final double radius;
  final Color color;
}

/// Everything hanging on the tree for a given December day (0 = nothing).
/// Day 1 to 24 adds a little more each day; the star lands on day 24.
class TreeDecorations {
  TreeDecorations._({
    required this.day,
    required this.lights,
    required this.baubles,
    required this.candyCanes,
    required this.garlands,
    required this.giftCount,
    required this.star,
  });

  factory TreeDecorations.forDay(int day, SceneLayout layout) {
    final tree = layout.tree;
    final random = math.Random(1224);
    final unit = layout.unit;

    // Light strands: one per tier, bottom tier first, on days 1, 5, 9, 13, 17.
    final lights = <TreeLight>[];
    final strandDays = [1, 5, 9, 13, 17];
    for (var s = 0; s < strandDays.length; s++) {
      if (day < strandDays[s]) break;
      final k = SceneTree.tierCount - 1 - s;
      final t = tree.tier(k);
      final yTop = t.apex.dy + (t.left.dy - t.apex.dy) * 0.55;
      final yBottom = t.left.dy - (t.left.dy - t.apex.dy) * 0.08;
      final count = 6 + (SceneTree.tierCount - 1 - s) * 3;
      for (var i = 0; i <= count; i++) {
        final f = i / count;
        final y = yTop + (yBottom - yTop) * (0.5 - 0.5 * math.cos(f * math.pi * 2));
        final half = tree.halfWidthAt(y) * 0.92;
        final x = tree.centerX - half + 2 * half * f;
        lights.add(TreeLight(
          Offset(x, y),
          _lightColors[(i + s) % _lightColors.length],
          random.nextDouble(),
        ));
      }
    }

    // Baubles: two new ones every day from day 2, in fixed slots so
    // yesterday's baubles stay where they were.
    final slots = <Bauble>[];
    var attempts = 0;
    while (slots.length < 46 && attempts < 2000) {
      attempts++;
      final y = tree.tip.dy + tree.height * (0.12 + 0.86 * random.nextDouble());
      final half = tree.halfWidthAt(y);
      if (half < unit * 0.03) continue;
      final x = tree.centerX + (random.nextDouble() * 2 - 1) * half * 0.85;
      final p = Offset(x, y);
      final r = unit * (0.011 + random.nextDouble() * 0.006);
      if (slots.any((b) => (b.position - p).distance < r * 3.2)) continue;
      slots.add(Bauble(p, r, _baubleColors[slots.length % _baubleColors.length]));
    }
    final baubleCount = day < 2 ? 0 : math.min(slots.length, (day - 1) * 2);
    final baubles = slots.take(baubleCount).toList();

    // Candy canes on the last days before the star.
    final candyCanes = <Offset>[];
    if (day >= 20) {
      final caneSlots = [
        Offset(tree.centerX - tree.halfBase * 0.55, tree.baseY - tree.height * 0.14),
        Offset(tree.centerX + tree.halfBase * 0.40, tree.baseY - tree.height * 0.30),
        Offset(tree.centerX - tree.halfBase * 0.20, tree.baseY - tree.height * 0.48),
        Offset(tree.centerX + tree.halfBase * 0.22, tree.baseY - tree.height * 0.66),
      ];
      candyCanes.addAll(caneSlots.take(day - 19));
    }

    // Tinsel garlands on days 6, 12 and 18, wrapped around three tiers.
    final garlands = <Path>[];
    final garlandTiers = [3, 2, 1];
    final garlandDays = [6, 12, 18];
    for (var i = 0; i < garlandDays.length; i++) {
      if (day < garlandDays[i]) break;
      final t = tree.tier(garlandTiers[i]);
      final y = t.apex.dy + (t.left.dy - t.apex.dy) * 0.72;
      final half = tree.halfWidthAt(y) * 0.95;
      final path = Path()
        ..moveTo(tree.centerX - half, y - unit * 0.02)
        ..quadraticBezierTo(tree.centerX, y + unit * 0.05, tree.centerX + half, y - unit * 0.02);
      garlands.add(path);
    }

    final giftCount = day >= 20 ? 3 : (day >= 15 ? 2 : (day >= 10 ? 1 : 0));

    return TreeDecorations._(
      day: day,
      lights: lights,
      baubles: baubles,
      candyCanes: candyCanes,
      garlands: garlands,
      giftCount: giftCount,
      star: day >= 24,
    );
  }

  final int day;
  final List<TreeLight> lights;
  final List<Bauble> baubles;
  final List<Offset> candyCanes;
  final List<Path> garlands;
  final int giftCount;
  final bool star;

  static const _lightColors = [
    Color(0xFFFFE08A),
    Color(0xFFFF7A7A),
    Color(0xFF8AD8FF),
    Color(0xFFFFB86C),
    Color(0xFFB8FF9C),
  ];

  static const _baubleColors = [
    Color(0xFFD6001C),
    Color(0xFFF2C14E),
    Color(0xFF3F7FD6),
    Color(0xFFE8ECF3),
    Color(0xFFB03A8C),
  ];
}
