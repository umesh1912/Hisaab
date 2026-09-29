import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'plant_form.dart';
import 'problem.dart';
import 'soil_check.dart';

Future<void> showPlantDetail(BuildContext context, int plantId) =>
    showAppSheet(context, (_) => _PlantDetail(plantId: plantId));

const _eventLabels = {
  'water': 'Watered',
  'damp': 'Soil was damp, waited',
  'feed': 'Fed',
  'treat': 'Treated',
};

class _PlantDetail extends StatelessWidget {
  const _PlantDetail({required this.plantId});
  final int plantId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final p = d?.plant(plantId);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (d == null || p == null) return const Padding(padding: EdgeInsets.all(24), child: Text('This plant was removed.'));
    final today = todayIso();
    final plan = store.planOf(p);
    final eff = effectiveEvery(p.every, d.season);
    final history = store.historyOf(p.id).take(6).toList();

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
                  Text(p.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  if (p.sci.isNotEmpty) Text(p.sci, style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
                  Text(p.place, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Pill(healthLabels[p.health] ?? 'Healthy', tone: p.health),
            Pill(exposures[p.exposure] ?? ''),
            if (d.pets && p.pet == 'toxic') const Pill('Not pet-safe', tone: 'sick'),
          ],
        ),
        const SizedBox(height: 12),
        InfoRow('Water', 'about every ${plural(eff, 'day')} (${seasons[d.season]})'),
        InfoRow('Last watered', relDay(today, p.last)),
        InfoRow('Next check', relDay(today, nextDue(p, d.season))),
        InfoRow('Today', plan.reason),
        if (p.feedEvery > 0)
          InfoRow('Feeding', 'every ${plural(p.feedEvery, 'day')}${p.lastFed == null ? '' : ' · last ${shortDate(p.lastFed!)}'}'),
        if (p.treating) InfoRow('Treatment', '${p.treatNote} · next ${relDay(today, p.treatNext!)}, until ${shortDate(p.treatUntil!)}'),
        if (d.pets)
          InfoRow('Pets', petLabels[p.pet] ?? '', valueColor: p.pet == 'toxic' ? badColor(context) : null),
        const SizedBox(height: 8),
        if (p.tip.isNotEmpty) NoteBox(p.tip, margin: const EdgeInsets.only(bottom: 8)),
        if (p.issue.isNotEmpty) NoteBox(p.issue, tone: 'bad', margin: const EdgeInsets.only(bottom: 8)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => showSoilCheck(context, p.id),
              icon: const Icon(Icons.water_drop),
              label: const Text('Water'),
            ),
            OutlinedButton.icon(
              onPressed: () => showProblemFinder(context, plantId: p.id),
              icon: const Icon(Icons.healing_outlined),
              label: const Text('Something wrong?'),
            ),
            OutlinedButton.icon(
              onPressed: () => showPlantForm(context, plantId: p.id),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            if (p.treating)
              TextButton(
                onPressed: () {
                  store.stopTreatment(p.id);
                  toast(context, 'Treatment reminders stopped');
                },
                child: const Text('Stop treatment'),
              ),
            if (p.health != 'ok')
              TextButton(
                onPressed: () {
                  store.editPlant(p.id, (x) {
                    x.health = 'ok';
                    x.issue = '';
                  });
                  toast(context, '${p.name} marked healthy');
                },
                child: const Text('Mark healthy'),
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () async {
                final name = p.name;
                final ok = await confirm(context, 'Delete $name?', 'Delete', body: 'Its care history will be removed too.');
                if (!ok || !context.mounted) return;
                Navigator.pop(context);
                store.deletePlant(plantId);
                toast(context, '$name deleted');
              },
              child: const Text('Delete'),
            ),
          ],
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Recent care', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final e in history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.note.isEmpty ? (_eventLabels[e.type] ?? e.type) : '${_eventLabels[e.type] ?? e.type}: ${e.note}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(shortDate(e.date), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
