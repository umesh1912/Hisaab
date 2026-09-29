import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showEditProfile(BuildContext context) => showAppSheet(context, (_) => const _EditProfileSheet());

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _bio = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  bool _ready = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _bio.dispose();
    _contact.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.data?.me;
    if (me == null) return const SizedBox.shrink();
    if (!_ready) {
      _name.text = me.name;
      _area.text = me.area;
      _bio.text = me.bio;
      _contact.text = me.contactName;
      _phone.text = me.contactPhone;
      _ready = true;
    }
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Edit profile'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _area,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Neighbourhood'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'About you', hintText: 'What you do and how you like to teach'),
        ),
        const FieldLabel('Trusted contact'),
        TextField(
          controller: _contact,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Mom'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
        ),
        const SizedBox(height: 6),
        Text(
          'Before an in-person session you can send them the time and place on WhatsApp.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            if (_name.text.trim().isEmpty) return setState(() => _error = 'Your name cannot be empty.');
            store.updateProfile(
              name: _name.text,
              area: _area.text,
              bio: _bio.text,
              contactName: _contact.text,
              contactPhone: _phone.text,
            );
            Navigator.pop(context);
            toast(context, 'Profile saved.');
          },
          child: const Text('Save profile'),
        ),
      ],
    );
  }
}
