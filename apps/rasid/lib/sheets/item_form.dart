import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add a new bill, or edit [item]. With [paste], the paste box starts open.
Future<void> showItemForm(BuildContext context, {Item? item, bool paste = false}) =>
    showAppSheet(context, (_) => _ItemForm(item: item, paste: paste));

class _WRow {
  _WRow(String label, this.until) : label = TextEditingController(text: label);
  final TextEditingController label;
  String until;
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({this.item, this.paste = false});
  final Item? item;
  final bool paste;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _paste = TextEditingController();
  final _brand = TextEditingController();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _price = TextEditingController();
  final _store = TextEditingController();
  final _inv = TextEditingController();
  final _serial = TextEditingController();
  final _room = TextEditingController();
  String cat = 'other';
  String owner = 'me';
  String date = todayIso();
  int? months = 12; // warranty length picked for a new item; null = dates set by hand
  final rows = <_WRow>[];
  bool showPaste = false;
  String? readNote;
  Set<String> check = {};
  String? error;

  bool get editing => widget.item != null;

  static const _periods = [12, 24, 36, 60];

  @override
  void initState() {
    super.initState();
    showPaste = widget.paste;
    final it = widget.item;
    if (it != null) {
      _brand.text = it.brand;
      _name.text = it.name;
      _model.text = it.model;
      _price.text = ((it.price + 50) ~/ 100).toString();
      _store.text = it.store;
      _inv.text = it.inv;
      _serial.text = it.serial;
      _room.text = it.room;
      cat = it.cat;
      owner = it.owner;
      date = it.date;
      months = null;
      for (final w in it.warranties) {
        rows.add(_WRow(w.label, w.until));
      }
    } else {
      rows.add(_WRow('Product', warrantyEnd(date, 12)));
    }
  }

  @override
  void dispose() {
    for (final c in [_paste, _brand, _name, _model, _price, _store, _inv, _serial, _room]) {
      c.dispose();
    }
    for (final r in rows) {
      r.label.dispose();
    }
    super.dispose();
  }

  void _setMonths(int m) {
    setState(() {
      months = m;
      if (rows.isEmpty) rows.add(_WRow('Product', date));
      rows.first.until = warrantyEnd(date, m);
    });
  }

  void _readText() {
    final b = parseBillText(_paste.text);
    final found = b.found;
    setState(() {
      if (b.brand != null) _brand.text = b.brand!;
      if (b.name != null) _name.text = b.name!;
      if (b.cat != null) cat = b.cat!;
      if (b.model != null) _model.text = b.model!;
      if (b.price != null) _price.text = ((b.price! + 50) ~/ 100).toString();
      if (b.store != null) _store.text = b.store!;
      if (b.invoice != null) _inv.text = b.invoice!;
      if (b.serial != null) _serial.text = b.serial!;
      if (b.date != null) date = b.date!;
      final m = b.warrantyMonths;
      if (m != null && m > 0) {
        months = _periods.contains(m) ? m : null;
        if (rows.isEmpty) rows.add(_WRow('Product', date));
        rows.first.until = warrantyEnd(date, m);
      } else if (months != null && rows.isNotEmpty) {
        rows.first.until = warrantyEnd(date, months!);
      }
      check = {
        if (b.brand == null) 'brand',
        if (b.name == null) 'name',
        if (b.price == null) 'price',
        if (b.date == null) 'date',
        if (b.serial == null) 'serial',
        if (b.warrantyMonths == null) 'warranty',
      };
      readNote = found.isEmpty
          ? 'Could not read anything. Fill in the fields below.'
          : 'Read ${found.join(', ')}. Check the fields marked below before saving.';
    });
  }

