import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/expense_detail.dart';
import '../ui.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? cat; // null = all

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final all = [...d.expenses]..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    final shown = cat == null ? all : all.where((e) => e.cat == cat).toList();

    // Last three months of flat spending
    final now = DateTime.now();
    final months = [for (var k = 2; k >= 0; k--) DateTime(now.year, now.month - k, 1)];
    String key(DateTime m) => isoDate(m).substring(0, 7);
    final totals = {
      for (final m in months) key(m): d.expenses.where((e) => e.date.startsWith(key(m))).fold<int>(0, (a, e) => a + e.amount),
    };
    final maxT = totals.values.fold<int>(1, (a, b) => a > b ? a : b);

    // Group rows by month
    final rows = <Widget>[];
    String? lastMonth;
    for (final e in shown) {
      final m = e.date.substring(0, 7);
      if (m != lastMonth) {
        final dt = parseIso('$m-01');
        rows.add(SectionTitle('${monthName(dt.month)} ${dt.year}'));
        lastMonth = m;
      }
      final mine = e.shares[d.meId] ?? 0;
      final lent = e.paidBy == d.meId ? e.amount - mine : -mine;
      rows.add(Card(
        child: ListTile(
          onTap: () => showExpenseDetail(context, e.id),
          leading: CategoryIcon(e.cat),
          title: Text(e.desc, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${d.nameOf(e.paidBy)} paid ${inr(e.amount)} · ${shortDate(e.date)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lent == 0 ? 'not involved' : (lent > 0 ? 'you lent' : 'you owe'),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (lent != 0)
                Text(inr(lent.abs()), style: TextStyle(fontWeight: FontWeight.w700, color: moneyColor(context, lent))),
            ],
          ),
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flat spending', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final m in months)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(inr(totals[key(m)]!), style: tt.labelSmall)),
                                const SizedBox(height: 4),
                                Container(
                                  height: 60 * totals[key(m)]! / maxT + 4,
                                  decoration: BoxDecoration(
                                    color: m.month == now.month ? cs.primary : cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(monthName(m.month), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('All'), selected: cat == null, onSelected: (_) => setState(() => cat = null)),
              ),
              for (final c in categories.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.value),
                    selected: cat == c.key,
                    onSelected: (_) => setState(() => cat = cat == c.key ? null : c.key),
                  ),
                ),
            ],
          ),
        ),
        if (d.recurring.isNotEmpty && cat == null) ...[
          const SectionTitle('Repeats every month'),
          for (final r in d.recurring)
            Card(
              child: ListTile(
                leading: CategoryIcon(r.cat),
                title: Text(r.desc),
                subtitle: Text('${inr(r.amount)} · ${d.nameOf(r.paidBy)} · next ${shortDate(r.next)}'),
                trailing: IconButton(
                  tooltip: 'Stop repeating',
                  icon: const Icon(Icons.event_busy_outlined),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Stop repeating ${r.desc}?'),
                        content: const Text('Past expenses stay. It just won\'t be suggested again.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Stop')),
                        ],
                      ),
                    );
                    if (ok == true) store.deleteRecurring(r.id);
                  },
                ),
              ),
            ),
        ],
        if (shown.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            body: 'Tap "Add expense" to log rent, bills or groceries.',
          )
        else
          ...rows,
      ],
    );
  }
}
