import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Add someone to the alert ladder, or edit them when [id] is given.
Future<void> showHelperSheet(BuildContext context, {String? id}) {
  final h = id == null ? null : StoreScope.read(context).data!.helper(id);
  return showAppSheet(context, (_) => _HelperSheet(existing: h));
}

class _HelperSheet extends StatefulWidget {
  const _HelperSheet({required this.existing});
  final Helper? existing;

  @override
  State<_HelperSheet> createState() => _HelperSheetState();
}

class _HelperSheetState extends State<_HelperSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _rel = TextEditingController(text: widget.existing?.rel ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late int step = widget.existing?.step ?? 60;
  String? error;

  @override
  void dispose() {
    _name.dispose();
    _rel.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _invite(String name, String caregiver, String parents) =>
      "Namaste $name, I've added you as a helper for $parents in Khayal. "
      "If a medicine isn't confirmed, I may message you to check on them. Thank you! – $caregiver";

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final editing = widget.existing;
    final isMe = editing?.id == 'me';
    final parents = d.parents.map((p) => p.name).join(' and ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(editing == null ? 'Add a helper' : (isMe ? 'You' : editing.name)),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Neha'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rel,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Who they are', hintText: 'Daughter · Bengaluru'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number'),
        ),
        const SizedBox(height: 16),
        Text('Ask after', style: tt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final s in stepChoices)
              ChoiceChip(label: Text('$s min'), selected: step == s, onSelected: (_) => setState(() => step = s)),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return setState(() => error = 'Add a name.');
            store.saveHelper(id: editing?.id, name: n, rel: _rel.text.trim(), phone: _phone.text.trim(), step: step);
            Navigator.pop(context);
            toast(context, editing == null ? '$n added. Send them an invite so they know.' : 'Saved.');
          },
          child: const Text('Save'),
        ),
        if (!isMe) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              final n = _name.text.trim();
              if (n.isEmpty) return setState(() => error = 'Add a name first.');
              whatsApp(context, _phone.text.trim(), _invite(n, d.caregiver, parents));
            },
            child: const Text('Send invite on WhatsApp'),
          ),
        ],
        if (editing != null && !isMe) ...[
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () {
              store.deleteHelper(editing.id);
              Navigator.pop(context);
              toast(context, '${editing.name} removed.');
            },
            child: const Text('Remove from ladder'),
          ),
        ],
      ],
    );
  }
}
