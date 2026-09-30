import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:christmas_buddy/src/scene/season.dart';
import 'package:christmas_buddy/src/scene/scene_events.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('automatic season changes on the first day of each northern season', () {
    final expected = [
      Season.winter,
      Season.winter,
      Season.spring,
      Season.spring,
      Season.spring,
      Season.summer,
      Season.summer,
      Season.summer,
      Season.autumn,
      Season.autumn,
      Season.autumn,
      Season.winter,
    ];
    for (final year in [2026, 2028]) {
      for (var month = 1; month <= 12; month++) {
        expect(Season.forDate(DateTime(year, month, 1)), expected[month - 1]);
        expect(
          Season.forDate(DateTime(year, month + 1, 0)),
          expected[month - 1],
        );
      }
    }
  });

  test(
    'manual choice persists; automatic restores date-based seasons and keeps progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      var settings = await AppSettings.load();
      final date = DateTime(2026, 9, 30);
      expect(settings.season, isNull);
      expect(settings.seasonFor(date), Season.autumn);
      await settings.markFound('2026-09-30');
      await settings.setSnowIntensity(SnowIntensity.heavy);
      for (final season in Season.values) {
        await settings.setSeason(season);
        settings = await AppSettings.load();
        expect(settings.seasonFor(date), season);
        expect(settings.seasonFor(DateTime(2026, 12, 24)), season);
      }
      await settings.setSeason(null);
      settings = await AppSettings.load();
      expect(settings.season, isNull);
      expect(settings.seasonFor(date), Season.autumn);
      expect(settings.seasonFor(DateTime(2026, 12, 24)), Season.winter);
      expect(settings.isFoundOn('2026-09-30'), isTrue);
      expect(settings.snowIntensity, SnowIntensity.heavy);
    },
  );

  test('unknown saved season safely follows the calendar', () async {
    SharedPreferences.setMockInitialValues({'scene_season': 'invalid'});
    final settings = await AppSettings.load();
    expect(settings.season, isNull);
    expect(settings.seasonFor(DateTime(2028, 2, 29)), Season.winter);
  });

  test(
    'summer override retains Christmas events without a winter aurora notice',
    () {
      final date = DateTime(2026, 12, 24);
      final summer = SceneEvents.forDate(date, season: Season.summer);
      expect(summer.aurora, isFalse);
      expect(summer.sleigh, isTrue);
      expect(SceneEvents.notice(DateTime(2026, 6, 1)), contains('fireflies'));
      expect(SceneEvents.forDate(date).aurora, isTrue);
    },
  );
}
