import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'customer_form.dart';

/// Opens the numpad entry sheet. With [entryId] it edits that entry of [customerId].
Future<void> showEntrySheet(
  BuildContext context, {
  required String kind,
  int? customerId,
  int? entryId,
  int amount = 0,
  String note = '',
}) {
  return showAppSheet(
    context,
    (_) => EntryForm(kind: kind, customerId: customerId, entryId: entryId, amount: amount, note: note),
  );
}

class EntryForm extends StatefulWidget {
  const EntryForm({super.key, required this.kind, this.customerId, this.entryId, this.amount = 0, this.note = ''});
  final String kind;
  final int? customerId;
  final int? entryId;
  final int amount; // paise, used to prefill a new entry
  final String note;

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late String kind = widget.kind;
  late int? customerId = widget.customerId;
  String digits = ''; // whole rupees typed on the numpad
  int extraPaise = 0; // paise kept from an edited entry, dropped once the amount is retyped
  final chosen = <String>{};
  final _note = TextEditingController();
  String date = todayIso();
  String? error;
  bool _init = false;

  bool get editing => widget.entryId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    var amount = widget.amount;
    var note = widget.note;
    if (editing) {
      final c = StoreScope.read(context).data!.customer(widget.customerId ?? -1);
      if (c != null) {
        for (final e in c.entries) {
          if (e.id == widget.entryId) {
            kind = e.kind;
            amount = e.amount;
            note = e.note;
            date = e.date;
          }
        }
      }
    }
    if (amount > 0) {
      digits = '${amount ~/ 100}';
      extraPaise = amount % 100;
    }
    final free = <String>[];
    for (final part in note.split(',')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      if (creditItems.contains(p) || payItems.contains(p)) {
        chosen.add(p);
      } else {
        free.add(p);
      }
    }
    _note.text = free.join(', ');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get amount => (int.tryParse(digits) ?? 0) * 100 + extraPaise;

  void _key(String k) {
    setState(() {
      extraPaise = 0;
      error = null;
      if (k == 'del') {
        if (digits.isNotEmpty) digits = digits.substring(0, digits.length - 1);
      } else {
        final next = (digits + k).replaceFirst(RegExp(r'^0+'), '');
        if (next.length <= 7) digits = next;
      }
    });
  }

