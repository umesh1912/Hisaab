import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showAppSheet(context, (_) => const SettingsForm());
}

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _me = TextEditingController();
  final _bride = TextEditingController();
  final _groom = TextEditingController();
  final _city = TextEditingController();
  final _buffer = TextEditingController();
  String date = todayIso();
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    _me.text = d.myName;
    _bride.text = d.bride;
    _groom.text = d.groom;
    _city.text = d.city;
    _buffer.text = '${d.bufferPct}';
    date = d.weddingDate;
  }

  @override
  void dispose() {
    _me.dispose();
    _bride.dispose();
    _groom.dispose();
    _city.dispose();
    _buffer.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final v = await pickIsoDate(context, date);
    if (v != null) setState(() => date = v);
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final bride = _bride.text.trim(), groom = _groom.text.trim();
    final buffer = int.tryParse(_buffer.text.trim());
    if (bride.isEmpty || groom.isEmpty) return setState(() => error = "Add the bride's and groom's names.");
    if (buffer == null || buffer < 0 || buffer > 100) return setState(() => error = 'Buffer should be between 0 and 100%.');
    store.updateSettings(
      myName: _me.text.trim(),
      bride: bride,
      groom: groom,
      city: _city.text.trim(),
      weddingDate: date,
      hotelName: d.hotelName,
      hotelRooms: d.hotelRooms,
      perRoom: d.perRoom,
      bufferPct: buffer,
    );
    setState(() => error = null);
    toast(context, 'Wedding details saved.');
  }

  Future<void> _reset() async {
    final ok = await confirmAction(
      context,
      title: 'Start over?',
      body: 'This deletes every guest, task, budget line and vendor on this phone. It cannot be undone.',
      action: 'Delete everything',
    );
    if (!ok || !mounted) return;
    Navigator.pop(context);
    StoreScope.read(context).resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Wedding settings'),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _bride, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Bride')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(controller: _groom, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Groom')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(controller: _city, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 10),
        PickerField(label: 'Wedding day', value: '${dayName(date)}, ${longDate(date)}', icon: Icons.event, onTap: _pickDate),
        const SizedBox(height: 10),
        TextField(controller: _me, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your name')),
        const SizedBox(height: 10),
        TextField(
          controller: _buffer,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Caterer buffer', suffixText: '%', helperText: 'Extra plates on top of the confirmed count'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Save details'),
        ),

        const FieldLabel('Functions'),
        for (final e in d.sortedEvents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.celebration_outlined),
            title: Text(e.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${dayName(e.date)} ${shortDate(e.date)}, ${time12(e.time)}${e.venue.isEmpty ? '' : ' · ${e.venue}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showEventSheet(context, id: e.id),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showEventSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add function'),
          ),
        ),

        const FieldLabel('Helpers'),
        Text('Relatives who take on tasks. Their number is used to send tasks on WhatsApp.', style: TextStyle(color: cs.onSurfaceVariant)),
        for (final h in d.helpers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Initial(h.name),
            title: Text(h.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(h.phone.isEmpty ? 'No number' : prettyPhone(h.phone)),
            trailing: IconButton(
              tooltip: 'Remove ${h.name}',
              icon: const Icon(Icons.close),
              onPressed: () => StoreScope.read(context).removeHelper(h.name),
            ),
            onTap: () => showHelperSheet(context, name: h.name),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showHelperSheet(context),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add helper'),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),
        TextButton.icon(
          onPressed: _reset,
          style: TextButton.styleFrom(foregroundColor: cs.error),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Start over'),
        ),
        Text(
          'Everything is saved on this phone only.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

// ---------------- one function ----------------

Future<void> showEventSheet(BuildContext context, {String? id}) {
  return showAppSheet(context, (_) => EventForm(id: id));
}

class EventForm extends StatefulWidget {
  const EventForm({super.key, this.id});
  final String? id;

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _name = TextEditingController();
  final _venue = TextEditingController();
  String date = todayIso();
  String time = '19:00';
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
    date = d.weddingDate;
    final id = widget.id;
    if (id == null) return;
    final e = d.event(id);
    if (e == null) {
      missing = true;
      return;
    }
    _name.text = e.name;
    _venue.text = e.venue;
    date = e.date;
    time = e.time;
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final v = await pickIsoDate(context, date);
    if (v != null) setState(() => date = v);
  }

  Future<void> _pickTime() async {
    final p = time.split(':');
    final initial = TimeOfDay(hour: int.tryParse(p.first) ?? 19, minute: p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) setState(() => time = hhmm(t.hour, t.minute));
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => error = 'Name the function, like Mehendi.');
    StoreScope.read(context).saveEvent(id: widget.id, name: name, date: date, time: time, venue: _venue.text.trim());
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    final ok = await confirmAction(
      context,
      title: 'Delete this function?',
      body: 'Families invited to it and tasks for it are kept, but no longer linked to it.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    StoreScope.read(context).deleteEvent(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (missing) return const Padding(padding: EdgeInsets.all(24), child: Text('This function no longer exists.'));
    final isNew = widget.id == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(isNew ? 'New function' : 'Edit function'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Function', hintText: 'Cocktail night'),
        ),
        const SizedBox(height: 10),
        PickerField(label: 'Date', value: '${dayName(date)}, ${longDate(date)}', icon: Icons.event, onTap: _pickDate),
        const SizedBox(height: 10),
        PickerField(label: 'Time', value: time12(time), icon: Icons.schedule, onTap: _pickTime),
        const SizedBox(height: 10),
        TextField(
          controller: _venue,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Venue', hintText: 'Rajmahal Gardens'),
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
          child: const Text('Save function'),
        ),
        if (!isNew) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete function'),
          ),
        ],
      ],
    );
  }
}

// ---------------- one helper ----------------

Future<void> showHelperSheet(BuildContext context, {String? name}) {
  return showAppSheet(context, (_) => HelperForm(name: name));
}

class HelperForm extends StatefulWidget {
  const HelperForm({super.key, this.name});
  final String? name;

  @override
  State<HelperForm> createState() => _HelperFormState();
}

class _HelperFormState extends State<HelperForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final n = widget.name;
    final h = n == null ? null : StoreScope.read(context).data?.helper(n);
    if (h != null) {
      _name.text = h.name;
      _phone.text = h.phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => error = 'Add their name.');
    if (name == 'You') return setState(() => error = 'Pick another name.');
    if (name != widget.name && d.helper(name) != null) return setState(() => error = '$name is already a helper.');
    store.saveHelper(oldName: widget.name, name: name, phone: _phone.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(widget.name == null ? 'New helper' : 'Edit helper'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Mama ji'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number (optional)'),
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
          child: const Text('Save helper'),
        ),
      ],
    );
  }
}
