import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'store.dart';

/// Makes the store available to every widget below it and rebuilds them on change.
class StoreScope extends InheritedNotifier<KhayalStore> {
  const StoreScope({super.key, required KhayalStore store, required super.child}) : super(notifier: store);

  static KhayalStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static KhayalStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const _avatarPalette = [
  Color(0xFF1D5C7A),
  Color(0xFF7A4FB5),
  Color(0xFF5E7A2B),
  Color(0xFFB5602B),
  Color(0xFF2F7F8F),
  Color(0xFF9C3D3D),
];

Color avatarColor(String id) {
  if (id == 'me') return _avatarPalette[0];
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarPalette[h % _avatarPalette.length];
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.color, this.size = 36});
  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}

/// A small round swatch in the pill's colour.
class PillDot extends StatelessWidget {
  const PillDot(this.color, {super.key, this.size = 14});
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: size > 20 ? 2 : 1),
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

/// An info note with an icon, like the prototype's safety notes.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

/// Label/value line used in summary boxes.
class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
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

// ---------- status colours (the prototype's good / bad / warn) ----------

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color goodColor(BuildContext c) => _dark(c) ? const Color(0xFF6ED49A) : const Color(0xFF2B7A4B);
Color goodSoft(BuildContext c) => _dark(c) ? const Color(0xFF163426) : const Color(0xFFDDF1E4);
Color warnColor(BuildContext c) => _dark(c) ? const Color(0xFFF2BE5C) : const Color(0xFFB97A12);
Color warnSoft(BuildContext c) => _dark(c) ? const Color(0xFF3A2F16) : const Color(0xFFFBEFD6);
Color accentColor(BuildContext c) => _dark(c) ? const Color(0xFFF5AE66) : const Color(0xFFE08A32);

/// Colour for a days-left count: red within a week, amber within 10 days.
Color stockColor(BuildContext c, int days) {
  if (days <= 7) return Theme.of(c).colorScheme.error;
  if (days <= 10) return warnColor(c);
  return goodColor(c);
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg = cs.surfaceContainerHighest;
    Color fg = cs.onSurfaceVariant;
    if (status == 'taken') {
      bg = goodSoft(context);
      fg = goodColor(context);
    } else if (status == 'missed') {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    } else if (status == 'due') {
      bg = warnSoft(context);
      fg = cs.onSurface;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        statusLabels[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
          decoration: status == 'skipped' ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

// ---------- external actions ----------

Future<void> openExternal(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) toast(context, 'No app on this phone can open that.');
}

void callPhone(BuildContext context, String phone, String name) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) {
    toast(context, 'Add a phone number for $name first.');
    return;
  }
  openExternal(context, 'tel:$digits');
}

/// Opens WhatsApp with [text] filled in, addressed to [phone] when there is one.
void whatsApp(BuildContext context, String phone, String text) {
  final d = waDigits(phone);
  final base = d.isEmpty ? 'https://wa.me/' : 'https://wa.me/$d';
  openExternal(context, '$base?text=${Uri.encodeComponent(text)}');
}

Future<void> copyText(BuildContext context, String text, String done) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) toast(context, done);
}

/// Opens the time picker and returns 'HH:mm', or null if cancelled.
Future<String?> pickTime(BuildContext context, String initial) async {
  final m = mins(initial);
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
  if (t == null) return null;
  return hhmm(t.hour * 60 + t.minute);
}

/// Picks which parent the screen is about. Shows missed doses or today's score under each name.
class WhoSwitch extends StatelessWidget {
  const WhoSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    if (d.parents.length < 2) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = isoDate(now);
    final sel = store.current.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < d.parents.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _whoButton(context, d.parents[i], sel == d.parents[i].id, today, now, cs)),
          ],
        ],
      ),
    );
  }

  Widget _whoButton(BuildContext context, Parent p, bool selected, String today, DateTime now, ColorScheme cs) {
    final store = StoreScope.read(context);
    final d = store.data!;
    final missed = missedToday(d.meds, d.logs, [p.id], now).length;
    final pct = dayAdherence(d.meds, d.logs, p.id, today, now) ?? 100;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => store.selectWho(p.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Avatar(name: p.name, color: Color(p.color), size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      missed > 0 ? '$missed missed' : '$pct% today',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: missed > 0 ? cs.error : cs.onSurfaceVariant,
                        fontWeight: missed > 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
