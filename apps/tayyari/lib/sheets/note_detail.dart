import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showNoteDetail(BuildContext context, int id) => showAppSheet(context, (_) => _NoteDetail(id: id));

Future<void> showAddQuestion(BuildContext context, int noteId) => showAppSheet(context, (_) => _AddQuestion(noteId: noteId));

class _NoteDetail extends StatelessWidget {
  const _NoteDetail({required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final n = store.data == null ? null : store.note(id);
    if (n == null) return const SizedBox(height: 120); // deleted; sheet is closing
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tones(context);
    final qs = store.noteQuestions(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(n.name, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${secName(n.sec)} · ${n.topic} · added ${shortDate(n.at)}', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (qs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No questions yet. Add the first one from these notes.', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        for (var i = 0; i < qs.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${qs[i].q}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      for (var k = 0; k < qs[i].o.length; k++)
                        Text(
                          '${'ABCD'[k % 4]}) ${qs[i].o[k]}${k == qs[i].a ? '  ✓' : ''}',
                          style: TextStyle(
                            color: k == qs[i].a ? t.good : cs.onSurfaceVariant,
                            fontWeight: k == qs[i].a ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      if (qs[i].src != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(border: Border(left: BorderSide(color: accentYellow, width: 3))),
                          child: Text(qs[i].src!, style: tt.bodySmall),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete question',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirm(context,
                        title: 'Delete this question?', body: 'It will also leave your revision.', action: 'Delete', danger: true);
                    if (ok) store.deleteNoteQuestion(qs[i].id);
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => showAddQuestion(context, id),
          icon: const Icon(Icons.add),
          label: const Text('Add a question'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: 'Delete these notes?',
              body: '${n.name} and its ${qs.length} question${qs.length == 1 ? '' : 's'} will be removed.',
              action: 'Delete',
              danger: true,
            );
            if (ok && context.mounted) {
              Navigator.pop(context);
              store.deleteNote(id);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete notes'),
        ),
      ],
    );
  }
}

class _AddQuestion extends StatefulWidget {
  const _AddQuestion({required this.noteId});
  final int noteId;

  @override
  State<_AddQuestion> createState() => _AddQuestionState();
}

class _AddQuestionState extends State<_AddQuestion> {
  final _q = TextEditingController();
  final _opts = List.generate(4, (_) => TextEditingController());
  final _ex = TextEditingController();
  final _src = TextEditingController();
  int answer = 0;
  String? error;

  @override
  void dispose() {
    _q.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    _ex.dispose();
    _src.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final q = _q.text.trim();
    final o = _opts.map((c) => c.text.trim()).toList();
    if (q.isEmpty) {
      setState(() => error = 'Type the question.');
      return;
    }
    if (o.any((x) => x.isEmpty)) {
      setState(() => error = 'Fill in all four options.');
      return;
    }
    if (o.toSet().length < 4) {
      setState(() => error = 'The four options should all be different.');
      return;
    }
    store.addNoteQuestion(noteId: widget.noteId, q: q, o: o, a: answer, ex: _ex.text.trim(), src: _src.text.trim());
    Navigator.pop(context);
    toast(context, 'Question added. It first appears in tomorrow\'s revision.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add a question', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _q,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Question'),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _opts[i],
              decoration: InputDecoration(labelText: 'Option ${'ABCD'[i]}'),
            ),
          ),
        const SizedBox(height: 4),
        Text('Correct answer', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              ChoiceChip(label: Text('ABCD'[i]), selected: answer == i, onSelected: (_) => setState(() => answer = i)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ex,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Explanation (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _src,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Source line from your notes (optional)', hintText: 'p.3: "Art. 32 – …"'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: const Text('Save question'),
        ),
      ],
    );
  }
}
