import 'dart:math' as math;
import 'dart:ui';

/// Where everything in the village stands, computed from the screen size.
/// Horizontal positions follow the width, vertical positions the height,
/// and sizes follow [unit] so tablets do not get cartoonishly large houses.
class SceneLayout {
  SceneLayout(this.size) {
    w = size.width;
    h = size.height;
    unit = math.min(w, h / 1.8);
    _build();
  }

  final Size size;
  late final double w;
  late final double h;
  late final double unit;

  late final Offset moon;
  late final double moonRadius;
  late final List<Offset> stars;
  late final List<Offset> farRidge;
  late final List<Offset> nearRidge;
  late final Path ground;
  late final double villageBase;
  late final List<House> houses;
  late final SceneTree tree;
  late final Snowman snowman;
  late final Lamp lamp;
  late final Fence fence;
  late final Rect sled;
  late final Pine leftPine;
  late final Pine rightPine;
  late final Rect drift;
  late final List<Rect> gifts;

  void _build() {
    moon = Offset(w * 0.86, h * 0.31);
    moonRadius = unit * 0.055;

    final random = math.Random(2412);
    final starList = <Offset>[];
    while (starList.length < 80) {
      final p = Offset(random.nextDouble() * w, random.nextDouble() * h * 0.46);
      if ((p - moon).distance < moonRadius * 2.2) continue;
      starList.add(p);
    }
    stars = starList;

    farRidge = _ridge(
      const [0.0, 0.10, 0.22, 0.33, 0.45, 0.57, 0.68, 0.80, 0.92, 1.0],
      const [0.06, 0.13, 0.08, 0.16, 0.10, 0.15, 0.07, 0.14, 0.09, 0.05],
      0.50,
    );
    nearRidge = _ridge(
      const [0.0, 0.15, 0.30, 0.48, 0.62, 0.78, 0.90, 1.0],
      const [0.04, 0.09, 0.05, 0.11, 0.06, 0.10, 0.04, 0.07],
      0.56,
    );

    ground = Path()
      ..moveTo(-1, h * 0.58)
      ..quadraticBezierTo(w * 0.15, h * 0.545, w * 0.32, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.575, w * 0.66, h * 0.565)
      ..quadraticBezierTo(w * 0.85, h * 0.55, w + 1, h * 0.57)
      ..lineTo(w + 1, h + 1)
      ..lineTo(-1, h + 1)
      ..close();
    villageBase = h * 0.605;

    final hw = unit * 0.15;
    houses = [
      _house(w * 0.02, hw, const Color(0xFF8B2E2E), door: true),
      _house(w * 0.20, hw * 0.92, const Color(0xFFD9B44A)),
      _house(w * 0.67, hw * 0.92, const Color(0xFF8B2E2E)),
      _house(w * 0.85, hw, const Color(0xFF56708A), door: true),
    ];

    tree = SceneTree(
      tip: Offset(w * 0.5, h * 0.31),
      baseY: h * 0.79,
      halfBase: unit * 0.31,
      trunkHalf: unit * 0.025,
      trunkBottom: h * 0.79 + h * 0.03,
    );

    // The foreground stays above the bottom 13 percent of the screen, where
    // the home screen lays its chip and quote card over the picture.
    snowman = Snowman(
      centerX: w * 0.80,
      groundY: h * 0.835,
      bottomRadius: unit * 0.055,
      middleRadius: unit * 0.042,
      headRadius: unit * 0.032,
    );

    lamp = Lamp(
      base: Offset(w * 0.135, h * 0.83),
      top: Offset(w * 0.135, h * 0.635),
      headWidth: unit * 0.05,
      headHeight: unit * 0.06,
    );

    fence = Fence(
      rect: Rect.fromLTWH(w * 0.55, h * 0.795, w * 0.17, unit * 0.045),
      postSpacing: unit * 0.035,
    );

    sled = Rect.fromLTWH(w * 0.20, h * 0.80, unit * 0.16, unit * 0.03);

    leftPine = Pine(tip: Offset(w * 0.03, h * 0.66), height: h * 0.30, halfWidth: unit * 0.13);
    rightPine = Pine(tip: Offset(w * 0.95, h * 0.70), height: h * 0.26, halfWidth: unit * 0.11);

    drift = Rect.fromLTWH(w * 0.36, h * 0.815, unit * 0.22, unit * 0.05);

    final g = unit * 0.05;
    gifts = [
      Rect.fromLTWH(tree.tip.dx + unit * 0.06, tree.baseY - g * 0.2, g, g * 0.8),
      Rect.fromLTWH(tree.tip.dx - unit * 0.14, tree.baseY, g * 0.9, g * 0.7),
      Rect.fromLTWH(tree.tip.dx + unit * 0.13, tree.baseY + g * 0.15, g * 0.75, g * 0.6),
    ];
  }

  List<Offset> _ridge(List<double> xs, List<double> peaks, double baseFrac) {
    return [
      for (var i = 0; i < xs.length; i++)
        Offset(w * xs[i], h * (baseFrac - peaks[i])),
    ];
  }

