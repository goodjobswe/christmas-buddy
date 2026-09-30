import 'dart:math' as math;

import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';

/// Decides where Pip hides on a given day.
///
/// Every year gets its own order of the 35 everyday spots, shuffled within
/// easy, medium and hard groups and then dealt out so a hard day comes at
/// most every fourth day and 1 December is always easy. December follows
/// that order from the first day, so it works as an advent calendar; the
/// rest of the year walks through the same order by day of the year.
/// 24 December is always the top of the tree, next to the star.
class ElfSchedule {
  static int spotFor(DateTime date) {
    if (date.month == 12 && date.day == 24) return ElfSpots.treeTop;
    final order = orderFor(date.year);
    if (date.month == 12 && date.day < 24) return order[date.day - 1];
    return order[(ChristmasCountdown.dayOfYear(date) - 1) % order.length];
  }

  /// The order of everyday spots for [year]. Same input, same output.
  static List<int> orderFor(int year) {
    final pools = <SpotDifficulty, List<int>>{
      for (final d in SpotDifficulty.values) d: [],
    };
    for (var i = 0; i < ElfSpots.count; i++) {
      if (i == ElfSpots.treeTop) continue;
      pools[ElfSpots.difficulty(i)]!.add(i);
    }
    for (final d in SpotDifficulty.values) {
      pools[d]!.shuffle(math.Random(year * 7919 + d.index));
    }

    // Hard spots go to evenly spaced positions first, never at the start,
    // then easy and medium alternate in the gaps.
    final total = ElfSpots.count - 1;
    final order = List<int?>.filled(total, null);
    final hard = pools[SpotDifficulty.hard]!;
    for (var k = 0; k < hard.length; k++) {
      final position = ((k + 0.5) * total / hard.length).floor().clamp(1, total - 1);
      order[position] = hard[k];
    }
    final easy = pools[SpotDifficulty.easy]!;
    final medium = pools[SpotDifficulty.medium]!;
    var wantEasy = true;
    for (var i = 0; i < total; i++) {
      if (order[i] != null) continue;
      final first = wantEasy ? easy : medium;
      final second = wantEasy ? medium : easy;
      final pool = first.isNotEmpty ? first : (second.isNotEmpty ? second : hard);
      order[i] = pool.removeLast();
      wantEasy = !wantEasy;
    }
    return order.cast<int>();
  }
}
