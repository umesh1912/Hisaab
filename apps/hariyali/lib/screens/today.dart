import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/plant_detail.dart';
import '../sheets/plant_form.dart';
import '../sheets/problem.dart';
import '../sheets/soil_check.dart';
import '../ui.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();

    final water = <Plant, CarePlan>{};
    final skip = <Plant, CarePlan>{};
    final done = <Plant, CarePlan>{};
    final soon = <Plant, CarePlan>{};
    for (final p in d.plants) {
      final plan = store.planOf(p);
      switch (plan.kind) {
        case 'water':
          water[p] = plan;
          break;
        case 'skip':
          skip[p] = plan;
          break;
        case 'done':
          done[p] = plan;
          break;
        default:
          if (plan.days <= 3) soon[p] = plan;
      }
    }
    final feed = d.plants.where((p) => feedDue(p, today)).toList();
    final treat = d.plants.where((p) => treatDue(p, today)).toList();
    final sick = d.plants.where((p) => p.health == 'sick' && !p.treating).toList();
    final soonList = soon.entries.toList()..sort((a, b) => a.value.days.compareTo(b.value.days));

    final n = water.length;
    final sub = [seasons[d.season] ?? '', if (d.location.isNotEmpty) d.location].join(' · ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageTitle(n > 0 ? '${plural(n, 'plant')} to water today' : 'Nothing to water today', sub: sub),
        const _WeatherCard(),
        if (d.plants.isEmpty) ...[
          const EmptyState(
            icon: Icons.local_florist_outlined,
            title: 'No plants yet',
            body: 'Add your plants and where they live. Hariyali works out which need water each day.',
          ),
          Center(
            child: FilledButton.icon(
              onPressed: () => showPlantForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add your first plant'),
            ),
          ),
        ],
        if (water.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (final e in water.entries)
                  _TaskRow(
                    plant: e.key,
                    why: '${e.key.place} · ${e.value.reason}',
                    trailing: FilledButton.icon(
                      key: Key('water-${e.key.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: waterColor(context),
                        foregroundColor: onWaterColor(context),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => showSoilCheck(context, e.key.id),
                      icon: const Icon(Icons.water_drop, size: 18),
                      label: const Text('Water'),
                    ),
                  ),
              ],
            ),
          ),
        if (skip.isNotEmpty) ...[
          const SectionTitle('Skipped for rain', trailing: 'checked again tomorrow'),
          Card(
            child: Column(
              children: [
                for (final e in skip.entries)
                  _TaskRow(
                    plant: e.key,
                    why: e.value.reason,
                    trailing: TextButton(
                      onPressed: () => showSoilCheck(context, e.key.id),
                      child: const Text('Water anyway'),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (feed.isNotEmpty || treat.isNotEmpty || sick.isNotEmpty) ...[
          const SectionTitle('Other care'),
          Card(
            child: Column(
              children: [
                for (final p in treat)
                  _TaskRow(
                    plant: p,
                    title: 'Treat ${p.name}',
                    why: '${p.treatNote} · until ${shortDate(p.treatUntil!)}',
                    trailing: OutlinedButton(
                      onPressed: () {
                        final finished = store.treatDone(p.id);
                        toast(
                          context,
                          finished
                              ? 'Treatment course finished. If ${p.name} looks better, mark it healthy in Plants.'
                              : 'Done. Next round ${relDay(todayIso(), p.treatNext ?? todayIso())}.',
                        );
                      },
                      child: const Text('Done'),
                    ),
                  ),
                for (final p in feed)
                  _TaskRow(
                    plant: p,
                    title: 'Feed ${p.name}',
                    why: 'A handful of compost or diluted liquid fertiliser',
                    trailing: OutlinedButton(
                      onPressed: () {
                        store.markFed(p.id);
                        toast(context, 'Fed. Next feed in ${plural(p.feedEvery, 'day')}.');
                      },
                      child: const Text('Done'),
                    ),
                  ),
                for (final p in sick)
                  _TaskRow(
                    plant: p,
                    title: 'Treat ${p.name}',
                    why: p.issue.isEmpty ? 'Marked as needing care' : p.issue,
                    whyColor: badColor(context),
                    trailing: FilledButton.tonal(
                      onPressed: () => showProblemFinder(context, plantId: p.id),
                      child: const Text('Find cause'),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (done.isNotEmpty) ...[
          const SectionTitle('Done today'),
          Card(
            child: Column(
              children: [
                for (final e in done.entries)
                  _TaskRow(
                    plant: e.key,
                    why: e.value.reason,
                    trailing: Icon(Icons.check_circle, color: waterColor(context)),
                  ),
              ],
            ),
          ),
        ],
        if (soonList.isNotEmpty) ...[
          const SectionTitle('Coming up'),
          Card(
            child: Column(
              children: [
                for (final e in soonList)
                  _TaskRow(
                    plant: e.key,
                    why: e.key.place,
                    trailing: Text(
                      relDay(today, nextDue(e.key, d.season)),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (d.plants.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NoteBox(
              'Hariyali doesn\'t send notifications. Check this list each evening, when it\'s cooler and a good time to water.',
            ),
          ),
      ],
    );
  }
}

/// Manual weather: the app has no forecast feed, so the owner sets today's conditions.
class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final w = store.weatherToday;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final rain = w?.rain ?? false;
    final hot = w?.hot ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(rain ? Icons.umbrella : (hot ? Icons.wb_sunny : Icons.cloud_outlined), color: cs.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Today\'s weather', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  key: const Key('rain-chip'),
                  avatar: const Icon(Icons.water_drop_outlined, size: 18),
                  label: const Text('Rain coming (5 mm+)'),
                  selected: rain,
                  onSelected: (v) => store.setWeather(rain: v, hot: hot),
                ),
                FilterChip(
                  key: const Key('hot-chip'),
                  avatar: const Icon(Icons.thermostat, size: 18),
                  label: const Text('Hot day (33°C+)'),
                  selected: hot,
                  onSelected: (v) => store.setWeather(rain: rain, hot: v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              w == null
                  ? 'Not set today. Hariyali doesn\'t fetch forecasts, so check your weather app and tap what applies.'
                  : 'Set for today. Rain skips open-balcony plants; hot days move watering to the evening.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.plant, required this.why, required this.trailing, this.title, this.whyColor});
  final Plant plant;
  final String why;
  final Widget trailing;
  final String? title;
  final Color? whyColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => showPlantDetail(context, plant.id),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            const Pot(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    why,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: whyColor ?? cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
