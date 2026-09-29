import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

// ---------------- new claim ----------------

Future<void> showNewClaim(BuildContext context, int itemId) => showAppSheet(context, (_) => _NewClaim(itemId: itemId));

class _NewClaim extends StatefulWidget {
  const _NewClaim({required this.itemId});
  final int itemId;

  @override
  State<_NewClaim> createState() => _NewClaimState();
}

class _NewClaimState extends State<_NewClaim> {
  final _details = TextEditingController();
  final _ref = TextEditingController();
  String issue = claimIssues.first;

  @override
  void initState() {
    super.initState();
    _details.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _details.removeListener(_refresh);
    _details.dispose();
    _ref.dispose();
    super.dispose();
  }

  String get _issueText {
    final det = _details.text.trim().replaceAll(RegExp(r'\.+$'), '');
    return det.isEmpty ? issue : '$issue: $det';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final it = store.data?.item(widget.itemId);
    if (it == null) return const SizedBox(height: 120, child: Center(child: Text('This item was removed.')));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final s = warrantyState(it, today);
    final w = s.warranty;
    final under = w == null ? 'Warranty' : '${w.label} warranty';
    final until = w?.until ?? today;
    final summary = claimSummary(it, _issueText, under, until);
    final brand = it.brand.trim().isEmpty ? 'the brand' : it.brand;

    Widget proof(String title, String sub, bool ok) => ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(ok ? Icons.check_circle : Icons.error_outline, color: ok ? goodColor(context) : warnColor(context)),
          title: Text(title),
          subtitle: Text(sub, style: const TextStyle(fontFamily: mono, fontSize: 12)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Claim for ${it.name.toLowerCase()}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Text("What's wrong?", style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final x in claimIssues)
              ChoiceChip(label: Text(x), selected: issue == x, onSelected: (_) => setState(() => issue = x)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _details,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Details (optional)', hintText: 'Makes a loud rattling sound on the highest speed'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ref,
          decoration: const InputDecoration(labelText: 'Service request number (if you have one)'),
        ),
        const SizedBox(height: 16),
        Text('What to send', style: tt.titleSmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(summary, style: const TextStyle(fontFamily: mono, fontSize: 12.5, height: 1.45)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => copyText(context, summary, 'Claim details copied.'),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            OutlinedButton.icon(
              onPressed: () => shareWhatsApp(context, summary),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Proof checklist', style: tt.titleSmall),
        proof('Invoice', it.inv.isEmpty ? 'Add the invoice number' : '${it.inv}, ${shortDate(it.date)}', it.inv.isNotEmpty),
        proof('Serial number', it.serial.isEmpty ? 'Add it from the sticker' : it.serial, it.serial.isNotEmpty),
        proof('Warranty valid', w == null ? 'No warranty found' : 'until ${longDate(until)}', s.cover != Cover.out),
        const SizedBox(height: 4),
        Text(
          "Send this through $brand's service request form, customer care or WhatsApp. Save the claim here to track it.",
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            store.raiseClaim(item: it, issue: _issueText, under: under, ref: _ref.text.trim());
            Navigator.of(context).popUntil((r) => r.isFirst);
            store.goTab(2);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Claim saved for ${it.title}. Proof is dated before the warranty ends.'),
              ));
          },
          child: Text('Raise claim with $brand', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ---------------- update a claim ----------------

Future<void> showClaimUpdate(BuildContext context, int claimId) => showAppSheet(context, (_) => _ClaimUpdate(claimId: claimId));

class _ClaimUpdate extends StatefulWidget {
  const _ClaimUpdate({required this.claimId});
  final int claimId;

  @override
  State<_ClaimUpdate> createState() => _ClaimUpdateState();
}

class _ClaimUpdateState extends State<_ClaimUpdate> {
  final _step = TextEditingController();
  final _note = TextEditingController();
  final _ref = TextEditingController();
  bool _refLoaded = false;

  static const _presets = ['Technician visited', 'Waiting for spare part', 'Part replaced', 'Replacement approved', 'Picked up for repair'];

  @override
  void dispose() {
    _step.dispose();
    _note.dispose();
    _ref.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = store.data?.claim(widget.claimId);
    if (c == null) return const SizedBox(height: 120, child: Center(child: Text('This claim was removed.')));
    if (!_refLoaded) {
      _ref.text = c.ref;
      _refLoaded = true;
    }
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final cur = c.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.isOpen ? 'Update status' : 'Claim details', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(c.issue, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (c.isOpen && cur != null) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              store.advance(c.id);
              final done = !(store.data?.claim(c.id)?.isOpen ?? false);
              Navigator.pop(context);
              toast(context, done ? 'Marked as repaired. Nice.' : 'Status updated.');
            },
            icon: const Icon(Icons.check),
            label: Text('Done: ${cur.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 16),
        ],
        if (c.isOpen) ...[
          Text('Or add what happened', style: tt.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [for (final p in _presets) ActionChip(label: Text(p), onPressed: () => setState(() => _step.text = p))],
          ),
          const SizedBox(height: 8),
          TextField(controller: _step, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Step')),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Promised within 5 working days'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  final t = _step.text.trim();
                  if (t.isEmpty) return;
                  store.addStep(c.id, t, _note.text.trim());
                  Navigator.pop(context);
                  toast(context, 'Status updated.');
                },
                child: const Text('Add update'),
              ),
              OutlinedButton(
                onPressed: () {
                  store.markRepaired(c.id);
                  Navigator.pop(context);
                  toast(context, 'Marked as repaired. Nice.');
                },
                child: const Text('Mark as repaired'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text('Reference number', style: tt.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(controller: _ref, decoration: const InputDecoration(hintText: 'BSH-SR-2609-55812', isDense: true))),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                store.setClaimRef(c.id, _ref.text.trim());
                toast(context, 'Reference saved.');
              },
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () async {
            final ok = await confirm(context, title: 'Delete this claim?', body: 'Its timeline will be removed. The item stays in the vault.', action: 'Delete');
            if (!ok || !context.mounted) return;
            store.deleteClaim(c.id);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete claim'),
        ),
      ],
    );
  }
}

// ---------------- escalate ----------------

Future<void> showEscalate(BuildContext context, int claimId) => showAppSheet(context, (_) => _Escalate(claimId: claimId));

class _Escalate extends StatelessWidget {
  const _Escalate({required this.claimId});
  final int claimId;

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final c = d?.claim(claimId);
    final it = c == null ? null : d?.item(c.itemId);
    if (c == null || it == null) return const SizedBox(height: 120, child: Center(child: Text('This claim was removed.')));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final text = escalationText(it, c, todayIso());

    Widget step(String n, String title, String sub) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 14, backgroundColor: cs.secondaryContainer, child: Text(n, style: TextStyle(color: cs.onSecondaryContainer))),
          title: Text(title),
          subtitle: Text(sub),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Escalate this claim', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          "Most delays are solved by escalating to the brand first. If that fails, the National Consumer Helpline and the government's e-Jagriti portal can help.",
        ),
        const SizedBox(height: 8),
        step('1', "Email ${it.brand}'s customer care head", 'Use the complaint below, with your reference number'),
        step('2', 'National Consumer Helpline', 'Call 1915, or file online. They contact the company for you.'),
        step('3', 'e-Jagriti consumer complaint', 'Formal complaint under the Consumer Protection Act, 2019'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(text, style: const TextStyle(fontFamily: mono, fontSize: 12, height: 1.45)),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => copyText(context, text, 'Complaint text copied.'),
          icon: const Icon(Icons.copy),
          label: const Text('Copy complaint text'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => openExternal(context, 'tel:1915'),
              icon: const Icon(Icons.call_outlined, size: 18),
              label: const Text('Call 1915'),
            ),
            OutlinedButton.icon(
              onPressed: () => openExternal(context, 'https://consumerhelpline.gov.in'),
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('Helpline site'),
            ),
            OutlinedButton.icon(
              onPressed: () => openExternal(context, 'https://e-jagriti.gov.in'),
              icon: const Icon(Icons.gavel, size: 18),
              label: const Text('e-Jagriti'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('This is general information, not legal advice.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
