import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:christmas_buddy/src/scene/season.dart';

/// How much snow falls. The December day adds on top of this.
enum SnowIntensity {
  off('Off'),
  light('Light'),
  normal('Normal'),
  heavy('Heavy'),
  blizzard('Blizzard');

  const SnowIntensity(this.label);
  final String label;
}

/// All user settings plus the elf progress, stored in shared preferences.
/// Listeners are notified on every change.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  static const _keyChristmasDay = 'christmas_day';
  static const _keySeason = 'scene_season';
  static const _keySnow = 'snow_intensity_v2';
  static const _keyMusic = 'music_on';
  static const _keySound = 'sound_on';
  static const _keyReminder = 'reminder_on';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyFound = 'elf_found_dates';

  /// Country codes where the main celebration is on Christmas Eve.
  static const christmasEveCountries = {
    'SE', 'NO', 'DK', 'FI', 'IS', 'DE', 'AT', 'CH', 'PL', 'CZ', 'SK', 'HU', //
    'EE', 'LV', 'LT', 'PT', 'LU', 'LI', 'SI', 'HR', 'AR', 'BR', 'CL', 'CO', //
    'MX', 'PE', 'UY', 'VE', 'PH', 'FO', 'GL',
  };

  final SharedPreferences _prefs;

  static Future<AppSettings> load({String? countryCode}) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(prefs);
    if (!prefs.containsKey(_keyChristmasDay)) {
      final eve = christmasEveCountries.contains(countryCode?.toUpperCase());
      await prefs.setInt(_keyChristmasDay, eve ? 24 : 25);
    }
    return settings;
  }

  int get christmasDay => _prefs.getInt(_keyChristmasDay) ?? 25;

  Future<void> setChristmasDay(int day) async {
    assert(day == 24 || day == 25);
    await _prefs.setInt(_keyChristmasDay, day);
    notifyListeners();
  }

  /// Null means follow the calendar. Unknown values also fall back to automatic.
  Season? get season {
    final saved = _prefs.getString(_keySeason);
    for (final value in Season.values) {
      if (value.name == saved) return value;
    }
    return null;
  }

  Season seasonFor(DateTime date) => season ?? Season.forDate(date);

  Future<void> setSeason(Season? value) async {
    if (value == null) {
      await _prefs.remove(_keySeason);
    } else {
      await _prefs.setString(_keySeason, value.name);
    }
    notifyListeners();
  }

  SnowIntensity get snowIntensity {
    final index = _prefs.getInt(_keySnow) ?? SnowIntensity.normal.index;
    return SnowIntensity
        .values[index.clamp(0, SnowIntensity.values.length - 1)];
  }

  Future<void> setSnowIntensity(SnowIntensity value) async {
    await _prefs.setInt(_keySnow, value.index);
    notifyListeners();
  }

  bool get musicOn => _prefs.getBool(_keyMusic) ?? true;

  Future<void> setMusicOn(bool value) async {
    await _prefs.setBool(_keyMusic, value);
    notifyListeners();
  }

  bool get soundOn => _prefs.getBool(_keySound) ?? true;

  Future<void> setSoundOn(bool value) async {
    await _prefs.setBool(_keySound, value);
    notifyListeners();
  }

  bool get reminderOn => _prefs.getBool(_keyReminder) ?? false;
  int get reminderHour => _prefs.getInt(_keyReminderHour) ?? 8;
  int get reminderMinute => _prefs.getInt(_keyReminderMinute) ?? 0;

  Future<void> setReminder({required bool on, int? hour, int? minute}) async {
    await _prefs.setBool(_keyReminder, on);
    if (hour != null) await _prefs.setInt(_keyReminderHour, hour);
    if (minute != null) await _prefs.setInt(_keyReminderMinute, minute);
    notifyListeners();
  }

  /// Dates (yyyy-MM-dd) on which the elf was found.
  Set<String> get foundDates =>
      (_prefs.getStringList(_keyFound) ?? const []).toSet();

  bool isFoundOn(String dateKey) => foundDates.contains(dateKey);

  Future<void> markFound(String dateKey) async {
    final dates = foundDates..add(dateKey);
    await _prefs.setStringList(_keyFound, dates.toList()..sort());
    notifyListeners();
  }

  /// How many of the first 24 December days of [year] the elf was found on.
  int foundInDecember(int year) {
    final prefix = '$year-12-';
    return foundDates.where((d) {
      if (!d.startsWith(prefix)) return false;
      final day = int.tryParse(d.substring(prefix.length)) ?? 0;
      return day >= 1 && day <= 24;
    }).length;
  }
}
