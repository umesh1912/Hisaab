import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/plant_detail.dart';
import '../ui.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final plants = d.plants;
    final flagged = d.pets ? plants.where((p) => p.pet == 'toxic').length : 0;

    final rows = <Widget>[];
    for (var i = 0; i < plants.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PlantCard(plant: plants[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < plants.length ? _PlantCard(plant: plants[i + 1]) : const SizedBox.shrink()),
          ],
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        PageTitle(
          plural(plants.length, 'plant'),
          sub: flagged > 0 ? '$flagged not safe for pets' : 'Tap a plant for its care and history',
        ),
        if (plants.isEmpty)
          const EmptyState(
            icon: Icons.local_florist_outlined,
            title: 'No plants yet',
            body: 'Tap "Add plant" and pick from the library, or add your own.',
          ),
        ...rows,
      ],
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final p = plant;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final plan = store.planOf(p);
    final level = plan.kind == 'done' ? 1.0 : waterLevel(p, today, d.season);
    final status = switch (plan.kind) {
      'done' => plan.reason.startsWith('Watered') ? 'Watered today' : 'Soil damp, waiting',
      'skip' => 'Skipped for rain',
      'water' => 'Water today',
      _ => 'Water in ${plural(plan.days, 'day')}',
    };
    final spot = p.place.split(' (').first;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showPlantDetail(context, p.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Pot(size: 52),
              const SizedBox(height: 6),
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(spot, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Pill(healthLabels[p.health] ?? 'Healthy', tone: p.health),
                  if (d.pets && p.pet == 'toxic') const Pill('Not pet-safe', tone: 'sick'),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: level,
                  minHeight: 6,
                  color: waterColor(context),
                  backgroundColor: cs.surfaceContainerHighest,
                  semanticsLabel: 'Water left',
                ),
              ),
              const SizedBox(height: 4),
              Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
