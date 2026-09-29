import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add a medicine, or edit one when [medId] is given.
Future<void> showMedForm(BuildContext context, {int? medId}) {
  final store = StoreScope.read(context);
  final existing = medId == null ? null : store.data!.med(medId);
  final who = existing?.who ?? store.current.id;
  return showAppSheet(context, (_) => _MedForm(existing: existing, who: who));
}

class _MedForm extends StatefulWidget {
  const _MedForm({required this.existing, required this.who});
  final Med? existing;
  final String who;

  @override
  State<_MedForm> createState() => _MedFormState();
}

class _MedFormState extends State<_MedForm> {
  late final TextEditingController _name;
  late final TextEditingController _strength;
  late final TextEditingController _purpose;
  late final TextEditingController _stock;
  late String who;
  late Set<String> times;
  late String food;
  late String form;
  late int per;
  late int color;
  String? error;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _strength = TextEditingController(text: m?.strength ?? '');
    _purpose = TextEditingController(text: m?.purpose ?? '');
    _stock = TextEditingController(text: '${m?.stock ?? 30}');
    who = widget.who;
    times = {...(m?.times ?? const ['09:00'])};
    food = m?.food ?? 'after';
    form = m?.form ?? 'tablet';
    per = m?.per ?? 1;
    color = m?.color ?? pillColors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _purpose.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _fill(MedPreset p) {
    setState(() {
      _name.text = p.name;
      _strength.text = p.strength;
      _purpose.text = p.purpose;
      times = {...p.times};
      food = p.food;
      error = null;
    });
  }

  Future<void> _otherTime() async {
    final t = await pickTime(context, '12:00');
    if (t != null) setState(() => times.add(t));
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data!;
    final name = _name.text.trim();
    final stock = int.tryParse(_stock.text.trim());
    final editing = widget.existing;
    if (name.isEmpty) return setState(() => error = "Type the medicine name as it's written on the strip.");
    if (times.isEmpty) return setState(() => error = 'Pick at least one time.');
    if (stock == null || stock < 0) return setState(() => error = 'Enter how many tablets are at home, like 30.');
    final dup = d.meds.any((m) => m.who == who && m.id != editing?.id && m.name.toLowerCase() == name.toLowerCase());
    if (dup) {
      return setState(() => error = '${d.nameOf(who)} already has $name. Check with the doctor before adding it twice.');
    }
    final list = times.toList();
    if (editing == null) {
      store.addMed(
        who: who,
        name: name,
        strength: _strength.text.trim(),
        form: form,
        purpose: _purpose.text.trim(),
        color: color,
        times: list,
        food: food,
        stock: stock,
        per: per,
      );
    } else {
      store.updateMed(
        editing.id,
        name: name,
        strength: _strength.text.trim(),
        form: form,
        purpose: _purpose.text.trim(),
        color: color,
        times: list,
        food: food,
        stock: stock,
        per: per,
      );
    }
    list.sort((a, b) => mins(a).compareTo(mins(b)));
    Navigator.pop(context);
    toast(
      context,
      editing == null
          ? '$name added. It shows on ${d.nameOf(who)}\'s day at ${list.map(t12).join(' and ')}.'
          : '$name saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final adding = widget.existing == null;
    final chipTimes = {...presetTimes, ...times}.toList()..sort((a, b) => mins(a).compareTo(mins(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(adding ? 'Add a medicine for ${d.nameOf(who)}' : 'Edit ${widget.existing!.name}'),
        if (adding && d.parents.length > 1) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final p in d.parents)
                ChoiceChip(label: Text(p.name), selected: who == p.id, onSelected: (_) => setState(() => who = p.id)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (adding) ...[
          Text('Common medicines', style: tt.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [for (final p in medPresets) ActionChip(label: Text(p.name), onPressed: () => _fill(p))],
          ),
          const SizedBox(height: 4),
          Text(
            'Fills the form with usual times. Always check them against the prescription.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Medicine', hintText: 'Metformin'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _strength,
                decoration: const InputDecoration(labelText: 'Strength', hintText: '500 mg'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _purpose,
          decoration: const InputDecoration(labelText: "What it's for (in plain words)", hintText: 'for sugar'),
        ),
        const SizedBox(height: 16),
        Text('When', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final t in chipTimes)
              FilterChip(
                label: Text(t12(t)),
                selected: times.contains(t),
                onSelected: (v) => setState(() {
                  if (v) {
                    times.add(t);
                  } else {
                    times.remove(t);
                  }
                }),
              ),
            ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Other time'), onPressed: _otherTime),
          ],
        ),
        const SizedBox(height: 16),
        Text('With food', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final f in foods)
              ChoiceChip(label: Text(foodText(f)), selected: food == f, onSelected: (_) => setState(() => food = f)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Each dose', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final n in const [1, 2, 3])
              ChoiceChip(label: Text('$n'), selected: per == n, onSelected: (_) => setState(() => per = n)),
            for (final f in const ['tablet', 'capsule'])
              ChoiceChip(label: Text(f), selected: form == f, onSelected: (_) => setState(() => form = f)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _stock,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: adding ? 'Tablets at home' : 'Tablets left'),
        ),
        const SizedBox(height: 16),
        Text('Pill colour', style: tt.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final c in pillColors)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => color = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: color == c ? cs.primary : cs.outlineVariant, width: color == c ? 3 : 1),
                  ),
                ),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: Text(adding ? 'Add medicine' : 'Save changes'),
        ),
      ],
    );
  }
}
