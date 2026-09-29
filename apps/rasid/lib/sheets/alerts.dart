import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'item_sheet.dart';
import 'reminder_sheet.dart';

/// In-app stand-in for push reminders: everything due in the next 30 days.
Future<void> showAlerts(BuildContext context) => showAppSheet(context, (_) => const _Alerts());

class _Alerts extends StatelessWidget {
  const _Alerts();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final list = alertReminders(d.reminders, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Alerts', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Warranties ending and services due in the next 30 days.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Nothing urgent.')),
          ),
        for (final r in list)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 56,
              child: Center(child: Tag(_dueTag(daysBetween(today, r.date)), tone: 'bad')),
            ),
            title: Text(r.title),
            subtitle: Text(longDate(r.date), style: const TextStyle(fontFamily: mono)),
            onTap: () {
              final id = r.itemId;
              if (r.kind == 'warranty' && id != null && d.item(id) != null) {
                showItemSheet(context, id);
              } else {
                showReminderForm(context, reminderId: r.id);
              }
            },
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            store.goTab(3);
          },
          child: const Text('See all reminders'),
        ),
      ],
    );
  }
}

String _dueTag(int d) {
  if (d < 0) return 'late';
  if (d == 0) return 'today';
  return '${d}d';
}
