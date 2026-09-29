import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<JodiStore> {
  const StoreScope({super.key, required JodiStore store, required super.child}) : super(notifier: store);

  static JodiStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static JodiStore read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Lime is you, coral is your partner, everywhere in the app.
Color personColor(BuildContext context, String who) {
  final dark = isDark(context);
  if (who == me) return dark ? const Color(0xFFC8F169) : const Color(0xFF4F8A06);
  return dark ? const Color(0xFFFF7A66) : const Color(0xFFD2442F);
}

Color onPersonColor(BuildContext context, String who) {
  if (!isDark(context)) return Colors.white;
  return who == me ? const Color(0xFF11140B) : const Color(0xFF1A0B08);
}

Color skipColor(BuildContext context) => isDark(context) ? const Color(0xFFF5C451) : const Color(0xFFB57B00);

Color skipSoftColor(BuildContext context) => isDark(context) ? const Color(0xFF3A3016) : const Color(0xFFFBF0D3);

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.who, required this.name, this.size = 36});
  final String who;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: personColor(context, who),
      child: Text(
        initial(name),
        style: TextStyle(color: onPersonColor(context, who), fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}

/// Two overlapping avatars, like the prototype's app bar.
class Duo extends StatelessWidget {
  const Duo({super.key, required this.meName, required this.partnerName});
  final String meName;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.surface;
    Widget ringed(Widget child) => Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
          child: child,
        );
    return SizedBox(
      width: 60,
      height: 36,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, child: ringed(PersonAvatar(who: me, name: meName, size: 32))),
          Positioned(left: 24, top: 0, child: ringed(PersonAvatar(who: them, name: partnerName, size: 32))),
        ],
      ),
    );
  }
}

/// "● You" heading inside a habit card.
class WhoHeader extends StatelessWidget {
  const WhoHeader({super.key, required this.who, required this.text});
  final String who;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: personColor(context, who), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
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
              overflow: TextOverflow.ellipsis,
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
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
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

/// A soft callout box with an icon, used for the "never miss twice" rule and notices.
class Callout extends StatelessWidget {
  const Callout({super.key, required this.icon, required this.child, this.color, this.iconColor});
  final IconData icon;
  final Widget child;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color ?? cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? cs.primary),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 8 weeks × 7 days of one habit, Monday at the top, this week on the right.
class HeatMap extends StatelessWidget {
  const HeatMap({super.key, required this.states, required this.today, required this.who, this.cell = 14});
  final Map<String, DayState> states;
  final String today;
  final String who;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dates = heatDates(today);
    Color fill(DayState s) => switch (s) {
          DayState.done => personColor(context, who),
          DayState.skip => skipColor(context),
          DayState.miss => cs.outlineVariant,
          DayState.pending || DayState.rest => cs.surfaceContainerHighest,
          DayState.future => Colors.transparent,
        };

    return Semantics(
      label: 'Last 8 weeks',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var w = 0; w < 8; w++)
            Padding(
              padding: EdgeInsets.only(right: w == 7 ? 0 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(builder: (context) {
                      final date = dates[w * 7 + d];
                      final s = cellState(states, date, today);
                      return Container(
                        width: cell,
                        height: cell,
                        margin: EdgeInsets.only(bottom: d == 6 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: fill(s),
                          borderRadius: BorderRadius.circular(3),
                          border: s == DayState.pending || s == DayState.future
                              ? Border.all(color: cs.outlineVariant, width: 1)
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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

/// Opens WhatsApp with [text] ready to send (the user picks the chat).
Future<void> shareOnWhatsApp(BuildContext context, String text) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not open WhatsApp on this phone.'), behavior: SnackBarBehavior.floating),
    );
  }
}

Future<bool> confirm(BuildContext context, {required String title, required String body, required String action}) async {
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

/// A label + small caption, used in sheets for switches.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: tt.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
