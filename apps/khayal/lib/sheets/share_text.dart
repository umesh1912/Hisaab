import 'package:flutter/material.dart';

import '../ui.dart';

/// Shows a ready-made message with Copy and WhatsApp buttons.
Future<void> showShareText(
  BuildContext context, {
  required String title,
  required String intro,
  required String text,
  String phone = '',
  List<Widget> details = const [],
  String copied = 'Copied.',
}) {
  return showAppSheet(
    context,
    (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title),
          if (intro.isNotEmpty) ...[
            Text(intro),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
            child: SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details,
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => copyText(ctx, text, copied),
                  child: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => whatsApp(ctx, phone, text),
                  child: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
