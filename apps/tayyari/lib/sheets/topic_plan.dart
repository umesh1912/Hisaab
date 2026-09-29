import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// This week's focus for a section, weakest topic first.
Future<void> showTopicPlan(BuildContext context, String sec) => showAppSheet(context, (_) => _TopicPlan(sec: sec));

/// Today's learning block: study the topic, then practise it.
Future<void> showLearnSheet(BuildContext context, String sec, String topic, void Function(int tab) onGo) =>
    showAppSheet(context, (_) => _LearnSheet(sec: sec, topic: topic, onGo: onGo, outer: context));

class _TopicPlan extends StatelessWidget {
  const _TopicPlan({required this.sec});
  final String sec;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final topics = weakestTopics(d.stats, sec);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Plan for ${secName(sec)}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text("This week's focus, weakest first. Each block is 25 minutes of learning, then 10 questions.", style: tt.bodyMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < topics.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 52,
              child: Center(
                child: topics[i].started
                    ? Pill('${topics[i].percent}%',
                        bg: masterySoft(context, topics[i].percent), fg: masteryColor(context, topics[i].percent))
                    : Pill('new', bg: Theme.of(context).colorScheme.surfaceContainerHighest, fg: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            title: Text(topics[i].topic),
            subtitle: Text(
              '${i == 0 ? 'Today' : dayName(addDaysIso(today, i))} · '
              '${topics[i].percent < 55 ? 'Re-read your notes + 20 questions' : '10 questions + shortcuts'}',
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            store.setWeekPlan(sec);
            Navigator.pop(context);
            toast(context, "Added. Today's block is on your plan.");
          },
          child: const Text('Add to my week'),
        ),
      ],
    );
  }
}

class _LearnSheet extends StatelessWidget {
  const _LearnSheet({required this.sec, required this.topic, required this.onGo, required this.outer});
  final String sec;
  final String topic;
  final void Function(int tab) onGo;
  final BuildContext outer;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = d.stats[topicKey(sec, topic)];
    final m = pct(mastery(s));
    final qs = store.questionsIn(sec, topic: topic);
    final notes = d.notes.where((n) => n.sec == sec && n.topic == topic).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Learn: $topic', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '${secName(sec)} · ${(s?.n ?? 0) == 0 ? 'not practised yet' : 'mastery $m%'} · ${qs.length} questions in your bank',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        const _Step(n: 1, text: 'Spend about 25 minutes on the topic: your class notes, book chapter or a lecture.'),
        const _Step(n: 2, text: 'Then answer up to 10 questions without looking. Rate each one so it comes back at the right time.'),
        const _Step(n: 3, text: 'Anything you got wrong returns tomorrow.'),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Your notes on this: ${notes.map((n) => n.name).join(', ')}', style: tt.bodySmall),
        ],
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: qs.isEmpty
              ? null
              : () {
                  final picked = pickPractice(qs, d.cards, todayIso(), 10);
                  store.startSession(picked.map((q) => q.id).toList(), 'topic', topic);
                  Navigator.pop(context);
                  onGo(1);
                },
          child: Text(qs.isEmpty ? 'No questions for this topic yet' : 'Practise ${qs.length < 10 ? qs.length : 10} questions'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () {
            store.markLearnDone();
            Navigator.pop(context);
          },
          child: const Text('Mark as done'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showTopicPlan(outer, sec);
          },
          child: Text('See the ${sectionShort[sec]} week plan'),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: cs.primaryContainer,
            child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
