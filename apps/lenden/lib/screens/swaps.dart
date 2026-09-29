import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/chat.dart';
import '../sheets/session.dart';
import '../ui.dart';

class SwapsScreen extends StatelessWidget {
  const SwapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tt = Theme.of(context).textTheme;
    final blocked = store.blockedSet;
    final upcoming = upcomingSessions(d.sessions, blocked);
    final requests = requestSessions(d.sessions, blocked);
    final past = pastSessions(d.sessions);
    final incoming = requests.where((s) => s.status == 'incoming').length;
    final unrated = past.where((s) => !s.rated).length;
    final list = [upcoming, requests, past][store.swapTab];

    String empty;
    switch (store.swapTab) {
      case 1:
        empty = 'No open requests. Find someone on Discover.';
        break;
      case 2:
        empty = 'Sessions you finish show up here.';
        break;
      default:
        empty = 'Nothing booked yet. Request a swap from Discover.';
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text('Your swaps', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text('Upcoming${upcoming.isEmpty ? '' : ' · ${upcoming.length}'}'),
                selected: store.swapTab == 0,
                onSelected: (_) => store.setSwapTab(0),
              ),
              ChoiceChip(
                label: Text('Requests${incoming == 0 ? '' : ' · $incoming new'}'),
                selected: store.swapTab == 1,
                onSelected: (_) => store.setSwapTab(1),
              ),
              ChoiceChip(
                label: Text('Past${unrated == 0 ? '' : ' · $unrated to rate'}'),
                selected: store.swapTab == 2,
                onSelected: (_) => store.setSwapTab(2),
              ),
            ],
          ),
        ),
        if (store.swapTab == 0)
          InfoNote(
            d.me.share
                ? 'Before in-person sessions, send the time and place to your trusted contact from the check-in screen. Meet in public places.'
                : 'Tip: turn on trusted-contact sharing in Profile before in-person sessions. Meet in public places.',
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          ),
        if (list.isEmpty)
          EmptyState(icon: Icons.event_available_outlined, title: 'Nothing here yet', body: empty)
        else
          for (final s in list) SessionCard(session: s),
      ],
    );
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final s = session;
    final p = d.person(s.withId);
    final first = p?.first ?? 'Someone';
    final dirColor = s.isLearn ? cs.primary : creditColor(context, 1);

    final actions = <Widget>[];
    switch (s.status) {
      case 'incoming':
        actions.addAll([
          OutlinedButton(
            onPressed: () {
              store.decline(s.id);
              toast(context, 'Declined. $first gets a polite note, not your reason.');
            },
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () {
              final back = store.acceptIncoming(s.id);
              toast(
                context,
                back == null
                    ? 'Accepted. It is in Upcoming.'
                    : 'Accepted. You teach on ${shortDate(s.date)} and learn ${back.skill.toLowerCase()} on ${shortDate(back.date)}.',
              );
            },
            child: const Text('Accept'),
          ),
        ]);
        break;
      case 'sent':
        actions.addAll([
          FilledButton.tonal(
            onPressed: () {
              store.markAccepted(s.id);
              toast(context, '$first accepted. It is in Upcoming.');
            },
            child: Text('$first said yes'),
          ),
          TextButton(
            onPressed: () {
              store.withdraw(s.id);
              toast(context, 'Request withdrawn.');
            },
            child: const Text('Withdraw'),
          ),
        ]);
        break;
      case 'confirmed':
        actions.addAll([
          OutlinedButton(onPressed: () => showChat(context, s.withId), child: const Text('Message')),
          FilledButton(onPressed: () => showCheckIn(context, s.id), child: const Text('Start session')),
          TextButton(
            onPressed: () async {
              final ok = await confirm(context, 'Cancel this session?', 'It will be removed for both of you.', 'Cancel session');
              if (!ok || !context.mounted) return;
              store.cancelSession(s.id);
              toast(context, 'Session cancelled.');
            },
            child: const Text('Cancel'),
          ),
        ]);
        break;
      default:
        if (!s.rated) {
          actions.add(FilledButton(onPressed: () => showRate(context, s.id), child: Text('Rate $first')));
        } else {
          actions.add(Tag('Completed · ${signedHrs(s.isLearn ? -s.hrs : s.hrs)} hr', icon: Icons.check, tone: TagTone.ok));
        }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text(monthShort(s.date).toUpperCase(), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      Text('${parseIso(s.date).day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isLearn ? 'You learn from $first' : 'You teach $first',
                        style: TextStyle(color: dirColor, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(s.skill, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        '${dayName(s.date)} ${t12(s.time)} · ${hrsText(s.hrs)} hr · ${s.mode}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (p != null) ...[const SizedBox(width: 8), PersonAvatar(p, size: 34)],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(s.mode == 'Online' ? Icons.videocam_outlined : Icons.place_outlined, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(s.place, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
              ],
            ),
            if (s.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('“${s.note}”', style: const TextStyle(fontSize: 13.5)),
                    if (s.offer.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Tag('Offers ${s.offer} in return', icon: Icons.swap_horiz, tone: TagTone.match),
                    ],
                  ],
                ),
              ),
            ],
            if (s.isLearn && s.pay == 'credits' && s.status != 'done') ...[
              const SizedBox(height: 8),
              Tag('Paid with ${hrsText(s.hrs)} credit${s.hrs == 1 ? '' : 's'} when done'),
            ],
            if (s.status == 'sent') ...[
              const SizedBox(height: 8),
              Text(
                'Waiting for $first. Tap "$first said yes" once they confirm.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
          ],
        ),
      ),
    );
  }
}
