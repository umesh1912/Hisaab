import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/budget_line.dart';
import '../ui.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = budgetTotals(d.budget);
    final over = d.budget.where((b) => b.over).toList();

    if (d.budget.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No budget yet',
            body: 'Add categories like Venue and Catering with the Category button, then fill in the estimate and what is committed.',
          ),
        ],
      );
    }

    Widget sumRow(String label, int v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant))),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(inr(v), style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w700)),
                ),
              ),
            ],
          ),
        );

    final String overNote;
    if (t.com <= t.est) {
      overNote = 'The total is still within budget.';
    } else {
      overNote = 'In total you have committed ${inr(t.com - t.est)} more than the budget.';
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BudgetDonut(paid: t.paidShare, committed: t.committedShare, percent: t.paidPercent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      sumRow('Budget', t.est),
                      sumRow('Committed', t.com),
                      sumRow('Paid', t.paid),
                      sumRow('Still to pay', t.toPay, strong: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (over.isNotEmpty)
          NoteBanner(
            danger: true,
            bold: 'Over estimate:',
            text: '${over.map((b) => '${b.cat} by ${inr(b.com - b.est)}').join(', ')}. $overNote',
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < d.budget.length; i++) ...[
                if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                InkWell(
                  onTap: () => showBudgetLineSheet(context, id: d.budget[i].id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _LineView(line: d.budget[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Dark bar = paid · light bar = committed · line = estimate. Tap a category to edit it.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _LineView extends StatelessWidget {
  const _LineView({required this.line});
  final BudgetLine line;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final b = line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(b.cat, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(
              '${inrShort(b.com)} / ${inrShort(b.est)}',
              style: b.over
                  ? TextStyle(color: cs.error, fontWeight: FontWeight.w800)
                  : TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BudgetBar(line: b),
        const SizedBox(height: 4),
        Text('Paid ${inr(b.paid)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
      ],
    );
  }
}
