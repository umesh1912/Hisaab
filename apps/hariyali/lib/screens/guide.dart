import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/problem.dart';
import '../sheets/species.dart';
import '../ui.dart';

/// Stands in for the prototype's photo scan: a searchable plant library and a symptom-based problem guide.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _search = TextEditingController();
  String view = 'plants';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final results = searchLibrary(_search.text);

    final children = <Widget>[
      const PageTitle('Identify or diagnose'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'plants', label: Text('Plant library')),
            ButtonSegment(value: 'problems', label: Text('Problems')),
          ],
          selected: {view},
          onSelectionChanged: (s) => setState(() => view = s.first),
        ),
      ),
    ];

    if (view == 'plants') {
      children.addAll([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search by name',
              hintText: 'Tulsi, pothos, gulab…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => setState(() => _search.clear()),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Photo identification isn\'t available in this version. Search the built-in library of ${plantLibrary.length} common Indian home and balcony plants instead.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        if (results.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'Not in the library',
            body: 'You can still add it from the Plants tab and set its care yourself.',
          ),
      ]);
      String? group;
      for (final s in results) {
        if (s.group != group) {
          group = s.group;
          children.add(SectionTitle(s.group));
        }
        final mine = d.plants.any((p) => p.speciesId == s.id);
        children.add(ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Pot(size: 40),
          title: Text(s.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${s.sci} · water about every ${plural(s.every, 'day')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mine
              ? Icon(Icons.check_circle, color: cs.primary, semanticLabel: 'In your plants')
              : (d.pets && s.pet == 'toxic' ? Icon(Icons.pets, color: badColor(context), semanticLabel: 'Not pet-safe') : null),
          onTap: () => showSpeciesDetail(context, s),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Text(
          'Pet safety follows the ASPCA toxic and non-toxic plant lists; "Not sure" means a plant isn\'t listed. If a pet chews a plant and seems unwell, call a vet.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ));
    } else {
      children.add(const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: ProblemFinder(),
      ));
    }

    return ListView(padding: const EdgeInsets.only(bottom: 32), children: children);
  }
}
