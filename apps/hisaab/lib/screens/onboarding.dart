import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _MateRow {
  final name = TextEditingController();
  final upi = TextEditingController();
  void dispose() {
    name.dispose();
    upi.dispose();
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _flat = TextEditingController();
  final _me = TextEditingController();
  final _myUpi = TextEditingController();
  final _mates = <_MateRow>[_MateRow(), _MateRow()];
  String? _error;

  @override
  void dispose() {
    _flat.dispose();
    _me.dispose();
    _myUpi.dispose();
    for (final m in _mates) {
      m.dispose();
    }
    super.dispose();
  }

  void _create() {
    final flat = _flat.text.trim();
    final me = _me.text.trim();
    final mates = _mates.where((m) => m.name.text.trim().isNotEmpty).toList();
    if (flat.isEmpty || me.isEmpty) {
      setState(() => _error = 'Add a flat name and your name.');
      return;
    }
    if (mates.isEmpty) {
      setState(() => _error = 'Add at least one flatmate.');
      return;
    }
    var n = 0;
    StoreScope.read(context).createFlat(
      flatName: flat,
      myName: me,
      myUpi: _myUpi.text.trim(),
      flatmates: [
        for (final m in mates) Member(id: 'm${++n}', name: m.name.text.trim(), upi: m.upi.text.trim()),
      ],
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
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.currency_rupee, color: cs.onPrimary, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Hisaab', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Split rent and bills, keep one shopping list and take turns on chores. Settle up over UPI.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextField(controller: _flat, decoration: const InputDecoration(labelText: 'Flat name', hintText: 'Flat 3B')),
            const SizedBox(height: 12),
            TextField(controller: _me, decoration: const InputDecoration(labelText: 'Your name')),
            const SizedBox(height: 12),
            TextField(
              controller: _myUpi,
              decoration: const InputDecoration(labelText: 'Your UPI ID (optional)', hintText: 'name@okaxis'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Text('Flatmates', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (var i = 0; i < _mates.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(controller: _mates[i].name, decoration: InputDecoration(labelText: 'Name ${i + 1}')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _mates[i].upi,
                        decoration: const InputDecoration(labelText: 'UPI ID'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    if (_mates.length > 1)
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          final row = _mates[i];
                          setState(() => _mates.removeAt(i));
                          WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _mates.add(_MateRow())),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add another flatmate'),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Create flat'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Everything is saved on this phone. No sign-up needed.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
