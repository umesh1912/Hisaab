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
  final _bride = TextEditingController();
  final _groom = TextEditingController();
  final _city = TextEditingController();
  late String _date = addDaysIso(todayIso(), 90);
  final _events = <String>{for (final p in presetEvents) p.$1};
  String? _error;

  @override
  void dispose() {
    _me.dispose();
    _bride.dispose();
    _groom.dispose();
    _city.dispose();
    super.dispose();
  }

  void _create() {
    final bride = _bride.text.trim();
    final groom = _groom.text.trim();
    if (bride.isEmpty || groom.isEmpty) {
      setState(() => _error = "Add the bride's and groom's names.");
      return;
    }
    StoreScope.read(context).createWedding(
      myName: _me.text.trim(),
      bride: bride,
      groom: groom,
      city: _city.text.trim(),
      weddingDate: _date,
      eventNames: _events.toList(),
    );
  }

  Future<void> _pickDate() async {
    final d = await pickIsoDate(context, _date);
    if (d != null) setState(() => _date = d);
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
              child: const Icon(Icons.local_florist, color: marigold, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Utsav', style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Text(
              'One place for the whole family to plan the wedding: guests and RSVPs by event, tasks for relatives, the budget and every vendor payment.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bride,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Bride', hintText: 'Riya'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _groom,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Groom', hintText: 'Kabir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City', hintText: 'Jaipur', helperText: 'Guests from other cities can be given hotel rooms'),
            ),
            const SizedBox(height: 12),
            PickerField(
              label: 'Wedding day',
              value: '${dayName(_date)}, ${longDate(_date)}',
              icon: Icons.event,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _me,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name (optional)', hintText: 'Anjali', helperText: 'Used to sign WhatsApp messages'),
            ),
            const FieldLabel('Functions'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in presetEvents)
                  FilterChip(
                    label: Text(p.$1),
                    selected: _events.contains(p.$1),
                    onSelected: (v) => setState(() => v ? _events.add(p.$1) : _events.remove(p.$1)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('You can rename them, change times and add more later.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Start planning'),
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
