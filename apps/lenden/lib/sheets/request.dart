import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showRequest(BuildContext context, String id) => showAppSheet(context, (_) => _RequestSheet(id: id));

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.id});
  final String id;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _place = TextEditingController();
  final _msg = TextEditingController();
  bool _ready = false;
  String _learn = '';
  String _pay = 'swap';
  String _teach = '';
  double _hrs = 1;
  String _mode = 'In person';
  String? _slot; // "yyyy-MM-dd|HH:mm"
  String? _error;

  @override
  void dispose() {
    _place.dispose();
    _msg.dispose();
    super.dispose();
  }

  String _defaultPlace(Person p) => _mode == 'Online' ? 'Video call' : 'Public park near ${p.area}';

  void _setup(AppData d, Person p, double free) {
    final tw = theyWantMine(p, d.me);
    final theirs = iWantTheirs(p, d.me);
    _learn = theirs.isNotEmpty ? theirs.first : (p.teaches.isNotEmpty ? p.teaches.first.name : '');
    _teach = tw.isNotEmpty ? tw.first : (d.me.teaches.isNotEmpty ? d.me.teaches.first.name : '');
    _pay = tw.isNotEmpty || free < 1 ? 'swap' : 'credits';
    if (_teach.isEmpty && free >= 1) _pay = 'credits';
    _mode = p.km != null ? 'In person' : 'Online';
    _place.text = _defaultPlace(p);
    _msg.text = "Hi ${p.first}! I'd love to learn ${_learn.toLowerCase()}. I'm a complete beginner.";
    _ready = true;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final p = d?.person(widget.id);
    final cs = Theme.of(context).colorScheme;
    if (d == null || p == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This profile is no longer available.'));
    }
    final free = store.freeHrs;
    if (!_ready) _setup(d, p, free);
    final today = todayIso();
    final days = [1, 2, 3, 5].map((n) => addDaysIso(today, n)).toList();
    final canSwap = d.me.teaches.isNotEmpty;
    final canCredits = free >= _hrs;
    final modes = <String>[if (p.km != null) 'In person', if (p.online) 'Online'];
    if (modes.isEmpty) modes.add('In person');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Swap with ${p.first}', leading: PersonAvatar(p, size: 36)),
        const FieldLabel("You'll learn"),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final t in p.teaches)
              ChoiceChip(
                label: chipText('${t.name} · ${t.level}'),
                selected: _learn == t.name,
                onSelected: (_) => setState(() => _learn = t.name),
              ),
          ],
        ),
        const FieldLabel('In return'),
        _Option(
          title: 'Teach ${p.first} back',
          subtitle: !canSwap
              ? 'Add a skill you teach in Profile first'
              : (theyWantMine(p, d.me).isNotEmpty ? 'Hour for hour, no credits move overall' : 'Offer one of your skills'),
          selected: _pay == 'swap',
          enabled: canSwap,
          onTap: () => setState(() => _pay = 'swap'),
        ),
        const SizedBox(height: 8),
        _Option(
          title: 'Pay with credits',
          subtitle: '${hrsText(free)} hr free to spend',
          selected: _pay == 'credits',
          enabled: canCredits,
          onTap: () => setState(() => _pay = 'credits'),
        ),
        if (_pay == 'swap' && canSwap) ...[
          const FieldLabel("You'll teach"),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in d.me.teachNames)
                ChoiceChip(
                  label: chipText(s),
                  selected: _teach == s,
                  onSelected: (_) => setState(() => _teach = s),
                ),
            ],
          ),
          if (p.wants.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${p.first} wants: ${p.wants.join(', ')}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          ],
        ],
        const FieldLabel('Length'),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment<double>(value: 1.0, label: Text('1 hr')),
            ButtonSegment<double>(value: 1.5, label: Text('1.5 hr')),
            ButtonSegment<double>(value: 2.0, label: Text('2 hr')),
          ],
          selected: {_hrs},
          onSelectionChanged: (s) => setState(() => _hrs = s.first),
        ),
        const FieldLabel('Where'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in modes)
              ChoiceChip(
                label: Text(m),
                selected: _mode == m,
                onSelected: (_) => setState(() {
                  _mode = m;
                  _place.text = _defaultPlace(p);
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Meeting place'),
        ),
        if (_mode == 'In person' && d.me.publicOnly) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in const [('Park', 'Public park near'), ('Library', 'Library near'), ('Café', 'Café near')])
                ActionChip(label: Text(s.$1), onPressed: () => setState(() => _place.text = '${s.$2} ${p.area}')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Meet in public places. Never share a home address.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        ],
        FieldLabel("When (${p.first}'s free times)"),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final day in days)
              for (final t in p.avail)
                ChoiceChip(
                  label: Text('${dayName(day)} ${shortDate(day)} · ${t12(t)}'),
                  selected: _slot == '$day|$t',
                  onSelected: (_) => setState(() => _slot = '$day|$t'),
                ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _msg,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        const SizedBox(height: 14),
        SummaryBox([
          ('You learn', '$_learn · ${hrsText(_hrs)} hr'),
          _pay == 'swap' ? ('You teach', '$_teach · ${hrsText(_hrs)} hr') : ('Credits', '−${hrsText(_hrs)} hr when done'),
        ]),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final slot = _slot;
            if (_learn.isEmpty) return setState(() => _error = 'Pick what you want to learn.');
            if (slot == null) return setState(() => _error = 'Pick a time that suits ${p.first}.');
            if (_pay == 'swap' && _teach.isEmpty) return setState(() => _error = 'Pick a skill to teach, or pay with credits.');
            final parts = slot.split('|');
            final err = store.sendRequest(
              personId: p.id,
              learn: _learn,
              pay: _pay,
              teach: _teach,
              hrs: _hrs,
              mode: _mode,
              place: _place.text.trim().isEmpty ? _defaultPlace(p) : _place.text.trim(),
              date: parts[0],
              time: parts[1],
              message: _msg.text,
            );
            if (err != null) return setState(() => _error = err);
            Navigator.pop(context);
            toast(context, 'Request sent to ${p.first}. Mark it accepted when they say yes.');
          },
          child: const Text('Send request'),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.subtitle, required this.selected, required this.enabled, required this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = enabled ? (selected ? cs.onPrimaryContainer : cs.onSurface) : cs.outline;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: enabled ? cs.primary : cs.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: fg)),
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
