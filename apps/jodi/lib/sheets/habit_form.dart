import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Opens the "New habit" sheet, or the edit sheet when [habitId] is given.
Future<void> showHabitForm(BuildContext context, {int? habitId}) =>
    showAppSheet(context, (_) => HabitForm(habitId: habitId));

class HabitForm extends StatefulWidget {
  const HabitForm({super.key, this.habitId});
  final int? habitId;

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  final _name = TextEditingController();
  final _cue = TextEditingController();
  String owner = me;
  List<bool> days = List.filled(7, true);
  bool shared = true;
  bool proof = false;
  String? error;
  bool _init = false;

  bool get editing => widget.habitId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final id = widget.habitId;
    if (id == null) return;
    final h = StoreScope.read(context).data?.habit(id);
    if (h == null) return;
    _name.text = h.name;
    _cue.text = cueBody(h.cue);
    owner = h.owner;
    days = List.of(h.days);
    shared = h.shared;
    proof = h.proof;
  }

  @override
  void dispose() {
    _name.dispose();
    _cue.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => error = 'Say what you’ll do, like “Floss”.');
    if (!days.any((x) => x)) return setState(() => error = 'Pick at least one day.');
    final cue = normalizeCue(_cue.text);
    final id = widget.habitId;
    if (id != null) {
      store.updateHabit(id, name: name, cue: cue, days: days, proof: proof, shared: shared);
      Navigator.pop(context);
      toast(context, 'Saved $name');
    } else {
      store.addHabit(owner: owner, name: name, cue: cue, days: days, proof: proof, shared: shared);
      Navigator.pop(context);
      toast(context, owner == me ? '$name added. ${d.partnerName} can see it now.' : '$name added for ${d.partnerName}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    if (d == null) return const SizedBox(height: 120);
    if (editing && d.habit(widget.habitId!) == null) return const SizedBox(height: 120); // deleted while open
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final forMe = owner == me;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(editing ? 'Edit habit' : 'New habit'),
        if (!editing) ...[
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: me, label: Text('For me')),
              ButtonSegment(
                value: them,
                label: Text('For ${d.partnerName.length > 10 ? '${d.partnerName.substring(0, 9)}…' : d.partnerName}'),
              ),
            ],
            selected: {owner},
            onSelectionChanged: (s) => setState(() => owner = s.first),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: forMe ? 'I will' : '${d.partnerName} will', hintText: 'Floss'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cue,
          decoration: const InputDecoration(labelText: 'After I (an existing routine)', hintText: 'brush my teeth at night'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('On these days', style: tt.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: Semantics(
                    button: true,
                    selected: days[i],
                    label: dayShort[i],
                    child: Material(
                      color: days[i] ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => days[i] = !days[i]),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              dayLetters[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: days[i] ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (forMe)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: shared,
            onChanged: (v) => setState(() => shared = v),
            title: Text('Share with ${d.partnerName}'),
            subtitle: const Text('Shows on their side and can be nudged'),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: proof,
          onChanged: (v) => setState(() => proof = v),
          title: const Text('Ask for proof'),
          subtitle: const Text('A line like a route or a timer at check-in'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(forMe ? 'Your plan' : '${d.partnerName}’s plan', style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(
                planText(normalizeCue(_cue.text), _name.text),
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 2),
              Text(daysText(days), style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer)),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(editing ? 'Save changes' : 'Start habit'),
        ),
      ],
    );
  }
}
