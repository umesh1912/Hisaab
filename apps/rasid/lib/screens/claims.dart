import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/claim_sheets.dart';
import '../sheets/item_sheet.dart';
import '../ui.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final claims = d.claims.reversed.toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text('Start a claim from any item in the vault. Rasid gathers the proof the service centre asks for.'),
        ),
        if (claims.isEmpty)
          const EmptyState(
            icon: Icons.build_outlined,
            title: 'No claims yet',
            body: 'When something breaks, open it in the vault and tap "Something\'s wrong".',
          ),
        for (final c in claims) ClaimCard(claimId: c.id),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: NoteBox(
            text: "Keep the reference number the service centre gives you. It's what you quote when you follow up or escalate.",
          ),
        ),
      ],
    );
  }
}

class ClaimCard extends StatelessWidget {
  const ClaimCard({super.key, required this.claimId});
  final int claimId;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final c = d.claim(claimId);
    final it = c == null ? null : d.item(c.itemId);
    if (c == null || it == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final days = daysBetween(c.started, today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => showItemSheet(context, it.id),
              child: Row(
                children: [
                  CatThumb(it.cat),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(c.issue, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tag(c.isOpen ? 'Open' : 'Fixed', tone: c.isOpen ? 'warn' : 'good'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < c.steps.length; i++) _StepRow(step: c.steps[i], last: i == c.steps.length - 1),
            const SizedBox(height: 4),
            Text(
              'Ref ${c.ref.isEmpty ? 'not added yet' : c.ref} · ${c.under}',
              style: TextStyle(fontFamily: mono, fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (c.isOpen)
                  FilledButton.tonal(onPressed: () => showClaimUpdate(context, c.id), child: const Text('Update status'))
                else
                  OutlinedButton(onPressed: () => showClaimUpdate(context, c.id), child: const Text('Edit')),
                if (c.isOpen && days >= 7)
                  OutlinedButton(onPressed: () => showEscalate(context, c.id), child: const Text("It's taking too long")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last});
  final ClaimStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final good = goodColor(context);
    final Color border = step.done ? good : (step.now ? cs.primary : cs.outlineVariant);
    final Color fill = step.done ? good : (step.now ? cs.primaryContainer : cs.surface);
    final sub = [step.date == null ? 'Pending' : shortDate(step.date!), if (step.note.isNotEmpty) step.note].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: Border.all(color: border, width: 2)),
                  child: step.done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                ),
                if (!last) Expanded(child: Container(width: 2, color: cs.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 4 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: TextStyle(fontWeight: step.now ? FontWeight.w700 : FontWeight.w600)),
                  Text(sub, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
