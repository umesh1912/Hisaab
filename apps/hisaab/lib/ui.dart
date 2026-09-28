import 'package:flutter/material.dart';

import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<HisaabStore> {
  const StoreScope({super.key, required HisaabStore store, required super.child}) : super(notifier: store);

  static HisaabStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static HisaabStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const _avatarPalette = [
  Color(0xFF1E5C4A),
  Color(0xFFB4541F),
  Color(0xFF4F5BA8),
  Color(0xFF8A3E7A),
  Color(0xFF2F7F8F),
  Color(0xFF7A6A1E),
  Color(0xFF9C3D3D),
  Color(0xFF3F6E2F),
];

Color avatarColor(String id) {
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarPalette[h % _avatarPalette.length];
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.id, required this.name, this.size = 36, this.dimmed = false});
  final String id;
  final String name;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final bg = dimmed ? Theme.of(context).colorScheme.outline : avatarColor(id);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
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

/// Green for money coming to you, red for money you owe.
Color moneyColor(BuildContext context, int v) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (v > 0) return dark ? const Color(0xFF7FD6A8) : const Color(0xFF1B7A4B);
  if (v < 0) return dark ? const Color(0xFFFF9C8A) : const Color(0xFFB3261E);
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

const categoryIcons = <String, IconData>{
  'rent': Icons.home_outlined,
  'utilities': Icons.bolt_outlined,
  'food': Icons.restaurant_outlined,
  'help': Icons.cleaning_services_outlined,
  'other': Icons.category_outlined,
};

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.cat, {super.key});
  final String cat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(categoryIcons[cat] ?? Icons.category_outlined, color: cs.onSecondaryContainer, size: 22),
    );
  }
}
