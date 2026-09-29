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
  final _area = TextEditingController();
  final _teach = TextEditingController();
  final _learn = TextEditingController();
  String _cat = 'tech';
  String _level = 'Good';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _teach.dispose();
    _learn.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    final teach = _teach.text.trim();
    final learns = splitSkills(_learn.text);
    if (name.isEmpty) return setState(() => _error = 'Add your name.');
    if (teach.isEmpty) return setState(() => _error = 'Add one thing you can teach.');
    if (learns.isEmpty) return setState(() => _error = 'Add at least one thing you want to learn.');
    StoreScope.read(context).createProfile(
      name: name,
      area: _area.text.trim(),
      teach: Skill(name: teach, cat: _cat, level: _level),
      learns: learns,
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
              child: Icon(Icons.swap_horiz, color: cs.onPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Lenden', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Teach what you know, learn what you don\'t. Every hour you teach earns one time credit, and every hour you learn spends one.',
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
              controller: _area,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Neighbourhood', hintText: 'HSR Layout, Bengaluru'),
            ),
            const SizedBox(height: 24),
            Text('You can teach', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _teach,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Skill', hintText: 'Excel, guitar, Tamil…'),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            Text('You want to learn', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _learn,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Skills to learn', hintText: 'Yoga, Spoken Kannada'),
            ),
            const SizedBox(height: 6),
            Text('Separate several skills with commas.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Start swapping'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => StoreScope.read(context).loadSample(),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Explore with sample data'),
            ),
            const SizedBox(height: 16),
            Text(
              'You start with 2 welcome credits. Everything is saved on this phone. '
              'Neighbours shown in this version are sample profiles.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
