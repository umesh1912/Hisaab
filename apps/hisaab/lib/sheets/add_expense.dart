import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showAddExpense(
  BuildContext context, {
  String presetDesc = '',
  String presetCat = 'food',
  bool clearMyBoughtItems = false,
}) {
  return showAppSheet(
    context,
    (_) => AddExpenseForm(presetDesc: presetDesc, presetCat: presetCat, clearMyBoughtItems: clearMyBoughtItems),
  );
}

class AddExpenseForm extends StatefulWidget {
  const AddExpenseForm({super.key, required this.presetDesc, required this.presetCat, required this.clearMyBoughtItems});
  final String presetDesc;
  final String presetCat;
  final bool clearMyBoughtItems;

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  late final TextEditingController _desc = TextEditingController(text: widget.presetDesc);
  final _amount = TextEditingController();
  late String cat = widget.presetCat;
  String mode = 'equal';
  String? paidBy;
  bool repeat = false;
  final included = <String>{};
  final exact = <String, TextEditingController>{};
  final weights = <String, int>{};
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data!;
    paidBy = d.meId;
    for (final m in d.members) {
      if (!m.away) included.add(m.id);
      exact[m.id] = TextEditingController();
      weights[m.id] = 1;
    }
    if (included.isEmpty) included.addAll(d.members.map((m) => m.id));
  }

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    for (final c in exact.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? get amount => parseRupees(_amount.text);

  Map<String, int>? _shares() {
    final a = amount;
    if (a == null || a <= 0) return null;
    switch (mode) {
      case 'exact':
        final out = <String, int>{};
        for (final e in exact.entries) {
          final t = e.value.text.trim();
          if (t.isEmpty) continue;
          final v = parseRupees(t);
          if (v == null || v < 0) return null;
          if (v > 0) out[e.key] = v;
        }
        return out;
      case 'shares':
        return weightedShares(a, Map.of(weights));
      default:
        return equalShares(a, included.toList());
    }
  }

  void _save() {
    final store = StoreScope.read(context);
    final desc = _desc.text.trim();
    final a = amount;
    if (desc.isEmpty) return setState(() => error = 'What was it for?');
    if (a == null || a <= 0) return setState(() => error = 'Enter an amount.');
    final shares = _shares();
    if (shares == null || shares.isEmpty) return setState(() => error = 'Pick who this is split between.');
    final sum = shares.values.fold<int>(0, (x, y) => x + y);
    if (sum != a) {
      return setState(() => error = 'Exact amounts add up to ${inrExact(sum)}, not ${inrExact(a)}.');
    }
    store.addExpense(
      desc: desc,
      amount: a,
      paidBy: paidBy!,
      shares: shares,
      mode: mode,
      cat: cat,
      repeatMonthly: repeat,
      clearMyBoughtItems: widget.clearMyBoughtItems,
    );
    Navigator.pop(context);
    toast(context, '$desc added');
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final a = amount ?? 0;

    Widget splitRows() {
      switch (mode) {
        case 'exact':
          final sum = exact.values.fold<int>(0, (x, c) => x + (parseRupees(c.text) ?? 0));
          final left = a - sum;
          return Column(
            children: [
              for (final m in d.members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Avatar(id: m.id, name: m.name, size: 30),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d.nameOf(m.id))),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: exact[m.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(prefixText: '₹ ', isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  left == 0 ? 'Adds up' : (left > 0 ? '${inrExact(left)} left' : '${inrExact(-left)} too much'),
                  style: TextStyle(color: left == 0 ? cs.primary : cs.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        case 'shares':
          final preview = a > 0 ? weightedShares(a, Map.of(weights)) : <String, int>{};
          return Column(
            children: [
              for (final m in d.members)
                Row(
                  children: [
                    Avatar(id: m.id, name: m.name, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d.nameOf(m.id))),
                    if (a > 0) Text(inr(preview[m.id] ?? 0), style: TextStyle(color: cs.onSurfaceVariant)),
                    IconButton(
                      onPressed: (weights[m.id] ?? 0) > 0 ? () => setState(() => weights[m.id] = weights[m.id]! - 1) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(width: 20, child: Text('${weights[m.id]}', textAlign: TextAlign.center)),
                    IconButton(
                      onPressed: () => setState(() => weights[m.id] = (weights[m.id] ?? 0) + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
            ],
          );
        default:
          final each = included.isEmpty ? 0 : a ~/ included.length;
          return Column(
            children: [
              for (final m in d.members)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: included.contains(m.id),
                  onChanged: (v) => setState(() => v == true ? included.add(m.id) : included.remove(m.id)),
                  secondary: Avatar(id: m.id, name: m.name, size: 30, dimmed: m.away),
                  title: Text(d.nameOf(m.id) + (m.away ? ' (away)' : '')),
                  subtitle: included.contains(m.id) && a > 0 ? Text(inr(each)) : null,
                ),
            ],
          );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add expense', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _desc,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What for?', hintText: 'Electricity bill'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in categories.entries)
              ChoiceChip(
                avatar: Icon(categoryIcons[c.key], size: 18),
                label: Text(c.value),
                selected: cat == c.key,
                onSelected: (_) => setState(() => cat = c.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: paidBy,
          decoration: const InputDecoration(labelText: 'Paid by'),
          items: [for (final m in d.members) DropdownMenuItem(value: m.id, child: Text(d.nameOf(m.id)))],
          onChanged: (v) => setState(() => paidBy = v),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'equal', label: Text('Equally')),
            ButtonSegment(value: 'exact', label: Text('Exact')),
            ButtonSegment(value: 'shares', label: Text('Shares')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => setState(() => mode = s.first),
        ),
        const SizedBox(height: 8),
        splitRows(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: repeat,
          onChanged: (v) => setState(() => repeat = v),
          title: const Text('Repeats every month'),
          subtitle: const Text('Get a reminder to add it next month'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Save expense'),
        ),
      ],
    );
  }
}
