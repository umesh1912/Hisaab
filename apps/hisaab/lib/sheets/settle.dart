import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showSettle(BuildContext context, Transfer t) {
  return showAppSheet(context, (_) => _Settle(t: t));
}

/// Builds a standard UPI deep link that any UPI app (GPay, PhonePe, Paytm, BHIM) can open.
Uri upiUri({required String pa, required String pn, required int paise, required String note}) {
  final am = (paise / 100).toStringAsFixed(2);
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {'pa': pa, 'pn': pn, 'am': am, 'cu': 'INR', 'tn': note},
  );
}

class _Settle extends StatefulWidget {
  const _Settle({required this.t});
  final Transfer t;

  @override
  State<_Settle> createState() => _SettleState();
}

class _SettleState extends State<_Settle> {
  late final TextEditingController _amt = TextEditingController(text: (widget.t.amount / 100).round().toString());

  @override
  void dispose() {
    _amt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = widget.t;
    final payee = d.member(t.to);
    final upi = payee?.upi ?? '';
    final iPay = t.from == d.meId;

    int? amount() {
      final v = parseRupees(_amt.text);
      return (v == null || v <= 0) ? null : v;
    }

    void markPaid() {
      final a = amount();
      if (a == null) return;
      store.recordPayment(t.from, t.to, a);
      Navigator.pop(context);
      toast(context, 'Payment of ${inr(a)} recorded');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(iPay ? 'Pay ${payee?.name ?? ''}' : 'Record a payment', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${d.nameOf(t.from)} → ${d.nameObj(t.to)}', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(
          controller: _amt,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (iPay) ...[
          if (upi.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('${payee?.name ?? 'They'} has no UPI ID saved'),
                subtitle: const Text('Add it from Flat settings, or pay another way and mark it paid.'),
              ),
            )
          else ...[
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(upi),
                subtitle: const Text('UPI ID'),
                trailing: IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: upi));
                    toast(context, 'UPI ID copied');
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: amount() == null
                  ? null
                  : () async {
                      final uri = upiUri(pa: upi, pn: payee?.name ?? '', paise: amount()!, note: '${d.flatName} via Hisaab');
                      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (!ok && context.mounted) toast(context, 'No UPI app found. Copy the ID instead.');
                    },
              icon: const Icon(Icons.send_to_mobile),
              label: const Text('Open UPI app'),
            ),
            const SizedBox(height: 6),
            Text(
              'After paying, come back and tap "Mark as paid".',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: amount() == null ? null : markPaid,
          child: const Text('Mark as paid'),
        ),
      ],
    );
  }
}
