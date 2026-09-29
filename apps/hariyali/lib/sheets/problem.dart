import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Opens the symptom checker for one plant.
Future<void> showProblemFinder(BuildContext context, {int plantId = 0}) => showAppSheet(
      context,
      (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetTitle('What\'s wrong?'),
          ProblemFinder(initialPlantId: plantId),
        ],
      ),
    );

Future<void> showProblemDetail(BuildContext context, String problemId, {int plantId = 0}) =>
    showAppSheet(context, (_) => _ProblemDetail(problemId: problemId, plantId: plantId));

/// Match what you see on a plant against common problems. Used on the Guide tab and in a sheet.
class ProblemFinder extends StatefulWidget {
  const ProblemFinder({super.key, this.initialPlantId = 0});
  final int initialPlantId; // 0 = no particular plant

  @override
  State<ProblemFinder> createState() => _ProblemFinderState();
}

class _ProblemFinderState extends State<ProblemFinder> {
  late int plantId = widget.initialPlantId;
  final picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();
    if (plantId != 0 && d.plant(plantId) == null) plantId = 0;
    final plant = plantId == 0 ? null : d.plant(plantId);
    final matches = matchProblems(picked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.plants.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: plantId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Which plant?'),
            items: [
              const DropdownMenuItem(value: 0, child: Text('No particular plant')),
              for (final p in d.plants) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => plantId = v ?? 0),
          ),
        if (plant != null && plant.issue.isNotEmpty) NoteBox('You noted: ${plant.issue}', tone: 'bad', margin: const EdgeInsets.only(top: 10)),
        const SizedBox(height: 14),
        Text('What do you see? Pick everything that fits.', style: tt.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final e in symptoms.entries)
              FilterChip(
                label: Text(e.value),
                selected: picked.contains(e.key),
                onSelected: (on) => setState(() {
                  if (on) {
                    picked.add(e.key);
                  } else {
                    picked.remove(e.key);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (picked.isEmpty)
          NoteBox(
            'Hariyali can\'t look at photos in this version. Match what you see to common problems instead. Look under the leaves and along the stems too.',
          )
        else ...[
          Text(
            matches.isEmpty ? 'No match in the guide.' : 'Most likely first',
            style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          for (final m in matches.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showProblemDetail(context, m.problem.id, plantId: plantId),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.problem.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                '${m.score} of your ${plural(picked.length, 'sign')} match${m.score == 1 ? 'es' : ''}',
                                style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(m.problem.signs, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'This is a best guess from what you describe. If a plant keeps getting worse, ask a local nursery.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ProblemDetail extends StatefulWidget {
  const _ProblemDetail({required this.problemId, required this.plantId});
  final String problemId;
  final int plantId;

  @override
  State<_ProblemDetail> createState() => _ProblemDetailState();
}

class _ProblemDetailState extends State<_ProblemDetail> {
  late int plantId = widget.plantId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final pr = problemById(widget.problemId);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (d == null || pr == null) return const SizedBox.shrink();
    if (plantId != 0 && d.plant(plantId) == null) plantId = 0;
    final plant = plantId == 0 ? null : d.plant(plantId);
    final repeats = pr.repeatDays > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(pr.name),
        Text(pr.signs, style: tt.bodyLarge),
        const SizedBox(height: 16),
        Text('What to do', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < pr.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: cs.primaryContainer,
                  child: Text('${i + 1}', style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(pr.steps[i])),
              ],
            ),
          ),
        const SizedBox(height: 4),
        NoteBox(pr.caution, tone: 'warn'),
        if (d.plants.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: plantId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'For which plant?'),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Choose a plant')),
              for (final p in d.plants) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => plantId = v ?? 0),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: plant == null
                ? null
                : () {
                    store.startTreatment(plant.id, pr);
                    Navigator.pop(context);
                    toast(
                      context,
                      repeats
                          ? 'Added to Today: ${pr.treatment.toLowerCase()} every ${pr.repeatDays} days for ${pr.courseDays ~/ 7} weeks.'
                          : '${plant.name} marked "Keep an eye": ${pr.name}.',
                    );
                  },
            icon: Icon(repeats ? Icons.event_repeat : Icons.visibility_outlined),
            label: Text(repeats ? 'Add treatment reminders' : 'Note it on the plant'),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Start with gentle treatments. If a plant keeps getting worse, ask a local nursery.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
