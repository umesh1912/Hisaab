import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showCheckIn(BuildContext context, int habitId) =>
    showAppSheet(context, (_) => CheckInForm(habitId: habitId));

class CheckInForm extends StatefulWidget {
  const CheckInForm({super.key, required this.habitId});
  final int habitId;

  @override
  State<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends State<CheckInForm> {
  final _note = TextEditingController();
  final _proof = TextEditingController();
  String effort = 'OK';
  bool? whatsapp;

  @override
  void dispose() {
    _note.dispose();
    _proof.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    final h = d?.habit(widget.habitId);
    if (d == null || h == null) return;
    final proof = _proof.text.trim();
    final note = [if (proof.isNotEmpty) proof, if (_note.text.trim().isNotEmpty) _note.text.trim()].join(' · ');
    final send = whatsapp ?? !d.simulatePartner;
    final streak = store.checkIn(h.id, note: note, effort: effort);
    if (send) {
      final shared = d.shareNotes && note.isNotEmpty ? '\n“$note”' : '';
      shareOnWhatsApp(context, '✅ ${h.name}, done today ($effort). $streak-day streak.$shared');
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$streak-day streak. ${send ? 'Opening WhatsApp for ${d.partnerName}.' : 'Keep it going.'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final h = d?.habit(widget.habitId);
    if (d == null || h == null) return const SizedBox(height: 120); // deleted or reset while open
    final cs = Theme.of(context).colorScheme;
    final send = whatsapp ?? !d.simulatePartner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Done: ${h.name}', sub: h.cue.isEmpty ? null : h.cue),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: 'Note for ${d.partnerName} (optional)', hintText: 'How did it go?'),
        ),
        if (h.proof) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _proof,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Proof',
              hintText: 'Route, time, pages…',
              helperText: 'This habit asks for proof. Add a line your partner can check.',
              prefixIcon: Icon(Icons.verified_outlined),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('How hard was it today?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Easy', label: Text('Easy')),
            ButtonSegment(value: 'OK', label: Text('OK')),
            ButtonSegment(value: 'Tough', label: Text('Tough')),
          ],
          selected: {effort},
          onSelectionChanged: (s) => setState(() => effort = s.first),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: send,
          onChanged: (v) => setState(() => whatsapp = v),
          title: Text('Tell ${d.partnerName} on WhatsApp'),
          subtitle: Text(d.shareNotes ? 'Sends the habit and your note' : 'Sends the habit only (notes are off)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: cs.primary),
          child: const Text('Check in'),
        ),
      ],
    );
  }
}
