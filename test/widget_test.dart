import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:christmas_buddy/main.dart';
import 'package:christmas_buddy/src/audio/audio_controller.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';
import 'package:christmas_buddy/src/settings/app_settings.dart';

Future<Widget> buildApp() async {
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load(countryCode: 'SE');
  final lists = SantaListStore(await SharedPreferences.getInstance());
  return ChristmasBuddyApp(
    settings: settings,
    lists: lists,
    audio: AudioController(enabled: false),
  );
}

void main() {
  testWidgets('home screen shows the countdown and the elf', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();

    final countdown = find.textContaining('UNTIL CHRISTMAS');
    final christmas = find.text('Merry Christmas!');
    expect(countdown.evaluate().isNotEmpty || christmas.evaluate().isNotEmpty, isTrue);
    expect(find.text('Pip the elf'), findsOneWidget);
    expect(find.textContaining('Pip is hiding'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Swedish locale defaults to Christmas Eve', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load(countryCode: 'SE');
    expect(settings.christmasDay, 24);
    SharedPreferences.setMockInitialValues({});
    final us = await AppSettings.load(countryCode: 'US');
    expect(us.christmasDay, 25);
  });

  testWidgets('the nice list can be added to', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();

    // The home screen ticks every second and keeps its snow falling, so
    // pumpAndSettle would never settle. Pump the transitions explicitly.
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.byTooltip('Menu'));
    await settle();
    await tester.tap(find.text("Santa's list"));
    await settle();

    expect(find.text('Nobody on the nice list yet. Add someone who has been extra nice this year and note what Santa is bringing.'), findsOneWidget);
    await tester.tap(find.text('Add to nice list'));
    await settle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Astrid');
    await tester.enterText(find.widgetWithText(TextFormField, 'What Santa is bringing'), 'A red bicycle');
    await tester.tap(find.text('Add'));
    await settle();

    expect(find.text('Astrid'), findsOneWidget);
    expect(find.text('A red bicycle'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
