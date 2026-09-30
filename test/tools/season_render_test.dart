// Run with RENDER_OUT set to a directory to inspect every season and key hiding props.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:christmas_buddy/main.dart';
import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/scene/christmas_scene.dart';
import 'package:christmas_buddy/src/scene/season.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

void main() {
  final out = Platform.environment['RENDER_OUT'];
  testWidgets('render seasonal home screens and hiding places', (tester) async {
    Directory(out!).createSync(recursive: true);
    for (final name in ['Rochester', 'OpenSans']) {
      await (FontLoader(name)
        ..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'))).load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.physicalSize = const Size(411, 890);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(411, 890));
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(countryCode: 'SE');
    final lists = SantaListStore(await SharedPreferences.getInstance());
    Future<void> capture(String name) async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      ChristmasBuddyApp(
        settings: settings,
        lists: lists,
        audio: AudioController(enabled: false),
      ),
    );
    for (final season in Season.values) {
      await settings.setSeason(season);
      await capture('home_${season.name}');
    }
    for (final season in Season.values) {
      for (final spot in [1, 7, 13]) {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              child: ChristmasScene(
                day: 0,
                elfSpotIndex: spot,
                showElf: true,
                flakeCount: 0,
                season: season,
                animate: false,
              ),
            ),
          ),
        );
        await capture('${season.name}_spot_$spot');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: out == null);
}
