import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'plant_form.dart';

/// Care guide for one plant in the built-in library.
Future<void> showSpeciesDetail(BuildContext context, Species s) =>
    showAppSheet(context, (ctx) => _SpeciesDetail(species: s, outer: context));

class _SpeciesDetail extends StatelessWidget {
  const _SpeciesDetail({required this.species, required this.outer});
  final Species species;
  final BuildContext outer; // the screen that opened the sheet, used to open the next one

  @override
  Widget build(BuildContext context) {
    final s = species;
    final d = StoreScope.of(context).data;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final season = d?.season ?? 'summer';
    final eff = effectiveEvery(s.every, season);
    final mine = d == null ? 0 : d.plants.where((p) => p.speciesId == s.id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Pot(size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(s.sci, style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
                  if (s.aka.isNotEmpty) Text(s.aka, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoRow('Group', s.group),
        InfoRow('Light', lightLabels[s.light] ?? ''),
        InfoRow('Good spot', exposures[s.exposure] ?? ''),
        InfoRow('Water', 'about every ${plural(s.every, 'day')} in summer${season == 'summer' ? '' : '; about ${plural(eff, 'day')} in the ${seasons[season]!.toLowerCase()}'}'),
        InfoRow('Feeding', s.feedEvery == 0 ? 'Rarely needed' : (s.feedEvery == 14 ? 'Every 2 weeks in the growing season' : 'Monthly in the growing season')),
        InfoRow('Pets', petLabels[s.pet] ?? '', valueColor: s.pet == 'toxic' ? badColor(context) : null),
        const SizedBox(height: 8),
        NoteBox(s.water, margin: const EdgeInsets.only(bottom: 8)),
        NoteBox(s.tip),
        const SizedBox(height: 8),
        Text(
          'Intervals are starting points for a typical pot. Small pots, sun and wind dry soil faster; the soil check is the final word.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            Navigator.pop(context);
            showPlantForm(outer, species: s);
          },
          icon: const Icon(Icons.add),
          label: Text(mine > 0 ? 'Add another ${s.name}' : 'Add to my plants'),
        ),
      ],
    );
  }
}
