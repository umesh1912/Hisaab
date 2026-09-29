import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/post_detail.dart';
import '../ui.dart';

/// A post in the feed: coloured stripe, headline, and the quick actions.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = post;
    final now = store.now;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final col = typeColor(context, p.type);

    Widget footer() {
      if (p.type == 'alert') {
        final exp = p.expiresAt;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AlertStatusPill(post: p),
                if (exp != null) Text('ends ${endsLabel(now, exp)}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: p.mine
                  ? Text('You posted this', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                  : p.myVote.isNotEmpty
                      ? Pill(
                          text: 'You said: ${p.myVote == 'yes' ? 'still on' : 'over'}',
                          bg: cs.secondaryContainer,
                          fg: cs.onSecondaryContainer,
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () => toast(context, store.vote(p.id, 'no')),
                              child: const Text('Over'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () => toast(context, store.vote(p.id, 'yes')),
                              child: const Text('Still on'),
                            ),
                          ],
                        ),
            ),
          ],
        );
      }
      final action = p.type == 'lost' ? 'I saw this' : (p.type == 'found' ? "It's mine" : 'Reply');
      return Row(
        children: [
          Expanded(
            child: Text(
              p.mine ? 'Posted by you' : 'Posted by ${p.by}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          if (!p.mine && !p.resolved)
            OutlinedButton(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => showPostDetail(context, p.id),
              child: Text(action),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showPostDetail(context, p.id),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TypeLabel(type: p.type, cat: p.cat)),
                        const SizedBox(width: 8),
                        Text(
                          '${kmText(p.km)} · ${ago(now, p.at)}',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      p.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (p.type == 'lost' && p.sightings.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${p.sightings.length} sighting${p.sightings.length == 1 ? '' : 's'}, latest ${ago(now, p.sightings.last.at)}'
                        '${p.reward.isNotEmpty ? ' · ${p.reward}' : ''}',
                        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ] else if (p.type == 'lost' && p.reward.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(p.reward, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                    if (p.resolved) ...[
                      const SizedBox(height: 8),
                      Pill(text: resolvedLabel(p.type), bg: goodSoft(context), fg: goodColor(context), icon: Icons.check),
                    ],
                    const SizedBox(height: 10),
                    Divider(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 10),
                    footer(),
                    if (p.safety) ...[
                      const SizedBox(height: 10),
                      const NoteBox(
                        icon: Icons.info_outline,
                        warn: true,
                        text: 'Reported by one person. In an emergency, call 112. '
                            'Galli shows safety reports without names or photos of suspects.',
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(left: 0, top: 0, bottom: 0, width: 5, child: ColoredBox(color: col)),
            ],
          ),
        ),
      ),
    );
  }
}
