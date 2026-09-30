import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';

void main() {
  const sizes = [
    Size(360, 640),
    Size(411, 890),
    Size(390, 844),
    Size(800, 1280),
    Size(1024, 1366),
  ];

  test('every hiding spot is on screen and below the countdown', () {
    for (final size in sizes) {
      final layout = SceneLayout(size);
      final screen = (Offset.zero & size).inflate(1);
      for (var i = 0; i < ElfSpots.count; i++) {
        final spot = ElfSpots.resolve(i, layout);
        final visible = spot.visibleRect;
        expect(screen.contains(visible.topLeft), isTrue, reason: 'spot $i at $size');
        expect(screen.contains(visible.bottomRight), isTrue, reason: 'spot $i at $size');
        // Keep clear of the countdown at the top and the chip and quote
        // card at the bottom of the home screen.
        expect(visible.center.dy, greaterThan(size.height * 0.26), reason: 'spot $i at $size');
        expect(visible.center.dy, lessThan(size.height * 0.83), reason: 'spot $i at $size');
        expect(spot.hitRect.width, greaterThanOrEqualTo(47.9));
        expect(spot.hitRect.height, greaterThanOrEqualTo(47.9));
        expect(visible.height, greaterThanOrEqualTo(8), reason: 'spot $i at $size is too small');
      }
    }
  });

  test('spots are spread out rather than piled up', () {
    final layout = SceneLayout(const Size(411, 890));
    final centers = [
      for (var i = 0; i < ElfSpots.count; i++) ElfSpots.resolve(i, layout).visibleRect.center,
    ];
    for (var a = 0; a < centers.length; a++) {
      for (var b = a + 1; b < centers.length; b++) {
        expect((centers[a] - centers[b]).distance, greaterThan(24), reason: 'spots $a and $b overlap');
      }
    }
  });

  test('index wraps around', () {
    final layout = SceneLayout(const Size(411, 890));
    expect(ElfSpots.resolve(24, layout).feet, ElfSpots.resolve(0, layout).feet);
  });
}
