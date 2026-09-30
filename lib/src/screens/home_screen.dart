import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/app_scope.dart';
import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/clock.dart';
import 'package:christmas_buddy/src/countdown/christmas_countdown.dart';
import 'package:christmas_buddy/src/countdown/countdown_panel.dart';
import 'package:christmas_buddy/src/elf/elf_lines.dart';
import 'package:christmas_buddy/src/elf/elf_painter.dart';
import 'package:christmas_buddy/src/elf/elf_schedule.dart';
import 'package:christmas_buddy/src/elf/found_dialog.dart';
import 'package:christmas_buddy/src/scene/christmas_scene.dart';
import 'package:christmas_buddy/src/scene/elf_spots.dart';
import 'package:christmas_buddy/src/scene/scene_events.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';
import 'package:christmas_buddy/src/share/share_scene.dart';
import 'package:christmas_buddy/src/snow/snowflakes.dart';
import 'package:christmas_buddy/src/theme.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', //
  'September', 'October', 'November', 'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sceneKey = GlobalKey<ChristmasSceneState>();
  final _shareKey = GlobalKey();
  final _random = Random();
  final _clock = ValueNotifier<DateTime>(appNow());

  Timer? _timer;
  Timer? _toastTimer;
  Timer? _hintTimer;
  bool _initialised = false;
  String _dateKey = '';
  String _line = '';
  String? _toast;
  bool _hintReady = false;
  double? _lastMissDistance;
  int _lastSleeps = -1;

  AppSettings get _settings => AppScope.of(context).settings;
  AudioController get _audio => AppScope.of(context).audio;
  ChristmasCountdown get _countdown =>
      ChristmasCountdown(christmasDay: _settings.christmasDay);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _armHint(const Duration(seconds: 40));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _refreshDay(appNow(), first: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _toastTimer?.cancel();
    _hintTimer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _tick() {
    final now = appNow();
    _clock.value = now;
    if (ChristmasCountdown.dateKey(now) != _dateKey) _refreshDay(now);
  }

  void _refreshDay(DateTime now, {bool first = false}) {
    final countdown = _countdown;
    final sleeps = countdown.sleeps(now);
    if (!first && sleeps < _lastSleeps) _audio.play(Sfx.chime);
    _lastSleeps = sleeps;
    setState(() {
      _dateKey = ChristmasCountdown.dateKey(now);
      _line = ElfLines.pick(_random, sleeps: sleeps, isChristmas: countdown.isChristmas(now));
      _lastMissDistance = null;
    });
  }

  void _newLine() {
    final now = appNow();
    final countdown = _countdown;
    setState(() {
      _line = ElfLines.pick(_random, sleeps: countdown.sleeps(now), isChristmas: countdown.isChristmas(now));
    });
  }

  void _armHint(Duration delay) {
    _hintTimer?.cancel();
    _hintTimer = Timer(delay, () {
      if (mounted) setState(() => _hintReady = true);
    });
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _onElfTap(ElfSpot spot) async {
    final settings = _settings;
    final audio = _audio;
    final now = appNow();
    final key = ChristmasCountdown.dateKey(now);
    _sceneKey.currentState?.react();
    if (settings.isFoundOn(key)) {
      audio.play(Sfx.wave);
      _showToast(ElfLines.pickAgain(_random));
      return;
    }
    await settings.markFound(key);
    audio.play(Sfx.jingle);
    if (!mounted) return;
    setState(() => _hintReady = false);
    final detail = now.month == 12
        ? 'Found on ${_dayLabel(now)}. ${settings.foundInDecember(now.year)} of 24 this December.'
        : 'Found on ${_dayLabel(now)}. ${settings.foundDates.length} found in total.';
    await showFoundDialog(
      context,
      line: ElfLines.foundLineFor(spot.reaction, _random),
      detail: detail,
      notice: SceneEvents.notice(now),
    );
  }

  void _onMissTap(Offset position, double distance) {
    _audio.play(Sfx.puff);
    if (_settings.isFoundOn(_dateKey)) return;
    final last = _lastMissDistance;
    _lastMissDistance = distance;
    final String text;
    if (distance < 70) {
      text = ElfLines.hot;
    } else if (last == null) {
      text = distance < 180 ? ElfLines.warmer : ElfLines.cold;
    } else {
      text = distance < last ? ElfLines.warmer : ElfLines.colder;
    }
    _showToast(text);
  }

  void _showHint() {
    _sceneKey.currentState?.showHint();
    setState(() => _hintReady = false);
    _armHint(const Duration(seconds: 20));
  }

  Future<void> _share() async {
    final now = appNow();
    final countdown = _countdown;
    final text = countdown.isChristmas(now)
        ? 'Merry Christmas from Christmas Buddy!'
        : '${countdown.sleeps(now)} sleeps until Christmas! Counting down with Christmas Buddy.';
    final messenger = ScaffoldMessenger.of(context);
    final ok = await shareScene(_shareKey, text: text);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Sharing is not available on this device.')));
    }
  }

  String _dayLabel(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final now = appNow();
        final countdown = ChristmasCountdown(christmasDay: settings.christmasDay);
        final day = ChristmasCountdown.decorationDay(now);
        final foundToday = settings.isFoundOn(_dateKey);
        final flakes = snowFlakeCount(
          intensityIndex: settings.snowIntensity.index,
          decorationDay: day,
        );

        return Scaffold(
          backgroundColor: nightBlue,
          body: RepaintBoundary(
            key: _shareKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ChristmasScene(
                  key: _sceneKey,
                  day: day,
                  elfSpotIndex: ElfSchedule.spotFor(now),
                  events: SceneEvents.forDate(now),
                  showElf: true,
                  flakeCount: flakes,
                  onElfTap: _onElfTap,
                  onMissTap: _onMissTap,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _RoundButton(
                              icon: settings.musicOn ? Icons.music_note : Icons.music_off,
                              tooltip: settings.musicOn ? 'Turn carols off' : 'Turn carols on',
                              onPressed: () => settings.setMusicOn(!settings.musicOn),
                            ),
                            const Spacer(),
                            _menu(context, settings),
                          ],
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<DateTime>(
                          valueListenable: _clock,
                          builder: (context, now, _) => CountdownPanel(countdown: countdown, now: now),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _toast == null
                              ? const SizedBox(height: 4)
                              : Align(
                                  key: ValueKey(_toast),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xEEFFD75E),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _toast!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A2A10)),
                                    ),
                                  ),
                                ),
                        ),
                        Row(
                          children: [
                            _ElfChip(
                              foundToday: foundToday,
                              decemberCount: now.month == 12 ? settings.foundInDecember(now.year) : null,
                              onTap: () => Navigator.pushNamed(context, '/calendar'),
                            ),
                            const Spacer(),
                            if (_hintReady && !foundToday)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0x66000000),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _showHint,
                                icon: const Icon(Icons.lightbulb_outline, size: 18),
                                label: const Text('Hint'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _newLine,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            decoration: BoxDecoration(
                              color: const Color(0x88000000),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _line,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Pip the elf',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontFamily: 'Rochester', color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menu(BuildContext context, AppSettings settings) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      offset: const Offset(0, 48),
      icon: const _RoundIcon(Icons.menu),
      onSelected: (value) {
        switch (value) {
          case 'list':
          case 'calendar':
          case 'settings':
          case 'about':
            Navigator.pushNamed(context, '/$value');
          case 'share':
            _share();
          case 'next':
            _audio.next();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'list', child: ListTile(leading: Icon(Icons.checklist), title: Text("Santa's list"))),
        const PopupMenuItem(value: 'calendar', child: ListTile(leading: Icon(Icons.calendar_month), title: Text("Pip's hiding spots"))),
        const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share the countdown'))),
        if (settings.musicOn)
          const PopupMenuItem(value: 'next', child: ListTile(leading: Icon(Icons.skip_next), title: Text('Next carol'))),
        const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
        const PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info_outline), title: Text('About'))),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: _RoundIcon(icon),
    );
  }
}

class _ElfChip extends StatelessWidget {
  const _ElfChip({required this.foundToday, required this.decemberCount, required this.onTap});

  final bool foundToday;
  final int? decemberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = decemberCount;
    final text = StringBuffer(foundToday ? 'Pip found today' : 'Pip is hiding');
    if (count != null) text.write(' · $count of 24');
    return Material(
      color: const Color(0x66000000),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Elf(height: 28, pose: foundToday ? ElfPose.wave : ElfPose.idle, t: 0.25),
              const SizedBox(width: 6),
              Text(text.toString(), style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
