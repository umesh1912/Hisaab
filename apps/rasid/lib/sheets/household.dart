import 'package:flutter/material.dart';

import '../ui.dart';

// ---------------- profile ----------------

Future<void> showProfileSheet(BuildContext context) => showAppSheet(context, (_) => const _Profile());

class _Profile extends StatefulWidget {
  const _Profile();

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  final _name = TextEditingController();
  final _home = TextEditingController();
  bool loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _home.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox.shrink();
    if (!loaded) {
      _name.text = d.myName;
      _home.text = d.homeName;
      loaded = true;
    }
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your profile', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your name')),
        const SizedBox(height: 12),
        TextField(
          controller: _home,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Home', hintText: 'Flat 204, Kondapur'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return;
            store.updateProfile(myName: n, homeName: _home.text.trim());
            Navigator.pop(context);
            toast(context, 'Profile saved.');
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------- household member ----------------

/// Add a person, or rename / remove the one with [memberId].
Future<void> showMemberSheet(BuildContext context, {String? memberId}) =>
    showAppSheet(context, (_) => _MemberSheet(memberId: memberId));

class _MemberSheet extends StatefulWidget {
  const _MemberSheet({this.memberId});
  final String? memberId;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  final _name = TextEditingController();
  bool loaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox.shrink();
    final id = widget.memberId;
    final m = id == null ? null : d.member(id);
    if (id != null && m == null) return const SizedBox(height: 120, child: Center(child: Text('This person was removed.')));
    if (!loaded && m != null) _name.text = m.name;
    loaded = true;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(m == null ? 'Add to household' : m.name, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('People in the household can own items. Everything stays on this phone.', style: tt.bodyMedium),
        const SizedBox(height: 16),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return;
            if (m == null) {
              store.addMember(n);
            } else {
              store.renameMember(m.id, n);
            }
            Navigator.pop(context);
            toast(context, m == null ? '$n added.' : 'Saved.');
          },
          child: Text(m == null ? 'Add person' : 'Save'),
        ),
        if (m != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () {
              final name = m.name;
              store.removeMember(m.id);
              Navigator.pop(context);
              toast(context, '$name removed. Their items are now yours.');
            },
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Remove from household'),
          ),
        ],
      ],
    );
  }
}

// ---------------- restore ----------------

Future<void> showRestoreSheet(BuildContext context) => showAppSheet(context, (_) => const _Restore());

class _Restore extends StatefulWidget {
  const _Restore();

  @override
  State<_Restore> createState() => _RestoreState();
}

class _RestoreState extends State<_Restore> {
  final _text = TextEditingController();
  String? error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Restore from a backup', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Paste the backup text you copied earlier. It replaces everything on this phone.', style: tt.bodyMedium),
        const SizedBox(height: 12),
        TextField(controller: _text, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: '{"homeName": …}')),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            final ok = StoreScope.read(context).importJson(_text.text);
            if (!ok) return setState(() => error = "That doesn't look like a Rasid backup.");
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Backup restored.'), behavior: SnackBarBehavior.floating));
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
