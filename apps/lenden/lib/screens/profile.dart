import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/edit_profile.dart';
import '../sheets/skill.dart';
import '../ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final me = d.me;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final done = d.sessions.where((s) => s.status == 'done').length;
    double taughtHrs(String skill) => d.sessions
        .where((s) => !s.isLearn && s.status == 'done' && s.skill == skill)
        .fold<double>(0, (a, s) => a + s.hrs);
    final contact = me.contactName.isEmpty ? 'your trusted contact' : me.contactName;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              Avatar(name: me.name, color: 0xFFE8552F, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.name,
                      overflow: TextOverflow.ellipsis,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${me.area.isEmpty ? 'No area set' : me.area} · $done ${done == 1 ? 'session' : 'sessions'} done',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => showEditProfile(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            me.bio.isEmpty ? 'Add a line about yourself so neighbours know what to expect.' : me.bio,
            style: me.bio.isEmpty ? TextStyle(color: cs.onSurfaceVariant) : tt.bodyLarge,
          ),
        ),
        SectionTitle(
          'I can teach',
          trailing: TextButton.icon(
            key: const ValueKey('add-teach'),
            onPressed: () => showAddSkill(context, teach: true),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        if (me.teaches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Add a skill so neighbours can find you.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            child: Column(
              children: [
                for (final t in me.teaches)
                  ListTile(
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${categories[t.cat] ?? 'Other'} · ${t.level} · taught ${hrsText(taughtHrs(t.name))} hr here'),
                    trailing: IconButton(
                      tooltip: 'Remove ${t.name}',
                      icon: const Icon(Icons.close),
                      onPressed: () => store.removeTeach(t.name),
                    ),
                  ),
              ],
            ),
          ),
        SectionTitle(
          'I want to learn',
          trailing: TextButton.icon(
            key: const ValueKey('add-learn'),
            onPressed: () => showAddSkill(context, teach: false),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: me.learns.isEmpty
                ? Text('Nothing yet. Add what you would like to learn.', style: TextStyle(color: cs.onSurfaceVariant))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final l in me.learns)
                        InputChip(
                          label: chipText(l),
                          onDeleted: () => store.removeLearn(l),
                          deleteButtonTooltipMessage: 'Remove $l',
                        ),
                    ],
                  ),
          ),
        ),
        const SectionTitle('Safety'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Share sessions with a trusted contact'),
                subtitle: Text('Send the time and place to $contact on WhatsApp from the check-in screen'),
                value: me.share,
                onChanged: (v) {
                  store.setShare(v);
                  toast(context, v ? 'Turned on.' : 'Turned off.');
                },
              ),
              SwitchListTile(
                title: const Text('Only show ID-verified people'),
                subtitle: const Text("Hides anyone who hasn't verified"),
                value: me.verifiedOnly,
                onChanged: (v) {
                  store.setVerifiedOnly(v);
                  toast(context, v ? 'Turned on.' : 'Turned off.');
                },
              ),
              SwitchListTile(
                title: const Text('Suggest public places only'),
                subtitle: const Text('Parks, libraries and cafés. Never home addresses.'),
                value: me.publicOnly,
                onChanged: (v) {
                  store.setPublicOnly(v);
                  toast(context, v ? 'Turned on.' : 'Turned off.');
                },
              ),
            ],
          ),
        ),
        if (d.blocked.isNotEmpty) ...[
          const SectionTitle('Blocked'),
          Card(
            child: Column(
              children: [
                for (final id in d.blocked)
                  ListTile(
                    leading: d.person(id) == null ? null : PersonAvatar(d.person(id)!, size: 36),
                    title: Text(d.person(id)?.name ?? 'Unknown'),
                    trailing: TextButton(
                      onPressed: () {
                        store.unblock(id);
                        toast(context, 'Unblocked.');
                      },
                      child: const Text('Unblock'),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SectionTitle('Your data'),
        Card(
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text('Erase all data', style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
            subtitle: const Text('Removes your profile, swaps, chats and credits from this phone.'),
            onTap: () async {
              final ok = await confirm(context, 'Erase everything?', 'This cannot be undone.', 'Erase');
              if (ok) store.resetAll();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Everything is saved on this phone. Neighbours in this version are sample profiles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
