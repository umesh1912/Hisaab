import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/reading.dart';
import '../sheets/share_text.dart';
import '../sheets/visit.dart';
import '../ui.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  void _summary(BuildContext context) {
    final store = StoreScope.read(context);
    final d = store.data!;
    final p = store.current;
    final today = todayIso();
    final next = d.visits.where((v) => v.who == p.id && v.date.compareTo(today) >= 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final visit = next.isEmpty ? null : next.first;
    showShareText(
      context,
      title: 'Doctor summary',
      intro: visit == null
          ? "The last 7 days of ${p.name}'s doses and readings, ready to show or send to the doctor."
          : "For ${p.name}'s visit: ${visit.title} on ${friendlyDate(visit.date, today)}.",
      text: doctorSummary(p: p, meds: d.meds, logs: d.logs, readings: d.readings, visit: visit, now: DateTime.now()),
      copied: 'Summary copied.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = store.current;
    final today = todayIso();
    final bp = recentReadings(d.readings, p.id, 'bp');
    final sg = recentReadings(d.readings, p.id, 'sugar');
    final visits = d.visits.where((v) => v.date.compareTo(today) >= 0).toList()
      ..sort((a, b) => (a.date + a.time).compareTo(b.date + b.time));
    final history = d.readings.where((r) => r.who == p.id).toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const WhoSwitch(),
        SectionTitle("${p.name}'s readings"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Blood pressure',
                  value: bp.isEmpty ? '–' : bp.last.label,
                  sub: bp.isEmpty
                      ? 'No readings yet'
                      : '${friendlyDate(bp.last.date, today)} · avg ${avgInt(bp.map((r) => r.a))}/${avgInt(bp.map((r) => r.b))}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Fasting sugar',
                  value: sg.isEmpty ? '–' : '${sg.last.a}',
                  sub: sg.isEmpty ? 'No readings yet' : 'mg/dL ${friendlyDate(sg.last.date, today).toLowerCase()} · avg ${avgInt(sg.map((r) => r.a))}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blood pressure, last ${bp.isEmpty ? 7 : bp.length} readings', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text("Green band = usual target. Follow the doctor's own numbers.", style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                if (bp.length < 2)
                  _NoChart(n: bp.length)
                else
                  LineChart(
                    labels: [for (final r in bp) dayName(r.date).substring(0, 1)],
                    series: [
                      [for (final r in bp) r.a],
                      [for (final r in bp) r.b],
                    ],
                    colors: [cs.primary, accentColor(context)],
                    lo: 60,
                    hi: 160,
                    bandLo: 60,
                    bandHi: 130,
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  children: [
                    _Legend(color: cs.primary, text: 'Upper (systolic)'),
                    _Legend(color: accentColor(context), text: 'Lower (diastolic)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fasting sugar, last ${sg.isEmpty ? 7 : sg.length} readings', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (sg.length < 2)
                  _NoChart(n: sg.length)
                else
                  LineChart(
                    labels: [for (final r in sg) dayName(r.date).substring(0, 1)],
                    series: [
                      [for (final r in sg) r.a],
                    ],
                    colors: [cs.primary],
                    lo: 80,
                    hi: 160,
                    bandLo: 80,
                    bandHi: 130,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showReadingSheet(context),
                  child: const Text('Add reading', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _summary(context),
                  child: const Text('Doctor summary', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Coming up',
          trailing: TextButton.icon(
            onPressed: () => showVisitSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add visit'),
          ),
        ),
        if (visits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No doctor visits or tests planned.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final v in visits)
                  ListTile(
                    leading: Avatar(
                      name: d.nameOf(v.who),
                      color: Color(d.parent(v.who)?.color ?? 0xFF1D5C7A),
                      size: 32,
                    ),
                    title: Text(v.title),
                    subtitle: Text(
                      '${friendlyDate(v.date, today)}, ${t12(v.time)}${v.note.isEmpty ? '' : ' · ${v.note}'}',
                    ),
                    onTap: () => showVisitSheet(context, visitId: v.id),
                  ),
              ],
            ),
          ),
        if (history.isNotEmpty) ...[
          const SectionTitle('Logged readings'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final r in history.take(6))
                  ListTile(
                    dense: true,
                    leading: Icon(r.kind == 'bp' ? Icons.favorite_border : Icons.water_drop_outlined, color: cs.primary),
                    title: Text('${r.kind == 'bp' ? 'BP' : 'Sugar'} ${r.label}'),
                    subtitle: Text(friendlyDate(r.date, today)),
                    trailing: IconButton(
                      tooltip: 'Delete reading',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        store.deleteReading(r.id);
                        toast(context, 'Reading deleted.');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            "Readings are for sharing with the doctor. Khayal doesn't diagnose or suggest dose changes.",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.sub});
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(sub, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NoChart extends StatelessWidget {
  const _NoChart({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        n == 0 ? 'No readings yet. Add one to start the chart.' : 'Add one more reading to see a chart.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// A small line chart with a target band, grid lines and day labels.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.labels,
    required this.series,
    required this.colors,
    required this.lo,
    required this.hi,
    required this.bandLo,
    required this.bandHi,
  });
  final List<String> labels;
  final List<List<int>> series;
  final List<Color> colors;
  final int lo;
  final int hi;
  final int bandLo;
  final int bandHi;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final range = chartRange(series.expand((s) => s), lo, hi);
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          labels: labels,
          series: series,
          colors: colors,
          min: range[0],
          max: range[1],
          bandLo: bandLo,
          bandHi: bandHi,
          band: goodSoft(context),
          grid: cs.outlineVariant,
          text: cs.onSurfaceVariant,
          surface: cs.surfaceContainerLow,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.labels,
    required this.series,
    required this.colors,
    required this.min,
    required this.max,
    required this.bandLo,
    required this.bandHi,
    required this.band,
    required this.grid,
    required this.text,
    required this.surface,
  });
  final List<String> labels;
  final List<List<int>> series;
  final List<Color> colors;
  final int min;
  final int max;
  final int bandLo;
  final int bandHi;
  final Color band;
  final Color grid;
  final Color text;
  final Color surface;

  void _label(Canvas canvas, String s, Offset at, {bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: text)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? at.dx - tp.width : at.dx - tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, right = 8.0, top = 8.0, bottom = 20.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    if (w <= 0 || h <= 0 || max <= min) return;
    final n = labels.length;
    double x(int i) => left + (n <= 1 ? w / 2 : i * w / (n - 1));
    double y(num v) => top + (max - v) / (max - min) * h;

    final bLo = bandLo < min ? min : bandLo;
    final bHi = bandHi > max ? max : bandHi;
    if (bHi > bLo) {
      canvas.drawRect(Rect.fromLTRB(left, y(bHi), left + w, y(bLo)), Paint()..color = band);
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var t = min + 20; t < max; t += 20) {
      canvas.drawLine(Offset(left, y(t)), Offset(left + w, y(t)), gridPaint);
      _label(canvas, '$t', Offset(left - 4, y(t)), right: true);
    }

    for (var s = 0; s < series.length; s++) {
      final vals = series[s];
      final color = colors[s % colors.length];
      final line = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < vals.length; i++) {
        final o = Offset(x(i), y(vals[i]));
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(path, line);
      for (var i = 0; i < vals.length; i++) {
        final o = Offset(x(i), y(vals[i]));
        final last = i == vals.length - 1;
        canvas.drawCircle(o, last ? 4 : 2.6, Paint()..color = last ? color : surface);
        canvas.drawCircle(
          o,
          last ? 4 : 2.6,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    for (var i = 0; i < n; i++) {
      _label(canvas, labels[i], Offset(x(i), size.height - 8));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.series != series || old.min != min || old.max != max || old.band != band || old.text != text;
}
