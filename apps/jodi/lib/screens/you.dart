import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/find_partner.dart';
import '../sheets/profile.dart';
import '../ui.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = todayIso();
    final place = d.meCity.isEmpty ? '' : '${d.meCity} · ';

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            children: [
              PersonAvatar(who: me, name: d.meName, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.meName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${place}partnered with ${d.partnerName} since ${shortDate(d.pairedOn)}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit names and pact',
                onPressed: () => showProfileSheet(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: d.shareNotes,
                onChanged: store.setShareNotes,
                title: const Text('Share check-in notes'),
                subtitle: Text('Notes and proof go into the messages you send ${d.partnerName}'),
              ),
              SwitchListTile(
                value: d.showNudges,
                onChanged: store.setShowNudges,
                title: const Text('Nudge buttons'),
                subtitle: Text('At most one nudge per habit per day for ${d.partnerName}'),
              ),
              SwitchListTile(
                value: d.paused,
                onChanged: store.setPaused,
                title: const Text('Pause partnership'),
                subtitle: const Text('For travel or illness; streaks freeze for both'),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.send_outlined),
                title: Text('Send ${d.partnerName} today’s summary'),
                subtitle: const Text('Opens WhatsApp with your check-ins'),
                onTap: () => shareOnWhatsApp(context, _summary(context, t)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Names, cities and pact'),
                subtitle: Text(d.pact, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => showProfileSheet(context),
              ),
            ],
          ),
        ),
        const SectionTitle('Want another partner?'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Some habits work better with someone who has the same goal. Jodi can match you with a stranger by goal, '
            'time zone and language. You chat by first name only until you both choose to share more.',
            style: tt.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: () => showFindPartner(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            icon: const Icon(Icons.person_search_outlined),
            label: const Text('Find a partner'),
          ),
        ),
        if (d.matchRequests.isNotEmpty) ...[
          const SectionTitle('Requests sent'),
          for (final n in d.matchRequests)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.hourglass_top),
              title: Text(n),
              subtitle: const Text('Waiting for a reply · 2-week trial if they accept'),
              trailing: TextButton(onPressed: () => store.cancelMatch(n), child: const Text('Cancel')),
            ),
        ],
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Start over?',
                body: 'This deletes every habit, check-in and message on this phone. It cannot be undone.',
                action: 'Delete everything',
              );
              if (ok && context.mounted) StoreScope.read(context).resetAll();
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset and start over'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Everything is saved on this phone only.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _summary(BuildContext context, String t) {
    final store = StoreScope.read(context);
    final d = store.data!;
    final due = store.dueToday(me);
    final lines = <String>['My Jodi check-ins today:'];
    for (final h in due) {
      final c = h.log[t];
      if (c == null) {
        lines.add('⬜ ${h.name}');
      } else {
        final note = d.shareNotes && c.note.isNotEmpty ? ' – ${c.note}' : '';
        lines.add('✅ ${h.name}$note');
      }
    }
    if (due.isEmpty) lines.add('Rest day, nothing due.');
    final score = store.scoreOf(me, store.statesOf(me));
    lines.add('This week: ${score.pct}% (${score.done}/${score.of}). Pact: ${d.pact}');
    return lines.join('\n');
  }
}
