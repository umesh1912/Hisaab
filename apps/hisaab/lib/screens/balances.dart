import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic.dart';
import '../sheets/settle.dart';
import '../ui.dart';

class BalancesScreen extends StatelessWidget {
  const BalancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final net = store.net;
    final debts = store.debts;
    final pairwiseCount = pairwiseDebts(store.ids, d.expenses, d.payments).length;
    final payments = [...d.payments]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SectionTitle('Everyone'),
        Card(
          child: Column(
            children: [
              for (final m in d.members)
                ListTile(
                  leading: Avatar(id: m.id, name: m.name, dimmed: m.away),
                  title: Text(d.nameOf(m.id)),
                  subtitle: Text(
                    (net[m.id] ?? 0) > 50 ? 'gets back' : ((net[m.id] ?? 0) < -50 ? 'owes' : 'settled'),
                  ),
                  trailing: Text(
                    inr((net[m.id] ?? 0).abs()),
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: moneyColor(context, net[m.id] ?? 0)),
                  ),
                ),
            ],
          ),
        ),
        SectionTitle(
          'How to settle',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fewest payments', style: tt.labelMedium),
              const SizedBox(width: 6),
              Switch(value: d.simplify, onChanged: store.setSimplify),
            ],
          ),
        ),
        if (d.simplify && pairwiseCount > debts.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '${debts.length} payment${debts.length == 1 ? '' : 's'} instead of $pairwiseCount. Same totals for everyone.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        if (debts.isEmpty)
          const EmptyState(icon: Icons.celebration_outlined, title: 'All settled', body: 'Nobody owes anybody.')
        else
          for (final t in debts)
            Card(
              child: ListTile(
                leading: Avatar(id: t.from, name: d.member(t.from)?.name ?? '?'),
                title: Text('${d.nameOf(t.from)} → ${d.nameObj(t.to)}'),
                subtitle: Text(inr(t.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: t.from == d.meId
                    ? FilledButton(onPressed: () => showSettle(context, t), child: const Text('Pay'))
                    : (t.to == d.meId
                        ? TextButton(
                            onPressed: () => _remind(context, t),
                            child: const Text('Remind'),
                          )
                        : TextButton(onPressed: () => showSettle(context, t), child: const Text('Record'))),
              ),
            ),
        if (payments.isNotEmpty) ...[
          const SectionTitle('Payments'),
          for (final p in payments.take(20))
            ListTile(
              dense: true,
              leading: Icon(Icons.check_circle_outline, color: cs.primary),
              title: Text('${d.nameOf(p.from)} paid ${d.nameObj(p.to)}'),
              subtitle: Text(shortDate(p.date)),
              trailing: Text(inr(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ],
    );
  }

  void _remind(BuildContext context, Transfer t) {
    final d = StoreScope.read(context).data!;
    final me = d.member(d.meId);
    final name = d.member(t.from)?.name ?? '';
    final upi = (me?.upi ?? '').isEmpty ? '' : ' UPI: ${me!.upi}';
    final msg = 'Hi $name, as per Hisaab for ${d.flatName} you owe me ${inr(t.amount)}.$upi Thanks!';
    launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
  }
}