  InputDecoration _dec(String label, String key, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: check.contains(key) ? 'Not found in the text, check this' : null,
      );

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final name = _name.text.trim();
    final price = parseRupees(_price.text);
    if (name.isEmpty || price == null || price <= 0) {
      setState(() => error = 'Check the item name and price before saving.');
      return;
    }
    final ws = <Warranty>[];
    for (final r in rows) {
      final l = r.label.text.trim();
      ws.add(Warranty(label: l.isEmpty ? 'Product' : l, until: r.until));
    }
    if (ws.any((w) => w.until.compareTo(date) < 0)) {
      setState(() => error = 'A warranty cannot end before the purchase date.');
      return;
    }
    final it = Item(
      id: widget.item?.id ?? store.newId(),
      name: name,
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      serial: _serial.text.trim(),
      cat: cat,
      room: _room.text.trim().isEmpty ? 'Home' : _room.text.trim(),
      price: price,
      date: date,
      store: _store.text.trim(),
      inv: _inv.text.trim(),
      warranties: ws,
      owner: d.member(owner) == null ? d.meId : owner,
      repairs: widget.item?.repairs ?? [],
    );
    if (editing) {
      store.updateItem(it);
      Navigator.pop(context);
      toast(context, 'Saved.');
    } else {
      store.addItem(it);
      store.searchVault('');
      Navigator.pop(context);
      final s = warrantyState(it, todayIso());
      toast(
        context,
        s.cover == Cover.out || s.warranty == null
            ? 'Saved. This one is already out of warranty.'
            : 'Saved. Covered until ${longDate(s.warranty!.until)}. It will show under the bell 30 days before.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    if (d == null) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final rooms = {...d.rooms, 'Kitchen', 'Living room', 'Bedroom'}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? 'Edit item' : 'Add a bill', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (!editing) ...[
          if (!showPaste)
            OutlinedButton.icon(
              onPressed: () => setState(() => showPaste = true),
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste bill or order email text'),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Paste the text of a bill or an order email', style: tt.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('paste-box'),
                    controller: _paste,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(hintText: 'Order ID, date, item, total…'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _readText,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Read the text'),
                  ),
                  if (readNote != null) ...[
                    const SizedBox(height: 8),
                    Text(readNote!, style: tt.bodySmall),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Rasid cannot read photos. Type the details from the bill, or paste its text. You check everything before saving.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(controller: _brand, textCapitalization: TextCapitalization.words, decoration: _dec('Brand', 'brand')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: _dec('Item', 'name')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Model')),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Price (₹)', 'price'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56), padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () async {
                  final v = await pickDate(context, date);
                  if (v == null) return;
                  setState(() {
                    date = v;
                    check.remove('date');
                    if (months != null && rows.isNotEmpty) rows.first.until = warrantyEnd(date, months!);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bought on', style: tt.labelSmall),
                    Text(longDate(date), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (check.contains('date'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Date not found in the text, check it', style: tt.bodySmall?.copyWith(color: cs.error)),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('cat-$cat'),
          initialValue: categories.containsKey(cat) ? cat : 'other',
          decoration: const InputDecoration(labelText: 'Category'),
          items: [for (final e in categories.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => setState(() => cat = v ?? 'other'),
        ),
        const SizedBox(height: 16),
        Text('Warranty', style: tt.titleSmall),
        if (!editing) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final m in _periods)
                ChoiceChip(
                  label: Text('${m ~/ 12} year${m > 12 ? 's' : ''}'),
                  selected: months == m,
                  onSelected: (_) => _setMonths(m),
                ),
            ],
          ),
          if (check.contains('warranty'))
            Text(
              "Warranty isn't in the text. Check the warranty card in the box.",
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
        ],
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: rows[i].label,
                    decoration: const InputDecoration(labelText: 'Cover', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    onPressed: () async {
                      final v = await pickDate(context, rows[i].until);
                      if (v == null) return;
                      setState(() {
                        rows[i].until = v;
                        if (i == 0) months = null;
                      });
                    },
                    child: Text('Until ${longDate(rows[i].until)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (rows.length > 1)
                  IconButton(
                    tooltip: 'Remove warranty',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final r = rows[i];
                      setState(() {
                        rows.removeAt(i);
                        if (i == 0) months = null;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) => r.label.dispose());
                    },
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              final base = rows.isEmpty ? date : rows.last.until;
              rows.add(_WRow(rows.isEmpty ? 'Product' : 'Extended', addMonthsIso(base, 12)));
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add another warranty'),
          ),
        ),
        Text('Extended, compressor or motor warranties each get their own end date.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(controller: _serial, decoration: _dec('Serial number (from the sticker)', 'serial', hint: 'e.g. HD9252-2609-1182')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _store, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Shop'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _inv, decoration: const InputDecoration(labelText: 'Invoice no.'))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _room, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Room')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final r in rooms) ActionChip(label: Text(r), onPressed: () => setState(() => _room.text = r)),
          ],
        ),
        if (d.members.length > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: d.member(owner) == null ? d.meId : owner,
            decoration: const InputDecoration(labelText: 'Owner'),
            items: [for (final m in d.members) DropdownMenuItem(value: m.id, child: Text(m.name))],
            onChanged: (v) => setState(() => owner = v ?? d.meId),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: Text(editing ? 'Save changes' : 'Save to vault'),
        ),
      ],
    );
  }
}
