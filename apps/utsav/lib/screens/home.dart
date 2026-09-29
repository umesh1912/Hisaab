import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/payment.dart';
import '../ui.dart';
import 'tasks.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGo, required this.onGuests});
  final void Function(int tab) onGo;
  final void Function(String eventId) onGuests;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final evs = d.sortedEvents;
    final days = daysBetween(today, d.weddingDate);
    final confirmed = peopleConfirmed(d.guests);
    final waiting = familiesWaiting(d.guests);
    final totals = budgetTotals(d.budget);
    final late = d.tasks.where((t) => isOverdue(t, today)).toList();
    final soon = openTasks(d.tasks).take(3).toList();
    final dueVendors = d.vendors.where((v) => v.hasNext).toList()..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    final pay = dueVendors.isEmpty ? null : dueVendors.first;

    final place = [
      if (d.city.isNotEmpty) d.city,
      evs.isEmpty ? longDate(d.weddingDate) : dateRange(evs.first.date, evs.last.date),
    ].join(' · ');

    final String cdNum;
    final String cdLabel;
    if (days > 0) {
      cdNum = '$days';
      cdLabel = days == 1 ? 'day to the wedding' : 'days to the wedding';
    } else if (days == 0) {
      cdNum = 'Today';
      cdLabel = 'is the wedding day';
    } else {
      cdNum = '${-days}';
      cdLabel = 'days since the wedding';
    }

    final onP = cs.onPrimary;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        // Hero
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place, style: tt.labelLarge?.copyWith(color: onP), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(
                d.couple,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.headlineMedium?.copyWith(color: onP, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _HeroNum(value: cdNum, label: cdLabel, color: onP)),
                  const SizedBox(width: 12),
                  Expanded(child: _HeroNum(value: '$confirmed', label: 'guests confirmed', color: onP)),
                ],
              ),
            ],
          ),
        ),

        // Events strip
        if (evs.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: evs.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final e = evs[i];
                return EventCard(
                  event: e,
                  sub: '${dayName(e.date)} ${shortDate(e.date)}, ${time12(e.time)}',
                  count: confirmedFor(d.guests, e.id),
                  selected: false,
                  onTap: () => onGuests(e.id),
                );
              },
            ),
          ),

        if (late.isNotEmpty)
          NoteBanner(
            danger: true,
            bold: '${late.length} task${late.length > 1 ? 's' : ''} overdue:',
            text: late.map((t) => t.title).join('; '),
          ),

        StatRow(items: [
          ('$waiting', waiting == 1 ? 'family yet to reply' : 'families yet to reply'),
          (inrShort(totals.com), 'committed of ${inrShort(totals.est)}'),
          (inrShort(totals.paid), 'paid so far'),
        ]),

        if (pay != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEXT PAYMENT', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(pay.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                        Text(
                          '${inr(pay.nextAmount ?? 0)} due ${shortDate(pay.nextDue!)}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () => showPaymentSheet(context, pay.id), child: const Text('Record')),
                ],
              ),
            ),
          ),

        SectionTitle('Coming up', trailing: TextButton(onPressed: () => onGo(2), child: const Text('All tasks'))),
        if (soon.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No open tasks. Add one with the Task button.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            child: Column(children: [for (final t in soon) TaskTile(task: t)]),
          ),
      ],
    );
  }
}

class _HeroNum extends StatelessWidget {
  const _HeroNum({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(color: color, fontSize: 40, height: 1, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// A small card for one function, used on Home and Guests.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.sub, required this.count, required this.selected, required this.onTap});
  final WEvent event;
  final String? sub;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 132,
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: selected ? cs.onPrimaryContainer : cs.onSurface),
                ),
                if (sub != null)
                  Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('$count coming', maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
