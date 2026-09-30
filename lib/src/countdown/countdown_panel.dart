import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';

const _shadows = [
  Shadow(color: Color(0xAA000000), blurRadius: 12, offset: Offset(0, 2)),
  Shadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1)),
];

/// The big number of sleeps and the exact time left, drawn over the sky.
class CountdownPanel extends StatelessWidget {
  const CountdownPanel({super.key, required this.countdown, required this.now});

  final ChristmasCountdown countdown;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (countdown.isChristmas(now)) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Merry Christmas!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rochester',
              fontSize: 54,
              height: 1.1,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
          Text(
            'SANTA HAS BEEN',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              letterSpacing: 3,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
        ],
      );
    }

    final sleeps = countdown.sleeps(now);
    final parts = CountdownParts.of(countdown.remaining(now));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sleeps',
          style: const TextStyle(
            fontFamily: 'Rochester',
            fontSize: 96,
            height: 1.0,
            color: Colors.white,
            shadows: _shadows,
          ),
        ),
        Text(
          sleeps == 1 ? 'SLEEP UNTIL CHRISTMAS' : 'SLEEPS UNTIL CHRISTMAS',
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14,
            letterSpacing: 3,
            color: Colors.white,
            shadows: _shadows,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Unit(parts.days, 'days'),
            _Unit(parts.hours, 'hours'),
            _Unit(parts.minutes, 'min'),
            _Unit(parts.seconds, 'sec'),
          ],
        ),
      ],
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit(this.value, this.label);

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x55000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 10,
              letterSpacing: 1,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
