import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<UtsavStore> {
  const StoreScope({super.key, required UtsavStore store, required super.child}) : super(notifier: store);

  static UtsavStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static UtsavStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Marigold, used for the groom's side and the toran.
const marigold = Color(0xFFF2A900);
const saffron = Color(0xFFE86A1C);
const whatsappGreen = Color(0xFF1F8A4C);

Color goodColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF5ED39A) : const Color(0xFF257A4A);
Color goodSoft(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF15301F) : const Color(0xFFDDF1E4);
Color warnSoft(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A2F14) : const Color(0xFFFCEFCF);

Color sideColor(BuildContext context, String side) =>
    side == 'groom' ? marigold : Theme.of(context).colorScheme.primary;

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.outline),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// A tinted note with an icon, like the prototype's banners.
class NoteBanner extends StatelessWidget {
  const NoteBanner({super.key, required this.text, this.icon = Icons.info_outline, this.danger = false, this.bold});
  final String text;
  final String? bold;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = danger ? cs.errorContainer : cs.secondaryContainer;
    final fg = danger ? cs.onErrorContainer : cs.onSecondaryContainer;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (bold != null) TextSpan(text: '$bold ', style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: text),
              ]),
              style: TextStyle(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three (or two) equal boxes with a big number and a small label.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.items, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6)});
  final List<(String, String)> items;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(items[i].$1, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 2),
                    Text(items[i].$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (status) {
      case rsvpYes:
        bg = goodSoft(context);
        fg = goodColor(context);
      case rsvpNo:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
      default:
        bg = warnSoft(context);
        fg = cs.onSurface;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(rsvpLabels[status] ?? status, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}

class SideDot extends StatelessWidget {
  const SideDot(this.side, {super.key});
  final String side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: sideColor(context, side), shape: BoxShape.circle),
    );
  }
}

class Initial extends StatelessWidget {
  const Initial(this.name, {super.key, this.size = 34});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary,
      child: Text(letter, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}

/// The marigold garland strip under the app bar.
class Toran extends StatelessWidget {
  const Toran({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 14, width: double.infinity, child: CustomPaint(painter: _ToranPainter()));
  }
}

class _ToranPainter extends CustomPainter {
  const _ToranPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final big = Paint()..color = marigold;
    final small = Paint()..color = saffron;
    for (double x = 8; x < size.width + 8; x += 16) {
      canvas.drawCircle(Offset(x, 4), 5, big);
      canvas.drawCircle(Offset(x + 8, 9), 3, small);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ring chart: light arc = committed, dark arc = paid, both as a share of the estimate.
class BudgetDonut extends StatelessWidget {
  const BudgetDonut({super.key, required this.paid, required this.committed, required this.percent});
  final double paid;
  final double committed;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: _DonutPainter(paid: paid, committed: committed, track: cs.surfaceContainerHighest, soft: cs.primaryContainer, strong: cs.primary),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
              Text('paid', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.paid, required this.committed, required this.track, required this.soft, required this.strong});
  final double paid;
  final double committed;
  final Color track;
  final Color soft;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, p(track));
    if (committed > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * committed, false, p(soft));
    if (paid > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * paid, false, p(strong));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.paid != paid || old.committed != committed || old.strong != strong || old.track != track;
}

/// One budget line's bar: committed (light), paid (dark), estimate marker when over.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.line});
  final BudgetLine line;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mx = math.max(math.max(line.est, line.com), math.max(line.paid, 1));
    double f(int v) => (v / mx).clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, width: w * f(line.com), child: ColoredBox(color: line.over ? cs.errorContainer : cs.primaryContainer)),
            Positioned(left: 0, top: 0, bottom: 0, width: w * f(line.paid), child: ColoredBox(color: cs.primary)),
            if (line.over) Positioned(left: math.max(0.0, w * f(line.est) - 2), top: 0, bottom: 0, width: 2, child: ColoredBox(color: cs.onSurface)),
          ],
        ),
      );
    });
  }
}

/// Opens a scrollable bottom sheet that moves above the keyboard.
Future<T?> showAppSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: builder(ctx),
      ),
    ),
  );
}

/// Title row for a sheet.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Label/value pairs in a tinted box (the prototype's "summary").
class SummaryBox extends StatelessWidget {
  const SummaryBox({super.key, required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: Text(r.$1, style: TextStyle(color: cs.onSurfaceVariant))),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: Text(r.$2, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

/// Icon + text for a button child; the text shrinks with an ellipsis instead of overflowing.
class IconLabel extends StatelessWidget {
  const IconLabel({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// Asks before something destructive. Returns true when confirmed.
Future<bool> confirmAction(BuildContext context, {required String title, required String body, required String action}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

/// Opens WhatsApp, the dialler or another app. Shows a toast if nothing can handle it.
Future<bool> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(const SnackBar(content: Text('Could not open the app for this.'), behavior: SnackBarBehavior.floating));
  }
  return ok;
}

Future<bool> openWhatsApp(BuildContext context, String text, {String phone = ''}) =>
    openExternal(context, waLink(text, phone: phone));

Future<void> callPhone(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) return;
  await openExternal(context, 'tel:$digits');
}

/// Date picker that returns an ISO date, or null if cancelled.
Future<String?> pickIsoDate(BuildContext context, String initial) async {
  final init = parseIso(initial);
  final now = DateTime.now();
  final first = DateTime(math.min(now.year - 1, init.year), 1, 1);
  final last = DateTime(math.max(now.year + 5, init.year + 1), 12, 31);
  final d = await showDatePicker(context: context, initialDate: init, firstDate: first, lastDate: last);
  return d == null ? null : isoDate(d);
}

/// A tappable field that shows a value and opens a picker.
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.value, required this.icon, required this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon)),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
