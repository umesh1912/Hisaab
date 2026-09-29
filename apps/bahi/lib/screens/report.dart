import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/customer.dart';
import '../sheets/day_sales.dart';
import '../sheets/settings.dart';
import '../ui.dart';

/// Seven days of counter sales (cash and UPI), the largest balances, and settings.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final en = d.en;
    final today = todayIso();
    final days = [for (var i = 6; i >= 0; i--) addDaysIso(today, -i)];
    final week = [for (final day in days) d.sales[day] ?? DaySales()];
    final total = week.fold<int>(0, (a, s) => a + s.total);
    final upi = week.fold<int>(0, (a, s) => a + s.upi);
    final top = byBalance(d.customers).where((c) => balanceOf(c) > 0).take(4).toList();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '${en ? 'Last 7 days' : 'पिछले 7 दिन'}: ${inr(total)}',
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeekBars(days: days, week: week),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Legend(color: brandRed, label: en ? 'Cash' : 'नकद'),
                    const _Legend(color: turmeric, label: 'UPI'),
                    if (total > 0)
                      Text('${(upi * 100 / total).round()}% UPI', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showDaySalesSheet(context, today),
                    child: Text(en ? 'Write sales for a day' : 'किसी दिन की बिक्री लिखें'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(en ? 'Largest balances' : 'सबसे ज़्यादा बाकी'),
        if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(en ? 'Nobody owes you money.' : 'किसी पर पैसा बाकी नहीं।', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          LedgerBox(
            children: [
              for (final c in top) CustomerRow(customer: c, onTap: () => showCustomerSheet(context, c.id)),
            ],
          ),
        SectionTitle(en ? 'Shop and data' : 'दुकान और डेटा'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(en ? 'Shop details' : 'दुकान की जानकारी'),
                subtitle: Text(d.shop.upi.isEmpty ? (en ? 'Add your UPI ID for reminders' : 'रिमाइंडर के लिए UPI ID जोड़ें') : d.shop.upi, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showSettingsSheet(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.translate),
                title: const Text('English'),
                subtitle: Text(en ? 'Switch off for Hindi' : 'हिंदी के लिए बंद रखें'),
                value: en,
                onChanged: (v) => store.setLang(v ? 'en' : 'hi'),
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(en ? 'Backup and restore' : 'बैकअप और वापसी'),
                subtitle: Text(en ? 'Everything is saved on this phone. Copy a backup to keep it safe.' : 'सारा डेटा इसी फ़ोन में है। सुरक्षित रखने के लिए बैकअप कॉपी करें।'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showSettingsSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Stacked bars: cash at the bottom (red), UPI on top (turmeric).
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days, required this.week});
  final List<String> days;
  final List<DaySales> week;

  static const _barMax = 90.0;

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    final cs = Theme.of(context).colorScheme;
    var mx = 0;
    for (final s in week) {
      if (s.total > mx) mx = s.total;
    }
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < week.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          week[i].total == 0 ? '–' : '${(week[i].total / 100000).toStringAsFixed(1)}k',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _stack(context, week[i], mx),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(dayShort(days[i], en), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stack(BuildContext context, DaySales s, int mx) {
    final h = mx == 0 ? 0.0 : s.total / mx * _barMax;
    final upiH = s.total == 0 ? 0.0 : h * s.upi / s.total;
    final cashH = h - upiH;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            Container(height: upiH, color: turmeric),
            Container(height: cashH < 2 && h > 0 ? 2 : cashH, color: brandRed),
            if (h == 0) Container(height: 2, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
