import 'dart:async';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// A timed test with SSC CGL marking. The timer is cancelled on dispose.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key, required this.questions, required this.seconds, required this.name, required this.kind});
  final List<Question> questions;
  final int seconds;
  final String name;
  final String kind; // 'full' | 'sectional'

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final answers = <int, int>{};
  final sure = <int, int>{};
  final marked = <int>{};
  late final DateTime started;
  late final DateTime endAt;
  Timer? _timer;
  int i = 0;
  int left = 0;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    started = DateTime.now();
    endAt = started.add(Duration(seconds: widget.seconds));
    left = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || submitted) return;
    final l = endAt.difference(DateTime.now()).inSeconds;
    if (l <= 0) {
      _submit(auto: true);
    } else {
      setState(() => left = l);
    }
  }

  void _submit({bool auto = false}) {
    if (submitted) return;
    submitted = true;
    _timer?.cancel();
    final used = DateTime.now().difference(started).inSeconds;
    final r = StoreScope.read(context).saveTest(
      name: widget.name,
      kind: widget.kind,
      questions: widget.questions,
      answers: answers,
      sure: sure,
      seconds: used > widget.seconds ? widget.seconds : used,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => ResultScreen(mockId: r.id)));
    if (auto) toast(context, "Time's up. Your test was submitted.");
  }

  Future<void> _confirmSubmit() async {
    final unanswered = widget.questions.length - answers.length;
    final ok = await confirm(
      context,
      title: 'Submit the test?',
      body: unanswered == 0
          ? 'You have answered every question.'
          : '$unanswered question${unanswered == 1 ? ' is' : 's are'} unanswered. Skipped questions score 0.',
      action: 'Submit',
    );
    if (ok && mounted) _submit();
  }

  Future<void> _confirmQuit() async {
    final ok = await confirm(
      context,
      title: 'Leave the test?',
      body: 'Your answers will not be saved.',
      action: 'Leave',
      danger: true,
    );
    if (ok && mounted) {
      submitted = true;
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  void _palette() {
    showAppSheet<void>(context, (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('All questions', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${answers.length} answered · ${marked.length} marked for review · ${widget.questions.length - answers.length} left',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var k = 0; k < widget.questions.length; k++)
                Builder(builder: (ctx2) {
                  final q = widget.questions[k];
                  final isAnswered = answers.containsKey(q.id);
                  final isMarked = marked.contains(q.id);
                  final bg = isMarked ? cs.tertiaryContainer : (isAnswered ? cs.primary : cs.surfaceContainerHighest);
                  final fg = isMarked ? cs.onTertiaryContainer : (isAnswered ? cs.onPrimary : cs.onSurface);
                  return Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => i = k);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: k == i
                            ? BoxDecoration(border: Border.all(color: cs.onSurface, width: 2), borderRadius: BorderRadius.circular(10))
                            : null,
                        child: Text('${k + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmSubmit();
            },
            child: const Text('Submit test'),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = widget.questions[i];
    final hindi = store.hindi && q.hasHindi;
    final lastQ = i == widget.questions.length - 1;
    final low = left <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Leave test', icon: const Icon(Icons.close), onPressed: _confirmQuit),
          title: Text(widget.name, overflow: TextOverflow.ellipsis),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: low ? cs.errorContainer : cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: low ? cs.onErrorContainer : cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    fmtClock(left),
                    style: TextStyle(fontWeight: FontWeight.w800, color: low ? cs.onErrorContainer : cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            IconButton(tooltip: 'All questions', icon: const Icon(Icons.grid_view), onPressed: _palette),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Question ${i + 1} of ${widget.questions.length}',
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${sectionShort[q.sec]} · +2 / −0.5',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(q.text(hindi), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 14),
            for (var k = 0; k < q.options(hindi).length; k++)
              OptionTile(
                index: k,
                text: q.options(hindi)[k],
                state: answers[q.id] == k ? OptState.selected : OptState.idle,
                onTap: () => setState(() => answers[q.id] = k),
              ),
            const SizedBox(height: 6),
            Text('How sure are you? (optional, helps find confident mistakes)',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (v, label) in const [(0, 'Guessing'), (1, 'Fairly sure'), (2, 'Certain')])
                  ChoiceChip(
                    label: Text(label),
                    selected: sure[q.id] == v,
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        sure[q.id] = v;
                      } else {
                        sure.remove(q.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: answers.containsKey(q.id) ? () => setState(() => answers.remove(q.id)) : null,
                  icon: const Icon(Icons.backspace_outlined, size: 18),
                  label: const Text('Clear response'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => marked.contains(q.id) ? marked.remove(q.id) : marked.add(q.id)),
                  icon: Icon(marked.contains(q.id) ? Icons.flag : Icons.outlined_flag, size: 18),
                  label: Text(marked.contains(q.id) ? 'Marked for review' : 'Mark for review'),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: i == 0 ? null : () => setState(() => i--),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: lastQ ? _confirmSubmit : () => setState(() => i++),
                    child: Text(lastQ ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Score, section breakdown and answer review for a finished or hand-entered test.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.mockId});
  final int mockId;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String filter = 'wrong'; // 'all' | 'wrong' | 'skipped'

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final m = store.mock(widget.mockId);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tones(context);

    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const EmptyState(icon: Icons.delete_outline, title: 'Deleted', body: 'This test is no longer saved.'),
      );
    }

    final qs = [for (final id in m.qids) store.question(id)].whereType<Question>().toList();
    final shown = qs.where((q) {
      final a = m.answers[q.id];
      if (filter == 'wrong') return a != null && a != q.a;
      if (filter == 'skipped') return a == null;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(m.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirm(context,
                  title: 'Delete ${m.name}?', body: 'Its score will be removed from your progress.', action: 'Delete', danger: true);
              if (ok && context.mounted) {
                Navigator.of(context).pop();
                store.deleteMock(m.id);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                FittedBox(
                  child: Text(
                    '${fmtMarks(m.score)} / ${fmtMarks(m.maxMarks)}',
                    style: TextStyle(color: cs.onPrimary, fontSize: 40, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${longDate(m.date)}${m.seconds > 0 ? ' · ${fmtMinutes(m.seconds)}' : ''}',
                  style: TextStyle(color: cs.onPrimary),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final sec in sectionKeys)
                    if (m.sections[sec] != null)
                      BarRow(
                        label: '${secName(sec)} · ${m.sections[sec]!.right} right, ${m.sections[sec]!.wrong} wrong',
                        value: '${fmtMarks(m.sections[sec]!.marks)} / ${fmtMarks(m.sections[sec]!.maxMarks)}',
                        fraction: m.sections[sec]!.maxMarks == 0 ? 0 : m.sections[sec]!.marks / m.sections[sec]!.maxMarks,
                      ),
                  const Divider(),
                  _Line('Right answers', '${m.right} (+${fmtMarks(m.right * markRight)})'),
                  _Line('Wrong answers', '${m.wrong} (−${fmtMarks(m.negative)})', color: t.bad),
                  _Line('Skipped', '${m.skipped}'),
                  _Line('Wrong but felt certain', '${m.confidentWrong}', color: t.bad),
                ],
              ),
            ),
          ),
          if (m.reviewable && m.wrong > 0)
            InfoNote(child: Text('The ${m.wrong} questions you got wrong are in tomorrow\'s revision.')),
          if (m.reviewable) ...[
            SectionTitle('Review answers', trailing: Text('${shown.length}', style: TextStyle(color: cs.onSurfaceVariant))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final (k, label) in const [('wrong', 'Wrong'), ('skipped', 'Skipped'), ('all', 'All')])
                    ChoiceChip(label: Text(label), selected: filter == k, onSelected: (_) => setState(() => filter = k)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Nothing here.', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            for (final q in shown) _ReviewTile(q: q, picked: m.answers[q.id], sure: m.sure[q.id], hindi: store.hindi && q.hasHindi),
          ],
          if (!m.reviewable)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('This score was entered by hand, so there are no answers to review.', style: tt.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.q, required this.picked, required this.sure, required this.hindi});
  final Question q;
  final int? picked;
  final int? sure;
  final bool hindi;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = tones(context);
    final p = picked;
    final ok = p == q.a;
    final icon = p == null ? Icons.remove_circle_outline : (ok ? Icons.check_circle : Icons.cancel);
    final color = p == null ? cs.outline : (ok ? t.good : t.bad);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, color: color),
        title: Text(q.text(hindi), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${sectionShort[q.sec]} · ${q.topic}${p != null && !ok && sure == 2 ? ' · felt certain' : ''}',
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (var k = 0; k < q.options(hindi).length; k++)
            OptionTile(
              index: k,
              text: q.options(hindi)[k],
              state: k == q.a ? OptState.right : (k == p ? OptState.wrong : OptState.idle),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Text(q.explanation(hindi), style: TextStyle(color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
