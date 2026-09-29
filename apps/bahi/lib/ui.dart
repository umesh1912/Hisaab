import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<BahiStore> {
  const StoreScope({super.key, required BahiStore store, required super.child}) : super(notifier: store);

  static BahiStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static BahiStore read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// True when the app is in English (Hindi is the default).
bool isEn(BuildContext context) => StoreScope.of(context).en;

/// Picks the Hindi or English text for the current language.
String tr(BuildContext context, String hi, String en) => isEn(context) ? en : hi;

// ---------- colours ----------
const brandRed = Color(0xFFA3201F);
const turmeric = Color(0xFFF2B705);
const turmericInk = Color(0xFF241A14);
const whatsAppGreen = Color(0xFF1F8A4C);

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Red: the customer owes the shop.
Color dueColor(BuildContext c) => _dark(c) ? const Color(0xFFF2806F) : const Color(0xFFB3261E);

/// Green: money came in / advance.
Color goodColor(BuildContext c) => _dark(c) ? const Color(0xFF5ED39A) : const Color(0xFF1D7A43);
Color dueSoft(BuildContext c) => _dark(c) ? const Color(0xFF3A1E1A) : const Color(0xFFF9E0DC);
Color goodSoft(BuildContext c) => _dark(c) ? const Color(0xFF15301F) : const Color(0xFFDCF0E2);

/// Text colour on solid red / green buttons.
Color onStrong(BuildContext c) => _dark(c) ? const Color(0xFF120D0B) : Colors.white;

Color balanceColor(BuildContext c, int balance) {
  if (balance > 0) return dueColor(c);
  if (balance < 0) return goodColor(c);
  return Theme.of(c).colorScheme.onSurfaceVariant;
}

const _avatarPalette = [
  Color(0xFFA3201F),
  Color(0xFF1D7A43),
  Color(0xFF8C5A0A),
  Color(0xFF2F5FA8),
  Color(0xFF6B3FA0),
  Color(0xFFB0487A),
  Color(0xFF2C7A7B),
  Color(0xFF7A5B2F),
];

Color avatarColor(int id) => _avatarPalette[(id - 1).abs() % _avatarPalette.length];

class Initial extends StatelessWidget {
  const Initial({super.key, required this.id, required this.name, this.size = 32});
  final int id;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: avatarColor(id), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.48)),
    );
  }
}

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
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
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

/// A soft information box with an icon.
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.text, this.icon = Icons.info_outline, this.color});
  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color ?? cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5))),
        ],
      ),
    );
  }
}

/// The ledger "page": a rounded box with a red margin line, like a bahi-khata.
class LedgerBox extends StatelessWidget {
  const LedgerBox({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: cs.outlineVariant));
      rows.add(children[i]);
    }
    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 48,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: _dark(context) ? const Color(0xFF7A2E2A) : const Color(0xFFD9534F)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        ],
      ),
    );
  }
}

/// One customer in a ledger list: initial (or a checkbox), name, status line and balance.
class CustomerRow extends StatelessWidget {
  const CustomerRow({super.key, required this.customer, this.onTap, this.selected, this.extra});
  final Customer customer;
  final VoidCallback? onTap;

  /// When not null, a checkbox is shown in place of the initial.
  final bool? selected;

  /// Optional extra status text (e.g. "Reminded 1 day ago").
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    final today = todayIso();
    final c = customer;
    final b = balanceOf(c);
    final od = oldestUnpaidDays(c, today);
    final lp = lastPayDate(c);
    final parts = <String>[
      if (b == 0) en ? 'Settled' : 'हिसाब साफ़',
      if (b < 0) en ? 'Advance' : 'एडवांस',
      if (b > 0) '$od ${en ? 'days' : 'दिन'} · ${en ? 'Last paid' : 'आखिरी भुगतान'}: ${lp == null ? '—' : dateLabel(lp, en)}',
      if (b > 0 && promiseActive(c, today)) '${en ? 'Promised' : 'वादा'} ${dateLabel(c.promise!, en)}',
      if (extra != null) extra!,
    ];
    final isLate = b > 0 && od > 14;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: selected == null
                    ? Initial(id: c.id, name: c.display(en), size: 28)
                    : Checkbox(
                        value: selected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: onTap == null ? null : (_) => onTap!(),
                      ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.display(en),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                  ),
                  Text(
                    parts.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isLate ? dueColor(context) : cs.onSurfaceVariant,
                      fontWeight: isLate ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  inr(b.abs()),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: balanceColor(context, b)),
                ),
              ),
            ),
          ],
        ),
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

/// Opens WhatsApp, the dialer or a UPI app. Returns false (and shows a message) if nothing can open it.
Future<bool> openExternal(BuildContext context, String url, {required String failMessage}) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) toast(context, failMessage);
  return ok;
}

/// Asks a yes/no question. Returns true only when the user confirms.
Future<bool> confirm(BuildContext context, {required String title, required String body, required String yes, required String no}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(no)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

/// A big solid red or green action button with a small caption, as in the paper register.
class BigAction extends StatelessWidget {
  const BigAction({super.key, required this.title, this.caption, required this.credit, required this.onTap});
  final String title;
  final String? caption;
  final bool credit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = credit ? dueColor(context) : goodColor(context);
    final fg = onStrong(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              if (caption != null)
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
