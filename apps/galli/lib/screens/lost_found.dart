import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/post_detail.dart';
import '../ui.dart';

/// Lost and found posts (up to 2 km and 14 days), with possible matches on top.
class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final now = store.now;
    final cs = Theme.of(context).colorScheme;
    final lost = lostFoundPosts(d.posts, 'lost', now);
    final found = lostFoundPosts(d.posts, 'found', now);
    final matches = possibleMatches(d.posts, now);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const ScreenTitle('Lost & found'),
        for (final m in matches) _MatchCard(match: m, told: d.told.contains(m.key)),
        SectionTitle('Lost', trailing: Text('${lost.length}', style: TextStyle(color: cs.onSurfaceVariant))),
        if (lost.isEmpty)
          _none(context, 'No lost pets or items nearby.')
        else
          _Grid(posts: lost),
        SectionTitle('Found', trailing: Text('${found.length}', style: TextStyle(color: cs.onSurfaceVariant))),
        if (found.isEmpty)
          _none(context, 'Nothing found and posted nearby.')
        else
          _Grid(posts: found),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Lost and found posts stay up for 14 days and reach 2 km, wider than alerts, because pets and people travel.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _none(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.told});
  final PossibleMatch match;
  final bool told;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = store.now;
    final l = match.lost;
    final f = match.found;
    final outside = f.km > d.radius;

    final buttons = <Widget>[
      FilledButton(
        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: () => showPostDetail(context, f.id),
        child: const Text('See the found post'),
      ),
    ];
    if (told) {
      buttons.add(Pill(text: l.mine ? 'Finder messaged' : 'Owner told', bg: cs.surface, fg: cs.onSurface, icon: Icons.check));
    } else if (l.mine) {
      buttons.add(OutlinedButton(
        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: () {
          store.messageFinder(l.id, f.id);
          toast(context, 'Message sent to the finder. It is in Inbox.');
        },
        child: const Text('Message the finder'),
      ));
    } else {
      buttons.add(OutlinedButton(
        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: () {
          store.tellOwner(l.id, f.id);
          toast(context, 'Sent to the owner, with the found post. +5 helpful points.');
        },
        child: const Text('Tell the owner'),
      ));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Possible match', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
          const SizedBox(height: 6),
          Text(
            '"${f.title}" was posted ${ago(now, f.at)}, ${kmText(f.km)} away. '
            '${outside ? "That's just outside your radius. " : ''}'
            'It may be ${l.mine ? 'yours' : 'the one in "${shortTitle(l.title, 40)}"'}.',
            style: TextStyle(color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: buttons),
        ],
      ),
    );
  }
}

/// Two-column grid of small cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.posts});
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < posts.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Mini(post: posts[i])),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < posts.length ? _Mini(post: posts[i + 1]) : const SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = post;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final col = typeColor(context, p.type);
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPostDetail(context, p.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeLabel(type: p.type, cat: p.cat),
              const SizedBox(height: 8),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(catIcon(p.cat), size: 36, color: col),
              ),
              const SizedBox(height: 8),
              Text(
                shortTitle(p.title, 60),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${kmText(p.km)} · ${ago(store.now, p.at)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (p.resolved) ...[
                const SizedBox(height: 6),
                Pill(text: resolvedLabel(p.type), bg: goodSoft(context), fg: goodColor(context), icon: Icons.check),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
