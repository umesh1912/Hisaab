import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<LendenStore> {
  const StoreScope({super.key, required LendenStore store, required super.child}) : super(notifier: store);

  static LendenStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static LendenStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const brand = Color(0xFFE8552F);

/// Teal for credits earned, brand orange for credits spent.
Color creditColor(BuildContext context, double h) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (h > 0) return dark ? const Color(0xFF3CC4B7) : const Color(0xFF0D7F76);
  if (h < 0) return dark ? const Color(0xFFFF7A55) : const Color(0xFFC2451F);
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Color starColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF2B632) : const Color(0xFFB27C00);

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.color, this.size = 40, this.verified = false});
  final String name;
  final int color;
  final double size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final cs = Theme.of(context).colorScheme;
    final circle = CircleAvatar(
      radius: size / 2,
      backgroundColor: Color(color),
      child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
    if (!verified) return circle;
    final badge = size * 0.36 < 14 ? 14.0 : size * 0.36;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: cs.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Icon(Icons.check, size: badge * 0.62, color: cs.onTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.p, {super.key, this.size = 40});
  final Person p;
  final double size;

  @override
  Widget build(BuildContext context) => Avatar(name: p.name, color: p.color, size: size, verified: p.verified);
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
              text.toUpperCase(),
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

/// A small rounded label, e.g. "Two-way match".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.icon, this.tone = TagTone.neutral});
  final String text;
  final IconData? icon;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg, fg;
    switch (tone) {
      case TagTone.match:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case TagTone.ok:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case TagTone.neutral:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

enum TagTone { neutral, match, ok }

/// Skill pill; highlighted when it matches something on the other side.
class SkillPill extends StatelessWidget {
  const SkillPill(this.text, {super.key, this.highlight = false});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          color: highlight ? cs.onPrimaryContainer : cs.onSurface,
        ),
      ),
    );
  }
}

/// Coloured note with a shield icon for safety tips.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.shield_outlined, this.margin = EdgeInsets.zero});
  final String text;
  final IconData icon;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: cs.onTertiaryContainer, fontSize: 13.5))),
        ],
      ),
    );
  }
}

/// Label/value rows in a tinted box.
class SummaryBox extends StatelessWidget {
  const SummaryBox(this.rows, {super.key});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: Text(r.$1, style: TextStyle(color: cs.onSurfaceVariant))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(r.$2, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars(this.n, {super.key, this.size = 14});
  final int n;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < n; i++) Icon(Icons.star_rounded, size: size, color: starColor(context))],
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

/// Title row used at the top of every sheet.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.leading});
  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey heading above a group of fields in a sheet.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Chip label that never grows wider than a phone screen allows.
Widget chipText(String s) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(s, overflow: TextOverflow.ellipsis),
    );

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

Future<void> openExternal(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) toast(context, 'No app found to open this.');
}

String mapsUrl(String place) => 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}';
String whatsAppUrl(String text, {String phone = ''}) => 'https://wa.me/${waNumber(phone)}?text=${Uri.encodeComponent(text)}';

Future<bool> confirm(BuildContext context, String title, String body, String action) async {
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
