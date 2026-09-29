import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/reflect.dart';
import '../ui.dart';
import 'habit_tile.dart';

const reactions = ['👏', '🔥', '💪'];

class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = todayIso();
    final theirStates = store.statesOf(them);
    final theirs = store.dueToday(them);
    final answered = store.reflection(me, weekStartIso(t)) != null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ScreenTitle('You and ${d.partnerName}'),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WhoHeader(who: them, text: '${d.partnerName}’s day'),
              if (theirs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    d.habitsOf(them).isEmpty
                        ? 'Add ${d.partnerName}’s habits with + Habit on Today.'
                        : 'Nothing due for ${d.partnerName} today.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                for (final h in theirs) HabitTile(habit: h, states: theirStates[h.id] ?? const {}, today: t),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Tap a habit to log it when ${d.partnerName} tells you it’s done.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Activity', trailing: 'only you two see this'),
        if (d.feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Check-ins, nudges and reactions show up here.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          for (final e in d.feed.take(30)) _FeedItem(event: e),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sunday check-in', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Every Sunday you both answer three short questions: what went well, what got in the way, '
                  'and one change for next week. You see each other’s answers.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => showReflect(context),
                  child: Text(answered ? 'See this week’s answers' : 'Answer this week’s questions'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.event});
  final FeedEvent event;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mine = event.who == me;
    final react = event.react;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(who: event.who, name: d.nameOf(event.who), size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: mine ? cs.primaryContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.text,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: mine ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                  ),
                  if (event.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '“${event.note}”',
                        style: tt.bodyMedium?.copyWith(color: mine ? cs.onPrimaryContainer : cs.onSurface),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    whenText(event.date, event.at, todayIso()),
                    style: tt.labelSmall?.copyWith(color: mine ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                  ),
                  if (!mine)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final r in reactions)
                            ChoiceChip(
                              key: ValueKey('react-${event.id}-$r'),
                              label: Text(r),
                              selected: react == r,
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'React $r',
                              onSelected: (_) => store.react(event.id, r),
                            ),
                        ],
                      ),
                    )
                  else if (react != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Chip(
                        label: Text('${d.partnerName} reacted $react'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
