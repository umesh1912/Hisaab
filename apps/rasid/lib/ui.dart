import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<RasidStore> {
  const StoreScope({super.key, required RasidStore store, required super.child}) : super(notifier: store);

  static RasidStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static RasidStore read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const mono = 'monospace';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
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

/// A tinted info box with an icon.
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.text, this.warn = false, this.icon = Icons.info_outline});
  final String text;
  final bool warn;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = warn ? cs.tertiaryContainer : cs.surfaceContainerHigh;
    final fg = warn ? cs.onTertiaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ],
      ),
    );
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

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

Future<void> copyText(BuildContext context, String text, String done) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) toast(context, done);
}

Future<void> openExternal(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) toast(context, 'Could not open that on this phone.');
}

Future<void> shareWhatsApp(BuildContext context, String text) =>
    openExternal(context, 'https://wa.me/?text=${Uri.encodeComponent(text)}');

Future<String?> pickDate(BuildContext context, String? current) async {
  final init = current != null && isIsoDate(current) ? parseIso(current) : DateTime.now();
  final d = await showDatePicker(
    context: context,
    initialDate: init,
    firstDate: DateTime(1990),
    lastDate: DateTime(2100),
  );
  return d == null ? null : isoDate(d);
}

Future<bool> confirm(BuildContext context, {required String title, required String body, required String action}) async {
  final r = await showDialog<bool>(
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
  return r ?? false;
}

// ---------------- status colours ----------------

Color goodColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF5ED39A) : const Color(0xFF1E7F4F);
Color warnColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF2BE4C) : const Color(0xFFB87A06);
Color badColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF2806F) : const Color(0xFFC8372B);

/// A small rounded label, tinted good / warn / bad / neutral.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone = 'neutral'});
  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color bg, fg;
    switch (tone) {
      case 'good':
        bg = dark ? const Color(0xFF15301F) : const Color(0xFFDCF1E5);
        fg = goodColor(context);
        break;
      case 'warn':
        bg = dark ? const Color(0xFF3A2F14) : const Color(0xFFFCF0D2);
        fg = dark ? const Color(0xFFF2BE4C) : const Color(0xFF8A5A00);
        break;
      case 'bad':
        bg = dark ? const Color(0xFF3A1E1A) : const Color(0xFFFBE3E0);
        fg = badColor(context);
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------- categories ----------------

const categoryIcons = <String, IconData>{
  'kitchen': Icons.kitchen_outlined,
  'cooling': Icons.ac_unit,
  'laundry': Icons.local_laundry_service_outlined,
  'phone': Icons.smartphone,
  'computer': Icons.laptop,
  'water': Icons.water_drop_outlined,
  'audio': Icons.headphones,
  'tv': Icons.tv,
  'home': Icons.home_outlined,
  'other': Icons.category_outlined,
};

class CatThumb extends StatelessWidget {
  const CatThumb(this.cat, {super.key, this.size = 44});
  final String cat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(categoryIcons[cat] ?? Icons.category_outlined, color: cs.onSecondaryContainer, size: size * 0.5),
    );
  }
}

/// One item in a list: icon, name, model and price, a bar of warranty left, and time left.
class ItemRow extends StatelessWidget {
  const ItemRow({super.key, required this.item, required this.onTap});
  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = warrantyState(item, todayIso());
    final barColor = s.cover == Cover.soon ? warnColor(context) : goodColor(context);
    final sub = [if (item.model.isNotEmpty) item.model, inr(item.price)].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CatThumb(item.cat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  if (s.cover != Cover.out) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: coverFraction(item, s),
                        minHeight: 6,
                        color: barColor,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: s.cover == Cover.out
                  ? const Tag('Expired')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeLeftLabel(s.days ?? 0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: mono,
                            fontWeight: FontWeight.w700,
                            color: s.cover == Cover.soon ? badColor(context) : cs.onSurface,
                          ),
                        ),
                        Text(
                          shortLabel(s.warranty?.label ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card holding rows separated by thin dividers.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(const Divider(height: 1, indent: 14, endIndent: 14));
      out.add(children[i]);
    }
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: out));
  }
}

/// A label on the left and a value on the right, for detail lists.
class KeyValue extends StatelessWidget {
  const KeyValue(this.k, this.v, {super.key});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(k, style: TextStyle(color: cs.onSurfaceVariant))),
          Expanded(child: Text(v.isEmpty ? '—' : v, textAlign: TextAlign.right, style: const TextStyle(fontFamily: mono, fontSize: 13))),
        ],
      ),
    );
  }
}

/// Paper-style bill with shop, invoice, item and total.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xFFF1F1EE) : Colors.white;
    const ink = Color(0xFF1D1F24);
    const st = TextStyle(fontFamily: mono, fontSize: 12.5, color: ink, height: 1.4);
    Widget r(String a, String b, {bool bold = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(a, style: bold ? st.copyWith(fontWeight: FontWeight.w700) : st)),
            const SizedBox(width: 10),
            Flexible(child: Text(b, textAlign: TextAlign.right, style: bold ? st.copyWith(fontWeight: FontWeight.w700) : st)),
          ],
        );
    const dash = Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: Color(0xFF9AA0AA)));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text((item.store.isEmpty ? 'Shop' : item.store).toUpperCase(), textAlign: TextAlign.center, style: st.copyWith(fontWeight: FontWeight.w700)),
          const Text('TAX INVOICE', textAlign: TextAlign.center, style: st),
          dash,
          r('Inv', item.inv.isEmpty ? '—' : item.inv),
          r('Date', longDate(item.date)),
          dash,
          r('${item.brand} ${item.model}'.trim(), inr(item.price)),
          if (item.serial.isNotEmpty) Text('S/N ${item.serial}', style: st.copyWith(fontSize: 11.5)),
          dash,
          r('TOTAL (incl. GST)', inr(item.price), bold: true),
        ],
      ),
    );
  }
}
