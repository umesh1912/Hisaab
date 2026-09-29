import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/item_form.dart';
import '../sheets/item_sheet.dart';
import '../ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final items = d.items;
    final covered = items.where((i) => warrantyState(i, today).cover != Cover.out).toList();
    final soon = items.where((i) => warrantyState(i, today).cover == Cover.soon).toList()
      ..sort((a, b) => (warrantyState(a, today).days ?? 0).compareTo(warrantyState(b, today).days ?? 0));
    final value = coveredValue(items, today);
    final open = d.claims.where((c) => c.isOpen).toList();
    final recent = [...items]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      key: const Key('home-list'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Still under warranty', style: tt.titleSmall?.copyWith(color: cs.onInverseSurface)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  inr(value),
                  style: tt.displaySmall?.copyWith(fontFamily: mono, fontWeight: FontWeight.w700, color: cs.onInverseSurface),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outline),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _HeroStat(value: '${items.length}', label: 'items saved')),
                  Expanded(child: _HeroStat(value: '${covered.length}', label: 'covered today')),
                  Expanded(
                    child: _HeroStat(
                      value: '${soon.length}',
                      label: 'end in 30 days',
                      color: soon.isEmpty ? null : const Color(0xFFF2BE4C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _QuickButton(
                  icon: Icons.document_scanner_outlined,
                  title: 'Add a bill',
                  sub: 'Type in the details',
                  onTap: () => showItemForm(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.mail_outline,
                  title: 'Order email',
                  sub: 'Paste the text',
                  onTap: () => showItemForm(context, paste: true),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Your vault is empty',
            body: 'Add the bill for an appliance or gadget. Rasid tracks its warranty and reminds you before it ends.',
          ),
        if (soon.isNotEmpty) ...[
          const SectionTitle('Ending soon'),
          ListCard(children: [for (final i in soon) ItemRow(item: i, onTap: () => showItemSheet(context, i.id))]),
        ],
        if (open.isNotEmpty) ...[
          const SectionTitle('Open repair'),
          for (final c in open) _OpenClaim(claimId: c.id),
        ],
        if (items.isNotEmpty) ...[
          SectionTitle(
            'Recently added',
            trailing: TextButton(onPressed: () => store.goTab(1), child: Text('All ${items.length}')),
          ),
          ListCard(children: [for (final i in recent.take(3)) ItemRow(item: i, onTap: () => showItemSheet(context, i.id))]),
        ],
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontFamily: mono, fontSize: 18, fontWeight: FontWeight.w700, color: color ?? cs.onInverseSurface)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onInverseSurface)),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.icon, required this.title, required this.sub, required this.onTap});
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenClaim extends StatelessWidget {
  const _OpenClaim({required this.claimId});
  final int claimId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final c = d.claim(claimId);
    final it = c == null ? null : d.item(c.itemId);
    if (c == null || it == null) return const SizedBox.shrink();
    final cur = c.current;
    final today = todayIso();
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => store.goTab(2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CatThumb(it.cat),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${cur?.title ?? 'In progress'} · since ${shortDate(cur?.date ?? c.started)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tag('Day ${daysBetween(c.started, today)}', tone: 'warn'),
            ],
          ),
        ),
      ),
    );
  }
}
