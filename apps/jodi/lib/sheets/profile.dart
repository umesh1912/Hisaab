import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showProfileSheet(BuildContext context) => showAppSheet(context, (_) => const ProfileSheet());

const pactTargets = [60, 70, 80, 90, 100];

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _me = TextEditingController();
  final _meCity = TextEditingController();
  final _partner = TextEditingController();
  final _partnerCity = TextEditingController();
  final _pact = TextEditingController();
  int target = 80;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    _me.text = d.meName;
    _meCity.text = d.meCity;
    _partner.text = d.partnerName;
    _partnerCity.text = d.partnerCity;
    _pact.text = d.pact;
    target = d.target;
  }

  @override
  void dispose() {
    _me.dispose();
    _meCity.dispose();
    _partner.dispose();
    _partnerCity.dispose();
    _pact.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    if (store.data == null) return;
    if (_me.text.trim().isEmpty || _partner.text.trim().isEmpty) {
      return setState(() => error = 'Both names are needed.');
    }
    if (_pact.text.trim().isEmpty) return setState(() => error = 'Write this week’s pact.');
    store.updateProfile(
      meName: _me.text,
      meCity: _meCity.text,
      partnerName: _partner.text,
      partnerCity: _partnerCity.text,
      pact: _pact.text,
      target: target,
    );
    Navigator.pop(context);
    toast(context, 'Saved');
  }

  @override
  Widget build(BuildContext context) {
    if (StoreScope.of(context).data == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Names and pact'),
        TextField(controller: _me, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your name')),
        const SizedBox(height: 12),
        TextField(controller: _meCity, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your city')),
        const SizedBox(height: 12),
        TextField(controller: _partner, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Partner’s name')),
        const SizedBox(height: 12),
        TextField(
          controller: _partnerCity,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Partner’s city'),
        ),
        const SizedBox(height: 20),
        Text('Weekly pact', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _pact,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(labelText: 'The forfeit', hintText: 'The one below 80% this week buys chai'),
        ),
        const SizedBox(height: 12),
        Text('Target for the week', style: tt.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final p in pactTargets)
              ChoiceChip(label: Text('$p%'), selected: target == p, onSelected: (_) => setState(() => target = p)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Keep the stakes light and playful. No money, no shame.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
