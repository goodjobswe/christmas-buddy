import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/elf/elf_painter.dart';

/// The celebration when the elf is found: sparkles, a jumping Pip and a line.
Future<void> showFoundDialog(
  BuildContext context, {
  required String line,
  required String detail,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xAA000000),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: SparkleBurst()),
          Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedElf(
                    height: 150,
                    pose: ElfPose.jump,
                    duration: Duration(milliseconds: 750),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You found Pip!',
                    style: TextStyle(fontFamily: 'Rochester', fontSize: 40, color: ElfColors.red),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hooray!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A one-shot burst of little stars and dots flying outwards.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({super.key});

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final List<_Sparkle> _sparkles = _Sparkle.burst(math.Random(), 32);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SparklePainter(_sparkles, _controller),
      ),
    );
  }
}

class _Sparkle {
  _Sparkle(this.angle, this.distance, this.size, this.color, this.isStar, this.delay);

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool isStar;
  final double delay;

  static const colors = [
    Color(0xFFFFD75E),
    Color(0xFFD6001C),
    Colors.white,
    Color(0xFF8AD8FF),
    Color(0xFF2E8B3A),
  ];

  static List<_Sparkle> burst(math.Random random, int count) {
    return List.generate(count, (i) {
      return _Sparkle(
        i * math.pi * 2 / count + random.nextDouble() * 0.3,
        0.55 + random.nextDouble() * 0.45,
        4 + random.nextDouble() * 6,
        colors[i % colors.length],
        i % 3 == 0,
        random.nextDouble() * 0.15,
      );
    });
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.sparkles, this.animation) : super(repaint: animation);

  final List<_Sparkle> sparkles;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = math.min(size.width, size.height) * 0.62;
    final paint = Paint();
    for (final s in sparkles) {
      final p = ((animation.value - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final ease = 1 - math.pow(1 - p, 3).toDouble();
      final pos = center + Offset(math.cos(s.angle), math.sin(s.angle)) * (reach * s.distance * ease);
      final fade = p < 0.6 ? 1.0 : 1 - (p - 0.6) / 0.4;
      paint.color = s.color.withValues(alpha: fade);
      final r = s.size * (1 - p * 0.4);
      if (s.isStar) {
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final radius = i.isEven ? r : r * 0.4;
          final a = i * math.pi / 4 + p * 2;
          final v = pos + Offset(math.cos(a) * radius, math.sin(a) * radius);
          if (i == 0) {
            path.moveTo(v.dx, v.dy);
          } else {
            path.lineTo(v.dx, v.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(pos, r * 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => true;
}
