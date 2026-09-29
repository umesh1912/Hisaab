import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add a place you care about (home, office, parents), or edit one when [index] is given.
Future<void> showAreaSheet(BuildContext context, {int? index}) =>
    showAppSheet(context, (_) => _AreaSheet(index: index));

class _AreaSheet extends StatefulWidget {
  const _AreaSheet({this.index});
  final int? index;

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  final _name = TextEditingController();
  double radius = 1.0;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final i = widget.index;
    final areas = StoreScope.read(context).data?.areas ?? [];
    if (i != null && i >= 0 && i < areas.length) {
      _name.text = areas[i].name;
      radius = radiusOptions.contains(areas[i].radiusKm) ? areas[i].radiusKm : 1.0;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'Give the place a name, like "Office · Hinjewadi".');
      return;
    }
    final store = StoreScope.read(context);
    final i = widget.index;
    if (i == null) {
      store.addArea(name, radius);
    } else {
      store.updateArea(i, name, radius);
    }
    Navigator.pop(context);
    toast(context, i == null ? '$name added.' : 'Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final i = widget.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(i == null ? 'Add an area' : 'Edit area', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          "Home, office or your parents' place. Use a landmark or locality, not your exact address.",
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name and locality', hintText: 'Office · Hinjewadi Phase 1'),
        ),
        const SizedBox(height: 14),
        Text('Alerts within', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        KmPicker(options: radiusOptions, value: radius, onChanged: (v) => setState(() => radius = v)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _save,
          child: Text(i == null ? 'Add area' : 'Save'),
        ),
        if (i != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => openExternal(context, mapsUrl(_name.text.split('·').last.trim(), '')),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Maps'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: cs.error),
                onPressed: () {
                  Navigator.pop(context);
                  store.deleteArea(i);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
