import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/app_scope.dart';
import 'package:christmas_buddy/src/clock.dart';
import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';
import 'package:christmas_buddy/src/elf/elf_painter.dart';

/// An advent style overview of which December days the elf was found on.
class ElfCalendarScreen extends StatelessWidget {
  const ElfCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final now = appNow();
        final inDecember = now.month == 12;
        // Outside December show last December if it was played, otherwise
        // look ahead to the coming one instead of a grid full of misses.
        final playedLastYear = settings.foundInDecember(now.year - 1) > 0;
        final year = inDecember || !playedLastYear ? now.year : now.year - 1;
        final upcoming = !inDecember && year == now.year;
        final found = settings.foundDates;
        final decemberCount = settings.foundInDecember(year);
        final today = ChristmasCountdown.dateKey(now);
        final subtitle = inDecember
            ? 'found so far this December'
            : (upcoming ? 'to find this December' : 'found in December $year');

        return Scaffold(
          appBar: AppBar(title: const Text("Pip's Hiding Spots")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const AnimatedElf(height: 90, pose: ElfPose.wave, shadow: false),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$decemberCount of 24',
                              style: const TextStyle(fontFamily: 'Rochester', fontSize: 34, color: ElfColors.red),
                            ),
                            Text(subtitle, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(
                              '${found.length} found in total',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'December $year',
                style: const TextStyle(fontFamily: 'Rochester', fontSize: 28),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var day = 1; day <= 24; day++)
                    _DayTile(
                      day: day,
                      state: _stateFor(
                        key: ChristmasCountdown.dateKey(DateTime(year, 12, day)),
                        today: today,
                        found: found,
                        now: now,
                        year: year,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Pip hides somewhere new every day of the year. In December each day '
                'counts towards the advent tally, and on the 24th he waits by the star.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      },
    );
  }

  _DayState _stateFor({
    required String key,
    required String today,
    required Set<String> found,
    required DateTime now,
    required int year,
  }) {
    if (found.contains(key)) return _DayState.found;
    if (key == today) return _DayState.today;
    final date = DateTime(year, 12, int.parse(key.substring(8)));
    return date.isBefore(DateTime(now.year, now.month, now.day)) ? _DayState.missed : _DayState.future;
  }
}

enum _DayState { found, missed, today, future }

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.state});

  final int day;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    Widget? mark;
    switch (state) {
      case _DayState.found:
        background = const Color(0xFF2E8B3A);
        foreground = Colors.white;
        mark = const Elf(height: 30, pose: ElfPose.wave, t: 0.2);
      case _DayState.missed:
        background = const Color(0xFFE6E1DC);
        foreground = Colors.grey.shade600;
        mark = Icon(Icons.close, size: 18, color: Colors.grey.shade500);
      case _DayState.today:
        background = const Color(0xFFFFF1C2);
        foreground = const Color(0xFF3A2A10);
        mark = const Icon(Icons.search, size: 20, color: Color(0xFFB8860B));
      case _DayState.future:
        background = const Color(0xFFF3EEEA);
        foreground = Colors.grey.shade400;
        mark = null;
    }
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: state == _DayState.today ? Border.all(color: const Color(0xFFB8860B), width: 2) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 4,
            child: Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: foreground)),
          ),
          if (mark != null) Center(child: mark),
        ],
      ),
    );
  }
}
