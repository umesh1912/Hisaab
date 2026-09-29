import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/settings.dart';
import '../sheets/share_text.dart';
import '../ui.dart';

class RefillsScreen extends StatelessWidget {
  const RefillsScreen({super.key});

  void _order(BuildContext context) {
    final store = StoreScope.read(context);
    final d = store.data!;
    final low = lowStock(d.meds);
    final text = refillMessage(low: low, nameOf: d.nameOf, address: d.address, caregiver: d.caregiver);
    showShareText(
      context,
      title: 'Send list to chemist',
      intro: '',
      text: text,
      phone: d.chemistPhone,
      copied: 'Order message copied.',
      details: [
        InfoLine('Chemist', d.chemist.isEmpty ? 'Not set · add in Settings' : d.chemist),
        if (d.chemistPhone.isNotEmpty) InfoLine('WhatsApp', d.chemistPhone),
        const SizedBox(height: 4),
        const InfoNote('Prices and stock are confirmed by the chemist. Tap "Refilled" when the new strips arrive.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final all = [...d.meds]..sort((a, b) => daysLeft(a).compareTo(daysLeft(b)));
    final low = lowStock(d.meds);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (low.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: warnSoft(context), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${low.length} medicine${low.length > 1 ? 's' : ''} will run out within 10 days',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send one list to the chemist near your parents. Many deliver the same day.',
                  style: TextStyle(color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _order(context),
                  child: const Text('Send list to chemist', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        SectionTitle('Stock · ${all.length} medicines'),
        if (all.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nothing to track yet',
            body: 'Add medicines with the number of tablets at home, and Khayal counts down as doses are taken.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < all.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _StockRow(med: all[i], today: today),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Stock goes down each time a dose is marked taken. Tap "Refilled" when a new strip arrives; it adds a month\'s supply.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SectionTitle('Chemist'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_pharmacy_outlined),
            title: Text(d.chemist.isEmpty ? 'Add the chemist near your parents' : d.chemist),
            subtitle: Text(d.chemistPhone.isEmpty ? 'WhatsApp number not set' : d.chemistPhone),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => showSettings(context),
          ),
        ),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.med, required this.today});
  final Med med;
  final String today;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final dl = daysLeft(med);
    final c = stockColor(context, dl);
    final pct = (dl / 30).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          PillDot(med.color, size: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: med.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' · ${d.nameOf(med.who)}', style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.stock} left · runs out ${friendlyDate(addDaysIso(today, dl > 365 ? 365 : dl), today)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    color: c,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dl >= 999 ? '–' : '$dl days', style: TextStyle(fontWeight: FontWeight.w700, color: c)),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  store.refill(med.id);
                  toast(context, '${med.name} refilled. Enough for ${daysLeft(med)} days.');
                },
                child: const Text('Refilled'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
