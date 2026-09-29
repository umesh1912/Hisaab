import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Adds a plant (optionally prefilled from the library) or edits an existing one.
Future<void> showPlantForm(BuildContext context, {int? plantId, Species? species}) =>
    showAppSheet(context, (_) => _PlantForm(plantId: plantId, species: species));

class _PlantForm extends StatefulWidget {
  const _PlantForm({this.plantId, this.species});
  final int? plantId;
  final Species? species;

  @override
  State<_PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends State<_PlantForm> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _sci = TextEditingController();
  final _place = TextEditingController();
  final _issue = TextEditingController();
  final _tip = TextEditingController();
  String speciesId = '';
  String exposure = 'indoor';
  int every = 3;
  String last = todayIso();
  String health = 'ok';
  String pet = 'unknown';
  int feedEvery = 0;
  String? error;
  bool _init = false;
  int _formVersion = 0; // bumps when a library pick changes dropdown values

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final id = widget.plantId;
    final p = id == null ? null : StoreScope.read(context).data?.plant(id);
    if (p != null) {
      _name.text = p.name;
      _sci.text = p.sci;
      _place.text = p.place;
      _issue.text = p.issue;
      _tip.text = p.tip;
      speciesId = p.speciesId;
      exposure = p.exposure;
      every = p.every;
      last = p.last;
      health = p.health;
      pet = p.pet;
      feedEvery = p.feedEvery;
    } else if (widget.species != null) {
      _apply(widget.species!);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _sci.dispose();
    _place.dispose();
    _issue.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _apply(Species s) {
    speciesId = s.id;
    _name.text = s.name;
    _sci.text = s.sci;
    _tip.text = s.tip;
    exposure = s.exposure;
    every = s.every;
    pet = s.pet;
    feedEvery = s.feedEvery;
    _formVersion++;
  }

  Future<void> _pickLast() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, now.month, now.day);
    var initial = parseIso(last);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(now)) initial = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
      helpText: 'Last watered',
    );
    if (picked != null) setState(() => last = isoDate(picked));
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final name = _name.text.trim();
    final place = _place.text.trim();
    if (name.isEmpty) return setState(() => error = 'Give the plant a name.');
    if (place.isEmpty) return setState(() => error = 'Say where it lives, e.g. "Balcony (west, open)".');
    final issue = health == 'ok' ? '' : _issue.text.trim();
    final id = widget.plantId;
    if (id != null && d.plant(id) != null) {
      store.editPlant(id, (p) {
        if (p.last != last || p.every != every) p.nextCheck = null;
        p.name = name;
        p.sci = _sci.text.trim();
        p.speciesId = speciesId;
        p.place = place;
        p.exposure = exposure;
        p.every = every;
        p.last = last;
        p.health = health;
        p.issue = issue;
        p.tip = _tip.text.trim();
        p.pet = pet;
        if (p.feedEvery != feedEvery && feedEvery > 0) p.lastFed ??= todayIso();
        p.feedEvery = feedEvery;
      });
      Navigator.pop(context);
      toast(context, '$name saved');
    } else {
      store.addPlant(Plant(
        id: d.newId(),
        name: name,
        sci: _sci.text.trim(),
        speciesId: speciesId,
        place: place,
        exposure: exposure,
        every: every,
        last: last,
        health: health,
        issue: issue,
        tip: _tip.text.trim(),
        pet: pet,
        feedEvery: feedEvery,
        lastFed: feedEvery > 0 ? todayIso() : null,
      ));
      Navigator.pop(context);
      toast(context, '$name added. Next check ${shortDate(addDaysIso(last, effectiveEvery(every, d.season)))}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();
    final editing = widget.plantId != null;
    final places = <String>{for (final p in d.plants) p.place}.toList();
    final results = searchLibrary(_search.text).take(6).toList();
    final feedOptions = <int>{0, 14, 30, feedEvery}.toList()..sort();
    final today = todayIso();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(editing ? 'Edit plant' : 'Add a plant'),
        if (!editing) ...[
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Search the plant library',
              hintText: 'Tulsi, money plant, rose…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final s in results)
                ChoiceChip(
                  label: Text(s.name),
                  selected: speciesId == s.id,
                  onSelected: (_) => setState(() => _apply(s)),
                ),
              if (results.isEmpty) Text('Not in the library. Fill in the details below.', style: tt.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Photo identification isn\'t available in this version. Pick from the library to fill in typical care, then adjust.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _sci, decoration: const InputDecoration(labelText: 'Scientific name (optional)')),
        const SizedBox(height: 12),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Where it lives', hintText: 'Balcony (west, open)'),
        ),
        if (places.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [for (final pl in places) ActionChip(label: Text(pl), onPressed: () => setState(() => _place.text = pl))],
          ),
        ],
        const SizedBox(height: 16),
        Text('Does rain reach it?', style: tt.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'indoor', label: Text('Indoors')),
            ButtonSegment(value: 'covered', label: Text('Covered')),
            ButtonSegment(value: 'open', label: Text('Open')),
          ],
          selected: {exposure},
          onSelectionChanged: (s) => setState(() => exposure = s.first),
        ),
        const SizedBox(height: 4),
        Text(
          exposure == 'open'
              ? 'Skipped on days you mark rain as expected.'
              : (exposure == 'covered' ? 'Gets sun and heat but no rain.' : 'Indoors: no rain, no hot-day tips.'),
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Water about every', style: tt.titleSmall),
                  Text('in summer; Hariyali stretches it in the monsoon and winter', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Less often',
              onPressed: every > 1 ? () => setState(() => every--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(width: 52, child: Text(plural(every, 'day'), textAlign: TextAlign.center, style: tt.titleSmall)),
            IconButton(
              tooltip: 'More often',
              onPressed: every < 60 ? () => setState(() => every++) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: const Text('Last watered'),
          subtitle: Text(relDay(today, last)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: _pickLast,
        ),
        const SizedBox(height: 8),
        Text('Health', style: tt.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'ok', label: Text('Healthy')),
            ButtonSegment(value: 'watch', label: Text('Watch')),
            ButtonSegment(value: 'sick', label: Text('Sick')),
          ],
          selected: {health},
          onSelectionChanged: (s) => setState(() => health = s.first),
        ),
        if (health != 'ok') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _issue,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What do you see?', hintText: 'White spots under leaves'),
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('pet$_formVersion'),
          initialValue: pet,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Safe for cats and dogs?'),
          items: [
            for (final e in petLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => pet = v ?? 'unknown'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('feed$_formVersion'),
          initialValue: feedEvery,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Feeding reminder'),
          items: [
            for (final f in feedOptions)
              DropdownMenuItem(
                value: f,
                child: Text(f == 0 ? 'Off' : (f == 14 ? 'Every 2 weeks' : (f == 30 ? 'Monthly' : 'Every $f days'))),
              ),
          ],
          onChanged: (v) => setState(() => feedEvery = v ?? 0),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tip,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Care tip (optional)'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: const Text('Save plant'),
        ),
      ],
    );
  }
}
