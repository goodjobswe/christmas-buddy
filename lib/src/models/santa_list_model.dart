/// One row on Santa's list: a person, what they get (or why they are on the
/// naughty side), and whether it has been sorted out.
class SantaListEntry {
  SantaListEntry({
    required this.id,
    required this.name,
    required this.note,
    required this.nice,
    this.done = false,
  });

  factory SantaListEntry.fromJson(Map<String, Object?> json) {
    return SantaListEntry(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      nice: json['nice'] as bool? ?? true,
      done: json['done'] as bool? ?? false,
    );
  }

  final String id;
  String name;
  String note;
  final bool nice;
  bool done;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'nice': nice,
        'done': done,
      };

  @override
  String toString() =>
      'SantaListEntry($id, $name, $note, nice: $nice, done: $done)';
}
