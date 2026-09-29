import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/helper.dart';
import '../sheets/parent_edit.dart';
import '../sheets/share_text.dart';
import '../ui.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final order = ladder(d.helpers);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SectionTitle('Who gets told'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text("If a dose isn't confirmed, work up this ladder until someone responds."),
        ),
        Card(
          child: Column(
            children: [
              const _Step(minutes: 0, text: "The dose shows as due on Today and on the parent's screen"),
              const Divider(height: 1),
              const _Step(minutes: 60, text: 'Not confirmed: it turns red on Today with a Call button'),
              for (final h in order) ...[
                const Divider(height: 1),
                _Step(
                  minutes: h.step,
                  text: h.id == 'me' ? 'You check in with a call' : 'Ask ${h.name} to check, with one tap on WhatsApp',
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: const InfoNote(
            "This app works on this phone only: it can't ring alarms or push alerts to others. "
            'Keep Khayal open on Today to see missed doses as they happen.',
          ),
        ),
        SectionTitle(
          'Family and helpers',
          trailing: TextButton.icon(
            onPressed: () => showHelperSheet(context),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Invite'),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final h in d.helpers)
                ListTile(
                  leading: Avatar(name: h.name, color: avatarColor(h.id)),
                  title: Text(h.id == 'me' ? '${h.name} (you)' : h.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${h.rel.isEmpty ? 'Helper' : h.rel} · after ${h.step} min'),
                  trailing: Switch(
                    value: h.on,
                    onChanged: (v) {
                      store.toggleHelper(h.id, v);
                      toast(context, v ? '${h.name} is back on the ladder.' : "${h.name} won't be asked.");
                    },
                  ),
                  onTap: () => showHelperSheet(context, id: h.id),
                ),
            ],
          ),
        ),
        const SectionTitle('Parents'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final p in d.parents)
                ListTile(
                  leading: Avatar(name: p.name, color: Color(p.color)),
                  title: Text(p.full.isEmpty ? p.name : '${p.name} · ${p.full}', overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.phone.isEmpty ? 'No phone number' : p.phone),
                  trailing: IconButton(
                    tooltip: 'Call ${p.name}',
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => callPhone(context, p.phone, p.name),
                  ),
                  onTap: () => showParentEdit(context, p.id),
                ),
            ],
          ),
        ),
        const SectionTitle('Settings'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile(
                value: d.quietHours,
                onChanged: store.setQuietHours,
                title: const Text('Quiet hours for helpers'),
                subtitle: const Text("11 PM to 6 AM: don't suggest asking neighbours"),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.summarize_outlined),
                title: const Text('Weekly summary'),
                subtitle: const Text('Doses, readings and refills for the family group'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showShareText(
                  context,
                  title: 'Weekly summary',
                  intro: 'Send this to the family group on Sunday.',
                  text: weeklySummary(d: d, now: DateTime.now()),
                  copied: 'Summary copied.',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Khayal is a reminder and record tool, not medical advice.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.minutes, required this.text});
  final int minutes;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text('$minutes min', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
