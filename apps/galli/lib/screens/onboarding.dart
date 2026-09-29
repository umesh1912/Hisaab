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
  final _locality = TextEditingController();
  double _radius = 1.0;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _locality.dispose();
    super.dispose();
  }

  void _start() {
    final name = _name.text.trim();
    final locality = _locality.text.trim();
    if (name.isEmpty || locality.isEmpty) {
      setState(() => _error = 'Add your name and your locality.');
      return;
    }
    StoreScope.read(context).setup(name: name, locality: locality, radius: _radius);
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
              child: Text('G.', style: TextStyle(color: cs.onPrimary, fontSize: 30, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 20),
            Text('Galli', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              "What's happening in your lane, right now. Alerts that neighbours confirm, "
              'lost pets with sightings on a map, and found items returned to their owners.',
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
              controller: _locality,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your locality', hintText: 'Kothrud, Pune'),
            ),
            const SizedBox(height: 16),
            Text('Show posts within', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            KmPicker(options: radiusOptions, value: _radius, onChanged: (v) => setState(() => _radius = v)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Get started'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Everything is saved on this phone. No sign-up, no location tracking: '
              'you type a locality and Galli never shows your exact address.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
