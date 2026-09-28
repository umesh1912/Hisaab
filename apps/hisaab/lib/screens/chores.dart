import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic.dart';
import '../ui.dart';

class ChoresScreen extends StatelessWidget {
  const ChoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final away = store.awaySet;
    final today = todayIso();
    final chores = [...d.chores]..sort((a, b) => a.due.compareTo(b.due));

    // Fair share: points vs. an even split among people who are home
    final totalPts = d.points.values.fold<int>(0, (a, b) => a + b);
    final maxPts = d.points.values.fold<int>(1, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (chores.isEmpty)
          const EmptyState(
            icon: Icons.cleaning_services_outlined,
            title: 'No chores yet',
            body: 'Add trash, dishes or water cans. Hisaab rotates turns and skips anyone who is away.',
          ),
        for (final c in chores) _ChoreCard(chore: c, today: today, away: away),
        if (d.members.isNotEmpty && totalPts > 0) ...[
          const SectionTitle('Fair share'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chores done so far', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  for (final m in d.members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Avatar(id: m.id, name: m.name, size: 28, dimmed: m.away),
                          const SizedBox(width: 10),
                          SizedBox(width: 72, child: Text(d.nameOf(m.id), overflow: TextOverflow.ellipsis)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (d.points[m.id] ?? 0) / maxPts,
                                minHeight: 10,
                                backgroundColor: cs.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 28, child: Text('${d.points[m.id] ?? 0}', textAlign: TextAlign.end)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoreCard extends StatelessWidget {
  const _ChoreCard({required this.chore, required this.today, required this.away});
  final Chore chore;
  final String today;
  final Set<String> away;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (chore.rotation.isEmpty) return const SizedBox.shrink();
    final ti = currentTurn(chore, away);
    final who = chore.rotation[ti];
    final days = daysBetween(today, chore.due);
    final overdue = days < 0;
    final mine = who == d.meId;
    final every = chore.everyDays == 1 ? 'Daily' : (chore.everyDays == 7 ? 'Weekly' : 'Every ${chore.everyDays} days');
    final dueText = days < 0 ? 'Overdue ${-days}d' : (days == 0 ? 'Today' : (days == 1 ? 'Tomorrow' : '${dayName(chore.due)}, ${shortDate(chore.due)}'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(chore.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: overdue ? cs.errorContainer : cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dueText,
                    style: tt.labelMedium?.copyWith(color: overdue ? cs.onErrorContainer : cs.onSecondaryContainer),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete ${chore.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) store.deleteChore(chore.id);
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete chore'))],
                ),
              ],
            ),
            Text(every, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var k = 0; k < chore.rotation.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: k == ti ? cs.primary : Colors.transparent, width: 2),
                      ),
                      child: Avatar(
                        id: chore.rotation[k],
                        name: d.member(chore.rotation[k])?.name ?? '?',
                        size: 26,
                        dimmed: away.contains(chore.rotation[k]),
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mine ? 'Your turn' : "${d.nameOf(who)}'s turn",
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    final next = store.completeChore(chore.id);
                    toast(context, 'Marked done. Next up: ${d.nameOf(next)}');
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
                if (chore.rotation.length > 1)
                  TextButton(
                    onPressed: () {
                      final other = store.swapChore(chore.id);
                      toast(context, 'Swapped with ${d.nameObj(other)}');
                    },
                    child: const Text('Swap turn'),
                  ),
                if (!mine)
                  TextButton(
                    onPressed: () {
                      final name = d.member(who)?.name ?? '';
                      final msg = 'Hey $name, gentle reminder: it\'s your turn for "${chore.name}" ($dueText). – via Hisaab';
                      launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Nudge'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
