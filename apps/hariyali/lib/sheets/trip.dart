import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Plan or edit a trip so Hariyali can write care notes for a helper.
Future<void> showTripSheet(BuildContext context) => showAppSheet(context, (_) => const _TripSheet());

class _TripSheet extends StatefulWidget {
  const _TripSheet();

  @override
  State<_TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<_TripSheet> {
  final _helper = TextEditingController();
  late String from;
  late String to;
  String lang = 'en';
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final t = StoreScope.read(context).data?.trip;
    final today = todayIso();
    from = t?.from ?? addDaysIso(today, 7);
    to = t?.to ?? addDaysIso(today, 11);
    lang = t?.lang ?? 'en';
    _helper.text = t?.helper ?? '';
  }

  @override
  void dispose() {
    _helper.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isFrom) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = DateTime(now.year + 1, now.month, now.day);
    var initial = parseIso(isFrom ? from : to);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'Leaving on' : 'Back on',
    );
    if (picked == null) return;
    setState(() {
      final v = isoDate(picked);
      if (isFrom) {
        from = v;
        if (to.compareTo(from) < 0) to = from;
      } else {
        to = v;
        if (from.compareTo(to) > 0) from = to;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final days = daysBetween(from, to) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Going away'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flight_takeoff),
          title: const Text('Away from'),
          subtitle: Text('${dayName(from)}, ${shortDate(from)}'),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: () => _pick(true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flight_land),
          title: const Text('Back after'),
          subtitle: Text('${dayName(to)}, ${shortDate(to)} · ${plural(days, 'day')} away'),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: () => _pick(false),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _helper,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Who is looking after them?', hintText: 'Lakshmi aunty'),
        ),
        const SizedBox(height: 16),
        Text('Note language', style: tt.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'ta', label: Text('தமிழ்')),
          ],
          selected: {lang},
          onSelectionChanged: (s) => setState(() => lang = s.first),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final helper = _helper.text.trim();
            if (helper.isEmpty) return setState(() => error = 'Add the helper\'s name, so the note can greet them.');
            store.setTrip(Trip(from: from, to: to, helper: helper, lang: lang));
            Navigator.pop(context);
            toast(context, 'Care note ready');
          },
          child: const Text('Save trip'),
        ),
      ],
    );
  }
}
