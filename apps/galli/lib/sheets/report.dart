import 'package:flutter/material.dart';

import '../ui.dart';

const reportReasons = [
  'False or rumour',
  "Shares someone's private details",
  'Hateful or targets a community',
  'Spam or selling',
  'Something else',
];

/// Asks why a post is being reported. Returns true when it was reported (and hidden).
Future<bool?> showReport(BuildContext context, int postId) =>
    showAppSheet<bool>(context, (_) => _ReportSheet(postId: postId));

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.postId});
  final int postId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? reason;
  String? error;

  void _send() {
    if (reason == null) {
      setState(() => error = 'Choose a reason.');
      return;
    }
    StoreScope.read(context).hidePost(widget.postId);
    Navigator.pop(context, true);
    toast(context, 'Reported and hidden from your feed. You can show hidden posts again from You.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Report this post', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final r in reportReasons)
              ChoiceChip(
                label: Text(r),
                selected: reason == r,
                onSelected: (_) => setState(() {
                  reason = r;
                  error = null;
                }),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _send,
          child: const Text('Report and hide'),
        ),
        const SizedBox(height: 8),
        Text(
          'The post is hidden on this phone straight away. If it could put someone in danger, call 112.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
