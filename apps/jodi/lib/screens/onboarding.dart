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
  final _meCity = TextEditingController();
  final _partner = TextEditingController();
  final _partnerCity = TextEditingController();
  final _pact = TextEditingController(text: 'The one below 80% this week buys chai');
  String? _error;

  @override
  void dispose() {
    _me.dispose();
    _meCity.dispose();
    _partner.dispose();
    _partnerCity.dispose();
    _pact.dispose();
    super.dispose();
  }

  void _start() {
    final meName = _me.text.trim();
    final partner = _partner.text.trim();
    if (meName.isEmpty) {
      setState(() => _error = 'Add your name.');
      return;
    }
    if (partner.isEmpty) {
      setState(() => _error = 'Add your partner’s name. Jodi is built for two.');
      return;
    }
    StoreScope.read(context).createPair(
      meName: meName,
      partnerName: partner,
      meCity: _meCity.text.trim(),
      partnerCity: _partnerCity.text.trim(),
      pact: _pact.text.trim(),
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
            Row(
              children: [
                PersonAvatar(who: me, name: 'I', size: 52),
                Transform.translate(offset: const Offset(-12, 0), child: PersonAvatar(who: them, name: 'T', size: 52)),
              ],
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(text: 'jodi', children: [TextSpan(text: '.', style: TextStyle(color: personColor(context, them)))]),
              style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const SizedBox(height: 6),
            Text(
              'Habits stick when someone’s watching. Track habits with one partner, cheer or nudge each other, and share a light weekly pact.',
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
              controller: _meCity,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your city (optional)', hintText: 'Mumbai'),
            ),
            const SizedBox(height: 24),
            Text('Your jodi', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'One friend who will notice when you show up, and when you don’t.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _partner,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Partner’s name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partnerCity,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Partner’s city (optional)', hintText: 'Delhi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pact,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Weekly pact', helperText: 'A playful forfeit, never money.'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Start as a pair'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'Everything is saved on this phone. Nudges and check-ins can be sent to your partner on WhatsApp.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
