import 'package:flutter_test/flutter_test.dart';

import 'package:christmas_buddy/src/elf/elf_schedule.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';

void main() {
  test('each year deals out every everyday spot once', () {
    for (final year in [2026, 2027, 2030]) {
      final order = ElfSchedule.orderFor(year);
      expect(order.length, ElfSpots.count - 1);
      expect(order.toSet().length, order.length, reason: 'no repeats in $year');
      expect(order, isNot(contains(ElfSpots.treeTop)));
    }
  });

  test('the order changes from year to year but is stable for a year', () {
    expect(ElfSchedule.orderFor(2026), isNot(equals(ElfSchedule.orderFor(2027))));
    expect(ElfSchedule.orderFor(2026), equals(ElfSchedule.orderFor(2026)));
  });

  test('hard days are spread out and 1 December is easy', () {
    for (final year in [2026, 2027, 2028, 2031]) {
      final order = ElfSchedule.orderFor(year);
      expect(ElfSpots.difficulty(order.first), SpotDifficulty.easy, reason: 'year $year');
      for (var i = 1; i < order.length; i++) {
        final hardTwice = ElfSpots.difficulty(order[i]) == SpotDifficulty.hard &&
            ElfSpots.difficulty(order[i - 1]) == SpotDifficulty.hard;
        expect(hardTwice, isFalse, reason: 'two hard days in a row at $i in $year');
      }
    }
  });

  test('December follows the order and the 24th is the tree top', () {
    final order = ElfSchedule.orderFor(2026);
    expect(ElfSchedule.spotFor(DateTime(2026, 12, 1)), order[0]);
    expect(ElfSchedule.spotFor(DateTime(2026, 12, 23)), order[22]);
    expect(ElfSchedule.spotFor(DateTime(2026, 12, 24)), ElfSpots.treeTop);
    expect(ElfSchedule.spotFor(DateTime(2027, 12, 24)), ElfSpots.treeTop);
  });

  test('the rest of the year visits every spot and never repeats on consecutive days', () {
    final seen = <int>{};
    int? previous;
    for (var day = DateTime(2026, 1, 1); day.isBefore(DateTime(2026, 12, 1)); day = day.add(const Duration(days: 1))) {
      final spot = ElfSchedule.spotFor(day);
      expect(spot, isNot(previous), reason: 'same spot two days running on $day');
      seen.add(spot);
      previous = spot;
    }
    expect(seen.length, ElfSpots.count - 1);
  });
}
