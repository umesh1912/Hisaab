import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/guest.dart';
import '../sheets/messages.dart';
import '../sheets/rooms.dart';
import '../ui.dart';
import 'home.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  String filter = 'all';

  static const _order = {rsvpWait: 0, rsvpYes: 1, rsvpNo: 2};

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final evs = d.sortedEvents;
    final ev = store.currentEvent;
    final waiting = familiesWaiting(d.guests);

    int n(String st) => d.guests.where((g) => g.status == st).length;
    final list = d.guests.where((g) => filter == 'all' || g.status == filter).toList()
      ..sort((a, b) {
        final c = (_order[a.status] ?? 3).compareTo(_order[b.status] ?? 3);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

    final confirmed = ev == null ? 0 : confirmedFor(d.guests, ev.id);
    final jain = ev == null ? 0 : jainFor(d.guests, ev.id);

    return ListView(
      key: const Key('guests-list'),
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        if (evs.isNotEmpty)
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: evs.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final e = evs[i];
                return EventCard(
                  event: e,
                  sub: null,
                  count: confirmedFor(d.guests, e.id),
                  selected: ev?.id == e.id,
                  onTap: () => store.selectEvent(e.id),
                );
              },
            ),
          ),
        if (ev != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ev.name} headcount', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    '${dayName(ev.date)} ${shortDate(ev.date)}, ${time12(ev.time)}${ev.venue.isEmpty ? '' : ' · ${ev.venue}'}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  StatRow(
                    padding: EdgeInsets.zero,
                    items: [('$confirmed', 'confirmed'), ('${confirmed - jain}', 'veg'), ('$jain', 'Jain')],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order ${platesWithBuffer(confirmed, d.bufferPct)} plates with a ${d.bufferPct}% buffer',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('share-count'),
                      onPressed: () => showHeadcountSheet(context, ev.id),
                      icon: const Icon(Icons.restaurant_outlined),
                      label: const Text('Share count with caterer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (waiting > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: FilledButton(
              key: const Key('remind'),
              style: FilledButton.styleFrom(
                backgroundColor: whatsappGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => showReminderSheet(context),
              child: IconLabel(
                icon: Icons.chat_outlined,
                text: 'Remind $waiting ${waiting == 1 ? 'family' : 'families'} on WhatsApp',
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in [
                ('all', 'All', d.guests.length),
                (rsvpWait, 'Waiting', n(rsvpWait)),
                (rsvpYes, 'Coming', n(rsvpYes)),
                (rsvpNo, "Can't come", n(rsvpNo)),
              ])
                ChoiceChip(
                  label: Text('${f.$2} ${f.$3}'),
                  selected: filter == f.$1,
                  onSelected: (_) => setState(() => filter = f.$1),
                ),
            ],
          ),
        ),
        if (d.guests.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No families yet',
            body: 'Add each invited family with the Family button: how many people, which side, and which functions.',
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No families here.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            child: Column(
              children: [
                for (final g in list)
                  ListTile(
                    title: Row(
                      children: [
                        SideDot(g.side),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${g.name} · ${g.people}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      [
                        if (g.rel.isNotEmpty) g.rel,
                        if (g.city.isNotEmpty) g.city,
                        if (g.room != null) 'room ${g.room}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: StatusPill(g.status),
                    onTap: () => showGuestSheet(context, id: g.id),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final s in ['bride', 'groom'])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SideDot(s),
                    const SizedBox(width: 6),
                    Text(d.sideName(s), style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton(
            key: const Key('rooms'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => showRoomsSheet(context),
            child: IconLabel(
              icon: Icons.hotel_outlined,
              text: d.hotelRooms > 0
                  ? 'Allot hotel rooms (${d.hotelRooms}${d.hotelName.isEmpty ? '' : ' at ${d.hotelName}'})'
                  : 'Set up hotel rooms',
            ),
          ),
        ),
      ],
    );
  }
}
