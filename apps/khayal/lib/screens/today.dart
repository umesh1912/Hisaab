import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/dose.dart';
import '../ui.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = isoDate(now);
    final p = store.current;
    final doses = dosesOn(d.meds, p.id, today);
    final missed = store.missedNow();
    final week = weekAdherence(d.meds, d.logs, p.id, now);
    final avg = averageOf(week);
    final taken = doses.where((x) => d.logs[x.key(today)]?.s == 'taken').length;

    return ListView(
      key: const ValueKey('list-today'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final m in missed) _MissedAlert(dose: m, now: now),
        const WhoSwitch(),

        // Week hero
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${p.name} · this week', style: tt.titleSmall?.copyWith(color: cs.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: avg == null ? '–' : '$avg%',
                    style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer),
                  ),
                  TextSpan(
                    text: '  of doses taken',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onPrimaryContainer),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _WeekBars(values: week, today: today),
            ],
          ),
        ),

        SectionTitle("${p.name}'s day · $taken of ${doses.length} taken"),
        if (doses.isEmpty)
          const EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines yet',
            body: 'Tap "Medicine" to add one. Each dose then shows here with its time.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < doses.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  DoseRow(dose: doses[i], date: today, now: now),
                ],
              ],
            ),
          ),

        const SectionTitle('Recent'),
        if (d.activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Nothing yet.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            child: Column(
              children: [
                for (final a in d.activity.take(4))
                  ListTile(
                    dense: true,
                    title: Text(a.text),
                    trailing: Text(
                      a.date == today ? t12(a.at) : shortDate(a.date),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => onGo(4),
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Who gets told'),
          ),
        ),
      ],
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values, required this.today});
  final List<int?> values;
  final String today;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 22,
                    height: values[i] == null ? 4 : (values[i]! * 0.5).clamp(6, 50).toDouble(),
                    decoration: BoxDecoration(
                      color: values[i] == null
                          ? cs.outlineVariant
                          : (values[i]! < 90 ? accentColor(context) : cs.onPrimaryContainer),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayName(addDaysIso(today, i - values.length + 1)).substring(0, 1),
                    style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One scheduled dose: time, pill colour, name and what happened.
class DoseRow extends StatelessWidget {
  const DoseRow({super.key, required this.dose, required this.date, required this.now});
  final Dose dose;
  final String date;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final m = dose.med;
    final log = d.logs[dose.key(date)];
    final s = doseStatus(log, date, dose.time, now);
    final String sub;
    if (s == 'taken' && log != null) {
      sub = 'Taken at ${t12(log.at)}${isLate(dose.time, log.at) ? ' (late)' : ''}';
    } else if (s == 'skipped' && log != null) {
      sub = log.reason.isEmpty ? 'Skipped' : 'Skipped · ${log.reason}';
    } else {
      sub = '${m.strength.isEmpty ? '' : '${m.strength} · '}${m.per} ${m.form} · ${foodText(m.food)}';
    }
    return InkWell(
      onTap: () => showDoseSheet(context, date: date, medId: m.id, time: dose.time),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 66,
              child: Text(t12(dose.time), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            PillDot(m.color, size: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: '  ${m.purpose}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (s == 'missed' || s == 'due')
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => showDoseSheet(context, date: date, medId: m.id, time: dose.time),
                child: const Text('Update'),
              )
            else
              StatusChip(s),
          ],
        ),
      ),
    );
  }
}

class _MissedAlert extends StatelessWidget {
  const _MissedAlert({required this.dose, required this.now});
  final Dose dose;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final m = dose.med;
    final p = d.parent(m.who);
    final name = p?.name ?? 'Parent';
    final quiet = d.quietHours && inQuietHours(now);
    final others = ladder(d.helpers).where((h) => h.id != 'me').toList();
    final today = isoDate(now);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$name hasn't taken ${m.name} (${t12(dose.time)})",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: cs.onErrorContainer),
          ),
          const SizedBox(height: 6),
          Text(
            'Not confirmed by ${t12(hhmm(mins(dose.time) + 60))}. Check with $name, then record what happened.'
            '${quiet ? ' Quiet hours are on, so helpers are not asked until 6 AM.' : ''}',
            style: TextStyle(color: cs.onErrorContainer),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton(
                onPressed: () => callPhone(context, p?.phone ?? '', name),
                child: Text('Call $name'),
              ),
              OutlinedButton(
                onPressed: () => showDoseSheet(context, date: today, medId: m.id, time: dose.time),
                child: const Text('Update dose'),
              ),
              if (!quiet)
                for (final h in others.take(2))
                  OutlinedButton(
                    onPressed: () => whatsApp(
                      context,
                      h.phone,
                      'Namaste ${h.name}, could you please check on $name? '
                      "${m.name} (${t12(dose.time)}) hasn't been confirmed yet. – ${d.caregiver}",
                    ),
                    child: Text('Ask ${h.name}'),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
