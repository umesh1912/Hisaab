import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showTaskSheet(BuildContext context, {int? id}) {
  return showAppSheet(context, (_) => TaskForm(id: id));
}

class TaskForm extends StatefulWidget {
  const TaskForm({super.key, this.id});
  final int? id;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _title = TextEditingController();
  final _newName = TextEditingController();
  final _newPhone = TextEditingController();
  String ev = '';
  String who = 'You';
  bool addingPerson = false;
  late String due = addDaysIso(todayIso(), 14);
  bool notify = true;
  bool missing = false;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final id = widget.id;
    if (id != null) {
      final t = d.task(id);
      if (t == null) {
        missing = true;
        return;
      }
      _title.text = t.title;
      ev = d.event(t.ev) == null ? '' : t.ev;
      who = t.who;
      due = t.due;
      notify = false;
    } else {
      ev = store.currentEvent?.id ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _newName.dispose();
    _newPhone.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final v = await pickIsoDate(context, due);
    if (v != null) setState(() => due = v);
  }

  void _save() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final title = _title.text.trim();
    if (title.isEmpty) return setState(() => error = 'Describe the task.');
    var person = who;
    if (addingPerson) {
      final name = _newName.text.trim();
      if (name.isEmpty) return setState(() => error = 'Add the name of the person who will do it.');
      store.saveHelper(name: name, phone: _newPhone.text.trim());
      person = name;
    }
    final id = store.saveTask(id: widget.id, title: title, who: person, ev: ev, due: due);
    final isNew = widget.id == null;
    final phone = d.helper(person)?.phone ?? '';
    final t = d.task(id);
    Navigator.pop(context);
    if (person != 'You' && notify && t != null) {
      toast(context, isNew ? 'Task added. Opening WhatsApp for $person.' : 'Saved. Opening WhatsApp for $person.');
      openWhatsApp(context, taskMessage(d, t), phone: phone);
    } else {
      toast(context, isNew ? 'Task added.' : 'Task saved.');
    }
  }

  Future<void> _delete() async {
    final id = widget.id;
    if (id == null) return;
    final ok = await confirmAction(context, title: 'Delete this task?', body: 'It will be removed for good.', action: 'Delete');
    if (!ok || !mounted) return;
    StoreScope.read(context).deleteTask(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final cs = Theme.of(context).colorScheme;
    if (d == null || missing) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This task no longer exists.'));
    }
    final people = <String>['You', ...d.helpers.map((h) => h.name)];
    if (!people.contains(who)) people.add(who);
    final isNew = widget.id == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(isNew ? 'New task' : 'Edit task'),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Task', hintText: 'Arrange 2 cars for baraat from hotel'),
        ),
        const FieldLabel('For which function'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in d.sortedEvents)
              ChoiceChip(label: Text(e.name), selected: ev == e.id, onSelected: (_) => setState(() => ev = e.id)),
            ChoiceChip(label: const Text('General'), selected: ev == '', onSelected: (_) => setState(() => ev = '')),
          ],
        ),
        const FieldLabel('Who will do it'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in people)
              ChoiceChip(
                label: Text(p),
                selected: !addingPerson && who == p,
                onSelected: (_) => setState(() {
                  who = p;
                  addingPerson = false;
                }),
              ),
            ChoiceChip(
              avatar: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Someone new'),
              selected: addingPerson,
              onSelected: (_) => setState(() => addingPerson = true),
            ),
          ],
        ),
        if (addingPerson) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _newName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Chacha ji'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'WhatsApp number (optional)', hintText: '98290 12345'),
          ),
        ],
        const SizedBox(height: 14),
        PickerField(label: 'Due', value: '${dayName(due)}, ${longDate(due)}', icon: Icons.event, onTap: _pickDue),
        if (addingPerson || who != 'You')
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notify,
            onChanged: (v) => setState(() => notify = v),
            title: const Text('Send it to them on WhatsApp'),
            subtitle: const Text('Opens WhatsApp with the task written out'),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(isNew ? 'Add task' : 'Save changes'),
        ),
        if (!isNew) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete task'),
          ),
        ],
      ],
    );
  }
}
