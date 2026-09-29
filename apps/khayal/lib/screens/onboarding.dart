import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _me = TextEditingController();
  final _myPhone = TextEditingController();
  final _p1 = TextEditingController(text: 'Papa');
  final _p1Phone = TextEditingController();
  final _p2 = TextEditingController(text: 'Mummy');
  final _p2Phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_me, _myPhone, _p1, _p1Phone, _p2, _p2Phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final me = _me.text.trim();
    final p1 = _p1.text.trim();
    final p2 = _p2.text.trim();
    if (me.isEmpty) {
      setState(() => _error = 'Add your name. Your parents see it on their "Call" button.');
      return;
    }
    if (p1.isEmpty && p2.isEmpty) {
      setState(() => _error = 'Add at least one parent.');
      return;
    }
    final parents = <Parent>[
      if (p1.isNotEmpty) Parent(id: 'p1', name: p1, phone: _p1Phone.text.trim(), color: parentColors[0]),
      if (p2.isNotEmpty) Parent(id: 'p2', name: p2, phone: _p2Phone.text.trim(), color: parentColors[1]),
    ];
    StoreScope.read(context).setup(caregiver: me, caregiverPhone: _myPhone.text.trim(), parents: parents);
  }

  Widget _parentRow(String label, TextEditingController name, TextEditingController phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: label),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
      key: const ValueKey('list-onboarding'),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.favorite, color: cs.onPrimary, size: 32),
            ),
            const SizedBox(height: 20),
            Text('Khayal', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              "Keep track of your parents' medicines from wherever you are: today's doses, missed ones, refills, "
              'readings for the doctor, and who to call.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _me,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name', hintText: 'Karan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _myPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Your phone (optional)'),
            ),
            const SizedBox(height: 24),
            Text('Who are you looking after?', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Leave a name empty if it is just one parent.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            _parentRow('Parent 1', _p1, _p1Phone),
            _parentRow('Parent 2', _p2, _p2Phone),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Start'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Everything is saved on this phone. No sign-up needed. Khayal is a reminder and record tool, not medical advice.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
