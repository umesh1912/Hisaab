import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'test.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tones(context);
    final all = store.mocksByDate;
    final full = all.where((m) => m.isFull).toList();
    final shown = full.length > 8 ? full.sublist(full.length - 8) : full;
    final last = store.lastFull;
    final today = todayIso();
    final days = [for (var i = 27; i >= 0; i--) addDaysIso(today, -i)];
    final studiedThisWeek = days.sublist(21).where((x) => (d.minutes[x] ?? 0) > 0).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Mock scores (out of 200)', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    if (shown.length >= 2)
                      Builder(builder: (context) {
                        final diff = shown.last.score - shown[shown.length - 2].score;
                        return Pill('${diff >= 0 ? '+' : ''}${fmtMarks(diff)} last',
                            bg: diff >= 0 ? t.goodSoft : t.badSoft, fg: diff >= 0 ? t.good : t.bad);
                      }),
                  ],
                ),
                const SizedBox(height: 12),
                if (shown.length < 2)
                  Text('Take or add two full mocks to see your trend.', style: TextStyle(color: cs.onSurfaceVariant))
                else
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _TrendPainter(
                        scores: [for (final m in shown) m.score],
                        labels: [for (final m in shown) _short(m.name)],
                        target: d.profile.target.toDouble(),
                        line: cs.primary,
                        grid: cs.outlineVariant,
                        text: cs.onSurfaceVariant,
                        good: t.good,
                        surface: cs.surfaceContainerLow,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (last != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${last.name}: ${fmtMarks(last.score)} / 200', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final sec in sectionKeys)
                    if (last.sections[sec] != null)
                      BarRow(
                        label: secName(sec),
                        value: '${fmtMarks(last.sections[sec]!.marks)} / ${fmtMarks(last.sections[sec]!.maxMarks)}',
                        fraction: last.sections[sec]!.maxMarks == 0 ? 0 : last.sections[sec]!.marks / last.sections[sec]!.maxMarks,
                        color: last.sections[sec]!.marks < 35 ? t.bad : cs.primary,
                      ),
                  const Divider(),
                  _Stat('Wrong answers', '${last.wrong} (−${fmtMarks(last.negative)} marks)'),
                  _Stat('Skipped', '${last.skipped}'),
                  _Stat('Wrong but felt sure', '${last.confidentWrong} of ${last.wrong}', color: t.bad),
                  const SizedBox(height: 8),
                  Text(
                    'SSC CGL Tier 1 gives 2 marks for a right answer and takes 0.5 for a wrong one. '
                    'With four options, even a blind guess gains marks on average, so the bigger problem is confident mistakes. '
                    'Wrong answers from tests taken in the app go straight into your revision.',
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Negative marking, honestly', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Average marks from answering when you are unsure (+2 right, −0.5 wrong):', style: tt.bodySmall),
                const SizedBox(height: 8),
                _Stat('Pure guess, 4 options left', '+${guessValue(4).toStringAsFixed(3)}'),
                _Stat('Ruled out 1 option', '+${guessValue(3).toStringAsFixed(2)}'),
                _Stat('Ruled out 2 options', '+${guessValue(2).toStringAsFixed(2)}'),
                _Stat('Skipping', '0'),
                const SizedBox(height: 8),
                Text(
                  'Guessing is not what costs you. Eliminate what you can, then answer. '
                  'The marks you can win back are the ones lost to answers you were sure of but got wrong.',
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Study days, last 4 weeks', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (var row = 0; row < 2; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        for (var i = row * 14; i < row * 14 + 14; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      cs.surfaceContainerHighest,
                                      cs.primary,
                                      heatLevel(d.minutes[days[i]] ?? 0) / 4,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text('Darker = more hours. Aim for 5 of 7 days. This week: $studiedThisWeek of 7.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SectionTitle('Tests and mocks'),
        if (all.isEmpty)
          const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No tests yet',
            body: 'Take a timed test from Practice, or add the score of a mock you took elsewhere.',
          )
        else
          for (final m in all.reversed)
            Card(
              child: ListTile(
                leading: IconBox(m.kind == 'manual' ? Icons.edit_note : Icons.timer_outlined),
                title: Text(m.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${shortDate(m.date)} · ${m.kind == 'manual' ? 'entered by hand' : '${m.questions} questions'} · ${m.wrong} wrong'),
                trailing: Text('${fmtMarks(m.score)}/${fmtMarks(m.maxMarks)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ResultScreen(mockId: m.id))),
              ),
            ),
      ],
    );
  }
}

String _short(String name) => name.startsWith('Mock ') ? 'M${name.substring(5)}' : (name.length > 4 ? name.substring(0, 4) : name);

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});
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

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.scores,
    required this.labels,
    required this.target,
    required this.line,
    required this.grid,
    required this.text,
    required this.good,
    required this.surface,
  });

  final List<double> scores;
  final List<String> labels;
  final double target;
  final Color line;
  final Color grid;
  final Color text;
  final Color good;
  final Color surface;

  void _label(Canvas canvas, String s, Offset at, Color color, {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx - tp.width / 2;
    if (align == TextAlign.right) dx = at.dx - tp.width;
    if (align == TextAlign.left) dx = at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;
    const left = 30.0, right = 10.0, top = 14.0, bottom = 22.0;
    var lo = [...scores, target].reduce((a, b) => a < b ? a : b);
    var hi = [...scores, target].reduce((a, b) => a > b ? a : b);
    lo = ((lo - 10) / 10).floorToDouble() * 10;
    hi = ((hi + 10) / 10).ceilToDouble() * 10;
    if (lo < 0) lo = 0;
    if (hi > 200) hi = 200;
    if (hi - lo < 20) hi = lo + 20;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    double x(int i) => left + i * w / (scores.length - 1);
    double y(double v) => top + (hi - v) / (hi - lo) * h;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final step = ((hi - lo) / 3 / 10).ceilToDouble() * 10;
    for (var v = lo; v <= hi; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width - right, y(v)), gridPaint);
      _label(canvas, fmtMarks(v), Offset(left - 4, y(v)), text, align: TextAlign.right);
    }

    // Target line, dashed.
    final tp = Paint()
      ..color = good
      ..strokeWidth = 1.5;
    for (var sx = left; sx < size.width - right; sx += 7) {
      final ex = (sx + 4) > size.width - right ? size.width - right : sx + 4;
      canvas.drawLine(Offset(sx, y(target)), Offset(ex, y(target)), tp);
    }
    _label(canvas, 'target ${fmtMarks(target)}', Offset(size.width - right, y(target) - 8), good, align: TextAlign.right);

    final path = Path()..moveTo(x(0), y(scores[0]));
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < scores.length; i++) {
      final lastOne = i == scores.length - 1;
      canvas.drawCircle(Offset(x(i), y(scores[i])), lastOne ? 5 : 3.5, Paint()..color = lastOne ? line : surface);
      canvas.drawCircle(
        Offset(x(i), y(scores[i])),
        lastOne ? 5 : 3.5,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label(canvas, labels[i], Offset(x(i), size.height - 8), text);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.scores != scores || old.target != target || old.line != line || old.text != text;
}
