import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showAddSkill(BuildContext context, {required bool teach}) =>
    showAppSheet(context, (_) => _AddSkillSheet(teach: teach));

class _AddSkillSheet extends StatefulWidget {
  const _AddSkillSheet({required this.teach});
  final bool teach;

  @override
  State<_AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends State<_AddSkillSheet> {
  final _name = TextEditingController();
  String _cat = 'tech';
  String _level = 'Expert';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();
    final teach = widget.teach;
    final have = (teach ? d.me.teachNames : d.me.learns).map((s) => s.toLowerCase()).toSet();
    final pool = <String>{};
    for (final p in d.people) {
      if (d.blocked.contains(p.id)) continue;
      pool.addAll(teach ? p.wants : p.teaches.map((t) => t.name));
    }
    final suggestions = pool.where((s) => !have.contains(s.toLowerCase())).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(teach ? 'Add a skill you teach' : 'Add something to learn'),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: 'Skill', hintText: teach ? 'e.g. Public speaking' : 'e.g. Photography'),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final s in suggestions) ActionChip(label: chipText(s), onPressed: () => setState(() => _name.text = s)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            teach ? 'Suggestions come from what people near you want to learn.' : 'Suggestions come from what people near you teach.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
        if (teach) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _cat,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final e in categories.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _cat = v ?? _cat),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _level,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Your level'),
            items: [for (final l in skillLevels) DropdownMenuItem(value: l, child: Text(l))],
            onChanged: (v) => setState(() => _level = v ?? _level),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final v = _name.text.trim();
            if (v.isEmpty) return setState(() => _error = 'Type a skill name first.');
            final err = teach ? store.addTeach(v, _cat, _level) : store.addLearn(v);
            if (err != null) return setState(() => _error = err);
            final lower = v.toLowerCase();
            final n = d.people
                .where((p) => !d.blocked.contains(p.id))
                .where((p) => teach
                    ? p.wants.any((w) => w.toLowerCase() == lower)
                    : p.teaches.any((t) => t.name.toLowerCase() == lower))
                .length;
            Navigator.pop(context);
            toast(
              context,
              n > 0 ? 'Added $v. $n ${n == 1 ? 'person' : 'people'} nearby ${teach ? 'want' : 'teach'} it.' : 'Added $v.',
            );
          },
          child: const Text('Add skill'),
        ),
      ],
    );
  }
}
