import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showPaymentSheet(BuildContext context, int vendorId) {
  return showAppSheet(context, (_) => PaymentForm(vendorId: vendorId));
}

class PaymentForm extends StatefulWidget {
  const PaymentForm({super.key, required this.vendorId});
  final int vendorId;

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _amount = TextEditingController();
  String method = paymentMethods.first;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final v = StoreScope.read(context).data?.vendor(widget.vendorId);
    if (v == null) return;
    final suggested = v.hasNext ? v.nextAmount! : v.left;
    if (suggested > 0) _amount.text = rupeesField(suggested);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final v = store.data?.vendor(widget.vendorId);
    if (v == null) return;
    final a = parseRupees(_amount.text);
    if (a == null || a <= 0) return setState(() => error = 'Enter the amount paid.');
    if (a > v.left) return setState(() => error = 'Only ${inrExact(v.left)} is left on this contract.');
    final applied = store.recordPayment(v.id, a, method);
    Navigator.pop(context);
    final rest = v.left;
    toast(context, '${inr(applied)} recorded for ${v.name}. ${rest > 0 ? '${inr(rest)} left to pay.' : 'Fully paid.'}');
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final v = d?.vendor(widget.vendorId);
    final cs = Theme.of(context).colorScheme;
    if (d == null || v == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This vendor no longer exists.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Payment to ${v.name}'),
        SummaryBox(rows: [
          ('Contract', inr(v.total)),
          ('Paid so far', inr(v.paid)),
          ('Left to pay', inr(v.left)),
          if (v.hasNext) ('Next due', '${inr(v.nextAmount!)} on ${shortDate(v.nextDue!)}'),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(labelText: 'Amount paid', prefixText: '₹ '),
        ),
        const FieldLabel('How'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in paymentMethods)
              ChoiceChip(label: Text(m), selected: method == m, onSelected: (_) => setState(() => method = m)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          d.lineFor(v.cat) == null
              ? 'Dated today.'
              : 'Dated today and added to the ${v.cat} budget. If this pays less than the instalment, the rest stays due on the same date.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Save payment'),
        ),
      ],
    );
  }
}
