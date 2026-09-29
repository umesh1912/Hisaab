import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _exam = TextEditingController(text: 'SSC CGL Tier 1');
  final _target = TextEditingController(text: '150');
  String _examDate = addDaysIso(todayIso(), 90);
  String? _error;

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
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(_examDate),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _examDate = isoDate(picked));
  }

  void _start() {
    final name = _name.text.trim();
    final target = int.tryParse(_target.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Add your name.');
      return;
    }
    if (target == null || target <= 0 || target > 200) {
      setState(() => _error = 'Target score should be between 1 and 200.');
      return;
    }
    StoreScope.read(context).setup(
      name: name,
      city: _city.text.trim(),
      exam: _exam.text.trim().isEmpty ? 'SSC CGL Tier 1' : _exam.text.trim(),
      examDate: _examDate,
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(18)),
              child: Text('T', style: TextStyle(color: cs.onPrimary, fontSize: 34, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 20),
            Text('Tayyari', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'A study buddy for SSC CGL. Revise questions just before you would forget them, practise your weakest topics, and take timed tests with negative marking.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City (optional)', hintText: 'Patna'),
            ),
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
                      child: Text(longDate(_examDate), overflow: TextOverflow.ellipsis),
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Start preparing'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Comes with 100 practice questions (General Awareness in Hindi too). Everything is saved on this phone. No sign-up needed.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
