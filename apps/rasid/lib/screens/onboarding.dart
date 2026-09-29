import 'package:flutter/material.dart';

import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _me = TextEditingController();
  final _home = TextEditingController();
  final _partner = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _me.dispose();
    _home.dispose();
    _partner.dispose();
    super.dispose();
  }

  void _create() {
    final me = _me.text.trim();
    if (me.isEmpty) {
      setState(() => _error = 'Add your name to start.');
      return;
    }
    StoreScope.read(context).createVault(myName: me, homeName: _home.text.trim(), partner: _partner.text.trim());
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
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.receipt_long, color: cs.onPrimary, size: 34),
              ),
            ),
            const SizedBox(height: 20),
            Text('Rasid', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Every bill, every warranty, found in seconds. Know before a warranty runs out, and get a repair claim ready in one tap.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _me,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _home,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Home (optional)', hintText: 'Flat 204, Kondapur'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partner,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Someone you share the house with (optional)'),
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
              child: const Text('Create my vault'),
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
