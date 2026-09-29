import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final b = store.balanceHrs;
    final r = reserved(d.sessions, d.circles);
    final free = b - r;
    final fg = cs.onPrimary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TIME CREDITS', style: tt.labelMedium?.copyWith(color: fg, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${b < 0 ? '−' : ''}${hrsText(b)}',
                      style: tt.displayMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Text('hours', style: tt.titleMedium?.copyWith(color: fg)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                r > 0
                    ? '${hrsText(r)} hr set aside for booked lessons. ${hrsText(free > 0 ? free : 0)} hr free to spend.'
                    : 'All of it is free to spend on lessons.',
                style: TextStyle(color: fg),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Pill('Taught ${hrsText(taughtHours(d.ledger))} hr'),
                  _Pill('Learnt ${hrsText(learntHours(d.ledger))} hr'),
                ],
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How credits work', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'One hour of teaching earns one credit, whatever the skill. An hour of Python is worth the same as an hour of Kannada. '
                  "Spend credits to learn from anyone, even if they don't want your skills.",
                ),
                const SizedBox(height: 6),
                Text(
                  'New members get 2 welcome credits. Credits can\'t be bought or turned into money.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(
          'History',
          trailing: Text('${d.ledger.length} ${d.ledger.length == 1 ? 'entry' : 'entries'}', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        if (d.ledger.isEmpty)
          const EmptyState(icon: Icons.hourglass_empty, title: 'No credits yet', body: 'Teach a session to earn your first credit.')
        else
          Card(
            child: Column(
              children: [
                for (final l in d.ledger)
                  ListTile(
                    title: Text(l.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(shortDate(l.date)),
                    trailing: Text(
                      '${signedHrs(l.hrs)} hr',
                      style: TextStyle(color: creditColor(context, l.hrs), fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
