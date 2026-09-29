import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/day_sales.dart';
import '../sheets/entry.dart';
import '../ui.dart';

/// Today's counter sales (entered by the shopkeeper) plus credit and collections from the khata.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final en = d.en;
    final today = todayIso();
    final sales = d.sales[today] ?? DaySales();
    final todays = entriesOn(d.customers, today);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '${en ? 'Today\'s sales' : 'आज की बिक्री'}: ${inr(sales.total)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Tile(label: en ? 'Cash' : 'नकद', amount: sales.cash)),
            const SizedBox(width: 10),
            Expanded(child: _Tile(label: 'UPI', amount: sales.upi)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Tile(label: en ? 'Credit given' : 'उधार दिया', amount: creditOn(d.customers, today), color: dueColor(context))),
            const SizedBox(width: 10),
            Expanded(child: _Tile(label: en ? 'Collected' : 'वसूली हुई', amount: collectedOn(d.customers, today), color: goodColor(context))),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const ValueKey('update-sales'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => showDaySalesSheet(context, today),
          icon: const Icon(Icons.edit_outlined),
          label: Text(en ? 'Write today\'s sales' : 'आज की बिक्री लिखें'),
        ),
        const SizedBox(height: 12),
        NoteBox(
          text: en
              ? 'Write your counter sales at closing time. Credit given and money collected are added up from khata entries automatically.'
              : 'दुकान बंद करते समय काउंटर की बिक्री लिखें। उधार और वसूली खाता एंट्री से अपने-आप जुड़ जाते हैं।',
        ),
        SectionTitle(
          en ? 'Today\'s khata entries' : 'आज की खाता एंट्री',
          trailing: Text('${todays.length}', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ),
        if (todays.isEmpty)
          LedgerBox(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                en ? 'No khata entries yet today.' : 'आज अभी कोई एंट्री नहीं।',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ])
        else
          LedgerBox(
            children: [
              for (final x in todays)
                InkWell(
                  onTap: () => showEntrySheet(context, kind: x.entry.kind, customerId: x.customer.id, entryId: x.entry.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                    child: Row(
                      children: [
                        Initial(id: x.customer.id, name: x.customer.display(en), size: 28),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.customer.display(en), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (x.entry.note.isNotEmpty)
                                Text(x.entry.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${x.entry.isCredit ? '' : '+'}${inr(x.entry.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: x.entry.isCredit ? dueColor(context) : goodColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.amount, this.color});
  final String label;
  final int amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SizedBox(
              height: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(inr(amount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color ?? cs.onSurface)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
