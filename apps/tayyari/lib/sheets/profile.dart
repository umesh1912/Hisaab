import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showProfile(BuildContext context) => showAppSheet(context, (_) => const _Profile());

class _Profile extends StatefulWidget {
  const _Profile();

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _exam = TextEditingController();
  final _target = TextEditingController();
  String _date = todayIso();
  bool _init = false;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final p = StoreScope.read(context).data?.profile;
    if (p == null) return;
    _name.text = p.name;
    _city.text = p.city;
    _exam.text = p.exam;
    _target.text = '${p.target}';
    _date = p.examDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _exam.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = parseIso(_date);
    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(now) ? now : init,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _date = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120); // just reset; sheet is closing
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Profile', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Your name')),
        const SizedBox(height: 12),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 12),
        TextField(controller: _exam, decoration: const InputDecoration(labelText: 'Exam')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Exam date'),
                  child: Text(longDate(_date), overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target / 200'),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final target = int.tryParse(_target.text.trim());
            if (target == null || target <= 0 || target > 200) {
              setState(() => error = 'Target score should be between 1 and 200.');
              return;
            }
            store.updateProfile(name: _name.text, city: _city.text, exam: _exam.text, examDate: _date, target: target);
            Navigator.pop(context);
            toast(context, 'Profile saved.');
          },
          child: const Text('Save profile'),
        ),
        const SizedBox(height: 16),
        Text(
          'Reminders: this app has no notifications. Open it each day; Today lists the revision that is due, and '
          'the Practice tab shows the count on its icon.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: 'Reset Tayyari?',
              body: 'This deletes your revision schedule, notes, questions and mock scores on this phone. It cannot be undone.',
              action: 'Delete everything',
              danger: true,
            );
            if (ok && context.mounted) {
              Navigator.pop(context);
              store.resetAll();
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset all data'),
        ),
      ],
    );
  }
}
