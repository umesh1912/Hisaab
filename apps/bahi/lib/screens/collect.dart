import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/customer.dart';
import '../sheets/remind.dart';
import '../ui.dart';

/// Who to collect from first: ranked by amount and age of the debt; tick and remind together.
class CollectScreen extends StatefulWidget {
  const CollectScreen({super.key});

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  final selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final en = d.en;
    final today = todayIso();
    final due = collectList(d.customers, today);
    final promised = promisedList(d.customers, today);
    selected.removeWhere((id) => !due.any((c) => c.id == id));
    final tt = Theme.of(context).textTheme;

    String? remindedNote(Customer c) {
      if (c.reminded == null) return null;
      final when = relativeDay(c.reminded!, today, en);
      return en ? 'Reminded $when' : 'याद दिलाया: $when';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(en ? 'Collect from these first' : 'पहले इनसे लें', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          en
              ? 'Ordered by amount and how long it\'s been unpaid. Tick customers and send polite reminders together.'
              : 'रकम और कितने दिन से बाकी है, उसके हिसाब से क्रम। ग्राहक चुनें और सबको विनम्र याद दिलाएँ।',
        ),
        const SizedBox(height: 12),
        if (due.isEmpty)
          EmptyState(
            icon: Icons.task_alt,
            title: en ? 'Nothing to collect' : 'कुछ बाकी नहीं',
            body: en ? 'Nobody owes you money right now, or everyone has promised a date.' : 'अभी किसी पर पैसा बाकी नहीं है, या सबने तारीख का वादा किया है।',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  en ? '${due.length} customers' : '${due.length} ग्राहक',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (selected.length == due.length) {
                    selected.clear();
                  } else {
                    selected
                      ..clear()
                      ..addAll(due.map((c) => c.id));
                  }
                }),
                child: Text(selected.length == due.length ? (en ? 'Clear' : 'हटाएँ') : (en ? 'Select all' : 'सब चुनें')),
              ),
            ],
          ),
          LedgerBox(
            children: [
              for (final c in due)
                CustomerRow(
                  key: ValueKey('collect-${c.id}'),
                  customer: c,
                  selected: selected.contains(c.id),
                  extra: remindedNote(c),
                  onTap: () => setState(() {
                    if (!selected.remove(c.id)) selected.add(c.id);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('remind-selected'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: whatsAppGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: selected.isEmpty
                ? null
                : () async {
                    final ids = due.where((c) => selected.contains(c.id)).map((c) => c.id).toList();
                    await showRemindSheet(context, ids);
                    if (mounted) setState(selected.clear);
                  },
            icon: const Icon(Icons.chat_outlined),
            label: Text('${en ? 'Remind selected' : 'चुने हुओं को याद दिलाएँ'} (${selected.length})'),
          ),
        ],
        if (promised.isNotEmpty) ...[
          SectionTitle(en ? 'Promised to pay' : 'भुगतान का वादा'),
          LedgerBox(
            children: [
              for (final c in promised) CustomerRow(customer: c, onTap: () => showCustomerSheet(context, c.id)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        NoteBox(
          icon: Icons.shield_outlined,
          text: en
              ? 'Bahi opens WhatsApp with the message ready and you press send. Be kind: once every 3 days per customer at most, and never after 9 PM.'
              : 'Bahi संदेश भरकर WhatsApp खोलता है, भेजना आप दबाते हैं। एक ग्राहक को 3 दिन में एक बार से ज़्यादा नहीं, और रात 9 बजे के बाद कभी नहीं।',
        ),
      ],
    );
  }
}
