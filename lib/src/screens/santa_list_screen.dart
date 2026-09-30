import 'package:flutter/material.dart';

import 'package:christmas_buddy/src/app_scope.dart';
import 'package:christmas_buddy/src/elf/elf_painter.dart';
import 'package:christmas_buddy/src/models/santa_list_model.dart';
import 'package:christmas_buddy/src/services/santa_list_store.dart';

/// The nice list and the naughty list, one tab each.
class SantaListScreen extends StatelessWidget {
  const SantaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Santa's List"),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Nice'),
              Tab(icon: Icon(Icons.sentiment_dissatisfied), text: 'Naughty'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListTab(nice: true),
            _ListTab(nice: false),
          ],
        ),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.nice});

  final bool nice;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).lists;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entries = nice ? store.nice : store.naughty;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: nice ? 'add-nice' : 'add-naughty',
            onPressed: () => _edit(context, store, null),
            icon: const Icon(Icons.add),
            label: Text(nice ? 'Add to nice list' : 'Add to naughty list'),
          ),
          body: entries.isEmpty
              ? _EmptyList(nice: nice)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _EntryTile(
                    entry: entries[i],
                    store: store,
                    onEdit: () => _edit(context, store, entries[i]),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, SantaListStore store, SantaListEntry? entry) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _EditForm(store: store, entry: entry, nice: nice),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.store, required this.onEdit});

  final SantaListEntry entry;
  final SantaListStore store;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        store.remove(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.name} removed')),
        );
      },
      child: Card(
        child: ListTile(
          leading: entry.nice
              ? Checkbox(
                  activeColor: const Color(0xFF2E8B3A),
                  value: entry.done,
                  onChanged: (value) => store.update(entry, done: value ?? false),
                )
              : const Icon(Icons.sentiment_dissatisfied, color: Color(0xFF8B2E2E)),
          title: Text(
            entry.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: entry.done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: entry.note.isEmpty ? null : Text(entry.note),
          trailing: IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.nice});

  final bool nice;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Elf(height: 90, pose: ElfPose.wave, t: 0.2),
            const SizedBox(height: 16),
            Text(
              nice
                  ? 'Nobody on the nice list yet. Add someone who has been extra nice this year and note what Santa is bringing.'
                  : 'The naughty list is empty. Pip says: keep it that way!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.store, required this.entry, required this.nice});

  final SantaListStore store;
  final SantaListEntry? entry;
  final bool nice;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.entry?.name ?? '');
  late final _note = TextEditingController(text: widget.entry?.note ?? '');

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final entry = widget.entry;
    if (entry == null) {
      await widget.store.add(name: _name.text, note: _note.text, nice: widget.nice);
    } else {
      await widget.store.update(entry, name: _name.text, note: _note.text);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing
                  ? 'Edit'
                  : (widget.nice ? 'Who has been nice?' : 'Who has been naughty?'),
              style: const TextStyle(fontFamily: 'Rochester', fontSize: 30),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.nice ? 'What Santa is bringing' : 'Why they are on the list',
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () async {
                      await widget.store.remove(widget.entry!.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(editing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
