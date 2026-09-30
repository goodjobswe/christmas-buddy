import 'package:flutter_test/flutter_test.dart';

import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';

void main() {
  const eve = ChristmasCountdown(christmasDay: 24);
  const day = ChristmasCountdown(christmasDay: 25);

  group('target date', () {
    test('counts to this year before Christmas', () {
      expect(eve.targetFor(DateTime(2026, 9, 30)), DateTime(2026, 12, 24));
      expect(day.targetFor(DateTime(2026, 12, 24, 23, 59)), DateTime(2026, 12, 25));
    });

    test('stays on this year while it is Christmas', () {
      expect(eve.targetFor(DateTime(2026, 12, 25, 12)), DateTime(2026, 12, 24));
      expect(day.targetFor(DateTime(2026, 12, 25, 12)), DateTime(2026, 12, 25));
    });

    test('moves to next year from 26 December', () {
      expect(eve.targetFor(DateTime(2026, 12, 26)), DateTime(2027, 12, 24));
      expect(day.targetFor(DateTime(2026, 12, 31, 23, 59)), DateTime(2027, 12, 25));
    });
  });

  group('sleeps', () {
    test('counts calendar nights, not 24 hour blocks', () {
      expect(eve.sleeps(DateTime(2026, 12, 1, 8)), 23);
      expect(eve.sleeps(DateTime(2026, 12, 23, 23, 59)), 1);
      expect(eve.sleeps(DateTime(2026, 12, 24, 10)), 0);
      expect(day.sleeps(DateTime(2026, 12, 24, 10)), 1);
      expect(day.sleeps(DateTime(2026, 12, 1)), 24);
    });

    test('is never negative and rolls over after Christmas', () {
      expect(eve.sleeps(DateTime(2026, 12, 25, 15)), 0);
      expect(eve.sleeps(DateTime(2026, 12, 26)), 363);
    });
  });

  group('isChristmas', () {
    test('covers the chosen day through 25 December', () {
      expect(eve.isChristmas(DateTime(2026, 12, 23, 23, 59)), isFalse);
      expect(eve.isChristmas(DateTime(2026, 12, 24)), isTrue);
      expect(eve.isChristmas(DateTime(2026, 12, 25, 23, 59)), isTrue);
      expect(eve.isChristmas(DateTime(2026, 12, 26)), isFalse);
      expect(day.isChristmas(DateTime(2026, 12, 24, 23, 59)), isFalse);
      expect(day.isChristmas(DateTime(2026, 12, 25)), isTrue);
    });
  });

  test('remaining is exact and never negative', () {
    expect(day.remaining(DateTime(2026, 12, 24, 22)), const Duration(hours: 2));
    expect(day.remaining(DateTime(2026, 12, 25, 1)), Duration.zero);
    final parts = CountdownParts.of(const Duration(days: 3, hours: 4, minutes: 5, seconds: 6));
    expect((parts.days, parts.hours, parts.minutes, parts.seconds), (3, 4, 5, 6));
  });

  test('decoration day only counts in December, capped at 24', () {
    expect(ChristmasCountdown.decorationDay(DateTime(2026, 11, 30)), 0);
    expect(ChristmasCountdown.decorationDay(DateTime(2026, 12, 1)), 1);
    expect(ChristmasCountdown.decorationDay(DateTime(2026, 12, 24)), 24);
    expect(ChristmasCountdown.decorationDay(DateTime(2026, 12, 31)), 24);
  });

  test('day of year', () {
    expect(ChristmasCountdown.dayOfYear(DateTime(2026, 1, 1)), 1);
    expect(ChristmasCountdown.dayOfYear(DateTime(2026, 12, 31)), 365);
    expect(ChristmasCountdown.dayOfYear(DateTime(2028, 12, 31)), 366);
  });

  test('date keys are zero padded', () {
    expect(ChristmasCountdown.dateKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(ChristmasCountdown.dateKey(DateTime(2026, 12, 24)), '2026-12-24');
  });
}
