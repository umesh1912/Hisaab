import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/post_detail.dart';
import '../ui.dart';
import '../widgets/map_view.dart';

/// Pins for every live post within your radius, with trails of sightings.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final now = store.now;
    final cs = Theme.of(context).colorScheme;
    final list = feedPosts(d.posts, d.radius, 'all', now);
    final trails = list.where((p) => p.type == 'lost' && p.sightings.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ScreenTitle('${list.length} post${list.length == 1 ? '' : 's'} on the map'),
        const RadiusPicker(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MapView(
            posts: list,
            radius: d.radius,
            trails: trails,
            onPinTap: (p) => showPostDetail(context, p.id),
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 4), child: MapLegend()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            'A schematic map around ${d.locality.isEmpty ? 'you' : d.locality}. Pins are placed by distance, '
            'near but not on the reported spot, and exact home addresses are never shown. '
            '${trails.isEmpty ? '' : 'Dotted purple lines are trails of sightings for lost pets. '}'
            'Open a post to see the place in Maps.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        if (list.isNotEmpty) const SectionTitle('On the map'),
        for (final p in list)
          ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: typeColor(context, p.type),
              child: Text(
                (typeLabels[p.type] ?? '?')[0],
                style: TextStyle(color: onTypeColor(context), fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${kmText(p.km)} · ${ago(now, p.at)}'),
            onTap: () => showPostDetail(context, p.id),
          ),
      ],
    );
  }
}
