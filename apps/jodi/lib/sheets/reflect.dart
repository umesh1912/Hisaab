import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

const reflectQuestions = [
  'What went well this week?',
  'What got in the way?',
  'One small change for next week?',
];

Future<void> showReflect(BuildContext context) => showAppSheet(context, (_) => const ReflectSheet());

class ReflectSheet extends StatefulWidget {
  const ReflectSheet({super.key});

  @override
  State<ReflectSheet> createState() => _ReflectSheetState();
}

class _ReflectSheetState extends State<ReflectSheet> {
  final _answers = [TextEditingController(), TextEditingController(), TextEditingController()];
  bool editing = false;
  String? error;

  @override
  void dispose() {
    for (final c in _answers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEdit(List<String> current) {
    for (var i = 0; i < _answers.length; i++) {
      _answers[i].text = i < current.length ? current[i] : '';
    }
    setState(() => editing = true);
  }

  void _save() {
    final a = _answers.map((c) => c.text.trim()).toList();
    if (a.any((x) => x.isEmpty)) return setState(() => error = 'Answer all three. A few words is enough.');
    StoreScope.read(context).saveReflection(a);
    setState(() {
      editing = false;
      error = null;
    });
    toast(context, 'Saved. You can see each other’s answers now.');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final week = weekStartIso(todayIso());
    final mine = store.reflection(me, week);
    final theirs = store.reflection(them, week);

    Widget answers(String who, List<String> list) => Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: who == me ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(who: who, name: d.nameOf(who), size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(who == me ? 'You' : d.partnerName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                ],
              ),
              for (var i = 0; i < reflectQuestions.length && i < list.length; i++) ...[
                const SizedBox(height: 8),
                Text(reflectQuestions[i], style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                Text(list[i], style: tt.bodyMedium),
              ],
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Sunday check-in', sub: 'Week of ${shortDate(week)}. Takes about two minutes.'),
        if (mine == null || editing) ...[
          for (var i = 0; i < reflectQuestions.length; i++) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: cs.primary,
                  child: Text('${i + 1}', style: TextStyle(color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(reflectQuestions[i], style: tt.titleSmall)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answers[i],
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 14),
          ],
          Text(
            theirs == null
                ? 'You both see the answers once you have both answered.'
                : '${d.partnerName} has answered. Save yours to see them.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: TextStyle(color: cs.error)),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Save answers'),
          ),
        ] else ...[
          answers(me, mine.answers),
          if (theirs != null)
            answers(them, theirs.answers)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${d.partnerName} hasn’t answered yet.', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _startEdit(mine.answers),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit mine'),
              ),
              OutlinedButton.icon(
                onPressed: () => shareOnWhatsApp(
                  context,
                  'My Jodi Sunday check-in:\n'
                  '${[for (var i = 0; i < reflectQuestions.length && i < mine.answers.length; i++) '${reflectQuestions[i]} ${mine.answers[i]}'].join('\n')}\n'
                  'Your turn!',
                ),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send on WhatsApp'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
