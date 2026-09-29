import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add a doctor visit or test, or edit one when [visitId] is given.
Future<void> showVisitSheet(BuildContext context, {int? visitId}) {
  final store = StoreScope.read(context);
  Visit? v;
  for (final x in store.data!.visits) {
    if (x.id == visitId) v = x;
  }
  return showAppSheet(context, (_) => _VisitSheet(existing: v, who: v?.who ?? store.current.id));
}

class _VisitSheet extends StatefulWidget {
  const _VisitSheet({required this.existing, required this.who});
  final Visit? existing;
  final String who;

  @override
  State<_VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends State<_VisitSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.existing?.note ?? '');
  late String who = widget.who;
  late String date = widget.existing?.date ?? addDaysIso(todayIso(), 7);
  late String time = widget.existing?.time ?? '10:00';
  String? error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(date),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => date = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final editing = widget.existing;
    final today = todayIso();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(editing == null ? 'Add a visit or test' : 'Edit visit'),
        if (d.parents.length > 1) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final p in d.parents)
                ChoiceChip(label: Text(p.name), selected: who == p.id, onSelected: (_) => setState(() => who = p.id)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What', hintText: 'Dr. Deshpande (diabetes)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _pickDate,
                child: Text(friendlyDate(date, today), textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final t = await pickTime(context, time);
                  if (t != null) setState(() => time = t);
                },
                child: Text(t12(time)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Note', hintText: 'Carry sugar log and reports'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) return setState(() => error = 'Say what the visit is for.');
            store.saveVisit(id: editing?.id, who: who, title: t, date: date, time: time, note: _note.text.trim());
            Navigator.pop(context);
            toast(context, editing == null ? 'Visit added. Open "Doctor summary" before you go.' : 'Visit saved.');
          },
          child: const Text('Save visit'),
        ),
        if (editing != null) ...[
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () {
              store.deleteVisit(editing.id);
              Navigator.pop(context);
              toast(context, 'Visit removed.');
            },
            child: const Text('Delete visit'),
          ),
        ],
      ],
    );
  }
}
