/// Pure date logic for the countdown. No Flutter imports, so it is easy to
/// unit test with fixed dates.
class ChristmasCountdown {
  const ChristmasCountdown({required this.christmasDay});

  /// 24 for people who celebrate on Christmas Eve, 25 for Christmas Day.
  final int christmasDay;

  /// Midnight at the start of the Christmas we are counting to. While it is
  /// Christmas (see [isChristmas]) this lies in the past; from 26 December
  /// the target moves to next year.
  DateTime targetFor(DateTime now) {
    final endOfChristmas = DateTime(now.year, 12, 26);
    if (now.isBefore(endOfChristmas)) {
      return DateTime(now.year, 12, christmasDay);
    }
    return DateTime(now.year + 1, 12, christmasDay);
  }

  /// True from midnight on the chosen day until the end of 25 December.
  bool isChristmas(DateTime now) {
    final start = DateTime(now.year, 12, christmasDay);
    final end = DateTime(now.year, 12, 26);
    return !now.isBefore(start) && now.isBefore(end);
  }

  /// Exact time left, never negative.
  Duration remaining(DateTime now) {
    final left = targetFor(now).difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Nights to sleep before Christmas morning: the number of calendar days
  /// between today and the target date. Uses UTC dates so daylight saving
  /// changes cannot skew the count.
  int sleeps(DateTime now) {
    final target = targetFor(now);
    final today = DateTime.utc(now.year, now.month, now.day);
    final day = DateTime.utc(target.year, target.month, target.day);
    final sleeps = day.difference(today).inDays;
    return sleeps < 0 ? 0 : sleeps;
  }

  /// How far the tree has been decorated: 1 to 24 in December, otherwise 0.
  static int decorationDay(DateTime now) {
    if (now.month != 12) return 0;
    return now.day > 24 ? 24 : now.day;
  }

  /// Which of the 24 hiding spots the elf uses today. In December it follows
  /// the date to keep the advent feel; the rest of the year it rotates.
  static int hidingSpot(DateTime now) {
    if (now.month == 12 && now.day <= 24) return now.day - 1;
    return dayOfYear(now) % 24;
  }

  static int dayOfYear(DateTime now) {
    final start = DateTime.utc(now.year, 1, 1);
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  /// Key used to remember which days the elf was found on.
  static String dateKey(DateTime now) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}

/// The parts of a remaining duration, ready to display.
class CountdownParts {
  const CountdownParts(this.days, this.hours, this.minutes, this.seconds);

  factory CountdownParts.of(Duration d) {
    return CountdownParts(
      d.inDays,
      d.inHours.remainder(24),
      d.inMinutes.remainder(60),
      d.inSeconds.remainder(60),
    );
  }

  final int days;
  final int hours;
  final int minutes;
  final int seconds;
}
