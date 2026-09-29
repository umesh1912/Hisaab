import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showProfileSheet(BuildContext context) => showAppSheet(context, (_) => const _ProfileSheet());

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _name = TextEditingController();
  final _locality = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    _name.text = d.name;
    _locality.text = d.locality;
  }

  @override
  void dispose() {
    _name.dispose();
    _locality.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your profile', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locality,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your locality', hintText: 'Kothrud, Pune'),
        ),
        const SizedBox(height: 6),
        Text(
          'Used for "Open in Maps" links and shared posts. Galli never stores your exact address.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () {
            StoreScope.read(context).updateProfile(_name.text, _locality.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
