import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showReport(BuildContext context, String id) => showAppSheet(context, (_) => _ReportSheet(id: id));

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.id});
  final String id;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = ['Asked for money or OTP', 'Made me feel unsafe', "Didn't show up", 'Fake profile', 'Something else'];
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.data?.person(widget.id);
    final cs = Theme.of(context).colorScheme;
    if (p == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This profile is no longer available.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Block ${p.first}'),
        Text('What happened? ${p.first} won\'t know you blocked them.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final r in _reasons)
              ChoiceChip(label: Text(r), selected: _reason == r, onSelected: (_) => setState(() => _reason = r)),
          ],
        ),
        const SizedBox(height: 14),
        const InfoNote(
          'Blocking hides them from Discover and Messages and cancels any open requests or sessions with them. '
          'You can unblock them later from Profile.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: cs.error, foregroundColor: cs.onError),
          onPressed: () {
            store.block(p.id);
            Navigator.pop(context);
            toast(context, '${p.first} is blocked.');
          },
          child: Text('Block ${p.first}'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
