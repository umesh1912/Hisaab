import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'chat.dart';
import 'report.dart';
import 'request.dart';

Future<void> showPerson(BuildContext context, String id) =>
    showAppSheet(context, (_) => _PersonSheet(id: id, host: context));

class _PersonSheet extends StatelessWidget {
  const _PersonSheet({required this.id, required this.host});
  final String id;
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final p = d?.person(id);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (d == null || p == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This profile is no longer available.'));
    }
    final tw = theyWantMine(p, d.me);
    final learns = d.me.learns.map((s) => s.toLowerCase()).toSet();
    final mine = d.me.teachNames.map((s) => s.toLowerCase()).toSet();
    final km = p.km;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(p.name),
        Row(
          children: [
            PersonAvatar(p, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: starColor(context)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${p.rating.toStringAsFixed(1)} · ${p.swaps} swaps',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.area}${km != null ? ' · $km km' : ''}${p.online ? ' · teaches online' : ''}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Tag('Phone', icon: Icons.check, tone: TagTone.ok),
                      p.verified
                          ? const Tag('ID verified', icon: Icons.check, tone: TagTone.ok)
                          : const Tag('ID not verified'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (p.bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(p.bio, style: tt.bodyLarge),
        ],
        const FieldLabel('Teaches'),
        for (final t in p.teaches)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${categories[t.cat] ?? 'Other'} · ${t.level}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                if (learns.contains(t.name.toLowerCase())) const Tag('On your list', tone: TagTone.match),
              ],
            ),
          ),
        const FieldLabel('Wants to learn'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final w in p.wants) SkillPill(w, highlight: mine.contains(w.toLowerCase()))],
        ),
        const SizedBox(height: 8),
        Text(
          tw.isNotEmpty
              ? 'You teach ${tw.join(' and ')}, so you can swap hour for hour.'
              : "You don't teach what ${p.first} wants yet. You can pay with credits instead.",
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        const FieldLabel('Reviews'),
        if (p.reviews.isEmpty)
          Text('No reviews yet.', style: TextStyle(color: cs.onSurfaceVariant))
        else
          for (final r in p.reviews)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.by, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Stars(r.stars),
                    ],
                  ),
                  if (r.text.isNotEmpty) ...[const SizedBox(height: 4), Text(r.text)],
                ],
              ),
            ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () {
                  Navigator.pop(context);
                  showChat(host, p.id);
                },
                child: const Text('Message'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () {
                  Navigator.pop(context);
                  showRequest(host, p.id);
                },
                child: const Text('Request a swap'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
              showReport(host, p.id);
            },
            child: Text('Report or block ${p.first}', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}
