import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'payment.dart';

Future<void> showVendorSheet(BuildContext context, {int? id}) {
  return showAppSheet(context, (_) => VendorForm(id: id));
}

class VendorForm extends StatefulWidget {
  const VendorForm({super.key, this.id});
  final int? id;

  @override
  State<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<VendorForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _total = TextEditingController();
  final _paid = TextEditingController();
  final _next = TextEditingController();
  final _note = TextEditingController();
  String? cat;
  late String nextDue = addDaysIso(todayIso(), 30);
  bool missing = false;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    final id = widget.id;
    if (id == null) {
      cat = d.budget.isEmpty ? null : d.budget.first.cat;
      return;
    }
    final v = d.vendor(id);
    if (v == null) {
      missing = true;
      return;
    }
    _name.text = v.name;
    _phone.text = v.phone;
    _total.text = rupeesField(v.total);
    _paid.text = rupeesField(v.paid);
    if (v.hasNext) {
      _next.text = rupeesField(v.nextAmount!);
      nextDue = v.nextDue!;
    }
    _note.text = v.note;
    cat = v.cat.isEmpty ? null : v.cat;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _total.dispose();
    _paid.dispose();
    _next.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final v = await pickIsoDate(context, nextDue);
    if (v != null) setState(() => nextDue = v);
  }

  void _save() {
    final store = StoreScope.read(context);
    if (store.data == null) return;
    final name = _name.text.trim();
    final total = parseRupees(_total.text);
    final paid = _paid.text.trim().isEmpty ? 0 : parseRupees(_paid.text);
    final next = _next.text.trim().isEmpty ? null : parseRupees(_next.text);
    if (name.isEmpty) return setState(() => error = 'Add the vendor name.');
    if (total == null || total <= 0) return setState(() => error = 'Enter the contract amount.');
    if (paid == null || paid < 0) return setState(() => error = 'Enter what has been paid so far (or leave it empty).');
    if (paid > total) return setState(() => error = 'Paid so far is more than the contract.');
    if (_next.text.trim().isNotEmpty && (next == null || next <= 0)) {
      return setState(() => error = 'Enter the next payment amount, or leave it empty.');
    }
    if (next != null && next > total - paid) return setState(() => error = 'The next payment is more than what is left (${inr(total - paid)}).');
    store.saveVendor(
      id: widget.id,
      name: name,
      cat: cat ?? '',
      phone: _phone.text.trim(),
      total: total,
      paid: paid,
      nextAmount: paid >= total ? null : next,
      nextDue: nextDue,
      note: _note.text.trim(),
    );
    Navigator.pop(context);
    toast(context, widget.id == null ? '$name added.' : '$name saved.');
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    final ok = await confirmAction(
      context,
      title: 'Delete this vendor?',
      body: 'Their payment history goes too. Amounts already added to the budget stay there.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    StoreScope.read(context).deleteVendor(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final cs = Theme.of(context).colorScheme;
    final v = widget.id == null ? null : d?.vendor(widget.id!);
    if (d == null || missing || (widget.id != null && v == null)) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This vendor no longer exists.'));
    }
    final cats = <String>[for (final b in d.budget) b.cat];
    if (cat != null && !cats.contains(cat)) cats.add(cat!);

    Widget money(TextEditingController c, String label, {String? helper}) => TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, prefixText: '₹ ', helperText: helper),
          onChanged: (_) => setState(() {}),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(v == null ? 'New vendor' : v.name, sub: v == null ? null : '${v.cat} · ${inr(v.left)} left to pay'),
        if (v != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (v.left > 0)
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context);
                      showPaymentSheet(context, v.id);
                    },
                    child: const Text('Record payment'),
                  ),
                if (v.phone.isNotEmpty)
                  OutlinedButton(
                    onPressed: () => callPhone(context, v.phone),
                    child: const IconLabel(icon: Icons.call_outlined, text: 'Call'),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Vendor', hintText: 'Shree Annapurna Caterers'),
        ),
        const SizedBox(height: 10),
        if (cats.isEmpty)
          Text('Add budget categories on the Budget tab to link vendors to them.', style: TextStyle(color: cs.onSurfaceVariant))
        else
          DropdownButtonFormField<String>(
            initialValue: cat,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Budget category'),
            items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
            onChanged: (x) => setState(() => cat = x),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 10),
        money(_total, 'Contract amount'),
        const SizedBox(height: 10),
        money(_paid, 'Paid so far', helper: v == null ? 'Advance already given, if any' : 'Correct this only if a payment was missed'),
        const SizedBox(height: 10),
        money(_next, 'Next payment (optional)'),
        if (_next.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          PickerField(label: 'Next payment due', value: '${dayName(nextDue)}, ${longDate(nextDue)}', icon: Icons.event, onTap: _pickDue),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          maxLines: null,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What was agreed', hintText: 'Menu, number of plates, what the advance covers...'),
        ),
        if (v != null && v.payments.isNotEmpty) ...[
          const FieldLabel('Payments recorded'),
          for (final p in v.payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${shortDate(p.date)} · ${p.method}', overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(inr(p.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Save vendor'),
        ),
        if (v != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete vendor'),
          ),
        ],
      ],
    );
  }
}
