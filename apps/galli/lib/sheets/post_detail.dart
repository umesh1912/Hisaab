import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import '../widgets/map_view.dart';
import 'new_post.dart';
import 'report.dart';

Future<void> showPostDetail(BuildContext context, int id) => showAppSheet(context, (_) => PostDetail(id: id));

class PostDetail extends StatefulWidget {
  const PostDetail({super.key, required this.id});
  final int id;

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  final _sighting = TextEditingController();
  final _claim = TextEditingController();
  final _reply = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _sighting.dispose();
    _claim.dispose();
    _reply.dispose();
    super.dispose();
  }

  void _addSighting(Post p) {
    final t = _sighting.text.trim();
    if (t.isEmpty) return setState(() => _error = 'Say where you saw it, e.g. "Outside the depot, heading west".');
    StoreScope.read(context).addSighting(p.id, t);
    _sighting.clear();
    setState(() => _error = null);
    toast(context, 'Sighting added to the post and the map.');
  }

  void _sendClaim(Post p) {
    final t = _claim.text.trim();
    if (t.length < 10) return setState(() => _error = 'Describe it in a few words: brand, colour, what is inside.');
    StoreScope.read(context).claim(p.id, t);
    Navigator.pop(context);
    toast(context, 'Sent to the finder. Your conversation is in Inbox.');
  }

  void _sendReply(Post p) {
    final t = _reply.text.trim();
    if (t.isEmpty) return setState(() => _error = 'Write a reply first.');
    StoreScope.read(context).reply(p.id, t);
    Navigator.pop(context);
    toast(context, 'Reply sent privately. It is in Inbox.');
  }

  Future<void> _delete(Post p) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this post?',
      body: 'It is removed from the feed, the map and your inbox. This cannot be undone.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    final store = StoreScope.read(context);
    Navigator.pop(context);
    store.deletePost(p.id);
    toast(context, 'Post deleted.');
  }

  Future<void> _report(Post p) async {
    final done = await showReport(context, p.id);
    if (done == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final p = d?.post(widget.id);
    if (d == null || p == null) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('This post was removed.')));
    }
    final now = store.now;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ended = isEnded(p, now);

    final section = <Widget>[];
    switch (p.type) {
      case 'alert':
        final exp = p.expiresAt;
        section.addAll([
          _label(context, 'Updates'),
          _Timeline(rows: [
            [ago(now, p.at), p.official ? 'Posted by ${p.by}' : (p.mine ? 'Posted by you' : 'Posted')],
            [
              ago(now, p.at + 30 * minuteMs < now ? p.at + 30 * minuteMs : now),
              '${p.yes} neighbour${p.yes == 1 ? '' : 's'} confirmed, ${p.no} said it’s over',
            ],
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [AlertStatusPill(post: p)]),
          const SizedBox(height: 8),
          if (ended)
            Text('This alert has ended.', style: TextStyle(color: cs.onSurfaceVariant))
          else if (exp != null)
            Text(
              'This alert disappears at ${endsLabel(now, exp)} unless someone updates it.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          if (!p.mine && !ended) ...[
            const SizedBox(height: 12),
            Text(
              p.myVote.isEmpty
                  ? 'Is this still happening?'
                  : 'You said: ${p.myVote == 'yes' ? 'still on' : 'over'}. You can change it.',
              style: tt.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: p.myVote == 'no' ? null : () => toast(context, store.vote(p.id, 'no')),
                    child: const Text('Over'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: p.myVote == 'yes' ? null : () => toast(context, store.vote(p.id, 'yes')),
                    child: const Text('Still on'),
                  ),
                ),
              ],
            ),
          ],
        ]);
      case 'lost':
        final lastSeen = p.body.contains('Last seen ') ? 'Last seen: ${p.body.split('Last seen ').last}' : 'Reported lost';
        section.addAll([
          MapView(posts: [p], radius: d.radius, trails: [p], highlight: p.id),
          const SizedBox(height: 14),
          _label(context, 'Sightings'),
          _Timeline(rows: [
            for (final s in p.sightings.reversed) [ago(now, s.at), s.text],
            [ago(now, p.at), lastSeen],
          ]),
          if (!p.resolved) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _sighting,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: p.mine ? 'Add a sighting someone told you about' : 'Where did you see it?',
                hintText: 'e.g. Outside Kothrud depot, heading west',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: typeColor(context, 'lost'),
                foregroundColor: onTypeColor(context),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _addSighting(p),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add sighting'),
            ),
          ],
        ]);
      case 'found':
        if (!p.mine && !p.resolved) {
          section.addAll([
            TextField(
              controller: _claim,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Describe it to prove it's yours",
                hintText: "What's inside, brand, any marks",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => _sendClaim(p),
              child: const Text('Send to the finder'),
            ),
            const SizedBox(height: 6),
            Text(
              'The finder decides. Never pay anyone to get a lost item back.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ]);
        }
      default:
        if (!p.mine && !ended) {
          section.addAll([
            TextField(
              controller: _reply,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Reply',
                hintText: p.type == 'help' ? 'Suggest someone you know' : 'Will be there!',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => _sendReply(p),
              child: const Text('Reply privately'),
            ),
          ]);
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypeLabel(type: p.type, cat: p.cat),
        const SizedBox(height: 8),
        Text(p.title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${kmText(p.km)} away · ${ago(now, p.at)} · by ${p.mine ? 'you' : p.by}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (p.official) Pill(text: 'Verified group', bg: goodSoft(context), fg: goodColor(context), icon: Icons.check),
          ],
        ),
        const SizedBox(height: 10),
        if (p.body.isNotEmpty) Text(p.body, style: tt.bodyLarge),
        if (p.reward.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(p.reward, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
        if (p.resolved) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(text: resolvedLabel(p.type), bg: goodSoft(context), fg: goodColor(context), icon: Icons.check),
          ),
        ],
        if (p.place.isNotEmpty || d.locality.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.place.isNotEmpty ? 'Near ${p.place}' : d.locality,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => openExternal(context, mapsUrl(p.place, d.locality)),
                child: const Text('Open in Maps'),
              ),
            ],
          ),
        ],
        if (p.safety) ...[
          const SizedBox(height: 10),
          const NoteBox(
            icon: Icons.info_outline,
            warn: true,
            text: 'Reported by one person. In an emergency, call 112. '
                'Galli shows safety reports without names or photos of suspects.',
          ),
        ],
        const SizedBox(height: 16),
        ...section,
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        if (p.mine) ...[
          _label(context, 'Your post'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  store.setResolved(p.id, !p.resolved);
                  toast(context, p.resolved ? 'Marked as ${resolvedLabel(p.type).toLowerCase()}.' : 'Reopened.');
                },
                icon: Icon(p.resolved ? Icons.undo : Icons.check),
                label: Text(p.resolved ? 'Reopen' : resolveAction(p.type)),
              ),
              OutlinedButton.icon(
                onPressed: () => showNewPost(context, editId: p.id),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: cs.error),
                onPressed: () => _delete(p),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => openExternal(context, whatsappUrl(shareText(p, d.locality))),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ),
            if (!p.mine) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _report(p),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Widget _label(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );

/// Time-stamped rows, newest first.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      rows[i][0],
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
                    ),
                  ),
                  Expanded(child: Text(rows[i][1])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
