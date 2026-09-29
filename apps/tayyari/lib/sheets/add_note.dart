import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'note_detail.dart';

/// Creates a note (a chapter or handout), then opens it so questions can be added.
Future<void> showAddNote(BuildContext context) async {
  final id = await showAppSheet<int>(context, (_) => const _AddNote());
  if (id != null && context.mounted) await showNoteDetail(context, id);
}

class _AddNote extends StatefulWidget {
  const _AddNote();

  @override
  State<_AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<_AddNote> {
  final _name = TextEditingController();
  String sec = 'ga';
  String topic = syllabus['ga']!.first;
  String? error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add notes', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Name the chapter or handout. Next, type the questions you want to be tested on, with the line each one comes from.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Notes title', hintText: 'Fundamental Rights, part 2'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: sec,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Section'),
          items: [for (final s in sectionKeys) DropdownMenuItem(value: s, child: Text(secName(s)))],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              sec = v;
              topic = syllabus[v]!.first;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('topic-$sec'),
          initialValue: topic,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Topic'),
          items: [for (final t in syllabus[sec]!) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) {
            if (v != null) setState(() => topic = v);
          },
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) {
              setState(() => error = 'Give the notes a title.');
              return;
            }
            final id = store.addNote(n, sec, topic);
            Navigator.pop(context, id);
          },
          child: const Text('Save note'),
        ),
      ],
    );
  }
}
