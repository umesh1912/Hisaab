import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/check_in.dart';
import '../sheets/habit_detail.dart';
import '../sheets/nudge.dart';
import '../ui.dart';

/// One habit row: tick (yours) or done-mark / Nudge (partner's), the cue and the streak.
class HabitTile extends StatelessWidget {
  const HabitTile({super.key, required this.habit, required this.states, required this.today});
  final Habit habit;
  final Map<String, DayState> states;
  final String today;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mine = habit.owner == me;
    final entry = habit.log[today];
    final done = entry != null;
    final streak = currentStreak(states, today);

    final sub = entry != null
        ? 'Done at ${t12(entry.at)}${entry.byPartnerLog ? ' · logged by you' : ''}'
        : '${habit.cue.isEmpty ? daysText(habit.days) : habit.cue}${habit.proof && mine ? ' · proof' : ''}';

    Widget partnerAction() {
      if (done) return _Tick(who: them, on: true, label: 'Done: ${habit.name}');
      if (!d.showNudges) return _Tick(who: them, on: false, label: 'Not done yet: ${habit.name}');
      final can = canNudge(d.nudges, habit.id, today);
      return OutlinedButton(
        onPressed: can ? () => showNudge(context, habit.id) : null,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 36),
        ),
        child: Text(can ? 'Nudge' : 'Nudged'),
      );
    }

    return InkWell(
      onTap: () => showHabitDetail(context, habit.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            if (mine) ...[
              _Tick(
                key: ValueKey('tick-${habit.id}'),
                who: me,
                on: done,
                label: done ? 'Undo: ${habit.name}' : 'Mark done: ${habit.name}',
                onTap: () {
                  if (done) {
                    store.undoCheckIn(habit.id);
                    toast(context, 'Check-in undone.');
                  } else {
                    showCheckIn(context, habit.id);
                  }
                },
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StreakBadge(streak: streak),
            if (!mine) ...[
              const SizedBox(width: 10),
              partnerAction(),
            ],
          ],
        ),
      ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.color});
  final int streak;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$streak🔥', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
        Text(streak == 1 ? 'day' : 'days', style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// The big square check-in button.
class _Tick extends StatelessWidget {
  const _Tick({super.key, required this.who, required this.on, required this.label, this.onTap});
  final String who;
  final bool on;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = personColor(context, who);
    final box = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: on ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? color : cs.outlineVariant, width: 2),
      ),
      child: on ? Icon(Icons.check_rounded, color: onPersonColor(context, who), size: 26) : null,
    );
    return Semantics(
      button: onTap != null,
      label: label,
      child: onTap == null
          ? box
          : Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: box),
            ),
    );
  }
}
