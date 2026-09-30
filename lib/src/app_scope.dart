import 'package:flutter/widgets.dart';

import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/notifications/reminder_scheduler.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

/// Hands the shared objects to every screen without a state package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.lists,
    required this.audio,
    required this.reminders,
    required super.child,
  });

  final AppSettings settings;
  final SantaListStore lists;
  final AudioController audio;
  final ReminderScheduler? reminders;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      settings != old.settings ||
      lists != old.lists ||
      audio != old.audio ||
      reminders != old.reminders;
}
