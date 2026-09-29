import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add a service reminder (optionally for [itemId]) or edit the one with [reminderId].
Future<void> showReminderForm(BuildContext context, {int? reminderId, int? itemId}) =>
    showAppSheet(context, (_) => _ReminderForm(reminderId: reminderId, itemId: itemId));

class _ReminderForm extends StatefulWidget {
  const _ReminderForm({this.reminderId, this.itemId});
  final int? reminderId;
  final int? itemId;

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  final _title = TextEditingController();
  String date = addMonthsIso(todayIso(), 1);
  int? itemId;
  int every = 0;
  bool loaded = false;
  String? error;

  static const _presets = ['Clean AC filters', 'Service ACs before summer', 'Change RO filter', 'Descale the geyser', 'Clean chimney filter'];

  @override
  void initState() {
    super.initState();
    itemId = widget.itemId;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox.shrink();
    final editing = widget.reminderId != null;
    final r = editing ? d.reminder(widget.reminderId!) : null;
    if (editing && r == null) return const SizedBox(height: 120, child: Center(child: Text('This reminder was removed.')));
    if (!loaded && r != null) {
      _title.text = r.title;
      date = r.date;
      itemId = r.itemId;
      every = r.everyMonths;
    }
    loaded = true;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final validItem = itemId != null && d.item(itemId!) != null ? itemId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? 'Service reminder' : 'Add a service reminder', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What to do'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [for (final p in _presets) ActionChip(label: Text(p), onPressed: () => setState(() => _title.text = p))],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: validItem,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Item'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('No particular item')),
            for (final i in d.items)
              DropdownMenuItem<int?>(value: i.id, child: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => itemId = v),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final v = await pickDate(context, date);
            if (v != null) setState(() => date = v);
          },
          icon: const Icon(Icons.event),
          label: Text('On ${longDate(date)}'),
        ),
        const SizedBox(height: 12),
        Text('Repeat', style: tt.titleSmall),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Once')),
            ButtonSegment(value: 3, label: Text('3 mo')),
            ButtonSegment(value: 6, label: Text('6 mo')),
            ButtonSegment(value: 12, label: Text('Yearly')),
          ],
          selected: {every},
          onSelectionChanged: (s) => setState(() => every = s.first),
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
            final t = _title.text.trim();
            if (t.isEmpty) return setState(() => error = 'Say what needs doing.');
            if (r != null) {
              store.updateReminder(r.id, title: t, date: date, itemId: validItem, everyMonths: every);
            } else {
              store.addReminder(title: t, date: date, itemId: validItem, everyMonths: every);
            }
            Navigator.pop(context);
            toast(context, 'Reminder saved for ${longDate(date)}.');
          },
          child: Text(editing ? 'Save changes' : 'Save reminder'),
        ),
        if (r != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final next = store.doneReminder(r.id);
                  Navigator.pop(context);
                  toast(context, next == null ? 'Done. Reminder cleared.' : 'Done. Next one on ${longDate(next)}.');
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Mark done'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: cs.error),
                onPressed: () {
                  store.deleteReminder(r.id);
                  Navigator.pop(context);
                  toast(context, 'Reminder deleted.');
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
