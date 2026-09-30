import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:christmas_buddy/src/snow/snowflake_model.dart';
import 'package:christmas_buddy/src/snow/snowflakes_painter.dart';

/// Falling snow that fills its parent. [flakeCount] can change at any time;
/// flakes are added at the top or dropped as they leave the screen. Dragging
/// a finger across the snow pushes it sideways like a gust of wind.
class SnowLayer extends StatefulWidget {
  const SnowLayer({super.key, required this.flakeCount, this.interactive = true});

  final int flakeCount;
  final bool interactive;

  @override
  State<SnowLayer> createState() => _SnowLayerState();
}

class _SnowLayerState extends State<SnowLayer> with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _flakes = <Snowflake>[];
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 0;
  double _wind = 0;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (_size == Size.zero) return;
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1) dt = 1 / 60;
    _time += dt;
    _wind *= math.pow(0.15, dt).toDouble();

    // Populate towards the wanted count a few flakes per frame, so a change
    // of intensity blows in gently instead of appearing at once.
    final want = widget.flakeCount;
    if (_flakes.length < want) {
      final add = math.min(want - _flakes.length, _flakes.isEmpty ? want : 3);
      for (var i = 0; i < add; i++) {
        _flakes.add(Snowflake(_random, _size.width, _size.height, fromTop: _flakes.isNotEmpty));
      }
    }

    for (var i = _flakes.length - 1; i >= 0; i--) {
      final flake = _flakes[i];
      if (!flake.advance(dt, _time, _wind, _size.width, _size.height)) {
        if (_flakes.length > want) {
          _flakes.removeAt(i);
        } else {
          flake.reset(_random, _size.width, _size.height);
        }
      }
    }
    if (_flakes.isNotEmpty || want > 0) _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final paint = CustomPaint(
          painter: SnowPainter(flakes: _flakes, repaint: _repaint),
          size: _size,
        );
        if (!widget.interactive) return IgnorePointer(child: paint);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) => _wind += d.delta.dx * 12,
          child: paint,
        );
      },
    );
  }
}

/// How many flakes to show for the settings and the day.
int snowFlakeCount({required int intensityIndex, required int decorationDay}) {
  if (intensityIndex <= 0) return 0;
  // Light 40, normal 90, heavy 160, blizzard 260, plus up to 60 percent more
  // as December goes on.
  const base = [0, 40, 90, 160, 260];
  final b = base[intensityIndex.clamp(0, base.length - 1)];
  final december = 1 + 0.6 * (decorationDay / 24);
  return (b * december).round();
}
