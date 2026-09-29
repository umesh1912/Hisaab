import 'package:flutter/material.dart';

import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _place = TextEditingController();
  String season = 'summer';
  bool pets = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    super.dispose();
  }

  void _start() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Add your name.');
      return;
    }
    StoreScope.read(context).setup(owner: name, location: _place.text.trim(), season: season, pets: pets);
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
              child: Icon(Icons.eco, color: cs.onPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Hariyali', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Plant care that checks the weather and the soil. See which plants need water today, skip balcony plants when rain is coming, find what\'s wrong, and leave clear notes for whoever waters them while you\'re away.',
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
              controller: _place,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Area and city (optional)', hintText: 'Adyar, Chennai'),
            ),
            const SizedBox(height: 20),
            Text('Season where you live', style: tt.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'summer', label: Text('Summer')),
                ButtonSegment(value: 'monsoon', label: Text('Monsoon')),
                ButtonSegment(value: 'winter', label: Text('Winter')),
              ],
              selected: {season},
              onSelectionChanged: (s) => setState(() => season = s.first),
            ),
            const SizedBox(height: 4),
            Text('Soil dries slower in the monsoon and winter, so Hariyali waters less often then.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pets at home'),
              subtitle: const Text('Flag plants that aren\'t safe for cats and dogs'),
              value: pets,
              onChanged: (v) => setState(() => pets = v),
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
              child: const Text('Start my garden'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Everything is saved on this phone. No sign-up, no internet needed.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
