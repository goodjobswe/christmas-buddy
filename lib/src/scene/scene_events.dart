import 'dart:math' as math;

import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';

/// The little surprises that vary from day to day, picked from the date so
/// everyone sees the same village on the same day.
class SceneEvents {
  const SceneEvents({
    required this.aurora,
    required this.reindeerStation,
    required this.sleigh,
  });

  /// Northern lights in the sky tonight.
  final bool aurora;

  /// Which reindeer station is occupied today, or null for none.
  final int? reindeerStation;

  /// Santa's sleigh crosses the moon (24 and 25 December).
  final bool sleigh;

  static SceneEvents forDate(DateTime date) {
    final random = math.Random(date.year * 1000 + ChristmasCountdown.dayOfYear(date));
    final roll = random.nextInt(12);
    final lucia = date.month == 12 && date.day == 13;
    final christmas = date.month == 12 && (date.day == 24 || date.day == 25);
    return SceneEvents(
      aurora: lucia || christmas || roll < 3,
      reindeerStation: christmas ? 0 : (roll >= 3 && roll < 7 ? (roll - 3) % 2 : null),
      sleigh: christmas,
    );
  }

  /// One or two sentences for the found dialog about what changed today.
  static String notice(DateTime date) {
    final events = forDate(date);
    final day = ChristmasCountdown.decorationDay(date);
    final buffer = StringBuffer();

    if (day == 0) {
      buffer.write('The tree stays bare until 1 December. Then something new goes up every day.');
    } else if (day == 1) {
      buffer.write('The first string of lights went up on the tree today.');
    } else if (day == 24) {
      buffer.write('The star is on top of the tree, and Santa is on his way.');
    } else if (const [5, 9, 13, 17].contains(day)) {
      buffer.write('Another string of lights went up today. The tree is getting brighter.');
    } else if (const [6, 12, 18].contains(day)) {
      buffer.write('A gold garland was wrapped around the tree today.');
    } else if (const [10, 15, 20].contains(day)) {
      buffer.write('A present appeared under the tree today.');
    } else if (day >= 21) {
      buffer.write('A candy cane was hung on the tree today.');
    } else {
      buffer.write('Two new baubles went up today. Can you spot them?');
    }

    if (events.sleigh) {
      buffer.write(' Keep an eye on the moon tonight.');
    } else if (events.aurora) {
      buffer.write(' Also, the northern lights are out tonight.');
    } else if (events.reindeerStation != null) {
      buffer.write(' Also, a reindeer wandered into the village today.');
    }
    return buffer.toString();
  }
}
