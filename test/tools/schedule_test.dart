// Prints where Pip hides, for checking a build by hand. Skipped unless
// PRINT_SCHEDULE is set to a year, or to a date for one day:
//
//   PRINT_SCHEDULE=2026 flutter test test/tools/schedule_test.dart
//   PRINT_SCHEDULE=2026-12-20 flutter test test/tools/schedule_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christmas_buddy/src/elf/elf_schedule.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_layout.dart';

final _arg = Platform.environment['PRINT_SCHEDULE'];

void main() {
  test('print the schedule', () {
    final arg = _arg!;
    final layout = SceneLayout(const Size(411, 914));
    String describe(DateTime date) {
      final index = ElfSchedule.spotFor(date);
      final spot = ElfSpots.resolve(index, layout);
      final c = spot.visibleRect.center;
      return 'spot $index (${ElfSpots.difficulty(index).name}, ${spot.reaction.name}) '
          'at ${(c.dx / layout.w * 100).round()}% across, ${(c.dy / layout.h * 100).round()}% down';
    }

    final date = DateTime.tryParse(arg);
    if (date != null) {
      // ignore: avoid_print
      print('${arg.padRight(10)} ${describe(date)}');
      return;
    }
    final year = int.parse(arg);
    for (var day = 1; day <= 24; day++) {
      final d = DateTime(year, 12, day);
      // ignore: avoid_print
      print('$year-12-${day.toString().padLeft(2, '0')} ${describe(d)}');
    }
  }, skip: _arg == null);
}
