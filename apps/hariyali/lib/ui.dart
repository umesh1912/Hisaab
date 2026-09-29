import 'package:flutter/material.dart';

import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<HariyaliStore> {
  const StoreScope({super.key, required HariyaliStore store, required super.child}) : super(notifier: store);

  static HariyaliStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static HariyaliStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const terracotta = Color(0xFFC8643B);

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

Color waterColor(BuildContext context) => isDark(context) ? const Color(0xFF6FB0EA) : const Color(0xFF2F7FC1);
Color onWaterColor(BuildContext context) => isDark(context) ? const Color(0xFF0D120C) : Colors.white;
Color badColor(BuildContext context) => isDark(context) ? const Color(0xFFF2806F) : const Color(0xFFB93A2B);

/// A simple pot with a leaf, so the list feels like a balcony.
class Pot extends StatelessWidget {
  const Pot({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: size * 0.13,
            right: size * 0.13,
            bottom: 0,
            height: size * 0.45,
            child: Container(
              decoration: BoxDecoration(
                color: terracotta,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(3),
                  topRight: const Radius.circular(3),
                  bottomLeft: Radius.circular(size * 0.22),
                  bottomRight: Radius.circular(size * 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.32,
            child: Icon(Icons.eco, color: cs.primary, size: size * 0.66),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
                trailing!,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: tt.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
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

/// An info box with an icon. [tone]: info | warn | bad.
class NoteBox extends StatelessWidget {
  const NoteBox(this.text, {super.key, this.tone = 'info', this.margin = EdgeInsets.zero});
  final String text;
  final String tone;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = tone == 'bad' ? cs.errorContainer : (tone == 'warn' ? cs.tertiaryContainer : cs.secondaryContainer);
    final fg = tone == 'bad' ? cs.onErrorContainer : (tone == 'warn' ? cs.onTertiaryContainer : cs.onSecondaryContainer);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tone == 'info' ? Icons.info_outline : Icons.warning_amber_rounded, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ],
      ),
    );
  }
}

/// A small rounded label. [tone]: ok | watch | sick | water | plain.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = 'plain'});
  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (tone) {
      case 'ok':
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case 'watch':
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case 'sick':
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A label on the left and a value on the right, for summaries.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (sub != null)
            Text(sub!, style: tt.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
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

Future<bool> confirm(BuildContext context, String title, String action, {String? body}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return ok == true;
}
