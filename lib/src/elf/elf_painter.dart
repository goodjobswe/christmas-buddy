import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pip's colours, shared with the app icon so the character stays the same.
class ElfColors {
  static const skin = Color(0xFFF6CFA8);
  static const skinShade = Color(0xFFE2B48A);
  static const cheek = Color(0x99F0827A);
  static const eye = Color(0xFF2B1B10);
  static const green = Color(0xFF2E8B3A);
  static const greenDark = Color(0xFF1F6B2C);
  static const red = Color(0xFFD6001C);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFF2C14E);
  static const boot = Color(0xFF5B3A1E);
}

enum ElfPose { idle, wave, jump }

/// Draws Pip the elf into [rect]. The drawing is defined on a 100 x 160 grid
/// and scaled to the rect, so it works from a 20 pixel hiding spot to a full
/// screen celebration. [t] runs 0..1 and drives the wave and jump poses.
class ElfPainter extends CustomPainter {
  const ElfPainter({
    this.pose = ElfPose.idle,
    this.t = 0,
    this.facingRight = true,
    this.shadow = false,
  });

  final ElfPose pose;
  final double t;
  final bool facingRight;
  final bool shadow;

  static const double unitWidth = 100;
  static const double unitHeight = 160;

  /// Height to width ratio of the elf drawing.
  static const double aspect = unitHeight / unitWidth;

  @override
  void paint(Canvas canvas, Size size) {
    paintInto(canvas, Offset.zero & size);
  }

  /// Paint the elf so that it fills [rect] (which should keep [aspect]).
  void paintInto(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / unitWidth, rect.height / unitHeight);
    if (!facingRight) {
      canvas.translate(unitWidth, 0);
      canvas.scale(-1, 1);
    }

    final lift = pose == ElfPose.jump ? math.sin(math.pi * t) * 26 : 0.0;

