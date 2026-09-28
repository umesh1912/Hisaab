import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showAddChore(BuildContext context) => showAppSheet(context, (_) => const _AddChore());

class _AddChore extends StatefulWidget {
  const _AddChore();

  @override
  State<_AddChore> createState() => _AddChoreState();
}

class _AddChoreState extends State<_AddChore> {
  final _name = TextEditingController();
  int every = 1;
  String? first;
  String? error;

  static const _presets = ['Take out the trash', 'Wash the dishes', 'Refill water cans', 'Clean the bathroom', 'Sweep and mop'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tt = Theme.of(context).textTheme;
    first ??= d.meId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add chore', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Chore'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final p in _presets) ActionChip(label: Text(p), onPressed: () => setState(() => _name.text = p)),
          ],
        ),
        const SizedBox(height: 16),
        Text('How often', style: tt.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Daily')),
            ButtonSegment(value: 2, label: Text('2 days')),
            ButtonSegment(value: 3, label: Text('3 days')),
            ButtonSegment(value: 7, label: Text('Weekly')),
          ],
          selected: {every},
          onSelectionChanged: (s) => setState(() => every = s.first),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: first,
          decoration: const InputDecoration(labelText: 'Who starts'),
          items: [for (final m in d.members) DropdownMenuItem(value: m.id, child: Text(d.nameOf(m.id)))],
          onChanged: (v) => setState(() => first = v),
        ),
        const SizedBox(height: 8),
        Text('Everyone takes turns in order. People marked away are skipped.', style: tt.bodySmall),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return setState(() => error = 'Name the chore.');
            store.addChore(n, every, first!);
            Navigator.pop(context);
            toast(context, '$n added');
          },
          child: const Text('Save chore'),
        ),
      ],
    );
  }
}
