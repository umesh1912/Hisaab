import 'dart:async';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// The big-button view for the parent: one card, one action, English or Hindi.
class ParentModeScreen extends StatefulWidget {
  const ParentModeScreen({super.key, required this.parentId});
  final String parentId;

  @override
  State<ParentModeScreen> createState() => _ParentModeScreenState();
}

class _ParentModeScreenState extends State<ParentModeScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const Scaffold(body: SizedBox.shrink());
    final p = d.parent(widget.parentId) ?? (d.parents.isEmpty ? null : d.parents.first);
    if (p == null) return const Scaffold(body: SizedBox.shrink());

    final hiLang = d.lang == 'hi';
    String tr(String en, String key) => hiLang ? (hindi[key] ?? en) : en;
    final now = DateTime.now();
    final today = isoDate(now);
    final nowMin = now.hour * 60 + now.minute;
    final doses = dosesOn(d.meds, p.id, today);
    String st(Dose x) => doseStatus(d.logs[x.key(today)], today, x.time, now);

    Dose? next;
    for (final x in doses) {
      final s = st(x);
      if (s == 'missed' || s == 'due') {
        next = x;
        break;
      }
    }
    if (next == null) {
      for (final x in doses) {
        if (st(x) == 'up') {
          next = x;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(t12(nowHhmm(now)), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${dayName(today)}, ${shortDate(today)} · ${p.name}',
                        style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => store.setLang(hiLang ? 'en' : 'hi'),
                  child: Text(hiLang ? 'English' : 'हिंदी', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (next != null)
              _NextCard(dose: next, status: st(next), hiLang: hiLang, nowMin: nowMin, today: today, tr: tr)
            else
              _BigCard(
                border: cs.primary,
                children: [
                  Text(
                    doses.isEmpty ? tr('No medicines today', 'nothing') : tr('All done for today', 'done'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Text(
              tr("Today's medicines", 'today').toUpperCase(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < doses.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ListRow(dose: doses[i], status: st(doses[i])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HelpButton(
                    text: hiLang ? '${d.caregiver} ${hindi['call']}' : 'Call ${d.caregiver}',
                    onTap: () => callPhone(context, d.caregiverPhone, d.caregiver),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HelpButton(
                    text: tr('I need help', 'help'),
                    onTap: () => whatsApp(context, d.caregiverPhone, '${p.name} needs help. Please call now.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to caregiver view'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.border, required this.children});
  final Color border;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.dose,
    required this.status,
    required this.hiLang,
    required this.nowMin,
    required this.today,
    required this.tr,
  });
  final Dose dose;
  final String status;
  final bool hiLang;
  final int nowMin;
  final String today;
  final String Function(String en, String key) tr;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final m = dose.med;
    final missed = status == 'missed';
    final accent = missed ? cs.error : cs.primary;
    final String when;
    if (missed) {
      when = hiLang ? '${hindi['missed']} · ${t12(dose.time)}' : 'Missed at ${t12(dose.time)}';
    } else if (status == 'due') {
      when = tr('Take now', 'now');
    } else {
      when = hiLang ? '${hindi['next']} · ${t12(dose.time)}' : 'Next at ${t12(dose.time)}';
    }
    final food = hiLang ? (hindi[m.food] ?? '') : foodText(m.food);
    final form = hiLang ? (hindi[m.form] ?? m.form) : m.form;
    final actionable = status != 'up' || mins(dose.time) - nowMin <= 30;
    final purpose = m.purpose.isEmpty ? '' : '${m.purpose[0].toUpperCase()}${m.purpose.substring(1)}';
    final dark = Theme.of(context).brightness == Brightness.dark;

    return _BigCard(
      border: accent,
      children: [
        Text(when, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: accent)),
        const SizedBox(height: 8),
        Text(m.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 12),
        Row(
          children: [
            PillDot(m.color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${m.per} $form${food.isEmpty ? '' : ' · $food'}',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        if (!hiLang && purpose.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(purpose, style: const TextStyle(fontSize: 19)),
        ],
        const SizedBox(height: 16),
        if (actionable) ...[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: goodColor(context),
              foregroundColor: dark ? const Color(0xFF0C1418) : Colors.white,
              minimumSize: const Size.fromHeight(76),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              store.markDose(today, m.id, dose.time, 'taken', nowHhmm(DateTime.now()));
              toast(context, hiLang ? (hindi['welldone'] ?? '') : "Well done! It's marked as taken.");
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 30),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    tr('I took it', 'took'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              side: BorderSide(color: cs.outlineVariant, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => toast(
              context,
              hiLang ? (hindi['snoozed'] ?? '') : 'OK. It stays here until you take it.',
            ),
            child: Text(tr('Not now', 'later'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          ),
        ] else
          Text(
            tr("Nothing to take right now. It will show here when it's time.", 'nothing'),
            style: TextStyle(fontSize: 19, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.dose, required this.status});
  final Dose dose;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final taken = status == 'taken';
    final missed = status == 'missed';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: taken ? goodColor(context) : (missed ? cs.errorContainer : cs.surfaceContainerHighest),
            ),
            child: taken
                ? Icon(Icons.check, size: 18, color: cs.surface)
                : (missed ? Text('!', style: TextStyle(fontWeight: FontWeight.w800, color: cs.onErrorContainer)) : null),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dose.med.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(t12(dose.time), style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    );
  }
}
