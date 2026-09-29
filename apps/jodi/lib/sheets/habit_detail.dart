import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'check_in.dart';
import 'habit_form.dart';

Future<void> showHabitDetail(BuildContext context, int habitId) =>
    showAppSheet(context, (_) => HabitDetail(habitId: habitId));

class HabitDetail extends StatelessWidget {
  const HabitDetail({super.key, required this.habitId});
  final int habitId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final h = d?.habit(habitId);
    if (d == null || h == null) return const SizedBox(height: 120); // deleted or reset while open
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = todayIso();
    final states = store.statesOf(h.owner)[h.id] ?? const <String, DayState>{};
    final mine = h.owner == me;
    final doneToday = h.log.containsKey(t);
    final dueToday = doneToday || scheduledOn(h, t, d.pauses);
    final recent = (h.log.keys.toList()..sort((a, b) => b.compareTo(a))).take(6).toList();

    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: personColor(context, h.owner))),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PersonAvatar(who: h.owner, name: d.nameOf(h.owner), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mine ? 'Your habit' : '${d.partnerName}’s habit',
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            if (mine && !h.shared) Chip(label: const Text('Private'), visualDensity: VisualDensity.compact),
          ],
        ),
        const SizedBox(height: 8),
        Text(h.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(planText(h.cue, h.name), style: tt.bodyLarge),
        Text(
          '${daysText(h.days)} · since ${shortDate(h.createdOn)}${h.proof ? ' · asks for proof' : ''}',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            stat('${currentStreak(states, t)}', 'streak'),
            const SizedBox(width: 8),
            stat('${bestStreak(states)}', 'best streak'),
            const SizedBox(width: 8),
            stat('${successRate(states, from: heatDates(t).first)}%', 'of days, 8 wks'),
          ],
        ),
        const SizedBox(height: 16),
        Center(child: HeatMap(states: states, today: t, who: h.owner, cell: 18)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (dueToday && !doneToday && mine)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showCheckIn(context, h.id);
                },
                icon: const Icon(Icons.check),
                label: const Text('Check in'),
              ),
            if (dueToday && !doneToday && !mine)
              FilledButton.icon(
                onPressed: () {
                  store.logForPartner(h.id);
                  toast(context, 'Logged for ${d.partnerName}.');
                },
                icon: const Icon(Icons.check),
                label: Text('${d.partnerName} did it'),
              ),
            if (doneToday)
              OutlinedButton.icon(
                onPressed: () {
                  store.undoCheckIn(h.id);
                  toast(context, 'Check-in undone.');
                },
                icon: const Icon(Icons.undo),
                label: const Text('Undo today'),
              ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showHabitForm(context, habitId: h.id);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Delete ${h.name}?',
                  body: 'Its streak and check-in history will be deleted too.',
                  action: 'Delete',
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  store.deleteHabit(h.id);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Recent check-ins', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          Text('None yet.', style: TextStyle(color: cs.onSurfaceVariant))
        else
          for (final date in recent)
            Builder(builder: (context) {
              final c = h.log[date]!;
              final extra = [c.effort, if (c.byPartnerLog) 'logged by you'].join(' · ');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.check_circle, color: personColor(context, h.owner)),
                title: Text(c.note.isEmpty ? '${dayName(date)} ${shortDate(date)}' : c.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(c.note.isEmpty ? '${t12(c.at)} · $extra' : '${dayName(date)} ${shortDate(date)} · ${t12(c.at)} · $extra'),
              );
            }),
      ],
    );
  }
}
