import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/item_sheet.dart';
import '../sheets/reminder_sheet.dart';
import '../ui.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final all = [...d.reminders]..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'Warranty end dates and service dates, in order. Anything due in the next 30 days shows under the bell at the top.',
          ),
        ),
        if (all.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nothing coming up',
            body: 'Warranty reminders are added when you save a bill. Add service dates like "clean AC filters" below.',
          )
        else
          ListCard(
            children: [
              for (final r in all)
                ListTile(
                  onTap: () {
                    if (r.kind == 'service') {
                      showReminderForm(context, reminderId: r.id);
                    } else if (r.itemId != null && d.item(r.itemId!) != null) {
                      showItemSheet(context, r.itemId!);
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                    child: Icon(r.kind == 'warranty' ? Icons.verified_user_outlined : Icons.build_outlined, size: 20),
                  ),
                  title: Text(r.title),
                  subtitle: _When(date: r.date, today: today, repeat: r.everyMonths),
                  trailing: Switch(
                    value: r.on,
                    onChanged: (v) {
                      store.toggleReminder(r.id, v);
                      toast(context, v ? 'Reminder on.' : 'Reminder off.');
                    },
                  ),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () => showReminderForm(context),
            icon: const Icon(Icons.add_alarm),
            label: const Text('Add a service reminder'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: NoteBox(text: 'Rasid does not send phone notifications. Open the app, or check the bell, to see what is due.'),
        ),
      ],
    );
  }
}

class _When extends StatelessWidget {
  const _When({required this.date, required this.today, required this.repeat});
  final String date;
  final String today;
  final int repeat;

  @override
  Widget build(BuildContext context) {
    final d = daysBetween(today, date);
    final urgent = d <= 30;
    final String rel;
    if (d < 0) {
      rel = '${-d} days overdue';
    } else if (d == 0) {
      rel = 'today';
    } else {
      rel = 'in ${timeLeftLabel(d)}';
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: longDate(date), style: const TextStyle(fontFamily: mono)),
          const TextSpan(text: ' · '),
          TextSpan(text: rel, style: urgent ? TextStyle(color: badColor(context), fontWeight: FontWeight.w700) : null),
          if (repeat > 0) TextSpan(text: repeat == 12 ? ' · yearly' : ' · every $repeat months'),
        ],
      ),
    );
  }
}
