import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/person.dart';
import '../ui.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _q = TextEditingController();
  final _f = PeopleFilter();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = discoverPeople(d, _f);
    final twoWay = list.where((p) => isTwoWay(p, d.me)).length;
    final today = todayIso();
    final blocked = store.blockedSet;
    final circles = d.circles
        .where((c) => !c.attended && !blocked.contains(c.host) && (c.joined || c.date.compareTo(today) >= 0))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            '${greeting(DateTime.now())}, ${d.me.name}. $twoWay two-way ${twoWay == 1 ? 'match' : 'matches'} near you.',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _q,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _f.query = v),
            decoration: InputDecoration(
              hintText: 'Guitar, Kannada, Python…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _f.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _q.clear();
                        _f.query = '';
                      }),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Wants my skills'),
                selected: _f.mutual,
                onSelected: (v) => setState(() => _f.mutual = v),
              ),
              FilterChip(
                label: const Text('Within 2 km'),
                selected: _f.near,
                onSelected: (v) => setState(() => _f.near = v),
              ),
              FilterChip(
                label: const Text('Online'),
                selected: _f.online,
                onSelected: (v) => setState(() => _f.online = v),
              ),
              FilterChip(
                label: const Text('ID verified'),
                selected: _f.verified || d.me.verifiedOnly,
                onSelected: (v) {
                  setState(() => _f.verified = v);
                  if (!v && d.me.verifiedOnly) store.setVerifiedOnly(false);
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final e in [const MapEntry('all', 'All'), ...categories.entries])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _f.cat == e.key,
                    onSelected: (_) => setState(() => _f.cat = e.key),
                  ),
                ),
            ],
          ),
        ),
        for (final c in circles) _CircleCard(circle: c),
        SectionTitle(
          'Best matches',
          trailing: Text('${list.length} ${list.length == 1 ? 'person' : 'people'}', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No one matches these filters',
            body: 'Try widening the distance or clearing a filter.',
          )
        else
          for (final p in list) PersonCard(person: p),
      ],
    );
  }
}

class PersonCard extends StatelessWidget {
  const PersonCard({super.key, required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final p = person;
    final tw = theyWantMine(p, d.me);
    final mutual = isTwoWay(p, d.me);
    final learns = d.me.learns.map((s) => s.toLowerCase()).toSet();
    final km = p.km;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPerson(context, p.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(p, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            if (mutual) const Tag('Two-way match', icon: Icons.swap_horiz, tone: TagTone.match),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: starColor(context)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${p.rating.toStringAsFixed(1)} · ${p.swaps} swaps · '
                                '${km != null ? '$km km' : 'Online'}${p.online && km != null ? ' · also online' : ''}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final t in p.teaches) SkillPill(t.name, highlight: learns.contains(t.name.toLowerCase()))],
              ),
              const SizedBox(height: 10),
              if (tw.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 18, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wants ${tw.join(', ')}, which you teach',
                          style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Wants to learn: ${p.wants.join(', ')}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});
  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = circle;
    final host = d.person(c.host);
    final km = host?.km;
    final fg = cs.onSecondaryContainer;
    final today = todayIso();
    final canAttend = c.joined && c.date.compareTo(today) <= 0;

    Widget button;
    if (canAttend) {
      button = FilledButton(
        onPressed: () {
          store.attendCircle(c.id);
          toast(context, '${hrsText(c.cost)} credit spent on ${c.title}.');
        },
        child: const Text('I attended'),
      );
    } else if (c.joined) {
      button = OutlinedButton(
        onPressed: () {
          store.toggleCircle(c.id);
          toast(context, 'Seat released. Your credit is free again.');
        },
        child: const Text('Leave circle'),
      );
    } else {
      button = FilledButton(
        onPressed: c.left <= 0
            ? null
            : () {
                final err = store.toggleCircle(c.id);
                toast(context, err ?? 'Seat booked. ${hrsText(c.cost)} credit set aside until ${dayName(c.date)}.');
              },
        child: const Text('Book a seat'),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CIRCLE${km != null ? ' · $km KM AWAY' : ''}${c.joined ? ' · BOOKED' : ''}',
            style: tt.labelSmall?.copyWith(color: fg, letterSpacing: 1.1, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${c.title} with ${host?.first ?? 'a neighbour'}',
            style: tt.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${dayName(c.date)} ${shortDate(c.date)}, ${t12(c.time)} · ${c.place} · ${hrsText(c.cost)} credit',
            style: TextStyle(color: fg, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: c.seats == 0 ? 0 : c.taken / c.seats,
              minHeight: 6,
              color: cs.primary,
              backgroundColor: cs.surface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('${c.left} of ${c.seats} seats left', style: TextStyle(color: fg, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              button,
            ],
          ),
        ],
      ),
    );
  }
}
