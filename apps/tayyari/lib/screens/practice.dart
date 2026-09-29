import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/test_setup.dart';
import '../store.dart';
import '../ui.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key, required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final s = store.session;
    if (s != null) return _SessionView(session: s, onGo: onGo);
    return _PracticeHome(onGo: onGo);
  }
}

class _PracticeHome extends StatelessWidget {
  const _PracticeHome({required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final due = store.due;
    final today = todayIso();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${due.length} question${due.length == 1 ? '' : 's'} due for revision',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Mixed from all sections. Say how sure you are, answer, then rate how easy it felt. '
                  'Tayyari picks when to show it again.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('start-revision'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: due.isEmpty ? null : () => store.startSession(due, 'due', 'Revision'),
                  child: Text(due.isEmpty ? 'All caught up' : 'Start revision'),
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Practise a section'),
        Card(
          child: Column(
            children: [
              for (final sec in sectionKeys)
                ListTile(
                  key: Key('practise-$sec'),
                  leading: IconBox(sectionIcons[sec] ?? Icons.quiz_outlined),
                  title: Text(secName(sec)),
                  subtitle: Text(
                    '${store.questionsIn(sec).length} questions · mastery ${sectionMastery(d.stats, sec) == null ? 'not started' : '${sectionMastery(d.stats, sec)}%'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final picked = pickPractice(store.questionsIn(sec), d.cards, today, 10);
                    store.startSession(picked.map((q) => q.id).toList(), 'section', secName(sec));
                  },
                ),
            ],
          ),
        ),
        const SectionTitle('Timed tests'),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('test-full'),
                leading: const IconBox(Icons.assignment_outlined),
                title: const Text('Full mock'),
                subtitle: const Text('Up to 100 questions · 60 min · +2 / −0.5'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showTestSetup(context, sec: 'full'),
              ),
              for (final sec in sectionKeys)
                ListTile(
                  key: Key('test-$sec'),
                  leading: const IconBox(Icons.timer_outlined),
                  title: Text('Sectional: ${secName(sec)}'),
                  subtitle: const Text('25 questions · 15 or 35 min'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showTestSetup(context, sec: sec),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionView extends StatelessWidget {
  const _SessionView({required this.session, required this.onGo});
  final PracticeSession session;
  final void Function(int tab) onGo;

  Future<void> _grade(BuildContext context, int g) async {
    final store = StoreScope.read(context);
    final summary = store.grade(g);
    if (summary == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DoneDialog(summary: summary),
    );
    if (summary.kind == 'due' && context.mounted) onGo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tones(context);
    final s = session;
    final q = store.question(s.current);
    final hindi = store.hindi && (q?.hasHindi ?? false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                q == null ? s.title : '${secName(q.sec)} · ${q.topic}',
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${s.i + 1} / ${s.ids.length}', style: tt.labelLarge),
            const SizedBox(width: 4),
            TextButton(
              key: const Key('end-session'),
              onPressed: () => StoreScope.read(context).endSession(),
              child: const Text('End'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < s.ids.length; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: i < s.results.length
                        ? (s.results[i] ? t.good : t.bad)
                        : (i == s.i ? cs.primary : cs.outlineVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (q == null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('This question was deleted.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final st = StoreScope.read(context);
                      st.answer(0);
                      _grade(context, 3);
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.text(hindi), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 14),
                  if (!s.answered) ...[
                    Text('How sure are you before answering?', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final (i, label) in const [(0, 'Guessing'), (1, 'Fairly sure'), (2, 'Certain')])
                          ChoiceChip(
                            key: Key('sure-$i'),
                            label: Text(label),
                            selected: s.sure == i,
                            onSelected: (_) => StoreScope.read(context).setSure(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (var i = 0; i < q.options(hindi).length; i++)
                    OptionTile(
                      key: Key('opt-$i'),
                      index: i,
                      text: q.options(hindi)[i],
                      state: !s.answered
                          ? OptState.idle
                          : (i == q.a ? OptState.right : (i == s.picked ? OptState.wrong : OptState.idle)),
                      onTap: s.answered ? null : () => StoreScope.read(context).answer(i),
                    ),
                  if (s.answered) ..._feedback(context, q, hindi),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _feedback(BuildContext context, Question q, bool hindi) {
    final store = StoreScope.of(context);
    final s = session;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tones(context);
    final correct = s.picked == q.a;
    final card = store.data!.cards[q.id] ?? CardState(due: todayIso());
    return [
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              correct ? (hindi ? 'सही!' : 'Correct.') : (hindi ? 'गलत।' : 'Not quite.'),
              style: TextStyle(fontWeight: FontWeight.w800, color: correct ? t.good : t.bad),
            ),
            const SizedBox(height: 4),
            Text(q.explanation(hindi), style: TextStyle(color: cs.onSurface)),
            if (!correct && s.sure == 2) ...[
              const SizedBox(height: 8),
              Text(
                'Watch out: you were certain but wrong. In the exam this costs ${fmtMarks(markWrong)} marks, '
                'and it points to an idea worth fixing. It comes back tomorrow.',
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ],
          ],
        ),
      ),
      if (q.src != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: accentYellow, width: 3))),
          child: Text('From your notes: ${q.src}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
      const SizedBox(height: 14),
      Text('When should you see this again?', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final (g, label) in const [(1, 'Again'), (2, 'Hard'), (3, 'Good'), (4, 'Easy')])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == 4 ? 0 : 6),
                child: Material(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: Key('grade-$g'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _grade(context, g),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: g == 1 ? t.bad : (g == 4 ? t.good : cs.onSurface),
                            ),
                          ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              intervalLabel(schedule(card, g, correct).ivl),
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ];
  }
}

class _DoneDialog extends StatelessWidget {
  const _DoneDialog({required this.summary});
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(summary.kind == 'due' ? 'Revision done' : 'Practice done'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('${summary.correct}/${summary.total}',
                    style: TextStyle(color: cs.onPrimary, fontSize: 40, fontWeight: FontWeight.w800)),
                Text('CORRECT', style: TextStyle(color: cs.onPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Questions you got wrong come back tomorrow. The rest are spaced further apart each time you remember them.'
            '${summary.confidentMisses > 0 ? ' ${summary.confidentMisses} were confident mistakes: they come first tomorrow.' : ''}',
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(summary.kind == 'due' ? 'Back to today' : 'Done'),
        ),
      ],
    );
  }
}
