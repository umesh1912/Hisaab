import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showReadingSheet(BuildContext context) => showAppSheet(context, (_) => const _ReadingSheet());

class _ReadingSheet extends StatefulWidget {
  const _ReadingSheet();

  @override
  State<_ReadingSheet> createState() => _ReadingSheetState();
}

class _ReadingSheetState extends State<_ReadingSheet> {
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _sugar = TextEditingController();
  String kind = 'bp';
  String? error;

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _sugar.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final p = store.current;
    if (kind == 'bp') {
      final s = int.tryParse(_sys.text.trim());
      final d = int.tryParse(_dia.text.trim());
      final e = checkBp(s, d);
      if (e != null || s == null || d == null) return setState(() => error = e);
      store.addReading(p.id, 'bp', s, d);
    } else {
      final v = int.tryParse(_sugar.text.trim());
      final e = checkSugar(v);
      if (e != null || v == null) return setState(() => error = e);
      store.addReading(p.id, 'sugar', v, 0);
    }
    Navigator.pop(context);
    toast(context, "Reading saved. It's in the doctor summary.");
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Add a reading for ${store.current.name}'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final k in const ['bp', 'sugar'])
              ChoiceChip(
                label: Text(k == 'bp' ? 'Blood pressure' : 'Fasting sugar'),
                selected: kind == k,
                onSelected: (_) => setState(() {
                  kind = k;
                  error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (kind == 'bp')
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sys,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Upper', hintText: '126'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _dia,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lower', hintText: '80'),
                ),
              ),
            ],
          )
        else
          TextField(
            controller: _sugar,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'mg/dL', hintText: '116'),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: const Text('Save reading'),
        ),
      ],
    );
  }
}