    if (shadow) {
      final squash = 1 - lift / 40;
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 157),
          width: 44 * squash,
          height: 9 * squash,
        ),
        Paint()..color = const Color(0x33000000),
      );
    }

    canvas.translate(0, -lift);
    _drawLegs(canvas);
    _drawArms(canvas);
    _drawBody(canvas);
    _drawHead(canvas);
    _drawHat(canvas);
    canvas.restore();
  }

  void _drawLegs(Canvas canvas) {
    final tucked = pose == ElfPose.jump ? math.sin(math.pi * t) * 8 : 0.0;
    final top = 118.0;
    final bottom = 146.0 - tucked;
    final bootTop = bottom - 4;
    final bootBottom = bottom + 12;

    for (final x in const [37.0, 53.0]) {
      final stocking = Rect.fromLTRB(x, top, x + 10, bottom);
      canvas.drawRect(stocking, Paint()..color = ElfColors.white);
      final stripe = Paint()..color = ElfColors.red;
      for (double y = top + 3; y < bottom; y += 6) {
        canvas.drawRect(
          Rect.fromLTRB(x, y, x + 10, math.min(y + 3, bottom)),
          stripe,
        );
      }
    }

    final boot = Paint()..color = ElfColors.boot;
    // Left boot, toe curls outwards to the left.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(33, bootTop, 49, bootBottom),
        const Radius.circular(5),
      ),
      boot,
    );
    canvas.drawCircle(Offset(31, bootBottom - 5), 4.5, boot);
    // Right boot.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(51, bootTop, 67, bootBottom),
        const Radius.circular(5),
      ),
      boot,
    );
    canvas.drawCircle(Offset(69, bootBottom - 5), 4.5, boot);
  }

  void _drawArms(Canvas canvas) {
    final sleeve = Paint()
      ..color = ElfColors.greenDark
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mitten = Paint()..color = ElfColors.red;

    const leftShoulder = Offset(37, 86);
    const rightShoulder = Offset(63, 86);
    Offset leftHand;
    Offset rightHand;
    switch (pose) {
      case ElfPose.idle:
        leftHand = const Offset(25, 112);
        rightHand = const Offset(75, 112);
      case ElfPose.wave:
        leftHand = const Offset(25, 112);
        final swing = math.sin(t * math.pi * 2 * 3) * 9;
        rightHand = Offset(82 + swing, 62 + swing.abs() * 0.3);
      case ElfPose.jump:
        final up = math.sin(math.pi * t);
        leftHand = Offset(22, 112 - 44 * up);
        rightHand = Offset(78, 112 - 44 * up);
    }
    canvas.drawLine(leftShoulder, leftHand, sleeve);
    canvas.drawLine(rightShoulder, rightHand, sleeve);
    canvas.drawCircle(leftHand, 5.5, mitten);
    canvas.drawCircle(rightHand, 5.5, mitten);
  }

  void _drawBody(Canvas canvas) {
    final tunic = Path()
      ..moveTo(36, 76)
      ..lineTo(64, 76)
      ..lineTo(70, 120)
      ..lineTo(30, 120)
      ..close();
    canvas.drawPath(tunic, Paint()..color = ElfColors.green);

    // Zigzag collar.
    final collar = Path()..moveTo(34, 76);
    for (var x = 34.0; x < 66; x += 8) {
      collar.lineTo(x + 4, 85);
      collar.lineTo(x + 8, 76);
    }
    collar.close();
    canvas.drawPath(collar, Paint()..color = ElfColors.white);

    // Belt and buckle.
    canvas.drawRect(
      const Rect.fromLTRB(30, 105, 70, 113),
      Paint()..color = ElfColors.red,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(45, 103, 55, 115),
        const Radius.circular(2),
      ),
      Paint()..color = ElfColors.gold,
    );
    canvas.drawRect(
      const Rect.fromLTRB(48, 106, 52, 112),
      Paint()..color = ElfColors.red,
    );
  }

  void _drawHead(Canvas canvas) {
    final skin = Paint()..color = ElfColors.skin;
    // Ears, drawn first so the face overlaps their base.
    final leftEar = Path()
      ..moveTo(32, 54)
      ..lineTo(17, 49)
      ..lineTo(33, 64)
      ..close();
    final rightEar = Path()
      ..moveTo(68, 54)
      ..lineTo(83, 49)
      ..lineTo(67, 64)
      ..close();
    canvas.drawPath(leftEar, skin);
    canvas.drawPath(rightEar, skin);
    canvas.drawPath(leftEar, Paint()..color = ElfColors.skinShade..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawPath(rightEar, Paint()..color = ElfColors.skinShade..style = PaintingStyle.stroke..strokeWidth = 1);

    canvas.drawCircle(const Offset(50, 58), 20, skin);

    // Cheeks.
    final cheek = Paint()..color = ElfColors.cheek;
    canvas.drawCircle(const Offset(39, 65), 4.2, cheek);
    canvas.drawCircle(const Offset(61, 65), 4.2, cheek);

    // Eyes with a highlight.
    final eye = Paint()..color = ElfColors.eye;
    final glint = Paint()..color = ElfColors.white;
    for (final x in const [43.0, 57.0]) {
      canvas.drawCircle(Offset(x, 57), 2.8, eye);
      canvas.drawCircle(Offset(x - 0.9, 56.1), 0.9, glint);
    }

    // Nose and smile.
    canvas.drawCircle(const Offset(50, 62), 1.6, Paint()..color = ElfColors.skinShade);
    final smile = Path()
      ..moveTo(44, 67)
      ..quadraticBezierTo(50, 73, 56, 67);
    canvas.drawPath(
      smile,
      Paint()
        ..color = ElfColors.eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawHat(Canvas canvas) {
    final green = Paint()..color = ElfColors.green;
    final cone = Path()
      ..moveTo(28, 44)
      ..quadraticBezierTo(42, 10, 60, 4)
      ..quadraticBezierTo(66, 22, 72, 44)
      ..close();
    canvas.drawPath(cone, green);

    // Floppy tip with a bell at the end.
    final tip = Path()
      ..moveTo(60, 4)
      ..quadraticBezierTo(76, 0, 84, 12);
    canvas.drawPath(
      tip,
      Paint()
        ..color = ElfColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(87, 15), 5.2, Paint()..color = ElfColors.gold);
    canvas.drawCircle(const Offset(87, 17), 1.3, Paint()..color = ElfColors.boot);

    // Band: red with a white trim on top.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(24, 38, 76, 48),
        const Radius.circular(4),
      ),
      Paint()..color = ElfColors.red,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(24, 36, 76, 41),
        const Radius.circular(2.5),
      ),
      Paint()..color = ElfColors.white,
    );
  }

  @override
  bool shouldRepaint(ElfPainter old) =>
      old.pose != pose ||
      old.t != t ||
      old.facingRight != facingRight ||
      old.shadow != shadow;
}

/// A sized elf, handy for dialogs and lists.
class Elf extends StatelessWidget {
  const Elf({
    super.key,
    required this.height,
    this.pose = ElfPose.idle,
    this.t = 0,
    this.facingRight = true,
    this.shadow = false,
  });

  final double height;
  final ElfPose pose;
  final double t;
  final bool facingRight;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height / ElfPainter.aspect, height),
      painter: ElfPainter(
        pose: pose,
        t: t,
        facingRight: facingRight,
        shadow: shadow,
      ),
    );
  }
}

/// An elf that loops its animation, for the found dialog and the calendar.
class AnimatedElf extends StatefulWidget {
  const AnimatedElf({
    super.key,
    required this.height,
    this.pose = ElfPose.wave,
    this.duration = const Duration(milliseconds: 900),
    this.shadow = true,
  });

  final double height;
  final ElfPose pose;
  final Duration duration;
  final bool shadow;

  @override
  State<AnimatedElf> createState() => _AnimatedElfState();
}

class _AnimatedElfState extends State<AnimatedElf>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Elf(
        height: widget.height,
        pose: widget.pose,
        t: _controller.value,
        shadow: widget.shadow,
      ),
    );
  }
}
