import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showParentEdit(BuildContext context, String id) {
  final p = StoreScope.read(context).data!.parent(id);
  if (p == null) return Future<void>.value();
  return showAppSheet(context, (_) => _ParentEdit(parent: p));
}

class _ParentEdit extends StatefulWidget {
  const _ParentEdit({required this.parent});
  final Parent parent;

  @override
  State<_ParentEdit> createState() => _ParentEditState();
}

class _ParentEditState extends State<_ParentEdit> {
  late final TextEditingController _name = TextEditingController(text: widget.parent.name);
  late final TextEditingController _full = TextEditingController(text: widget.parent.full);
  late final TextEditingController _age = TextEditingController(text: widget.parent.age > 0 ? '${widget.parent.age}' : '');
  late final TextEditingController _phone = TextEditingController(text: widget.parent.phone);
  late final TextEditingController _cond = TextEditingController(text: widget.parent.conditions);

  @override
  void dispose() {
    for (final c in [_name, _full, _age, _phone, _cond]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('About ${widget.parent.name}'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'What you call them', hintText: 'Papa'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _full,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name (for the doctor summary)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cond,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Conditions', hintText: 'Type 2 diabetes, high BP'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            StoreScope.read(context).updateParent(
              widget.parent.id,
              name: _name.text,
              full: _full.text,
              age: int.tryParse(_age.text.trim()) ?? 0,
              phone: _phone.text,
              conditions: _cond.text,
            );
            Navigator.pop(context);
            toast(context, 'Saved.');
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
