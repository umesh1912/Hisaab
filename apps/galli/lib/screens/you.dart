import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/area.dart';
import '../sheets/post_detail.dart';
import '../sheets/profile.dart';
import '../ui.dart';

/// Profile, your posts, areas, notification choices and data.
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = store.now;
    final mine = d.posts.where((p) => p.mine).toList()..sort((a, b) => b.at.compareTo(a.at));
    final hidden = d.posts.where((p) => p.hidden).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.primary,
                child: Text(
                  d.name.isEmpty ? '?' : d.name[0].toUpperCase(),
                  style: TextStyle(color: cs.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      '${d.locality} · ${d.points} helpful points',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => showProfileSheet(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Earn helpful points by confirming alerts (+1), adding sightings (+3) and telling owners about matches (+5).',
            style: TextStyle(fontSize: 13),
          ),
        ),

        SectionTitle('My posts', trailing: Text('${mine.length}', style: TextStyle(color: cs.onSurfaceVariant))),
        if (mine.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('You have not posted anything yet.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          for (final p in mine)
            Card(
              child: ListTile(
                onTap: () => showPostDetail(context, p.id),
                leading: Icon(typeIcons[p.type], color: typeColor(context, p.type)),
                title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${typeLabels[p.type]} · ${ago(now, p.at)} · '
                  '${p.resolved ? resolvedLabel(p.type) : (isEnded(p, now) ? 'Ended' : 'Live')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

        SectionTitle(
          'My areas',
          trailing: TextButton.icon(
            onPressed: () => showAreaSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        if (d.areas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Add home, office or your parents’ place.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < d.areas.length; i++)
                  ListTile(
                    onTap: () => showAreaSheet(context, index: i),
                    title: Text(d.areas[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Alerts within ${radiusLabel(d.areas[i].radiusKm)}'),
                    trailing: Switch(value: d.areas[i].on, onChanged: (v) => store.setAreaOn(i, v)),
                  ),
              ],
            ),
          ),

        const SectionTitle('Notify me about'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Chooses what shows under the bell. Galli does not send push notifications on this phone.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final pref in notifyPrefs)
                SwitchListTile(
                  value: d.prefs[pref[0]] ?? true,
                  onChanged: (v) {
                    store.setPref(pref[0], v);
                    toast(context, v ? '${pref[1]} will show under the bell.' : '${pref[1]} muted.');
                  },
                  title: Text(pref[1]),
                  subtitle: pref[2].isEmpty ? null : Text(pref[2]),
                ),
            ],
          ),
        ),

        const SectionTitle('Data'),
        Card(
          child: Column(
            children: [
              if (hidden > 0)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text('Show $hidden hidden post${hidden == 1 ? '' : 's'}'),
                  subtitle: const Text('Posts you reported'),
                  onTap: () {
                    store.unhideAll();
                    toast(context, 'Hidden posts are back in your feed.');
                  },
                ),
              ListTile(
                leading: Icon(Icons.restart_alt, color: cs.error),
                title: Text('Reset and start over', style: TextStyle(color: cs.error)),
                subtitle: const Text('Deletes everything Galli saved on this phone'),
                onTap: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Reset Galli?',
                    body: 'This deletes your posts, conversations and settings on this phone. It cannot be undone.',
                    action: 'Delete everything',
                  );
                  if (ok) store.resetAll();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
