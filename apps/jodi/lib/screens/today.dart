import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/habit_form.dart';
import '../ui.dart';
import 'habit_tile.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = todayIso();
    final myStates = store.statesOf(me);
    final theirStates = store.statesOf(them);
    final mine = store.dueToday(me);
    final theirs = store.dueToday(them);
    final left = mine.where((h) => !h.log.containsKey(t)).length;

    String headline;
    if (d.habitsOf(me).isEmpty) {
      headline = 'Start with one small habit';
    } else if (mine.isEmpty) {
      headline = 'Nothing due today. Rest up.';
    } else if (left > 0) {
      headline = '$left to do before the day ends';
    } else {
      headline = 'Your day is done. Nice.';
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (d.paused)
          Callout(
            icon: Icons.pause_circle_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partnership paused. Streaks are frozen for both of you.'),
                const SizedBox(height: 6),
                TextButton(onPressed: () => store.setPaused(false), child: const Text('Resume')),
              ],
            ),
          ),
        ScreenTitle(headline),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WhoHeader(who: me, text: 'You'),
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: d.habitsOf(me).isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Write it as a plan: “After I brush my teeth, I will floss.”',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => showHabitForm(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add your first habit'),
                            ),
                          ],
                        )
                      : Text('No habits due today.', style: TextStyle(color: cs.onSurfaceVariant)),
                )
              else
                for (final h in mine) HabitTile(habit: h, states: myStates[h.id] ?? const {}, today: t),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WhoHeader(who: them, text: d.partnerCity.isEmpty ? d.partnerName : '${d.partnerName} · ${d.partnerCity}'),
              if (theirs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    d.habitsOf(them).isEmpty
                        ? 'No habits for ${d.partnerName} yet. Add theirs with + Habit.'
                        : 'Nothing due for ${d.partnerName} today.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                for (final h in theirs) HabitTile(habit: h, states: theirStates[h.id] ?? const {}, today: t),
            ],
          ),
        ),
        PactCard(mine: store.scoreOf(me, myStates), theirs: store.scoreOf(them, theirStates)),
        Callout(
          icon: Icons.warning_amber_rounded,
          iconColor: skipColor(context),
          color: skipSoftColor(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Never miss twice. ', style: TextStyle(fontWeight: FontWeight.w800)),
                    const TextSpan(
                      text: 'You each get one skip a week. A single missed day barely affects a habit; '
                          'two in a row is where habits break.',
                    ),
                  ],
                ),
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Skips left this week: you ${skipsLeft(myStates, t)} · ${d.partnerName} ${skipsLeft(theirStates, t)}',
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "This week's pact": both partners' progress bars racing to the target.
class PactCard extends StatelessWidget {
  const PactCard({super.key, required this.mine, required this.theirs});
  final WeekScore mine;
  final WeekScore theirs;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final left = daysLeftInWeek(todayIso());

    Widget side(String who, String name, WeekScore s) {
      final color = personColor(context, who);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${s.pct}%', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            ),
            Text(
              '$name · ${s.done}/${s.of}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.of == 0 ? 0 : s.done / s.of,
                minHeight: 6,
                color: color,
                backgroundColor: cs.outlineVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              left == 0 ? 'THIS WEEK’S PACT · ENDS TONIGHT' : 'THIS WEEK’S PACT · ENDS SUNDAY',
              style: tt.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(d.pact, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: side(me, 'You', mine)),
                const SizedBox(width: 10),
                Expanded(child: side(them, d.partnerName, theirs)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${pactVerdict(mine, theirs, d.target, d.partnerName)}. Target ${d.target}%.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