  String _noteText() {
    final items = kind == 'credit' ? creditItems : payItems;
    final parts = [
      for (final i in items)
        if (chosen.contains(i)) i,
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
    ];
    return parts.join(', ');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(date),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => date = isoDate(picked));
  }

  Future<void> _newCustomer() async {
    final id = await showCustomerForm(context);
    if (id != null && mounted) setState(() => customerId = id);
  }

  void _save() {
    final store = StoreScope.read(context);
    final en = store.en;
    final cid = customerId;
    if (cid == null || store.data!.customer(cid) == null) {
      setState(() => error = en ? 'Choose a customer.' : 'ग्राहक चुनें।');
      return;
    }
    if (amount <= 0) {
      setState(() => error = en ? 'Enter an amount.' : 'रकम लिखें।');
      return;
    }
    final c = store.data!.customer(cid)!;
    final int bal;
    if (editing) {
      bal = store.updateEntry(customerId: cid, entryId: widget.entryId!, kind: kind, amount: amount, note: _noteText(), date: date);
    } else {
      bal = store.addEntry(customerId: cid, kind: kind, amount: amount, note: _noteText(), date: date);
    }
    Navigator.pop(context);
    final sign = kind == 'credit' ? '' : '+';
    toast(context, '${c.display(en)}: $sign${inrExact(amount)} · ${en ? 'balance' : 'बाकी'} ${inr(bal)}');
  }

  Future<void> _delete() async {
    final store = StoreScope.read(context);
    final en = store.en;
    final ok = await confirm(
      context,
      title: en ? 'Delete this entry?' : 'यह एंट्री हटाएँ?',
      body: en ? 'The balance will be worked out again without it.' : 'इसके बिना बाकी फिर से गिना जाएगा।',
      yes: en ? 'Delete' : 'हटाएँ',
      no: en ? 'Cancel' : 'रद्द करें',
    );
    if (!ok || !mounted) return;
    store.deleteEntry(widget.customerId!, widget.entryId!);
    Navigator.pop(context);
    toast(context, en ? 'Entry deleted' : 'एंट्री हटाई गई');
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final en = d.en;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final credit = kind == 'credit';
    final strong = credit ? dueColor(context) : goodColor(context);
    final soft = credit ? dueSoft(context) : goodSoft(context);
    final customers = [...d.customers]..sort((a, b) => a.display(en).compareTo(b.display(en)));
    final validCustomer = customerId != null && d.customer(customerId!) != null;
    final items = credit ? creditItems : payItems;

    final owner = widget.customerId == null ? null : d.customer(widget.customerId!);
    if (editing && (owner == null || !owner.entries.any((e) => e.id == widget.entryId))) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(en ? 'This entry no longer exists.' : 'यह एंट्री अब नहीं है।', textAlign: TextAlign.center),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          editing ? (en ? 'Edit entry' : 'एंट्री बदलें') : (credit ? (en ? 'Gave credit' : 'उधार दिया') : (en ? 'Got payment' : 'पैसा मिला')),
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _KindButton(label: en ? 'Gave credit' : 'उधार दिया', active: credit, color: dueColor(context), soft: dueSoft(context), onTap: () => setState(() {
              if (kind != 'credit') chosen.clear();
              kind = 'credit';
            }))),
            const SizedBox(width: 8),
            Expanded(child: _KindButton(label: en ? 'Got payment' : 'पैसा मिला', active: !credit, color: goodColor(context), soft: goodSoft(context), onTap: () => setState(() {
              if (kind != 'pay') chosen.clear();
              kind = 'pay';
            }))),
          ],
        ),
        const SizedBox(height: 12),
        if (editing)
          Text(
            en ? 'Customer: ${d.customer(customerId!)?.display(en) ?? ''}' : 'ग्राहक: ${d.customer(customerId!)?.display(en) ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          )
        else if (customers.isEmpty)
          OutlinedButton.icon(
            onPressed: _newCustomer,
            icon: const Icon(Icons.person_add_alt),
            label: Text(en ? 'Add your first customer' : 'पहला ग्राहक जोड़ें'),
          )
        else
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('cust-pick-$customerId'),
                  initialValue: validCustomer ? customerId : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: en ? 'Customer' : 'ग्राहक'),
                  hint: Text(en ? 'Choose…' : 'चुनें…'),
                  items: [
                    for (final c in customers)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.display(en)} (${inr(balanceOf(c))})', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    customerId = v;
                    error = null;
                  }),
                ),
              ),
              IconButton(
                tooltip: en ? 'New customer' : 'नया ग्राहक',
                onPressed: _newCustomer,
                icon: const Icon(Icons.person_add_alt),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
          child: SizedBox(
            height: 52,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(inrExact(amount), style: TextStyle(color: strong, fontSize: 42, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['00', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _NumKey(value: row[i], onTap: () => _key(row[i]))),
                ],
              ],
            ),
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in items)
              FilterChip(
                label: Text(i),
                selected: chosen.contains(i),
                onSelected: (v) => setState(() => v ? chosen.add(i) : chosen.remove(i)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: en ? 'Note (optional)' : 'नोट (ज़रूरी नहीं)', isDense: true),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.event_outlined, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${en ? 'Date' : 'तारीख'}: ${relativeDay(date, todayIso(), en)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(onPressed: _pickDate, child: Text(en ? 'Change' : 'बदलें')),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
          ),
        FilledButton(
          key: const ValueKey('entry-save'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: strong,
            foregroundColor: onStrong(context),
          ),
          onPressed: _save,
          child: Text(en ? 'Save' : 'सेव करें', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        if (editing) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: Text(en ? 'Delete entry' : 'एंट्री हटाएँ'),
          ),
        ],
      ],
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({required this.label, required this.active, required this.color, required this.soft, required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: active ? soft : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: active ? color : cs.outlineVariant, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: active ? color : cs.onSurface),
          ),
        ),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('key-$value'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: value == 'del'
                ? Icon(Icons.backspace_outlined, semanticLabel: isEn(context) ? 'Delete' : 'मिटाएँ')
                : Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
