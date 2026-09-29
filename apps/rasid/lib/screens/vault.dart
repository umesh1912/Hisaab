import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/item_sheet.dart';
import '../ui.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final list = filterItems(d.items, query: store.vaultQuery, cat: store.vaultCat, show: store.vaultShow, today: today);
    final cats = <String>[];
    for (final i in d.items) {
      if (!cats.contains(i.cat)) cats.add(i.cat);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextFormField(
            key: ValueKey('vault-search-${store.searchEpoch}'),
            initialValue: store.vaultQuery,
            onChanged: store.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Brand, model, serial, shop…',
              suffixIcon: store.vaultQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => store.searchVault(''),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'covered', label: Text('Covered')),
              ButtonSegment(value: 'out', label: Text('Expired')),
            ],
            selected: {store.vaultShow},
            onSelectionChanged: (s) => store.setVaultShow(s.first),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final c in ['all', ...cats])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c == 'all' ? 'All' : (categories[c] ?? c)),
                    selected: store.vaultCat == c,
                    showCheckmark: false,
                    onSelected: (_) => store.setVaultCat(c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                d.items.isEmpty ? 'No bills yet. Tap "Add bill" to save your first one.' : 'Nothing matches. Try the serial number or the shop name.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          )
        else
          ListCard(children: [for (final i in list) ItemRow(item: i, onTap: () => showItemSheet(context, i.id))]),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Sorted by the warranty that ends first. Items with more than one warranty, like a compressor, show the next one to end.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
