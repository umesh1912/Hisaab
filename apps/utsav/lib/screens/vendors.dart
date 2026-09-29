import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/payment.dart';
import '../sheets/vendor.dart';
import '../ui.dart';

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();

    if (d.vendors.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No vendors yet',
            body: 'Add the venue, caterer, decorator and others with the Vendor button to track every balance and due date.',
          ),
        ],
      );
    }

    final owed = d.vendors.fold<int>(0, (a, v) => a + v.left);
    final vendors = [...d.vendors]
      ..sort((a, b) {
        if (a.hasNext != b.hasNext) return a.hasNext ? -1 : 1;
        if (a.hasNext && b.hasNext) return a.nextDue!.compareTo(b.nextDue!);
        return a.name.compareTo(b.name);
      });

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            owed > 0 ? '${inr(owed)} still to pay across ${d.vendors.length} vendors' : 'Every vendor is fully paid',
            style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        for (final v in vendors) _VendorCard(vendor: v, today: today),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            "Write down what was agreed in each vendor's notes, so the whole family knows the terms.",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor, required this.today});
  final Vendor vendor;
  final String today;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final v = vendor;
    final soon = v.hasNext && daysBetween(today, v.nextDue!) <= 10;
    final late = v.hasNext && v.nextDue!.compareTo(today) < 0;
    final progress = v.total <= 0 ? 1.0 : (v.paid / v.total).clamp(0.0, 1.0).toDouble();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showVendorSheet(context, id: v.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              Text(
                '${v.cat.isEmpty ? 'Vendor' : v.cat} · paid ${inr(v.paid)} of ${inr(v.total)}',
                style: TextStyle(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (v.hasNext)
                Text(
                  late
                      ? 'Overdue: ${inr(v.nextAmount!)} was due ${shortDate(v.nextDue!)}'
                      : 'Next: ${inr(v.nextAmount!)} on ${shortDate(v.nextDue!)}',
                  style: soon ? TextStyle(color: cs.error, fontWeight: FontWeight.w800) : TextStyle(color: cs.onSurfaceVariant),
                )
              else if (v.left <= 0)
                Text('Fully paid', style: TextStyle(color: goodColor(context), fontWeight: FontWeight.w800))
              else
                Text('${inr(v.left)} left, no date set', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: cs.surfaceContainerHighest),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (v.left > 0)
                    FilledButton.tonal(
                      onPressed: () => showPaymentSheet(context, v.id),
                      child: const Text('Record payment'),
                    ),
                  if (v.phone.isNotEmpty)
                    IconButton(
                      tooltip: 'Call ${v.name}',
                      onPressed: () => callPhone(context, v.phone),
                      icon: const Icon(Icons.call_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
