import 'package:flutter/material.dart';

import '../logic.dart';
import '../screens/test.dart';
import '../ui.dart';

/// Picks a section (or full mock) and pace, then starts a timed test.
Future<void> showTestSetup(BuildContext context, {String sec = 'quant'}) =>
    showAppSheet(context, (_) => _TestSetup(initial: sec, outer: context));

class _TestSetup extends StatefulWidget {
  const _TestSetup({required this.initial, required this.outer});
  final String initial;
  final BuildContext outer;

  @override
  State<_TestSetup> createState() => _TestSetupState();
}

class _TestSetupState extends State<_TestSetup> {
  late String sec = widget.initial;
  bool relaxed = true;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = sec == 'full'
        ? sectionKeys.fold<int>(0, (a, s) => a + _cap(store.questionsIn(s).length))
        : _cap(store.questionsIn(sec).length);
    final full = sec == 'full';
    final perQ = full || !relaxed ? examSecondsPerQuestion : relaxedSecondsPerQuestion;
    final seconds = count * perQ;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Timed test', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text('What to practise', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(label: const Text('Full mock'), selected: full, onSelected: (_) => setState(() => sec = 'full')),
            for (final s in sectionKeys)
              ChoiceChip(label: Text(sectionShort[s] ?? s), selected: sec == s, onSelected: (_) => setState(() => sec = s)),
          ],
        ),
        if (!full) ...[
          const SizedBox(height: 14),
          Text('Pace', style: tt.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text('Relaxed · $relaxedSecondsPerQuestion s a question'),
                selected: relaxed,
                onSelected: (_) => setState(() => relaxed = true),
              ),
              ChoiceChip(
                label: Text('Exam pace · $examSecondsPerQuestion s'),
                selected: !relaxed,
                onSelected: (_) => setState(() => relaxed = false),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count questions · ${fmtMinutes(seconds)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '+${fmtMarks(markRight)} for a right answer, −${fmtMarks(markWrong)} for a wrong one, 0 if skipped. '
                'The test submits itself when time runs out.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: a blind guess among four options gains ${guessValue(4).toStringAsFixed(3)} marks on average, and more once you rule an option out. '
          'Skip only when you have no idea and no time; watch out for answers you feel sure of without checking.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('start-test'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: count == 0
              ? null
              : () {
                  final qs = store.buildTest(sec);
                  final name = full
                      ? 'Full mock ${store.data!.mocks.where((m) => m.kind == 'full').length + 1}'
                      : '${sectionShort[sec]} sectional';
                  Navigator.pop(context);
                  Navigator.of(widget.outer).push(MaterialPageRoute<void>(
                    builder: (_) => TestScreen(
                      questions: qs,
                      seconds: qs.length * perQ,
                      name: name,
                      kind: full ? 'full' : 'sectional',
                    ),
                  ));
                },
          child: const Text('Start test'),
        ),
      ],
    );
  }
}

int _cap(int n) => n > questionsPerSection ? questionsPerSection : n;
