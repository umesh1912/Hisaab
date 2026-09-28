import 'package:flutter/material.dart';

import '../ui.dart';

Future<void> showFlatSheet(BuildContext context) => showAppSheet(context, (_) => const _FlatSheet());

class _FlatSheet extends StatelessWidget {
  const _FlatSheet();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120); // just reset, sheet is closing
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(d.flatName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Mark someone away and they skip chores and new equal splits.', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final m in d.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(id: m.id, name: m.name, dimmed: m.away),
            title: Text(m.id == d.meId ? '${m.name} (you)' : m.name),
            subtitle: Text(m.upi.isEmpty ? 'No UPI ID · tap to add' : m.upi),
            onTap: () => _editMember(context, m.id),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Away', style: tt.labelSmall),
                Switch(value: m.away, onChanged: (v) => store.setAway(m.id, v)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addMember(context),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add flatmate'),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Hisaab?'),
                content: const Text('This deletes every expense, chore and payment on this phone. It cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete everything'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              Navigator.pop(context);
              store.resetAll();
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset and start over'),
        ),
      ],
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final res = await _memberDialog(context, title: 'Add flatmate');
    if (res != null && res.$1.isNotEmpty && context.mounted) {
      StoreScope.read(context).addMember(res.$1, res.$2);
    }
  }

  Future<void> _editMember(BuildContext context, String id) async {
    final m = StoreScope.read(context).data!.member(id)!;
    final res = await _memberDialog(context, title: 'Edit ${m.name}', name: m.name, upi: m.upi);
    if (res != null && context.mounted) {
      StoreScope.read(context).updateMember(id, name: res.$1, upi: res.$2);
    }
  }
}

Future<(String, String)?> _memberDialog(BuildContext context, {required String title, String name = '', String upi = ''}) {
  final n = TextEditingController(text: name);
  final u = TextEditingController(text: upi);
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: n, autofocus: name.isEmpty, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: u,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'name@okaxis'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, (n.text.trim(), u.text.trim())), child: const Text('Save')),
      ],
    ),
  );
}
