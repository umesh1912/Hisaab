import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final spots = <String, List<String>>{};
    for (final p in d.plants) {
      spots.putIfAbsent(p.place, () => []).add(p.name);
    }
    final toxic = d.plants.where((p) => p.pet == 'toxic').length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const PageTitle('Your home'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(d.ownerName),
                subtitle: Text(d.location.isEmpty ? 'Add your area and city' : d.location),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => showAppSheet(context, (_) => const _ProfileSheet()),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.pets),
                title: const Text('Pets at home'),
                subtitle: const Text('Flag plants that aren\'t safe for cats and dogs'),
                value: d.pets,
                onChanged: (v) {
                  store.setPets(v);
                  toast(context, v ? 'Pet safety on. ${plural(toxic, 'plant')} flagged.' : 'Pet safety off.');
                },
              ),
              const ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Reminders'),
                subtitle: Text('This version can\'t send notifications. The Today tab shows what\'s due; the evening is a good time to check it.'),
              ),
            ],
          ),
        ),
        const SectionTitle('Season'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'summer', label: Text('Summer')),
                    ButtonSegment(value: 'monsoon', label: Text('Monsoon')),
                    ButtonSegment(value: 'winter', label: Text('Winter')),
                  ],
                  selected: {d.season},
                  onSelectionChanged: (s) => store.setSeason(s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  'Soil dries slower in the monsoon (about 1.3× the summer interval) and winter (about 1.5×). Change this when the weather turns.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (spots.isNotEmpty) ...[
          const SectionTitle('Spots in your home'),
          Card(
            child: Column(
              children: [
                for (final e in spots.entries)
                  ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value.join(', ')),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Light and whether a spot gets rain change how often each plant needs water.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
        const SectionTitle('Data'),
        Card(
          child: ListTile(
            leading: Icon(Icons.restart_alt, color: cs.error),
            title: const Text('Start over'),
            subtitle: const Text('Delete all plants and history from this phone'),
            onTap: () async {
              final ok = await confirm(context, 'Start over?', 'Delete everything', body: 'All plants, care history and trips on this phone will be deleted.');
              if (ok) store.resetAll();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Everything is stored only on this phone.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _name = TextEditingController();
  final _place = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    _name.text = d?.ownerName ?? '';
    _place.text = d?.location ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Your home'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Area and city', hintText: 'Adyar, Chennai'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final store = StoreScope.read(context);
            if (store.data == null) return;
            store.updateProfile(_name.text, _place.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
