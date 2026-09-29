import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Writes the counter's cash and UPI sales for a day (today by default).
Future<void> showDaySalesSheet(BuildContext context, String date) {
  return showAppSheet(context, (_) => DaySalesForm(date: date));
}

class DaySalesForm extends StatefulWidget {
  const DaySalesForm({super.key, required this.date});
  final String date;

  @override
  State<DaySalesForm> createState() => _DaySalesFormState();
}

class _DaySalesFormState extends State<DaySalesForm> {
  final _cash = TextEditingController();
  final _upi = TextEditingController();
  late String date = widget.date;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _load();
  }

  void _load() {
    final s = StoreScope.read(context).data?.sales[date];
    _cash.text = s == null || s.cash == 0 ? '' : rupeesField(s.cash);
    _upi.text = s == null || s.upi == 0 ? '' : rupeesField(s.upi);
  }

  @override
  void dispose() {
    _cash.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(date),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      date = isoDate(picked);
      error = null;
      _load();
    });
  }

  void _save() {
    final store = StoreScope.read(context);
    final en = store.en;
    final cash = _cash.text.trim().isEmpty ? 0 : parseRupees(_cash.text);
    final upi = _upi.text.trim().isEmpty ? 0 : parseRupees(_upi.text);
    if (cash == null || upi == null) {
      setState(() => error = en ? 'Check the amounts.' : 'रकम जाँचें।');
      return;
    }
    store.setSales(date, cash: cash, upi: upi);
    Navigator.pop(context);
    toast(context, '${en ? 'Sales saved' : 'बिक्री सेव हुई'}: ${inr(cash + upi)}');
  }

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cash = parseRupees(_cash.text) ?? 0;
    final upi = parseRupees(_upi.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(en ? 'Counter sales' : 'काउंटर बिक्री', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.event_outlined, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${dayShort(date, en)}, ${dateLabel(date, en)} (${relativeDay(date, todayIso(), en)})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: _pickDate, child: Text(en ? 'Change' : 'बदलें')),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('sales-cash'),
          controller: _cash,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: en ? 'Cash' : 'नकद', prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('sales-upi'),
          controller: _upi,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'UPI', prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Text('${en ? 'Total' : 'कुल'}: ${inrExact(cash + upi)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          en ? 'Don\'t include udhaar here. Credit and collections come from the khata.' : 'उधार यहाँ न जोड़ें। उधार और वसूली खाते से आते हैं।',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('sales-save'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: Text(en ? 'Save' : 'सेव करें'),
        ),
      ],
    );
  }
}
