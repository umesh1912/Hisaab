import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import '../widgets/post_card.dart';

/// "Nearby": every live post within your radius, newest first.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final now = store.now;
    final list = feedPosts(d.posts, d.radius, d.typeFilter, now);
    final live = liveAlertCount(list, now);
    final filters = ['all', ...postTypes];

    return ListView(
      key: const Key('feed'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ScreenTitle(live > 0 ? '$live live alert${live > 1 ? 's' : ''} near you' : 'All quiet near you'),
        const RadiusPicker(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final f in filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f == 'all' ? 'All' : (typeLabels[f] ?? f)),
                    selected: d.typeFilter == f,
                    onSelected: (_) => store.setTypeFilter(f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (list.isEmpty)
          EmptyState(
            icon: Icons.location_searching,
            title: 'Nothing here within ${radiusLabel(d.radius)}',
            body: d.posts.isEmpty
                ? 'Be the first: post an alert, a lost pet or something you found.'
                : 'Widen the radius, pick another type, or check back later.',
          )
        else
          for (final p in list) PostCard(key: ValueKey(p.id), post: p),
      ],
    );
  }
}
