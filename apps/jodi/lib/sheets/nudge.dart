import 'package:flutter/material.dart';

import '../ui.dart';

const nudgePresets = [
  'You’ve got this 💪',
  '20 min, then Netflix?',
  'Doing mine right now. Join me?',
  'Don’t break the streak!',
];

Future<void> showNudge(BuildContext context, int habitId) => showAppSheet(context, (_) => NudgeForm(habitId: habitId));

class NudgeForm extends StatefulWidget {
  const NudgeForm({super.key, required this.habitId});
  final int habitId;

  @override
  State<NudgeForm> createState() => _NudgeFormState();
}

class _NudgeFormState extends State<NudgeForm> {
  String message = nudgePresets.first;
  bool? whatsapp;

  void _send() {
    final store = StoreScope.read(context);
    final d = store.data;
    final h = d?.habit(widget.habitId);
    if (d == null || h == null) return;
    final send = whatsapp ?? !d.simulatePartner;
    store.nudge(h.id, message);
    if (send) shareOnWhatsApp(context, '$message\n(${h.name})');
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Nudge sent. That’s the limit for ${h.name.toLowerCase()} today.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final h = d?.habit(widget.habitId);
    if (d == null || h == null) return const SizedBox(height: 120);
    final tt = Theme.of(context).textTheme;
    final send = whatsapp ?? !d.simulatePartner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Nudge ${d.partnerName}'),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'About: '),
              TextSpan(text: h.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '. Pick a message. Kind nudges work better than guilt.'),
            ],
          ),
          style: tt.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final m in nudgePresets)
              ChoiceChip(
                label: Text(m),
                selected: message == m,
                onSelected: (_) => setState(() => message = m),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: send,
          onChanged: (v) => setState(() => whatsapp = v),
          title: const Text('Send it on WhatsApp'),
          subtitle: const Text('You pick the chat; the message is ready to go'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _send,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Send nudge'),
        ),
      ],
    );
  }
}
