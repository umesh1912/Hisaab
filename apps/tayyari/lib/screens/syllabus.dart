import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/topic_plan.dart';
import '../ui.dart';

class SyllabusScreen extends StatelessWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'Mastery comes from your answers over time, weighted towards recent ones. '
            'Red topics cost you the most marks. Tap a topic to practise it.',
            style: tt.bodyMedium,
          ),
        ),
        for (final sec in sectionKeys)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(builder: (context) {
                final p = sectionMastery(d.stats, sec);
                final color = p == null ? cs.outline : masteryColor(context, p);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(secName(sec), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text(p == null ? 'Not started' : '$p%',
                            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (p ?? 0) / 100,
                        minHeight: 8,
                        color: color,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in topicMasteries(d.stats, sec)) _TopicChip(t: t),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: Key('plan-$sec'),
                      onPressed: () => showTopicPlan(context, sec),
                      icon: const Icon(Icons.event_note_outlined, size: 18),
                      label: Text('Plan ${sectionShort[sec]}'),
                    ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.t});
  final TopicMastery t;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final p = t.percent;
    final bg = t.started ? masterySoft(context, p) : cs.surfaceContainerHighest;
    final fg = t.started && p < 55 ? tones(context).bad : cs.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final qs = store.questionsIn(t.sec, topic: t.topic);
          if (qs.isEmpty) {
            toast(context, 'No questions for ${t.topic} yet. Add some from your notes.');
            return;
          }
          final picked = pickPractice(qs, store.data!.cards, todayIso(), 10);
          store.startSession(picked.map((q) => q.id).toList(), 'topic', t.topic);
          toast(context, '${picked.length} ${t.topic} questions are ready in Practice.');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            t.started ? '${t.topic} $p%' : '${t.topic} · new',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}
