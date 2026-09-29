import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'add_med.dart';

Future<void> showMedDetail(BuildContext context, int id) async {
  final r = await showAppSheet<String>(context, (_) => _MedDetail(id: id));
  if (r == 'edit' && context.mounted) showMedForm(context, medId: id);
}

class _MedDetail extends StatefulWidget {
  const _MedDetail({required this.id});
  final int id;

  @override
  State<_MedDetail> createState() => _MedDetailState();
}

class _MedDetailState extends State<_MedDetail> {
  bool asking = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final m = d.med(widget.id);
    final cs = Theme.of(context).colorScheme;
    if (m == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This medicine was stopped.'));
    }
    final who = d.nameOf(m.who);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(m.title),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              InfoLine('For', '$who · ${m.purpose}'),
              InfoLine('Dose', '${m.per} ${m.form}'),
              InfoLine('Times', m.times.map(t12).join(', ')),
              InfoLine('How', foodText(m.food)),
              InfoLine('Stock', '${m.stock} left · ${daysLeft(m)} days'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            PillDot(m.color, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'The pill colour is shown on $who\'s screen with every dose, so the right strip gets picked.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'edit'),
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  store.refill(m.id);
                  toast(context, '${m.name} refilled. Enough for ${daysLeft(m)} days.');
                },
                child: const Text('Refilled'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!asking)
          TextButton(
            onPressed: () => setState(() => asking = true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Stop this medicine'),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Stop this medicine?', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onErrorContainer)),
                const SizedBox(height: 4),
                Text(
                  'Only do this if the doctor has stopped it. Past records stay.',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => asking = false),
                        child: const Text('Keep it'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                        onPressed: () {
                          final name = m.name;
                          store.stopMed(m.id);
                          Navigator.pop(context);
                          toast(context, '$name stopped. It no longer shows on Today.');
                        },
                        child: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
