import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/customer.dart';
import '../sheets/customer_form.dart';
import '../sheets/entry.dart';
import '../sheets/quick_entry.dart';
import '../ui.dart';

/// The register: total to collect, quick entry, the two big buttons and every customer by balance.
class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final en = d.en;
    final today = todayIso();
    final cs = Theme.of(context).colorScheme;
    final owing = d.customers.where((c) => balanceOf(c) > 0).length;
    final overdue = d.customers.where((c) => isOverdue(c, today)).length;
    final list = byBalance(d.customers).where((c) => matchesSearch(c, _search.text)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Cover(total: totalToCollect(d.customers), owing: owing, overdue: overdue),
        const SizedBox(height: 12),
        _QuickButton(onTap: () => showQuickEntry(context)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BigAction(
                key: const ValueKey('gave'),
                credit: true,
                title: en ? 'Gave credit' : 'उधार दिया',
                caption: en ? 'Customer took goods' : 'ग्राहक ने सामान लिया',
                onTap: () => showEntrySheet(context, kind: 'credit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigAction(
                key: const ValueKey('got'),
                credit: false,
                title: en ? 'Got payment' : 'पैसा मिला',
                caption: en ? 'Customer paid' : 'ग्राहक ने पैसे दिए',
                onTap: () => showEntrySheet(context, kind: 'pay'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: en ? 'Search name' : 'नाम खोजें',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: en ? 'Clear' : 'साफ़ करें',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (d.customers.isEmpty)
          EmptyState(
            icon: Icons.menu_book_outlined,
            title: en ? 'Your khata is empty' : 'खाता अभी खाली है',
            body: en ? 'Add the customers who buy on credit, then write their udhaar here.' : 'जो ग्राहक उधार लेते हैं उन्हें जोड़ें, फिर उनका उधार यहाँ लिखें।',
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(en ? 'No customer matches.' : 'कोई ग्राहक नहीं मिला।', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          LedgerBox(
            children: [
              for (final c in list)
                CustomerRow(
                  key: ValueKey('cust-${c.id}'),
                  customer: c,
                  onTap: () => showCustomerSheet(context, c.id),
                ),
            ],
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('new-customer'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => showCustomerForm(context),
          icon: const Icon(Icons.person_add_alt),
          label: Text(en ? 'New customer' : 'नया ग्राहक'),
        ),
      ],
    );
  }
}

/// The red register cover with the turmeric stripe.
class _Cover extends StatelessWidget {
  const _Cover({required this.total, required this.owing, required this.overdue});
  final int total;
  final int owing;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    const fg = Colors.white;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned(right: 18, top: 0, bottom: 0, child: Container(width: 6, color: turmeric)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 36, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(en ? 'Total to collect' : 'कुल बाकी (लेना है)', style: const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 50,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(inr(total), style: const TextStyle(color: fg, fontSize: 40, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _CoverStat(value: '$owing', label: en ? 'customers' : 'ग्राहक')),
                    const SizedBox(width: 10),
                    Expanded(child: _CoverStat(value: '$overdue', label: en ? 'overdue (15+ days)' : 'देर से (15+ दिन)')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverStat extends StatelessWidget {
  const _CoverStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// The turmeric "speak or type an entry" button.
class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    return Material(
      color: turmeric,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey('quick'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: turmericInk, shape: BoxShape.circle),
                child: const Icon(Icons.mic_none, color: turmeric),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      en ? 'Speak or type an entry' : 'बोलकर या लिखकर एंट्री करें',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: turmericInk, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      en ? 'e.g. “Ramesh 340 udhaar”' : 'जैसे: “रमेश 340 उधार”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: turmericInk, fontSize: 13),
                    ),
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
