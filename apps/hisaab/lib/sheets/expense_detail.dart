import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showExpenseDetail(BuildContext context, int id) {
  return showAppSheet(context, (_) => _ExpenseDetail(id: id));
}

class _ExpenseDetail extends StatelessWidget {
  const _ExpenseDetail({required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Expense? e;
    for (final x in d.expenses) {
      if (x.id == id) e = x;
    }
    if (e == null) return const SizedBox(height: 120);
    final ex = e;
    const modeText = {'equal': 'Split equally', 'exact': 'Exact amounts', 'shares': 'Split by shares'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CategoryIcon(ex.cat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.desc, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${categories[ex.cat] ?? 'Other'} · ${dayName(ex.date)}, ${shortDate(ex.date)}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(inrExact(ex.amount), style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        Text('${d.nameOf(ex.paidBy)} paid · ${modeText[ex.mode] ?? ''}', style: TextStyle(color: cs.onSurfaceVariant)),
        if (ex.note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('“${ex.note}”', style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        for (final s in ex.shares.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(id: s.key, name: d.member(s.key)?.name ?? '?', size: 32),
            title: Text(d.nameOf(s.key)),
            subtitle: Text(s.key == ex.paidBy ? 'paid, own share' : 'owes ${d.nameObj(ex.paidBy)}'),
            trailing: Text(inrExact(s.value), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: cs.error, minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete this expense?'),
                content: Text('${ex.desc} (${inr(ex.amount)}) will be removed and balances recalculated.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              Navigator.pop(context);
              store.deleteExpense(ex.id);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete expense'),
        ),
      ],
    );
  }
}
