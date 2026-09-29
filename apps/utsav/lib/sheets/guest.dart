import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showGuestSheet(BuildContext context, {int? id}) {
  return showAppSheet(context, (_) => GuestForm(id: id));
}

class GuestForm extends StatefulWidget {
  const GuestForm({super.key, this.id});
  final int? id;

  @override
  State<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<GuestForm> {
  final _name = TextEditingController();
  final _lead = TextEditingController();
  final _phone = TextEditingController();
  final _people = TextEditingController(text: '2');
  final _jain = TextEditingController(text: '0');
  final _rel = TextEditingController();
  final _city = TextEditingController();
  String side = 'bride';
  String status = rsvpWait;
  final events = <String>{};
  bool missing = false;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    final id = widget.id;
    if (id == null) {
      _city.text = d.city;
      events.addAll(d.events.map((e) => e.id));
      return;
    }
    final g = d.guest(id);
    if (g == null) {
      missing = true;
      return;
    }
    _name.text = g.name;
    _lead.text = g.lead;
    _phone.text = g.phone;
    _people.text = '${g.people}';
    _jain.text = '${g.jain}';
    _rel.text = g.rel;
    _city.text = g.city;
    side = g.side;
    status = g.status;
    events.addAll(g.events);
  }

  @override
  void dispose() {
    _name.dispose();
    _lead.dispose();
    _phone.dispose();
    _people.dispose();
    _jain.dispose();
    _rel.dispose();
    _city.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    if (store.data == null) return;
    final name = _name.text.trim();
    final people = int.tryParse(_people.text.trim());
    final jain = int.tryParse(_jain.text.trim().isEmpty ? '0' : _jain.text.trim());
    if (name.isEmpty) return setState(() => error = 'Add a name, like "Mehta family".');
    if (people == null || people < 1) return setState(() => error = 'How many people? At least 1.');
    if (jain == null || jain < 0 || jain > people) return setState(() => error = 'Jain count must be between 0 and $people.');
    if (status == rsvpYes && events.isEmpty) return setState(() => error = 'Pick the functions they are coming to.');
    store.saveGuest(
      id: widget.id,
      name: name,
      lead: _lead.text.trim(),
      phone: _phone.text.trim(),
      side: side,
      people: people,
      status: status,
      events: events.toList(),
      jain: jain,
      city: _city.text.trim(),
      rel: _rel.text.trim(),
    );
    Navigator.pop(context);
    toast(context, widget.id == null ? '$name added.' : '$name updated. Headcounts recalculated.');
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    final ok = await confirmAction(context, title: 'Remove this family?', body: 'They will be taken off the guest list and every headcount.', action: 'Remove');
    if (!ok || !mounted) return;
    StoreScope.read(context).deleteGuest(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final cs = Theme.of(context).colorScheme;
    final g = widget.id == null ? null : d?.guest(widget.id!);
    if (d == null || missing || (widget.id != null && g == null)) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This family is no longer on the list.'));
    }
    final isNew = g == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          g == null ? 'New family' : g.name,
          sub: g == null ? null : '${d.sideName(g.side)}${g.room == null ? '' : ' · room ${g.room}'}',
        ),
        if (g != null && g.phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  onPressed: () => callPhone(context, g.phone),
                  child: const IconLabel(icon: Icons.call_outlined, text: 'Call'),
                ),
                if (g.status == rsvpWait)
                  OutlinedButton(
                    onPressed: () {
                      store.markReminded(g.id);
                      openWhatsApp(context, rsvpReminderText(d), phone: g.phone);
                    },
                    child: const IconLabel(icon: Icons.chat_outlined, text: 'Remind'),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Family', hintText: 'Mehta family'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _lead,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Contact person', hintText: 'Rakesh Mehta'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number', hintText: '98290 12345'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _people,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'People'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _jain,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Of them, Jain'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _rel,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Relation', hintText: 'Mama ji, college friends...'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Coming from (city)'),
        ),
        const FieldLabel('Side'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in ['bride', 'groom'])
              ChoiceChip(
                avatar: SideDot(s),
                label: Text(d.sideName(s)),
                selected: side == s,
                onSelected: (_) => setState(() => side = s),
              ),
          ],
        ),
        const FieldLabel('RSVP'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in [rsvpYes, rsvpWait, rsvpNo])
              ChoiceChip(
                label: Text(rsvpLabels[s]!),
                selected: status == s,
                onSelected: (_) => setState(() => status = s),
              ),
          ],
        ),
        if (status != rsvpNo && d.events.isNotEmpty) ...[
          FieldLabel(status == rsvpYes ? 'Coming to' : 'Invited to'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in d.sortedEvents)
                FilterChip(
                  label: Text(e.name),
                  selected: events.contains(e.id),
                  onSelected: (v) => setState(() => v ? events.add(e.id) : events.remove(e.id)),
                ),
            ],
          ),
        ],
        if (g != null && g.remindedOn != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Reminded on WhatsApp on ${shortDate(g.remindedOn!)}', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Save family'),
        ),
        if (!isNew) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove family'),
          ),
        ],
      ],
    );
  }
}
