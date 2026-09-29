import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic.dart';
import '../ui.dart';

/// The caterer's count for one function, ready to send.
Future<void> showHeadcountSheet(BuildContext context, String eventId) {
  return showAppSheet(context, (ctx) => _Headcount(eventId: eventId));
}

class _Headcount extends StatelessWidget {
  const _Headcount({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final e = d?.event(eventId);
    final cs = Theme.of(context).colorScheme;
    if (d == null || e == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This function no longer exists.'));
    }
    final text = headcountText(d, e, todayIso());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Headcount for caterer'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: SelectableText(text, style: const TextStyle(fontSize: 15, height: 1.4)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: whatsappGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
          onPressed: () => openWhatsApp(context, text),
          child: const IconLabel(icon: Icons.chat_outlined, text: 'Send on WhatsApp'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) toast(context, 'Headcount copied.');
          },
          child: const IconLabel(icon: Icons.copy, text: 'Copy'),
        ),
        const SizedBox(height: 12),
        Text(
          'Numbers update as RSVPs change. Send a final count 3 days before the function.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Reminds every family that hasn't replied, one WhatsApp chat at a time.
Future<void> showReminderSheet(BuildContext context) {
  return showAppSheet(context, (ctx) => const _Reminder());
}

class _Reminder extends StatefulWidget {
  const _Reminder();

  @override
  State<_Reminder> createState() => _ReminderState();
}

class _ReminderState extends State<_Reminder> {
  final _msg = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d != null) _msg.text = rsvpReminderText(d);
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();
    final today = todayIso();
    final waiting = d.guests.where((g) => g.status == rsvpWait).toList();
    final sent = waiting.where((g) => g.remindedOn == today).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          'RSVP reminder',
          sub: waiting.isEmpty
              ? 'Every family has replied.'
              : 'For the ${waiting.length} ${waiting.length == 1 ? 'family' : 'families'} who haven\'t replied. '
                  'WhatsApp opens for one family at a time; come back here for the next.',
        ),
        TextField(
          controller: _msg,
          maxLines: null,
          minLines: 4,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        const SizedBox(height: 8),
        if (waiting.isNotEmpty)
          Text('$sent of ${waiting.length} sent today', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        for (final g in waiting)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SideDot(g.side),
            minLeadingWidth: 12,
            title: Text(g.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              g.phone.isEmpty
                  ? 'No number saved'
                  : (g.remindedOn == null ? prettyPhone(g.phone) : 'Reminded ${shortDate(g.remindedOn!)}'),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: g.phone.isEmpty
                ? null
                : (g.remindedOn == today
                    ? Icon(Icons.check_circle, color: goodColor(context))
                    : FilledButton.tonal(
                        onPressed: () {
                          store.markReminded(g.id);
                          openWhatsApp(context, _msg.text, phone: g.phone);
                        },
                        child: const Text('Send'),
                      )),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => openWhatsApp(context, _msg.text),
          child: const IconLabel(icon: Icons.group_outlined, text: 'Send to a group instead'),
        ),
        const SizedBox(height: 10),
        Text(
          'When they reply, open the family on the Guests tab and set their RSVP. Headcounts update straight away.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
