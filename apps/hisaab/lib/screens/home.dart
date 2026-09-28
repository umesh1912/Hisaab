import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/settle.dart';
import '../ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final myNet = store.net[d.meId] ?? 0;
    final myDebts = store.debts.where((t) => t.from == d.meId || t.to == d.meId).toList();
    final today = todayIso();
    final away = store.awaySet;

    final myChores = d.chores.where((c) => c.rotation.isNotEmpty && c.rotation[currentTurn(c, away)] == d.meId).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    final dueBills = d.recurring.where((r) => daysBetween(today, r.next) <= 3).toList()
      ..sort((a, b) => a.next.compareTo(b.next));
    final openItems = d.list.where((i) => !i.done).length;

    final monthPrefix = today.substring(0, 7);
    final myMonthSpend = d.expenses
        .where((e) => e.date.startsWith(monthPrefix))
        .fold<int>(0, (a, e) => a + (e.shares[d.meId] ?? 0));

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        // Balance hero
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                myNet > 50 ? 'Flatmates owe you' : (myNet < -50 ? 'You owe' : 'You are all settled'),
                style: tt.titleSmall?.copyWith(color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 4),
              Text(
                inr(myNet.abs()),
                style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 4),
              Text(
                'Your share this month: ${inr(myMonthSpend)}',
                style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
              ),
              if (myDebts.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final t in myDebts.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Avatar(id: t.from == d.meId ? t.to : t.from, name: d.member(t.from == d.meId ? t.to : t.from)?.name ?? '?', size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.from == d.meId ? 'You pay ${d.nameObj(t.to)}' : '${d.nameOf(t.from)} pays you',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ),
                        Text(inr(t.amount), style: TextStyle(fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (myDebts.any((t) => t.from == d.meId))
                      FilledButton.icon(
                        onPressed: () => showSettle(context, myDebts.firstWhere((t) => t.from == d.meId)),
                        icon: const Icon(Icons.send_to_mobile),
                        label: const Text('Settle up'),
                      ),
                    const Spacer(),
                    TextButton(onPressed: () => onGo(4), child: const Text('All balances')),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Quick stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: _Stat(icon: Icons.shopping_cart_outlined, value: '$openItems', label: 'on the list', onTap: () => onGo(2))),
              const SizedBox(width: 10),
              Expanded(child: _Stat(icon: Icons.cleaning_services_outlined, value: '${myChores.length}', label: 'chores on you', onTap: () => onGo(3))),
            ],
          ),
        ),

        if (dueBills.isNotEmpty) ...[
          const SectionTitle('Bills coming up'),
          for (final r in dueBills)
            Card(
              child: ListTile(
                leading: CategoryIcon(r.cat),
                title: Text(r.desc),
                subtitle: Text(
                  '${inr(r.amount)} · ${d.nameOf(r.paidBy)} ${r.paidBy == d.meId ? 'pay' : 'pays'} · ${_dueText(daysBetween(today, r.next))}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    store.postRecurring(r.id);
                    toast(context, '${r.desc} added and split equally');
                  },
                  child: const Text('Add'),
                ),
              ),
            ),
        ],

        const SectionTitle('Your chores'),
        if (myChores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Nothing on you right now.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          for (final c in myChores)
            Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: Text(_dueText(daysBetween(today, c.due))),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    final next = store.completeChore(c.id);
                    toast(context, 'Done. Next up: ${d.nameOf(next)}');
                  },
                  child: const Text('Done'),
                ),
              ),
            ),

        const SectionTitle('Recent activity'),
        if (d.activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Nothing yet.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          for (final a in d.activity.take(8))
            ListTile(
              dense: true,
              leading: Icon(Icons.history, color: cs.outline),
              title: Text(a.text),
              trailing: Text(shortDate(a.date), style: TextStyle(color: cs.onSurfaceVariant)),
            ),
      ],
    );
  }
}

String _dueText(int days) {
  if (days < -1) return 'Overdue by ${-days} days';
  if (days == -1) return 'Overdue since yesterday';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due in $days days';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.onTap});
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(label, style: TextStyle(color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
