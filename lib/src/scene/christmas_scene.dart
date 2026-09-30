import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_events.dart';
import 'package:christmas_buddy/src/scene/scene_fx_painter.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';
import 'package:christmas_buddy/src/scene/scene_painter.dart';
import 'package:christmas_buddy/src/scene/season.dart';
import 'package:christmas_buddy/src/scene/tree_decorations.dart';
import 'package:christmas_buddy/src/snow/snowflakes.dart';

/// The whole picture: static village, animated effects and falling snow.
/// Taps are sorted into hits on the elf and misses, so the home screen never
/// needs to know where he is.
class ChristmasScene extends StatefulWidget {
  const ChristmasScene({
    super.key,
    required this.day,
    required this.elfSpotIndex,
    required this.showElf,
    required this.flakeCount,
    this.events = const SceneEvents(aurora: false, reindeerStation: null, sleigh: false),
    this.animate = true,
    this.season = Season.winter,
    this.onElfTap,
    this.onMissTap,
  });

  /// December day 1 to 24 for the decorations, 0 outside December.
  final int day;
  final Season season;
  final int elfSpotIndex;
  final bool showElf;
  final int flakeCount;
  final SceneEvents events;
  final bool animate;
  final void Function(ElfSpot spot)? onElfTap;
  final void Function(Offset position, double distanceToElf)? onMissTap;

  @override
  State<ChristmasScene> createState() => ChristmasSceneState();
}

class ChristmasSceneState extends State<ChristmasScene> with TickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  final List<SnowPuff> _puffs = [];
  late final Ticker _ticker;
  late final AnimationController _elfAnim;
  double? _hintStart;

  SceneLayout? _layout;
  TreeDecorations? _decorations;
  int _decorationsDay = -1;
  ElfSpot? _spot;
  int _spotIndex = -1;

  ElfSpot? get elfSpot => _spot;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.animate) _ticker.start();
    _elfAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elfAnim.dispose();
    _time.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    _puffs.removeWhere((p) => t - p.start > SnowPuff.duration);
    if (_hintStart != null && t - _hintStart! > SceneFxPainter.hintDuration) {
      _hintStart = null;
    }
    _time.value = t;
  }

  /// Plays the hidden elf's reaction for his spot: a wave, a pop up, a peek
  /// out, a wobble or a jump.
  void react() {
    _elfAnim.forward(from: 0);
  }

  /// Draws pulsing rings around the elf for a couple of seconds.
  void showHint() {
    _hintStart = _time.value;
  }

  void _ensureLayout(Size size) {
    if (_layout == null || _layout!.size != size) {
      _layout = SceneLayout(size);
      _decorationsDay = -1;
      _spotIndex = -1;
    }
    if (_decorationsDay != widget.day) {
      _decorations = TreeDecorations.forDay(widget.day, _layout!);
      _decorationsDay = widget.day;
    }
    if (_spotIndex != widget.elfSpotIndex) {
      _spot = ElfSpots.resolve(widget.elfSpotIndex, _layout!);
      _spotIndex = widget.elfSpotIndex;
    }
  }

  void _handleTap(TapDownDetails details) {
    final pos = details.localPosition;
    final spot = _spot;
    if (spot != null && widget.showElf && spot.hitRect.contains(pos)) {
      widget.onElfTap?.call(spot);
      return;
    }
    _puffs.add(SnowPuff(pos, _time.value));
    final distance = spot == null ? double.infinity : (pos - spot.visibleRect.center).distance;
    widget.onMissTap?.call(pos, distance);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _ensureLayout(size);
        final layout = _layout!;
        final decorations = _decorations!;
        final spot = widget.showElf ? _spot : null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _elfAnim,
                  builder: (context, _) => CustomPaint(
                    isComplex: true,
                    willChange: false,
                    painter: ScenePainter(
                      layout: layout,
                      decorations: decorations,
                      events: widget.events,
                      season: widget.season,
                      elfSpot: spot,
                      elfReacting: _elfAnim.isAnimating,
                      elfT: _elfAnim.value,
                    ),
                  ),
                ),
              ),
              RepaintBoundary(
                child: IgnorePointer(
                  child: CustomPaint(
                    willChange: true,
                    painter: SceneFxPainter(
                      layout: layout,
                      decorations: decorations,
                      events: widget.events,
                      season: widget.season,
                      time: _time,
                      puffs: _puffs,
                      hintStart: _hintStart,
                      hintCenter: spot?.hitRect.center,
                    ),
                  ),
                ),
              ),
              if (widget.season == Season.winter)
                RepaintBoundary(
                  child: SnowLayer(flakeCount: widget.animate ? widget.flakeCount : 0),
                ),
            ],
          ),
        );
      },
    );
  }
}
