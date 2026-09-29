import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Records the score of a full mock taken elsewhere (25 questions a section).
Future<void> showAddMock(BuildContext context) => showAppSheet(context, (_) => const _AddMock());

class _AddMock extends StatefulWidget {
  const _AddMock();

  @override
  State<_AddMock> createState() => _AddMockState();
}

class _AddMockState extends State<_AddMock> {
  late final TextEditingController _name;
  final _right = {for (final s in sectionKeys) s: TextEditingController()};
  final _wrong = {for (final s in sectionKeys) s: TextEditingController()};
  final _sure = TextEditingController();
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    _name = TextEditingController(text: 'Mock ${(d?.mocks.where((m) => m.isFull).length ?? 0) + 1}');
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in [..._right.values, ..._wrong.values]) {
      c.dispose();
    }
    _sure.dispose();
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Map<String, SectionScore> get _sections => {
        for (final s in sectionKeys)
          s: SectionScore(
            right: _n(_right[s]!),
            wrong: _n(_wrong[s]!),
            skipped: questionsPerSection - _n(_right[s]!) - _n(_wrong[s]!),
          ),
      };

  void _save() {
    final store = StoreScope.read(context);
    final secs = _sections;
    for (final s in sectionKeys) {
      final sc = secs[s]!;
      if (sc.right < 0 || sc.wrong < 0 || sc.skipped < 0) {
        setState(() => error = '${secName(s)}: right + wrong can be at most $questionsPerSection.');
        return;
      }
    }
    final wrong = secs.values.fold<int>(0, (a, s) => a + s.wrong);
    final sure = _n(_sure);
    if (sure < 0 || sure > wrong) {
      setState(() => error = '"Wrong but felt sure" can be at most the number of wrong answers ($wrong).');
      return;
    }
    store.addManualMock(
      name: _name.text.trim().isEmpty ? 'Mock' : _name.text.trim(),
      date: todayIso(),
      sections: secs,
      confidentWrong: sure,
    );
    Navigator.pop(context);
    toast(context, 'Mock score saved.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final secs = _sections;
    final valid = secs.values.every((s) => s.skipped >= 0);
    final total = secs.values.fold<double>(0, (a, s) => a + s.marks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add mock score', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('For a full mock taken elsewhere: 25 questions in each section, +2 right, −0.5 wrong.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        for (final s in sectionKeys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(secName(s), style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _right[s],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Right'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _wrong[s],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Wrong'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        TextField(
          controller: _sure,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Wrong but felt sure (optional)'),
        ),
        const SizedBox(height: 12),
        Text(
          valid ? 'Score: ${fmtMarks(total)} / 200' : 'Each section has only $questionsPerSection questions.',
          style: TextStyle(fontWeight: FontWeight.w800, color: valid ? cs.onSurface : cs.error),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: const Text('Save mock'),
        ),
      ],
    );
  }
}
