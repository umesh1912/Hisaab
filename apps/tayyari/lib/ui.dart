import 'package:flutter/material.dart';

import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<TayyariStore> {
  const StoreScope({super.key, required TayyariStore store, required super.child}) : super(notifier: store);

  static TayyariStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static TayyariStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Status colours that work in light and dark themes.
class Tones {
  const Tones({
    required this.good,
    required this.goodSoft,
    required this.bad,
    required this.badSoft,
    required this.warn,
    required this.warnSoft,
    required this.accentSoft,
  });
  final Color good;
  final Color goodSoft;
  final Color bad;
  final Color badSoft;
  final Color warn;
  final Color warnSoft;
  final Color accentSoft;
}

const _light = Tones(
  good: Color(0xFF1F8150),
  goodSoft: Color(0xFFDCF1E4),
  bad: Color(0xFFC9362B),
  badSoft: Color(0xFFFBE2DE),
  warn: Color(0xFFB97800),
  warnSoft: Color(0xFFFCF0D3),
  accentSoft: Color(0xFFFFF6C7),
);

const _dark = Tones(
  good: Color(0xFF5ED39A),
  goodSoft: Color(0xFF15301F),
  bad: Color(0xFFF2806F),
  badSoft: Color(0xFF3A1E1A),
  warn: Color(0xFFF2BE4C),
  warnSoft: Color(0xFF3A2F14),
  accentSoft: Color(0xFF3A3413),
);

Tones tones(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;

const accentYellow = Color(0xFFFFE45C);

Color masteryColor(BuildContext context, int p) {
  final t = tones(context);
  if (p < 55) return t.bad;
  if (p < 75) return t.warn;
  return t.good;
}

Color masterySoft(BuildContext context, int p) {
  final t = tones(context);
  if (p < 55) return t.badSoft;
  if (p < 75) return t.warnSoft;
  return t.goodSoft;
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
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

/// A small rounded label with its own colours.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.bg, required this.fg, this.icon});
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // FittedBox scales the label down instead of overflowing when a slot (e.g. ListTile leading) is narrow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
            Text(text, maxLines: 1, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// A tinted box with an icon and text, for hints and warnings.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.child, this.icon = Icons.info_outline, this.color, this.margin});
  final Widget child;
  final IconData icon;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color ?? tones(context).accentSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurface),
          const SizedBox(width: 10),
          Expanded(child: DefaultTextStyle.merge(style: TextStyle(color: cs.onSurface), child: child)),
        ],
      ),
    );
  }
}

/// A labelled horizontal bar, e.g. "Quant  38 / 50".
class BarRow extends StatelessWidget {
  const BarRow({super.key, required this.label, required this.value, required this.fraction, this.color});
  final String label;
  final String value;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: color ?? cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

enum OptState { idle, selected, right, wrong }

/// One answer option with a letter badge.
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.index, required this.text, this.state = OptState.idle, this.onTap});
  final int index;
  final String text;
  final OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = tones(context);
    var border = cs.outlineVariant;
    var bg = cs.surface;
    var boxBg = cs.surfaceContainerHighest;
    var boxFg = cs.onSurface;
    if (state == OptState.selected) {
      border = cs.primary;
      bg = cs.primaryContainer;
      boxBg = cs.primary;
      boxFg = cs.onPrimary;
    } else if (state == OptState.right) {
      border = t.good;
      bg = t.goodSoft;
      boxBg = t.good;
      boxFg = cs.surface;
    } else if (state == OptState.wrong) {
      border = t.bad;
      bg = t.badSoft;
      boxBg = t.bad;
      boxFg = cs.surface;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: boxBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('ABCD'[index % 4], style: TextStyle(color: boxFg, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface))),
              ],
            ),
          ),
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

/// Asks a yes/no question. Returns true only when the user confirms.
Future<bool> confirm(BuildContext context, {required String title, required String body, required String action, bool danger = false}) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

const sectionIcons = <String, IconData>{
  'quant': Icons.calculate_outlined,
  'reason': Icons.extension_outlined,
  'eng': Icons.translate,
  'ga': Icons.public,
};

class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
    );
  }
}
