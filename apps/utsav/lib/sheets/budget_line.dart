import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showBudgetLineSheet(BuildContext context, {int? id}) {
  return showAppSheet(context, (_) => BudgetLineForm(id: id));
}

class BudgetLineForm extends StatefulWidget {
  const BudgetLineForm({super.key, this.id});
  final int? id;

  @override
  State<BudgetLineForm> createState() => _BudgetLineFormState();
}

class _BudgetLineFormState extends State<BudgetLineForm> {
  final _cat = TextEditingController();
  final _est = TextEditingController();
  final _com = TextEditingController();
  final _paid = TextEditingController();
  bool missing = false;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    final id = widget.id;
    if (d == null || id == null) return;
    final b = d.line(id);
    if (b == null) {
      missing = true;
      return;
    }
    _cat.text = b.cat;
    _est.text = rupeesField(b.est);
    _com.text = rupeesField(b.com);
    _paid.text = rupeesField(b.paid);
  }

  @override
  void dispose() {
    _cat.dispose();
    _est.dispose();
    _com.dispose();
    _paid.dispose();
    super.dispose();
  }

  int? _money(TextEditingController c) => c.text.trim().isEmpty ? 0 : parseRupees(c.text);

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final cat = _cat.text.trim();
    final est = _money(_est), com = _money(_com), paid = _money(_paid);
    if (cat.isEmpty) return setState(() => error = 'Name the category.');
    final clash = d.lineFor(cat);
    if (clash != null && clash.id != widget.id) return setState(() => error = 'There is already a category called $cat.');
    if (est == null || com == null || paid == null || est < 0 || com < 0 || paid < 0) {
      return setState(() => error = 'Enter amounts in rupees, like 4,50,000.');
    }
    store.saveBudgetLine(id: widget.id, cat: cat, est: est, com: com, paid: paid);
    Navigator.pop(context);
    toast(context, widget.id == null ? '$cat added.' : '$cat saved.');
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    final ok = await confirmAction(context, title: 'Delete this category?', body: 'Vendors in it stay, but their payments will no longer count here.', action: 'Delete');
    if (!ok || !mounted) return;
    StoreScope.read(context).deleteBudgetLine(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final cs = Theme.of(context).colorScheme;
    if (d == null || missing) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This category no longer exists.'));
    }
    final isNew = widget.id == null;
    final line = isNew ? null : d.line(widget.id!);
    final vendors = line == null ? const <Vendor>[] : d.vendors.where((v) => v.cat == line.cat).toList();

    Widget money(TextEditingController c, String label, String helper) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label, prefixText: '₹ ', helperText: helper),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(isNew ? 'New category' : 'Edit category'),
        TextField(
          controller: _cat,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Category', hintText: 'Mehendi artist'),
        ),
        money(_est, 'Estimate', 'What the family planned to spend'),
        money(_com, 'Committed', 'Signed contracts and agreed amounts'),
        money(_paid, 'Paid', 'Vendor payments you record are added here'),
        if (vendors.isNotEmpty) ...[
          const FieldLabel('Vendors in this category'),
          for (final v in vendors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(v.name, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text('${inr(v.paid)} of ${inr(v.total)}', style: TextStyle(color: cs.onSurfaceVariant)),
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
          child: Text(isNew ? 'Add category' : 'Save category'),
        ),
        if (!isNew) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete category'),
          ),
        ],
      ],
    );
  }
}
