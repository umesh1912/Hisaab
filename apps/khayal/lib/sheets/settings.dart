import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showSettings(BuildContext context) {
  final d = StoreScope.read(context).data;
  if (d == null) return Future<void>.value();
  return showAppSheet(context, (_) => _Settings(data: d));
}

class _Settings extends StatefulWidget {
  const _Settings({required this.data});
  final AppData data;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  late final TextEditingController _me = TextEditingController(text: widget.data.caregiver);
  late final TextEditingController _myPhone = TextEditingController(text: widget.data.caregiverPhone);
  late final TextEditingController _address = TextEditingController(text: widget.data.address);
  late final TextEditingController _chemist = TextEditingController(text: widget.data.chemist);
  late final TextEditingController _chemistPhone = TextEditingController(text: widget.data.chemistPhone);
  bool confirmErase = false;

  @override
  void dispose() {
    for (final c in [_me, _myPhone, _address, _chemist, _chemistPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (store.data == null) return const SizedBox(height: 80);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Settings'),
        TextField(
          controller: _me,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _myPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Your phone (for the "Call" button)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(labelText: "Parents' home address (for deliveries)"),
        ),
        const SizedBox(height: 20),
        Text('Chemist', style: tt.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _chemist,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Shree Medical, Shivaji Nagar'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chemistPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            store.updateSettings(
              caregiver: _me.text,
              caregiverPhone: _myPhone.text,
              address: _address.text,
              chemist: _chemist.text,
              chemistPhone: _chemistPhone.text,
            );
            Navigator.pop(context);
            toast(context, 'Settings saved.');
          },
          child: const Text('Save settings'),
        ),
        const SizedBox(height: 24),
        if (!confirmErase)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () => setState(() => confirmErase = true),
            child: const Text('Erase all data'),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Erase every medicine, dose record and reading on this phone?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: cs.onErrorContainer),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => confirmErase = false),
                        child: const Text('Keep'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                        onPressed: () {
                          Navigator.pop(context);
                          store.resetAll();
                        },
                        child: const Text('Erase'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
