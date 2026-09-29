import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Sends reminders to several customers. WhatsApp opens one chat at a time, so each gets a Send button.
Future<void> showRemindSheet(BuildContext context, List<int> ids) {
  return showAppSheet(context, (_) => RemindSheet(ids: ids));
}

class RemindSheet extends StatefulWidget {
  const RemindSheet({super.key, required this.ids});
  final List<int> ids;

  @override
  State<RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends State<RemindSheet> {
  final sent = <int>{};

  Future<void> _send(Customer c) async {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final en = store.en;
    final ok = await openExternal(
      context,
      whatsAppLink(c.phone, reminderText(d.shop, c, en)),
      failMessage: en ? 'WhatsApp is not installed.' : 'WhatsApp नहीं मिला।',
    );
    if (!ok) return;
    store.markReminded(c.id);
    if (mounted) setState(() => sent.add(c.id));
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final en = isEn(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (d == null) return const SizedBox.shrink();
    final today = todayIso();
    final customers = [
      for (final id in widget.ids)
        if (d.customer(id) != null) d.customer(id)!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(en ? 'Send reminders' : 'याद दिलाएँ', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          en
              ? 'Tap Send for each customer. WhatsApp opens with the message ready; press send there and come back for the next one.'
              : 'हर ग्राहक के लिए "भेजें" दबाएँ। WhatsApp संदेश भरकर खुलेगा; वहाँ भेजें और अगले के लिए वापस आएँ।',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        if (quietHours(DateTime.now())) ...[
          const SizedBox(height: 10),
          NoteBox(
            icon: Icons.nightlight_outlined,
            text: en ? 'It\'s outside 9 AM to 9 PM. Better to send these in the morning.' : 'अभी सुबह 9 से रात 9 के बाहर का समय है। सुबह भेजना ठीक रहेगा।',
          ),
        ],
        const SizedBox(height: 12),
        for (final c in customers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Initial(id: c.id, name: c.display(en), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.display(en), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        [
                          inr(balanceOf(c)),
                          if (phoneForWhatsApp(c.phone).isEmpty) en ? 'no mobile number' : 'मोबाइल नंबर नहीं',
                          if (remindedRecently(c, today) && !sent.contains(c.id))
                            en ? 'reminded ${relativeDay(c.reminded!, today, en)}' : '${relativeDay(c.reminded!, today, en)} याद दिलाया',
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                sent.contains(c.id)
                    ? Icon(Icons.check_circle, color: goodColor(context), semanticLabel: en ? 'Sent' : 'भेजा')
                    : FilledButton.tonal(
                        onPressed: () => _send(c),
                        child: Text(en ? 'Send' : 'भेजें'),
                      ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context),
          child: Text(en ? 'Done' : 'हो गया'),
        ),
      ],
    );
  }
}
