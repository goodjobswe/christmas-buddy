import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:christmas_buddy/src/models/santa_list_model.dart';

/// Santa's nice and naughty lists, stored as one JSON string in shared
/// preferences. Small enough that a database would be overkill.
class SantaListStore extends ChangeNotifier {
  SantaListStore(this._prefs) : _entries = _read(_prefs);

  static const _key = 'santa_list_v2';

  final SharedPreferences _prefs;
  final List<SantaListEntry> _entries;

  static Future<SantaListStore> load() async {
    return SantaListStore(await SharedPreferences.getInstance());
  }

  static List<SantaListEntry> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SantaListEntry.fromJson(e as Map<String, Object?>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  List<SantaListEntry> get nice => _sorted(true);
  List<SantaListEntry> get naughty => _sorted(false);

  List<SantaListEntry> _sorted(bool nice) {
    final list = _entries.where((e) => e.nice == nice).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<SantaListEntry> add({
    required String name,
    required String note,
    required bool nice,
  }) async {
    final entry = SantaListEntry(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name.trim(),
      note: note.trim(),
      nice: nice,
    );
    _entries.add(entry);
    await _save();
    return entry;
  }

  Future<void> update(SantaListEntry entry,
      {String? name, String? note, bool? done}) async {
    if (name != null) entry.name = name.trim();
    if (note != null) entry.note = note.trim();
    if (done != null) entry.done = done;
    await _save();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }
}
