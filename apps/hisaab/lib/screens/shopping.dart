import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/add_expense.dart';
import '../ui.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    StoreScope.read(context).addItem(t);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final open = d.list.where((i) => !i.done).toList();
    final bought = d.list.where((i) => i.done).toList();
    final myBought = bought.where((i) => i.boughtBy == d.meId).length;

    Widget item(ListItem i) => Dismissible(
          key: ValueKey(i.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: cs.errorContainer,
            child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
          ),
          onDismissed: (_) => store.removeItem(i.id),
          child: CheckboxListTile(
            value: i.done,
            onChanged: (_) => store.toggleItem(i.id),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              i.name,
              style: i.done ? TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant) : null,
            ),
            subtitle: Text(i.done ? 'Bought by ${d.nameOf(i.boughtBy ?? '')}' : 'Added by ${d.nameOf(i.by)}'),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add an item, e.g. Milk', prefixIcon: Icon(Icons.add)),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('Add')),
            ],
          ),
        ),
        if (myBought > 0)
          Card(
            color: cs.tertiaryContainer,
            child: ListTile(
              leading: Icon(Icons.receipt_outlined, color: cs.onTertiaryContainer),
              title: Text('You bought $myBought item${myBought == 1 ? '' : 's'}', style: TextStyle(color: cs.onTertiaryContainer)),
              subtitle: Text('Log the bill so everyone chips in', style: TextStyle(color: cs.onTertiaryContainer)),
              trailing: FilledButton(
                onPressed: () => showAddExpense(
                  context,
                  presetDesc: 'Groceries',
                  presetCat: 'food',
                  clearMyBoughtItems: true,
                ),
                child: const Text('Log bill'),
              ),
            ),
          ),
        if (d.list.isEmpty)
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'The list is empty',
            body: 'Add what the flat needs. Whoever goes to the shop ticks it off.',
          ),
        if (open.isNotEmpty) ...[
          SectionTitle('To buy · ${open.length}'),
          for (final i in open) item(i),
        ],
        if (bought.isNotEmpty) ...[
          SectionTitle('Bought · ${bought.length}'),
          for (final i in bought) item(i),
        ],
      ],
    );
  }
}
