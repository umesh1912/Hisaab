import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/household.dart';
import '../sheets/item_form.dart';
import '../ui.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final rooms = d.rooms;
    final roomWidth = (MediaQuery.sizeOf(context).width - 32 - 8) / 2;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            leading: CircleAvatar(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              child: Text(d.myName.isEmpty ? '?' : d.myName[0].toUpperCase()),
            ),
            title: Text(d.myName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d.homeName.isEmpty ? 'Add your home name' : d.homeName, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(tooltip: 'Edit profile', icon: const Icon(Icons.edit_outlined), onPressed: () => showProfileSheet(context)),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add online orders from email', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Copy the text of an order or delivery email from Amazon, Flipkart, Croma and others, and paste it. Rasid picks out the item, price, date and order number for you to check.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => showItemForm(context, paste: true),
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Paste an order email'),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(
          'Household',
          trailing: TextButton.icon(
            onPressed: () => showMemberSheet(context),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Add'),
          ),
        ),
        ListCard(
          children: [
            for (final m in d.members)
              ListTile(
                onTap: m.id == d.meId ? () => showProfileSheet(context) : () => showMemberSheet(context, memberId: m.id),
                leading: CircleAvatar(
                  backgroundColor: m.id == d.meId ? cs.primary : cs.tertiary,
                  foregroundColor: m.id == d.meId ? cs.onPrimary : cs.onTertiary,
                  child: Text(m.name.isEmpty ? '?' : m.name[0].toUpperCase()),
                ),
                title: Text(m.id == d.meId ? '${m.name} (you)' : m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${m.id == d.meId ? 'Owner' : 'Can add and claim'} · ${_count(d.items.where((i) => i.owner == m.id).length)}',
                ),
              ),
          ],
        ),
        if (rooms.isNotEmpty) ...[
          const SectionTitle('Rooms'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in rooms)
                  SizedBox(
                    width: roomWidth,
                    child: Material(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => store.searchVault(r),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(_count(d.items.where((i) => i.room == r).length), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SectionTitle('Export and backup'),
        ListCard(
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Copy list for insurance (CSV)'),
              subtitle: const Text('Items, prices, serials, shops and warranties'),
              onTap: () => copyText(context, insuranceCsv(d), 'CSV copied. Paste it into a sheet or an email.'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share a summary on WhatsApp'),
              onTap: () => shareWhatsApp(context, vaultSummary(d, today)),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Copy a full backup'),
              subtitle: const Text('Keep it in your notes or email to restore later'),
              onTap: () => copyText(context, store.exportJson(), 'Backup copied.'),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from a backup'),
              onTap: () => showRestoreSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Erase everything?',
                body: 'All bills, claims and reminders on this phone will be deleted. Copy a backup first if you want to keep them.',
                action: 'Erase',
              );
              if (ok) store.resetAll();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Erase all data'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Everything is stored only on this phone. Nothing is uploaded.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

String _count(int n) => '$n item${n == 1 ? '' : 's'}';
