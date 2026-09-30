import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:christmas_buddy/src/app_scope.dart';
import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/notifications/reminder_scheduler.dart';
import 'package:christmas_buddy/src/screens/about_screen.dart';
import 'package:christmas_buddy/src/screens/elf_calendar_screen.dart';
import 'package:christmas_buddy/src/screens/home_screen.dart';
import 'package:christmas_buddy/src/screens/santa_list_screen.dart';
import 'package:christmas_buddy/src/screens/settings_screen.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';
import 'package:christmas_buddy/src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final entry
        in {
          'Christmas Buddy': 'christmas-buddy-MIT.txt',
          'Open Sans': 'OpenSans-OFL.txt',
          'Rochester': 'Rochester-Apache-2.0.txt',
        }.entries) {
      final text = await rootBundle.loadString(
        'assets/licenses/${entry.value}',
      );
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
  final country = PlatformDispatcher.instance.locale.countryCode;
  final settings = await AppSettings.load(countryCode: country);
  final lists = await SantaListStore.load();
  runApp(
    ChristmasBuddyApp(
      settings: settings,
      lists: lists,
      audio: AudioController(),
      reminders: ReminderScheduler(),
    ),
  );
}

class ChristmasBuddyApp extends StatefulWidget {
  const ChristmasBuddyApp({
    super.key,
    required this.settings,
    required this.lists,
    required this.audio,
    this.reminders,
  });

  final AppSettings settings;
  final SantaListStore lists;
  final AudioController audio;
  final ReminderScheduler? reminders;

  @override
  State<ChristmasBuddyApp> createState() => _ChristmasBuddyAppState();
}

class _ChristmasBuddyAppState extends State<ChristmasBuddyApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_applySettings);
    _applySettings();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_applySettings);
    super.dispose();
  }

  void _applySettings() {
    final settings = widget.settings;
    widget.audio.soundOn = settings.soundOn;
    widget.audio.setMusicOn(settings.musicOn);
    widget.reminders?.sync(settings);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: widget.settings,
      lists: widget.lists,
      audio: widget.audio,
      reminders: widget.reminders,
      child: MaterialApp(
        title: 'Christmas Buddy',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routes: {
          '/': (context) => const HomeScreen(),
          '/list': (context) => const SantaListScreen(),
          '/calendar': (context) => const ElfCalendarScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/about': (context) => const AboutScreen(),
        },
      ),
    );
  }
}
