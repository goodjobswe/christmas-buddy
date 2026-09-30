import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/app_scope.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final reminderTime = TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute);
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _SectionTitle('Christmas is on'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 24, label: Text('24 December')),
                  ButtonSegment(value: 25, label: Text('25 December')),
                ],
                selected: {settings.christmasDay},
                onSelectionChanged: (selection) => settings.setChristmasDay(selection.first),
              ),
              const _Hint(
                'Christmas Eve for Sweden and much of Europe, Christmas Day for most of '
                'the English speaking world. The countdown ends at midnight.',
              ),
              const _SectionTitle('Snow'),
              Slider(
                value: settings.snowIntensity.index.toDouble(),
                min: 0,
                max: (SnowIntensity.values.length - 1).toDouble(),
                divisions: SnowIntensity.values.length - 1,
                label: settings.snowIntensity.label,
                onChanged: (value) => settings.setSnowIntensity(SnowIntensity.values[value.round()]),
              ),
              _Hint('${settings.snowIntensity.label}. It snows a little harder as December goes on, '
                  'and you can blow the snow sideways with a finger.'),
              const _SectionTitle('Sound'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Carols'),
                subtitle: const Text('Music box versions of the classics'),
                value: settings.musicOn,
                onChanged: settings.setMusicOn,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound effects'),
                subtitle: const Text('Jingles when you find Pip'),
                value: settings.soundOn,
                onChanged: settings.setSoundOn,
              ),
              const _SectionTitle('Daily reminder'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remind me every morning in December'),
                subtitle: const Text('How many sleeps are left, and a nudge that Pip has moved'),
                value: settings.reminderOn,
                onChanged: (on) => _toggleReminder(context, on),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: settings.reminderOn,
                title: const Text('Time'),
                trailing: Text(
                  reminderTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: reminderTime);
                  if (picked != null) {
                    await settings.setReminder(on: true, hour: picked.hour, minute: picked.minute);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleReminder(BuildContext context, bool on) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (on) {
      final allowed = await scope.reminders?.requestPermission() ?? true;
      if (!allowed) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Notifications are turned off for Christmas Buddy in the phone settings.'),
        ));
        return;
      }
    }
    await scope.settings.setReminder(on: on);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Rochester', fontSize: 28, color: Color(0xFFD6001C)),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700)),
    );
  }
}
