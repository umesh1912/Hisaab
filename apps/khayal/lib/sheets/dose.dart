import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showDoseSheet(BuildContext context, {required String date, required int medId, required String time}) =>
    showAppSheet(context, (_) => _DoseSheet(date: date, medId: medId, time: time));

class _DoseSheet extends StatefulWidget {
  const _DoseSheet({required this.date, required this.medId, required this.time});
  final String date;
  final int medId;
  final String time;

  @override
  State<_DoseSheet> createState() => _DoseSheetState();
}

class _DoseSheetState extends State<_DoseSheet> {
  String? choice; // taken | skipped
  String at = '09:00';
  String reason = skipReasons.first;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final m = d.med(widget.medId);
    final tt = Theme.of(context).textTheme;
    if (m == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This medicine was stopped.'));
    }
    final now = DateTime.now();
    final name = d.nameOf(m.who);
    final log = d.logs[doseKey(widget.date, m.id, widget.time)];
    final status = doseStatus(log, widget.date, widget.time, now);
    if (choice == null) {
      choice = log?.s ?? 'taken';
      at = (log != null && log.s == 'taken') ? log.at : nowHhmm(now);
      if (log != null && skipReasons.contains(log.reason)) reason = log.reason;
    }
    final intro = log != null
        ? 'Recorded as ${log.s} at ${t12(log.at)}. You can correct it.'
        : status == 'up'
            ? 'This dose is later today. Record it now if $name has taken it early.'
            : "$name hasn't confirmed this dose. If you've checked with $name, record what happened.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('${m.name} · ${t12(widget.time)}'),
        Text(intro),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'taken', label: Text('Taken'), icon: Icon(Icons.check)),
            ButtonSegment(value: 'skipped', label: Text('Skipped'), icon: Icon(Icons.block)),
          ],
          selected: {choice!},
          onSelectionChanged: (s) => setState(() => choice = s.first),
        ),
        const SizedBox(height: 16),
        if (choice == 'taken')
          OutlinedButton.icon(
            onPressed: () async {
              final t = await pickTime(context, at);
              if (t != null) setState(() => at = t);
            },
            icon: const Icon(Icons.schedule),
            label: Text('Taken at ${t12(at)}'),
          )
        else ...[
          Text('Reason', style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final r in skipReasons)
                ChoiceChip(label: Text(r), selected: reason == r, onSelected: (_) => setState(() => reason = r)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const InfoNote("Don't give a double dose to catch up unless the doctor has said it's safe."),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final taken = choice == 'taken';
            store.markDose(widget.date, m.id, widget.time, choice!, taken ? at : nowHhmm(DateTime.now()),
                reason: taken ? '' : reason);
            Navigator.pop(context);
            toast(context, taken ? 'Marked as taken. Stock updated.' : 'Marked as skipped. It shows in the doctor summary.');
          },
          child: const Text('Save'),
        ),
        if (log != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              store.clearDose(widget.date, m.id, widget.time);
              Navigator.pop(context);
              toast(context, 'Record cleared.');
            },
            child: const Text('Clear this record'),
          ),
        ],
      ],
    );
  }
}
