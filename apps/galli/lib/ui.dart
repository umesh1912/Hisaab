import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<GalliStore> {
  const StoreScope({super.key, required GalliStore store, required super.child}) : super(notifier: store);

  static GalliStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static GalliStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// The colour that marks each kind of post (the stripe, the pin, the label).
Color typeColor(BuildContext context, String type) {
  final dark = isDark(context);
  switch (type) {
    case 'alert':
      return dark ? const Color(0xFFFF7440) : const Color(0xFFE0431B);
    case 'lost':
      return dark ? const Color(0xFFA688F0) : const Color(0xFF7447D1);
    case 'found':
      return dark ? const Color(0xFF5ED39A) : const Color(0xFF1E7F4F);
    case 'help':
      return dark ? const Color(0xFF78A6F5) : const Color(0xFF2361D0);
    default:
      return dark ? const Color(0xFFA0A4AB) : const Color(0xFF6B6F76);
  }
}

/// Text colour to use on top of [typeColor].
Color onTypeColor(BuildContext context) => isDark(context) ? const Color(0xFF111214) : Colors.white;

Color goodColor(BuildContext context) => isDark(context) ? const Color(0xFF5ED39A) : const Color(0xFF1E7F4F);
Color goodSoft(BuildContext context) => isDark(context) ? const Color(0xFF15301F) : const Color(0xFFDCF0E3);
Color warnSoft(BuildContext context) => isDark(context) ? const Color(0xFF3A2F14) : const Color(0xFFFCF0D3);

const typeIcons = <String, IconData>{
  'alert': Icons.warning_amber_rounded,
  'lost': Icons.search,
  'found': Icons.volunteer_activism_outlined,
  'help': Icons.help_outline,
  'notice': Icons.campaign_outlined,
};

IconData catIcon(String cat) {
  switch (cat) {
    case 'Pet':
      return Icons.pets;
    case 'Phone':
      return Icons.smartphone;
    case 'Document':
      return Icons.badge_outlined;
    case 'Power':
      return Icons.power_off_outlined;
    case 'Water':
      return Icons.water_drop_outlined;
    case 'Road':
      return Icons.traffic_outlined;
    case 'Safety':
      return Icons.shield_outlined;
    case 'Event':
      return Icons.event_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}

/// "● LOST · PET" in the post's colour.
class TypeLabel extends StatelessWidget {
  const TypeLabel({super.key, required this.type, this.cat = ''});
  final String type;
  final String cat;

  @override
  Widget build(BuildContext context) {
    final c = typeColor(context, type);
    final text = cat.isEmpty ? (typeLabels[type] ?? type) : '${typeLabels[type] ?? type} · $cat';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}

/// A small rounded label, e.g. "Unverified · 1 confirm".
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.bg, required this.fg, this.icon});
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
              style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Verified / confirmed / unverified label for an alert.
class AlertStatusPill extends StatelessWidget {
  const AlertStatusPill({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (alertStatus(post)) {
      case 'official':
        return Pill(text: 'Verified source', bg: goodSoft(context), fg: goodColor(context), icon: Icons.check);
      case 'confirmed':
        return Pill(text: '${post.yes} confirm', bg: goodSoft(context), fg: goodColor(context), icon: Icons.check);
      default:
        return Pill(text: 'Unverified · ${post.yes} confirm', bg: warnSoft(context), fg: cs.onSurface);
    }
  }
}

/// A tinted note with an icon, used for safety and privacy messages.
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.icon, required this.text, this.warn = false});
  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? warnSoft(context) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: cs.onSurface))),
        ],
      ),
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

/// Big bold screen heading, like the prototype's h-title.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// "Radius  [500 m | 1 km | 2 km]" bound to the store.
class RadiusPicker extends StatelessWidget {
  const RadiusPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text('Radius', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: SegmentedButton<double>(
              showSelectedIcon: false,
              segments: [
                for (final r in radiusOptions) ButtonSegment(value: r, label: Text(radiusLabel(r))),
              ],
              selected: {d.radius},
              onSelectionChanged: (s) => store.setRadius(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// A picker for a distance in km, used in forms.
class KmPicker extends StatelessWidget {
  const KmPicker({super.key, required this.options, required this.value, required this.onChanged});
  final List<double> options;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<double>(
        showSelectedIcon: false,
        segments: [for (final r in options) ButtonSegment(value: r, label: Text(radiusLabel(r)))],
        selected: {options.contains(value) ? value : options.first},
        onSelectionChanged: (s) => onChanged(s.first),
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

/// Opens WhatsApp, Maps or the dialler outside the app.
Future<void> openExternal(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) toast(context, 'Could not open that on this phone.');
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}
