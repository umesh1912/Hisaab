import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'claim_sheets.dart';
import 'item_form.dart';
import 'reminder_sheet.dart';

Future<void> showItemSheet(BuildContext context, int itemId) =>
    showAppSheet(context, (_) => _ItemSheet(itemId: itemId));

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.itemId});
  final int itemId;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  bool askDelete = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final it = d?.item(widget.itemId);
    if (d == null || it == null) return const SizedBox(height: 120, child: Center(child: Text('This item was removed.')));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final s = warrantyState(it, today);
    final claims = d.claims.where((c) => c.itemId == it.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(it.title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'Edit item',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showItemForm(context, item: it),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReceiptCard(item: it),
        const SizedBox(height: 16),
        Text('Warranties', style: tt.titleSmall),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              if (it.warranties.isEmpty)
                const ListTile(title: Text('No warranty added'), subtitle: Text('Edit the item to add one')),
              for (final w in it.warranties)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('until ${longDate(w.until)}', style: TextStyle(fontFamily: mono, fontSize: 12.5, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _leftTag(daysBetween(today, w.until)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KeyValue('Room', it.room),
        KeyValue('Owner', d.nameOf(it.owner)),
        KeyValue('Category', categories[it.cat] ?? it.cat),
        KeyValue('Bought', longDate(it.date)),
        KeyValue('Serial', it.serial),
        if (s.cover == Cover.soon && s.warranty != null) ...[
          const SizedBox(height: 10),
          NoteBox(
            warn: true,
            text: 'Ends on ${shortDate(s.warranty!.until)}. If anything is wrong with it, even a small noise, get it checked before then.',
          ),
        ],
        if (claims.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Claims', style: tt.titleSmall),
          for (final c in claims)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(c.isOpen ? Icons.build_circle_outlined : Icons.check_circle_outline),
              title: Text(c.issue, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${c.isOpen ? 'Open' : 'Fixed'} · raised ${shortDate(c.started)}'),
              onTap: () {
                Navigator.pop(context);
                store.goTab(2);
              },
            ),
        ],
        if (it.repairs.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Repair history', style: tt.titleSmall),
          for (final r in it.repairs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.handyman_outlined),
              title: Text(r.note.isEmpty ? 'Paid repair' : r.note, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(longDate(r.date)),
              trailing: Text(inr(r.cost), style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w600)),
            ),
        ],
        const SizedBox(height: 16),
        if (s.cover != Cover.out)
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => showNewClaim(context, it.id),
            icon: const Icon(Icons.build_outlined),
            label: const Text("Something's wrong: start a claim"),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => showRepairForm(context, it.id),
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: const Text('Log a paid repair'),
            ),
            OutlinedButton.icon(
              onPressed: () => showReminderForm(context, itemId: it.id),
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('Service reminder'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!askDelete)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () => setState(() => askDelete = true),
            child: const Text('Remove from vault'),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Remove this item and its bill?', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onErrorContainer)),
                const SizedBox(height: 4),
                Text('Its reminders and claims will be removed too.', style: TextStyle(color: cs.onErrorContainer)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => setState(() => askDelete = false), child: const Text('Keep')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                        onPressed: () {
                          final name = it.title;
                          store.deleteItem(it.id);
                          Navigator.pop(context);
                          toast(context, '$name removed.');
                        },
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _leftTag(int d) {
    if (d < 0) return const Tag('Ended');
    if (d <= 30) return Tag('${timeLeftLabel(d)} left', tone: 'bad');
    return Tag('${timeLeftLabel(d)} left', tone: 'good');
  }
}

// ---------------- paid repair ----------------

Future<void> showRepairForm(BuildContext context, int itemId) =>
    showAppSheet(context, (_) => _RepairForm(itemId: itemId));

class _RepairForm extends StatefulWidget {
  const _RepairForm({required this.itemId});
  final int itemId;

  @override
  State<_RepairForm> createState() => _RepairFormState();
}

class _RepairFormState extends State<_RepairForm> {
  final _cost = TextEditingController();
  final _note = TextEditingController();
  String date = todayIso();
  String? error;

  @override
  void dispose() {
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Log a paid repair', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Keep the repair history, so you have it if you sell or insure this item.', style: tt.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What was fixed', hintText: 'Replaced the drain pump'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cost,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cost (₹)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final v = await pickDate(context, date);
            if (v != null) setState(() => date = v);
          },
          icon: const Icon(Icons.event),
          label: Text('On ${longDate(date)}'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () {
            final cost = parseRupees(_cost.text);
            if (cost == null || cost < 0) return setState(() => error = 'Enter what the repair cost.');
            StoreScope.read(context).addRepair(widget.itemId, Repair(date: date, cost: cost, note: _note.text.trim()));
            Navigator.pop(context);
            toast(context, 'Repair saved.');
          },
          child: const Text('Save repair'),
        ),
      ],
    );
  }
}
