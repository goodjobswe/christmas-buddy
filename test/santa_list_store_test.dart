import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gifts survive reload, edits, completion and deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SantaListStore.load();
    final astrid = await store.add(
      name: ' Astrid ',
      note: ' Bicycle ',
      nice: true,
    );
    await store.add(name: 'Pip', note: 'Too many biscuits', nice: false);
    await store.update(astrid, note: 'A red bicycle', done: true);
    final reloaded = await SantaListStore.load();
    expect(reloaded.nice.single.name, 'Astrid');
    expect(reloaded.nice.single.note, 'A red bicycle');
    expect(reloaded.nice.single.done, isTrue);
    expect(reloaded.naughty.single.name, 'Pip');
    await reloaded.remove(astrid.id);
    expect((await SantaListStore.load()).nice, isEmpty);
    expect((await SantaListStore.load()).naughty, hasLength(1));
  });

  test('invalid stored JSON cannot prevent app startup', () async {
    for (final raw in ['not json', '{}', 'null', '42']) {
      SharedPreferences.setMockInitialValues({'santa_list_v2': raw});
      final store = await SantaListStore.load();
      expect(store.nice, isEmpty);
      expect(store.naughty, isEmpty);
    }
  });

  test(
    'a damaged row does not hide valid gifts or rewrite stored data',
    () async {
      final raw = jsonEncode([
        {'id': 'valid', 'name': 'Astrid', 'note': 'Bicycle', 'nice': true},
        {'id': 17, 'name': 'Damaged'},
        {'id': 'bad-type', 'done': 'yes'},
        null,
        'not a row',
      ]);
      SharedPreferences.setMockInitialValues({'santa_list_v2': raw});
      final store = await SantaListStore.load();
      expect(store.nice.single.name, 'Astrid');
      expect(
        (await SharedPreferences.getInstance()).getString('santa_list_v2'),
        raw,
      );
    },
  );
}
