import 'dart:math' as math;

/// One falling snowflake. Positions are in logical pixels; [depth] runs
/// from 0 (far away: small, slow, faint) to 1 (close: big, fast, bright).
class Snowflake {
  Snowflake(math.Random random, double width, double height, {bool fromTop = false}) {
    reset(random, width, height, fromTop: fromTop);
  }

  double x = 0;
  double y = 0;
  double depth = 0;
  double radius = 1;
  double speed = 20;
  double swayPhase = 0;
  double swayAmount = 10;
  double swaySpeed = 1;
  double alpha = 1;

  void reset(math.Random random, double width, double height, {bool fromTop = true}) {
    depth = random.nextDouble();
    final eased = depth * depth;
    radius = 0.8 + eased * 2.6;
    speed = 18 + eased * 60 + random.nextDouble() * 10;
    swayPhase = random.nextDouble() * math.pi * 2;
    swayAmount = 6 + random.nextDouble() * 18;
    swaySpeed = 0.6 + random.nextDouble() * 0.9;
    alpha = 0.35 + eased * 0.55;
    x = random.nextDouble() * width;
    y = fromTop ? -radius * 2 - random.nextDouble() * 40 : random.nextDouble() * height;
  }

  /// Advances the flake by [dt] seconds. [wind] is a horizontal push in
  /// pixels per second that decays over time. Returns false once the flake
  /// has left the screen and should be recycled.
  bool advance(double dt, double time, double wind, double width, double height) {
    y += speed * dt;
    final sway = math.sin(time * swaySpeed + swayPhase) * swayAmount;
    x += (sway * 0.6 + wind * (0.3 + depth * 0.7)) * dt;
    if (x < -20) x += width + 40;
    if (x > width + 20) x -= width + 40;
    return y < height + radius * 2;
  }
}
