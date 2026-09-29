import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/habit_detail.dart';
import '../ui.dart';
import 'habit_tile.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = todayIso();
    final states = {...store.statesOf(me), ...store.statesOf(them)};
    final habits = [...d.habitsOf(me), ...d.habitsOf(them)];

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const ScreenTitle('Last 8 weeks'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              LegendDot(color: personColor(context, me), label: 'You done'),
              LegendDot(color: personColor(context, them), label: '${d.partnerName} done'),
              LegendDot(color: skipColor(context), label: 'Skip used'),
              LegendDot(color: cs.outlineVariant, label: 'Missed'),
              LegendDot(color: cs.surfaceContainerHighest, label: 'Rest day'),
            ],
          ),
        ),
        if (habits.isEmpty)
          const EmptyState(
            icon: Icons.grid_view,
            title: 'No habits yet',
            body: 'Add a habit and your check-ins will fill this grid, one square a day.',
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < habits.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                  _HabitProgress(habit: habits[i], states: states[habits[i].id] ?? const {}, today: t),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Habits usually take weeks to months to feel automatic. In one well-known study the median was 66 days, '
            'with a wide range. Consistency matters more than perfection.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _HabitProgress extends StatelessWidget {
  const _HabitProgress({required this.habit, required this.states, required this.today});
  final Habit habit;
  final Map<String, DayState> states;
  final String today;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rate = successRate(states, from: heatDates(today).first);
    final best = bestStreak(states);
    final streak = currentStreak(states, today);
    final who = habit.owner == me ? 'You' : d.partnerName;
    final weekStart = weekStartIso(today);
    final skips = states.entries.where((e) => e.value == DayState.skip).length;
    final thisWeek = states.entries.where((e) => e.value == DayState.done && e.key.compareTo(weekStart) >= 0).length;

    return InkWell(
      onTap: () => showHabitDetail(context, habit.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '$who · $rate% of days · best streak $best',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StreakBadge(streak: streak, color: personColor(context, habit.owner)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeatMap(states: states, today: today, who: habit.owner),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Mini(label: 'This week', value: '$thisWeek done'),
                      _Mini(label: 'Days', value: daysText(habit.days)),
                      _Mini(label: 'Skips used', value: '$skips in total'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