  House _house(double left, double width, Color color, {bool door = false}) {
    final wallHeight = width * 0.5;
    final roofHeight = width * 0.45;
    final walls = Rect.fromLTWH(left, villageBase - wallHeight, width, wallHeight);
    final peak = Offset(walls.center.dx, walls.top - roofHeight);
    final chimney = Rect.fromLTWH(
      walls.left + width * 0.66,
      walls.top - roofHeight * 0.85,
      width * 0.14,
      roofHeight * 0.55,
    );
    final win = width * 0.17;
    final windows = door
        ? [Rect.fromLTWH(walls.left + width * 0.62, walls.top + wallHeight * 0.28, win, win)]
        : [
            Rect.fromLTWH(walls.left + width * 0.18, walls.top + wallHeight * 0.28, win, win),
            Rect.fromLTWH(walls.left + width * 0.65, walls.top + wallHeight * 0.28, win, win),
          ];
    final doorRect = Rect.fromLTWH(
      walls.left + width * 0.18,
      walls.bottom - wallHeight * 0.72,
      width * 0.2,
      wallHeight * 0.72,
    );
    return House(
      walls: walls,
      roofPeak: peak,
      chimney: chimney,
      windows: windows,
      door: door ? doorRect : null,
      color: color,
    );
  }

  /// Height of the far ridge at [x], for standing things on it.
  static double ridgeYAt(List<Offset> ridge, double x) {
    for (var i = 0; i < ridge.length - 1; i++) {
      final a = ridge[i];
      final b = ridge[i + 1];
      if (x >= a.dx && x <= b.dx) {
        final f = (x - a.dx) / (b.dx - a.dx);
        return a.dy + (b.dy - a.dy) * f;
      }
    }
    return ridge.last.dy;
  }
}

class House {
  const House({
    required this.walls,
    required this.roofPeak,
    required this.chimney,
    required this.windows,
    required this.door,
    required this.color,
  });

  final Rect walls;
  final Offset roofPeak;
  final Rect chimney;
  final List<Rect> windows;
  final Rect? door;
  final Color color;

  double get overhang => walls.width * 0.08;
}

class SceneTree {
  const SceneTree({
    required this.tip,
    required this.baseY,
    required this.halfBase,
    required this.trunkHalf,
    required this.trunkBottom,
  });

  final Offset tip;
  final double baseY;
  final double halfBase;
  final double trunkHalf;
  final double trunkBottom;

  double get height => baseY - tip.dy;
  double get centerX => tip.dx;

  static const tierCount = 5;

  /// The triangle of tier [k] (0 is the top): apex and base corners.
  ({Offset apex, Offset left, Offset right}) tier(int k) {
    final apexY = tip.dy + height * 0.17 * k;
    final baseYk = tip.dy + height * (0.36 + 0.16 * k);
    final half = halfBase * (0.36 + 0.16 * k);
    return (
      apex: Offset(centerX, apexY),
      left: Offset(centerX - half, baseYk),
      right: Offset(centerX + half, baseYk),
    );
  }

  /// Half width of the silhouette at [y], for placing decorations inside.
  double halfWidthAt(double y) {
    var best = 0.0;
    for (var k = 0; k < tierCount; k++) {
      final t = tier(k);
      if (y >= t.apex.dy && y <= t.left.dy) {
        final f = (y - t.apex.dy) / (t.left.dy - t.apex.dy);
        best = math.max(best, (t.right.dx - centerX) * f);
      }
    }
    return best;
  }
}

class Snowman {
  const Snowman({
    required this.centerX,
    required this.groundY,
    required this.bottomRadius,
    required this.middleRadius,
    required this.headRadius,
  });

  final double centerX;
  final double groundY;
  final double bottomRadius;
  final double middleRadius;
  final double headRadius;

  Offset get bottom => Offset(centerX, groundY - bottomRadius * 0.9);
  Offset get middle => Offset(centerX, bottom.dy - bottomRadius * 0.85 - middleRadius * 0.6);
  Offset get head => Offset(centerX, middle.dy - middleRadius * 0.85 - headRadius * 0.6);
}

class Lamp {
  const Lamp({
    required this.base,
    required this.top,
    required this.headWidth,
    required this.headHeight,
  });

  final Offset base;
  final Offset top;
  final double headWidth;
  final double headHeight;

  Rect get head => Rect.fromCenter(
        center: Offset(top.dx, top.dy + headHeight * 0.5),
        width: headWidth,
        height: headHeight,
      );
}

class Fence {
  const Fence({required this.rect, required this.postSpacing});

  final Rect rect;
  final double postSpacing;
}

class Pine {
  const Pine({required this.tip, required this.height, required this.halfWidth});

  final Offset tip;
  final double height;
  final double halfWidth;

  double get bottom => tip.dy + height;

  /// Half width of the silhouette at [y].
  double halfWidthAt(double y) {
    final f = ((y - tip.dy) / height).clamp(0.0, 1.0);
    return halfWidth * f;
  }
}
